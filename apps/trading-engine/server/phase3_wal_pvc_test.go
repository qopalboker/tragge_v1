//nolint:errcheck,goconst,gosec,gocyclo,noctx,staticcheck,ineffassign,prealloc,gofmt,goimports // E2E/integration test harness
package server

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"

	"go.uber.org/zap"
)

// TestPhase3_WALPVCRescheduleSimulation models Kubernetes PVC reattach:
// write durable WAL → close process → reopen same path → recover pending →
// no duplicate after commit.
//
// Invoked by scripts/phase3/wal-pvc-reschedule-sim.mjs with WAL_PVC_SIM_PATH.
func TestPhase3_WALPVCRescheduleSimulation(t *testing.T) {
	walPath := os.Getenv("WAL_PVC_SIM_PATH")
	if walPath == "" {
		dir := t.TempDir()
		walPath = filepath.Join(dir, "engine.jsonl")
	} else {
		// Ensure parent exists (PVC mount)
		if err := os.MkdirAll(filepath.Dir(walPath), 0o750); err != nil {
			t.Fatalf("mkdir: %v", err)
		}
	}

	// --- Phase 1: "pod A" writes durable intent ---
	wal1, err := NewWriteAheadLog(WALConfig{MaxEntries: 1000, PersistPath: walPath}, zap.NewNop())
	if err != nil {
		t.Fatalf("open wal1: %v", err)
	}
	data, _ := json.Marshal(PositionUpdateData{
		PositionID: "pvc-pos-1", Symbol: "BTC/USD", Side: "long",
		QtyOpen: 10, EntryPrice: 50000, QtyUsed: 10,
	})
	seq, err := wal1.Write(WALOpCreatePosition, "contest-pvc", "user-pvc", "BTC/USD", data)
	if err != nil {
		t.Fatalf("write: %v", err)
	}
	if seq == 0 {
		t.Fatal("seq 0")
	}
	// Simulate crash before MarkCommitted (Crash C-ish pending)
	if err := wal1.Close(); err != nil {
		t.Fatalf("close1: %v", err)
	}

	// --- Phase 2: "pod delete" — only durable volume remains ---
	if _, err := os.Stat(walPath); err != nil {
		t.Fatalf("WAL must survive process death: %v", err)
	}

	// --- Phase 3: "pod B" reattaches same PVC path ---
	wal2, err := NewWriteAheadLog(WALConfig{MaxEntries: 1000, PersistPath: walPath}, zap.NewNop())
	if err != nil {
		t.Fatalf("open wal2 after remount: %v", err)
	}
	defer wal2.Close()

	pending := wal2.GetPendingEntries()
	if len(pending) != 1 {
		t.Fatalf("expected 1 pending after PVC reattach, got %d", len(pending))
	}
	if pending[0].SeqNum != seq || pending[0].Symbol != "BTC/USD" {
		t.Fatalf("recovered entry mismatch: %+v", pending[0])
	}

	// Recovery resolves pending (DB check would discard or apply).
	// Here we commit once — second open must not re-pending.
	if !wal2.MarkCommitted(seq) {
		t.Fatal("MarkCommitted failed")
	}
	if err := wal2.Close(); err != nil {
		t.Fatalf("close2: %v", err)
	}

	wal3, err := NewWriteAheadLog(WALConfig{MaxEntries: 1000, PersistPath: walPath}, zap.NewNop())
	if err != nil {
		t.Fatalf("open wal3: %v", err)
	}
	defer wal3.Close()
	if n := len(wal3.GetPendingEntries()); n != 0 {
		t.Fatalf("after commit remount expected 0 pending, got %d", n)
	}

	// Storage failure: unwritable path must fail closed (no ephemeral fallback)
	t.Run("storage_unwritable_fail_closed", func(t *testing.T) {
		bad := filepath.Join(t.TempDir(), "no-such", "nested", "engine.jsonl")
		// Parent not created → OpenFile fails after load miss... actually load returns nil for missing file
		// Create parent as a file so OpenFile fails
		parent := filepath.Dir(bad)
		if err := os.WriteFile(parent, []byte("not-a-dir"), 0o600); err != nil {
			// create parent dir then replace with file
			_ = os.MkdirAll(filepath.Dir(parent), 0o750)
			_ = os.WriteFile(parent, []byte("x"), 0o600)
		}
		_, err := NewWriteAheadLog(WALConfig{MaxEntries: 10, PersistPath: bad}, zap.NewNop())
		if err == nil {
			t.Fatal("expected fail-closed when WAL path not openable")
		}
	})

	// Corrupt WAL directory content fail-closed
	t.Run("corrupt_wal_fail_closed", func(t *testing.T) {
		dir := t.TempDir()
		p := filepath.Join(dir, "bad.jsonl")
		if err := os.WriteFile(p, []byte("not-json\n"), 0o640); err != nil {
			t.Fatal(err)
		}
		_, err := NewWriteAheadLog(WALConfig{MaxEntries: 10, PersistPath: p}, zap.NewNop())
		if err == nil {
			t.Fatal("corrupt WAL must refuse to open")
		}
	})

	_ = context.Background()
}
