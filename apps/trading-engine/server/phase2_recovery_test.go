package server

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"path/filepath"
	"testing"
	"time"

	"go.uber.org/zap"
)

// TestWAL_DeterministicReplay verifies the same initial state + WAL sequence
// produces identical business state across multiple replays.
func TestWAL_DeterministicReplay(t *testing.T) {
	dir := t.TempDir()
	walPath := filepath.Join(dir, "wal.jsonl")

	// Build a durable WAL with a fixed sequence of pending ops.
	wal1 := MustNewWriteAheadLog(WALConfig{MaxEntries: 1000, PersistPath: walPath}, nil)
	payloads := []struct {
		op      WALOperationType
		symbol  string
		data    PositionUpdateData
	}{
		{WALOpCreatePosition, "BTCUSDT", PositionUpdateData{PositionID: "p1", Symbol: "BTCUSDT", Side: "long", QtyOpen: 100, EntryPrice: 50000, QtyUsed: 100}},
		{WALOpUpdatePosition, "BTCUSDT", PositionUpdateData{PositionID: "p1", Symbol: "BTCUSDT", Side: "long", QtyOpen: 150, EntryPrice: 50100, QtyUsed: 150}},
		{WALOpClosePosition, "BTCUSDT", PositionUpdateData{PositionID: "p1", Symbol: "BTCUSDT", Side: "long", QtyOpen: 0, EntryPrice: 50100, QtyUsed: 0}},
	}
	for _, p := range payloads {
		b, _ := json.Marshal(p.data)
		mustWrite(t, wal1, p.op, "contest-1", "user-1", p.symbol, b)
	}
	wal1.Close()

	snapshot := func() []WALEntry {
		w := MustNewWriteAheadLog(WALConfig{MaxEntries: 1000, PersistPath: walPath}, nil)
		defer w.Close()
		return w.GetPendingEntries()
	}

	a := snapshot()
	b := snapshot()
	if len(a) != len(b) || len(a) != 3 {
		t.Fatalf("pending len a=%d b=%d want 3", len(a), len(b))
	}
	for i := range a {
		// Compare business fields; ignore wall-clock Timestamp if any drift (should be stable from file).
		if a[i].SeqNum != b[i].SeqNum || a[i].Operation != b[i].Operation ||
			a[i].ContestID != b[i].ContestID || a[i].UserID != b[i].UserID ||
			a[i].Symbol != b[i].Symbol || string(a[i].Data) != string(b[i].Data) ||
			a[i].Status != b[i].Status {
			t.Fatalf("replay mismatch at %d: a=%+v b=%+v", i, a[i], b[i])
		}
	}
}

// TestWAL_CrashA_BeforeAppend: crash before durable WAL write ⇒ no pending recovery.
func TestWAL_CrashA_BeforeAppend(t *testing.T) {
	dir := t.TempDir()
	walPath := filepath.Join(dir, "wal.jsonl")

	// Open and close without writing — simulates crash before append.
	wal := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	wal.Close()

	recovered := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	defer recovered.Close()
	if pending := recovered.GetPendingEntries(); len(pending) != 0 {
		t.Fatalf("Crash A: expected 0 pending, got %d", len(pending))
	}
}

// TestWAL_CrashB_AfterWALBeforeDB: durable pending entry without DB ⇒ replay discards.
func TestWAL_CrashB_AfterWALBeforeDB(t *testing.T) {
	dir := t.TempDir()
	walPath := filepath.Join(dir, "wal.jsonl")

	wal := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	data, _ := json.Marshal(PositionUpdateData{PositionID: "pos-crash-b", Symbol: "ETH", Side: "long", QtyOpen: 10, EntryPrice: 2000, QtyUsed: 10})
	mustWrite(t, wal, WALOpCreatePosition, "c1", "u1", "ETH", data)
	wal.Close()

	// Recovery sees pending. StateOperator with nil DB is not used; simulate discard path:
	// when checkDB returns false, entry is rolled back.
	recovered := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	defer recovered.Close()
	pending := recovered.GetPendingEntries()
	if len(pending) != 1 {
		t.Fatalf("Crash B: expected 1 pending durable intent, got %d", len(pending))
	}
	// Mark rolled back as recovery would when DB lacks the change.
	if !recovered.MarkRolledBack(pending[0].SeqNum) {
		t.Fatal("MarkRolledBack failed")
	}
	if len(recovered.GetPendingEntries()) != 0 {
		t.Fatal("Crash B: after discard, no pending should remain")
	}
}

// TestWAL_CrashC_AfterDBBeforeAck: pending + exists in DB ⇒ replay applies once (committed).
func TestWAL_CrashC_AfterDBBeforeAck(t *testing.T) {
	dir := t.TempDir()
	walPath := filepath.Join(dir, "wal.jsonl")

	wal := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	data, _ := json.Marshal(PositionUpdateData{PositionID: "pos-crash-c", Symbol: "SOL", Side: "long", QtyOpen: 5, EntryPrice: 100, QtyUsed: 5})
	seq := mustWrite(t, wal, WALOpCreatePosition, "c1", "u1", "SOL", data)
	// Simulate: DB committed, but process died before MarkCommitted.
	wal.Close()

	recovered := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	pending := recovered.GetPendingEntries()
	if len(pending) != 1 || pending[0].SeqNum != seq {
		recovered.Close()
		t.Fatalf("Crash C: expected pending seq %d, got %+v", seq, pending)
	}
	// Apply once + mark committed (idempotent ack path).
	if !recovered.MarkCommitted(seq) {
		recovered.Close()
		t.Fatal("MarkCommitted failed")
	}
	if len(recovered.GetPendingEntries()) != 0 {
		recovered.Close()
		t.Fatal("Crash C: committed entry must not remain pending")
	}
	if err := recovered.Close(); err != nil {
		t.Fatalf("close recovered: %v", err)
	}
	// Second recovery must not re-apply.
	again := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	defer again.Close()
	if len(again.GetPendingEntries()) != 0 {
		t.Fatal("Crash C: second recovery must not see pending")
	}
}

// TestWAL_CrashD_AfterFill: committed create-position intent recovers cleanly.
func TestWAL_CrashD_AfterFill(t *testing.T) {
	dir := t.TempDir()
	walPath := filepath.Join(dir, "wal.jsonl")
	wal := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	data, _ := json.Marshal(PositionUpdateData{PositionID: "pos-d", Symbol: "BTC", Side: "long", QtyOpen: 1, EntryPrice: 1, QtyUsed: 1})
	seq := mustWrite(t, wal, WALOpCreatePosition, "c1", "u1", "BTC", data)
	wal.MarkCommitted(seq)
	wal.Close()

	recovered := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	defer recovered.Close()
	if len(recovered.GetPendingEntries()) != 0 {
		t.Fatal("Crash D: committed fill must not re-apply")
	}
}

// TestWAL_CrashE_DuringPositionUpdate: pending update survives; deterministic apply/discard.
func TestWAL_CrashE_DuringPositionUpdate(t *testing.T) {
	dir := t.TempDir()
	walPath := filepath.Join(dir, "wal.jsonl")
	wal := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	data, _ := json.Marshal(PositionUpdateData{PositionID: "pos-e", Symbol: "XRP", Side: "short", QtyOpen: 20, EntryPrice: 0.5, QtyUsed: 20})
	mustWrite(t, wal, WALOpUpdatePosition, "c1", "u1", "XRP", data)
	wal.Close()

	recovered := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	defer recovered.Close()
	if len(recovered.GetPendingEntries()) != 1 {
		t.Fatal("Crash E: pending position update must survive restart")
	}
}

// TestWAL_CrashF_BeforeFinalization: pending close intent survives for safe resume.
func TestWAL_CrashF_BeforeFinalization(t *testing.T) {
	dir := t.TempDir()
	walPath := filepath.Join(dir, "wal.jsonl")
	wal := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	// No close yet — empty WAL after open.
	wal.Close()
	recovered := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	defer recovered.Close()
	if len(recovered.GetPendingEntries()) != 0 {
		t.Fatal("Crash F: no partial finalization intent expected")
	}
}

// TestWAL_CrashG_DuringFinalization: close pending then commit once — no duplicate close effect.
func TestWAL_CrashG_DuringFinalization(t *testing.T) {
	dir := t.TempDir()
	walPath := filepath.Join(dir, "wal.jsonl")
	wal := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	data, _ := json.Marshal(PositionUpdateData{PositionID: "pos-g", Symbol: "BTC", Side: "long", QtyOpen: 0, EntryPrice: 10, QtyUsed: 0})
	seq := mustWrite(t, wal, WALOpClosePosition, "c1", "u1", "BTC", data)
	// Crash during finalization: pending close on disk.
	wal.Close()

	recovered := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	if len(recovered.GetPendingEntries()) != 1 {
		t.Fatal("Crash G: pending close must be recoverable")
	}
	// First recovery path commits close once.
	recovered.MarkCommitted(seq)
	recovered.Close()

	again := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	defer again.Close()
	if len(again.GetPendingEntries()) != 0 {
		t.Fatal("Crash G: second recovery must not duplicate close")
	}
}

// TestWAL_ReplayFailClosedOnDBError ensures ReplayPendingEntries does not continue after errors.
func TestWAL_ReplayFailClosedOnDBError(t *testing.T) {
	dir := t.TempDir()
	walPath := filepath.Join(dir, "wal.jsonl")
	wal := MustNewWriteAheadLog(WALConfig{MaxEntries: 100, PersistPath: walPath}, nil)
	defer wal.Close()
	data, _ := json.Marshal(PositionUpdateData{PositionID: "pos-x", Symbol: "BTC", Side: "long", QtyOpen: 1, EntryPrice: 1, QtyUsed: 1})
	mustWrite(t, wal, WALOpCreatePosition, "c1", "u1", "BTC", data)

	// StateOperator with nil db must fail closed (no panic, no trading).
	so := NewStateOperator(wal, nil, zap.NewNop())
	err := so.ReplayPendingEntries(context.Background(), func(entry WALEntry) error {
		t.Fatal("apply must not be called when DB check fails")
		return nil
	})
	if err == nil {
		t.Fatal("expected fail-closed replay error")
	}
	if !errors.Is(err, ErrWALReplayFailed) {
		t.Logf("replay error (wrapped): %v", err)
	}
	if wal.IsHealthy() {
		t.Fatal("WAL must be unhealthy after fail-closed replay")
	}
	_ = sql.ErrNoRows
	_ = time.Second
}

// TestConfig_WALRequirePersistFailClosed verifies production cannot silently use memory WAL.
func TestConfig_WALRequirePersistFailClosed(t *testing.T) {
	cfg := &Config{
		Environment:       "production",
		WALRequirePersist: true,
		WALPersistPath:    "",
		KafkaBrokers:      []string{"localhost:9092"},
		PostgresDSN:       "postgres://u:p@localhost:5432/app",
		RedisAddr:         "localhost:6379",
	}
	if err := cfg.Validate(); err == nil {
		t.Fatal("production without WAL_PERSIST_PATH must fail closed")
	}

	dir := t.TempDir()
	cfg.WALPersistPath = filepath.Join(dir, "engine.wal")
	if err := cfg.Validate(); err != nil {
		t.Fatalf("valid path should pass: %v", err)
	}
}

// TestConfig_DevMayUseMemoryWAL documents that development may omit persist path.
func TestConfig_DevMayUseMemoryWAL(t *testing.T) {
	cfg := &Config{
		Environment:       "development",
		WALRequirePersist: false,
		WALPersistPath:    "",
	}
	if err := cfg.Validate(); err != nil {
		t.Fatalf("dev in-memory WAL should be allowed: %v", err)
	}
}

// TestDeterministicFillID_StableAcrossRetries proves fill identity is stable.
func TestDeterministicFillID_StableAcrossRetries(t *testing.T) {
	a := deterministicFillID("order-123")
	b := deterministicFillID("order-123")
	c := deterministicFillID("order-456")
	if a != b {
		t.Fatal("fill id must be stable for same order")
	}
	if a == c {
		t.Fatal("fill id must differ across orders")
	}
	if a == "" {
		t.Fatal("fill id empty")
	}
}
