//nolint:errcheck,goconst,gosec,gocyclo,noctx,staticcheck,ineffassign,prealloc,gofmt,goimports // E2E/integration test harness
package wallet

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"
)

// TestPhase3_BackupRestoreDrill proves backup material can be produced from the
// live database and critical relations remain queryable after a logical snapshot
// into a restore schema (no host pg_dump required).
//
// Steps:
//  1. Connect to live Postgres
//  2. CREATE SCHEMA restore_drill_* and copy critical tables via CREATE TABLE AS
//  3. Validate row-count parity for non-empty or structure presence
//  4. Write a dump manifest file (operator artifact)
//  5. DROP restore schema
func TestPhase3_BackupRestoreDrill(t *testing.T) {
	if testing.Short() {
		t.Skip("short")
	}
	db := openE2E(t)
	defer db.Close()
	ctx := context.Background()

	schema := fmt.Sprintf("restore_drill_%d", time.Now().Unix())
	if _, err := db.ExecContext(ctx, "CREATE SCHEMA "+schema); err != nil {
		t.Fatalf("create schema: %v", err)
	}
	defer func() {
		_, _ = db.ExecContext(context.Background(), "DROP SCHEMA IF EXISTS "+schema+" CASCADE")
	}()

	// Critical business tables (Phase 3 Test F)
	tables := []string{
		"users",
		"contests",
		"contest_participants",
		"orders",
		"fills",
		"positions",
		"wallets",
		"wallet_ledger",
		"contest_settlements",
	}

	type snap struct {
		table string
		count int64
	}
	var snaps []snap
	for _, tbl := range tables {
		var exists bool
		if err := db.QueryRowContext(ctx, `
			SELECT EXISTS (
			  SELECT 1 FROM information_schema.tables
			  WHERE table_schema='public' AND table_name=$1
			)`, tbl).Scan(&exists); err != nil || !exists {
			t.Fatalf("critical table missing in source: %s", tbl)
		}
		var n int64
		if err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM "+tbl).Scan(&n); err != nil {
			t.Fatalf("count %s: %v", tbl, err)
		}
		// Logical backup: structure + data into restore schema
		q := fmt.Sprintf(`CREATE TABLE %s.%s AS TABLE public.%s`, schema, tbl, tbl)
		if _, err := db.ExecContext(ctx, q); err != nil {
			t.Fatalf("snapshot %s: %v", tbl, err)
		}
		var n2 int64
		if err := db.QueryRowContext(ctx, "SELECT COUNT(*) FROM "+schema+"."+tbl).Scan(&n2); err != nil {
			t.Fatalf("restore count %s: %v", tbl, err)
		}
		if n2 != n {
			t.Fatalf("parity fail %s: source=%d restore=%d", tbl, n, n2)
		}
		snaps = append(snaps, snap{table: tbl, count: n})
	}

	// Operator artifact
	dir := t.TempDir()
	manifest := filepath.Join(dir, "backup_manifest.txt")
	f, err := os.Create(manifest)
	if err != nil {
		t.Fatal(err)
	}
	fmt.Fprintf(f, "phase3_backup_restore schema=%s ts=%s\n", schema, time.Now().UTC().Format(time.RFC3339))
	for _, s := range snaps {
		fmt.Fprintf(f, "%s\t%d\n", s.table, s.count)
	}
	f.Close()
	info, _ := os.Stat(manifest)
	if info.Size() < 10 {
		t.Fatal("manifest empty")
	}
	t.Logf("PASS backup/restore drill tables=%d manifest=%s", len(snaps), manifest)
}
