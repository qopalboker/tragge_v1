//nolint:errcheck,gosec,goconst // E2E harness against local Postgres; credentials from env/files.
package server

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func idempotencyDSN(t *testing.T) string {
	t.Helper()
	if v := os.Getenv("TRAGGE_E2E_DATABASE_URL"); v != "" {
		return v
	}
	// Prefer env path; fall back to monorepo secrets file for local Compose.
	passPath := os.Getenv("TRAGGE_E2E_PG_PASS_FILE")
	if passPath == "" {
		passPath = filepath.Join("..", "..", "infra", "docker", "secrets", "postgres_admin_password.txt")
	}
	b, err := os.ReadFile(passPath) //nolint:gosec // local e2e password file path
	if err != nil {
		t.Skipf("no db credentials: %v", err)
	}
	pass := strings.TrimSpace(string(b))
	return fmt.Sprintf("postgres://tragge_admin:%s@127.0.0.1:5432/app?sslmode=disable", pass)
}

// Concurrent claims of the same client_order_id must return the same order_id once.
func TestClaimClientOrderID_Concurrent(t *testing.T) {
	db, err := sql.Open("pgx", idempotencyDSN(t))
	if err != nil {
		t.Fatal(err)
	}
	defer db.Close()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := db.PingContext(ctx); err != nil {
		t.Skipf("postgres: %v", err)
	}
	var exists bool
	_ = db.QueryRowContext(ctx, `SELECT EXISTS (
		SELECT 1 FROM information_schema.tables WHERE table_name='order_client_submissions')`).Scan(&exists)
	if !exists {
		t.Skip("migration 0105 not applied")
	}

	// Concurrent INSERT ... ON CONFLICT is the durable gate (same SQL as claimClientOrderID).
	clientOrderID := uuid.New().String()
	userID := uuid.New().String()
	contestID := uuid.New().String()

	// Ensure fake users/contests not required — table has no FKs
	var wg sync.WaitGroup
	const n = 16
	orderIDs := make([]string, n)
	errs := make([]error, n)
	for i := 0; i < n; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			_, err := db.ExecContext(ctx, `
				INSERT INTO order_client_submissions (client_order_id, user_id, contest_id, order_id)
				VALUES ($1::uuid, $2::uuid, $3::uuid, $1::uuid)
				ON CONFLICT (client_order_id) DO NOTHING
			`, clientOrderID, userID, contestID)
			errs[i] = err
			var oid string
			qerr := db.QueryRowContext(ctx, `
				SELECT order_id::text FROM order_client_submissions WHERE client_order_id=$1::uuid
			`, clientOrderID).Scan(&oid)
			if qerr != nil {
				errs[i] = qerr
				return
			}
			orderIDs[i] = oid
		}(i)
	}
	wg.Wait()

	for i, e := range errs {
		if e != nil {
			t.Fatalf("claim %d: %v", i, e)
		}
	}
	for i := 1; i < n; i++ {
		if orderIDs[i] != orderIDs[0] {
			t.Fatalf("order_id mismatch: %s vs %s", orderIDs[0], orderIDs[i])
		}
	}
	if orderIDs[0] != clientOrderID {
		t.Fatalf("order_id %s != client_order_id %s", orderIDs[0], clientOrderID)
	}
	var cnt int
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM order_client_submissions WHERE client_order_id=$1::uuid`, clientOrderID).Scan(&cnt)
	if cnt != 1 {
		t.Fatalf("want 1 claim row, got %d", cnt)
	}

	// Distinct identity still creates a second row
	other := uuid.New().String()
	_, err = db.ExecContext(ctx, `
		INSERT INTO order_client_submissions (client_order_id, user_id, contest_id, order_id)
		VALUES ($1::uuid, $2::uuid, $3::uuid, $1::uuid)
	`, other, userID, contestID)
	if err != nil {
		t.Fatal(err)
	}
	var total int
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM order_client_submissions WHERE user_id=$1::uuid`, userID).Scan(&total)
	if total < 2 {
		t.Fatalf("want >=2 rows for distinct ids, got %d", total)
	}

	_, _ = db.ExecContext(ctx, `DELETE FROM order_client_submissions WHERE user_id=$1::uuid`, userID)
}
