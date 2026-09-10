package db

import (
	"context"
	"database/sql"
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
)

// Use a disposable database migrated through 0118 with a DDL-capable role.
// Each case rolls back its fixture and the complete 0119 up/down migrations.
// This separate opt-in never runs the deferred ECON-ADJ certification.
func TestMigration0119PostgreSQL(t *testing.T) {
	dsn := os.Getenv("TRAGGE_MIGRATION_TEST_DATABASE_URL")
	if dsn == "" {
		t.Skip("TRAGGE_MIGRATION_TEST_DATABASE_URL not configured")
	}
	database, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := database.Close(); err != nil {
			t.Errorf("close migration test database: %v", err)
		}
	}()
	ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
	defer cancel()
	var version int
	var dirty bool
	if err := database.QueryRowContext(ctx, "SELECT version, dirty FROM schema_migrations").Scan(&version, &dirty); err != nil {
		t.Fatal(err)
	}
	if version != 118 || dirty {
		t.Fatalf("requires clean migration 118, got version=%d dirty=%v", version, dirty)
	}
	read := func(name string) string {
		t.Helper()
		// #nosec G304 -- name is one of the two fixed migration filenames below.
		raw, err := os.ReadFile(filepath.Join(migrationDir(), name))
		if err != nil {
			t.Fatal(err)
		}
		return string(raw)
	}
	up := read("0119_lifecycle004_financial_reversal.up.sql")
	down := read("0119_lifecycle004_financial_reversal.down.sql")
	cases := []struct{ name, prepare string }{
		{"implicit_names", ""},
		{"already_removed", `ALTER TABLE contest_prize_pool_ledger
			DROP CONSTRAINT contest_prize_pool_ledger_amount_cents_check,
			DROP CONSTRAINT contest_prize_pool_ledger_direction_check,
			DROP CONSTRAINT contest_prize_pool_ledger_reason_check,
			DROP CONSTRAINT contest_prize_pool_ledger_reference_type_check`},
		{"renamed", `ALTER TABLE contest_prize_pool_ledger RENAME CONSTRAINT contest_prize_pool_ledger_amount_cents_check TO "Legacy amount CHECK";
			ALTER TABLE contest_prize_pool_ledger RENAME CONSTRAINT contest_prize_pool_ledger_direction_check TO legacy_direction;
			ALTER TABLE contest_prize_pool_ledger RENAME CONSTRAINT contest_prize_pool_ledger_reason_check TO legacy_reason;
			ALTER TABLE contest_prize_pool_ledger RENAME CONSTRAINT contest_prize_pool_ledger_reference_type_check TO legacy_reference`},
		// Adding the same anonymous checks makes PostgreSQL choose suffixed names.
		{"generated_name_collision", `ALTER TABLE contest_prize_pool_ledger
			ADD CHECK (amount_cents > 0), ADD CHECK (direction = 'credit'),
			ADD CHECK (reason = 'contest_admission'), ADD CHECK (reference_type = 'contest_admission')`},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			tx, err := database.BeginTx(ctx, nil)
			if err != nil {
				t.Fatal(err)
			}
			defer func() {
				if err := tx.Rollback(); err != nil && !errors.Is(err, sql.ErrTxDone) {
					t.Errorf("rollback migration test: %v", err)
				}
			}()
			exec := func(query string) {
				t.Helper()
				if _, err := tx.ExecContext(ctx, query); err != nil {
					t.Fatal(err)
				}
			}
			exec("SET LOCAL lock_timeout = '5s'; SET LOCAL statement_timeout = '15s'")
			// Preserve a populated account and admission ledger, not just empty DDL.
			exec(`WITH participant AS (
				INSERT INTO users(email,password_hash) VALUES ('migration-0119@example.test','test-only') RETURNING id
			), contest AS (
				INSERT INTO contests(name,starts_at,ends_at,entry_fee_cents,platform_fee_bps)
				VALUES ('migration-0119',CURRENT_TIMESTAMP,CURRENT_TIMESTAMP+interval '1 hour',1000,2000) RETURNING id
			)
			INSERT INTO contest_participants(contest_id,user_id,qty_total,qty_available)
			SELECT contest.id,participant.id,100,100 FROM contest,participant;
			INSERT INTO contest_prize_pool_ledger(contest_id,pool_account_id,amount_cents,direction,reason,
				reference_type,reference_id,participant_user_id,policy_version,balance_after_cents,idempotency_key)
			SELECT p.contest_id,a.id,800,'credit','contest_admission','contest_admission','migration-0119',
				p.user_id,'contest_funds_v1',800,'migration-0119'
			FROM contest_participants p JOIN users u ON u.id=p.user_id
			JOIN contest_prize_pool_accounts a ON a.contest_id=p.contest_id
			WHERE u.email='migration-0119@example.test';
			UPDATE contest_prize_pool_accounts SET balance_cents=800
			WHERE contest_id=(SELECT contest_id FROM contest_prize_pool_ledger WHERE idempotency_key='migration-0119');
			ALTER TABLE contest_prize_pool_ledger ADD CONSTRAINT migration_0119_unrelated_cap CHECK (amount_cents < 1000000);
			CREATE TEMP TABLE migration_0119_other(amount_cents BIGINT CHECK (amount_cents > 0)) ON COMMIT DROP`)
			if tc.prepare != "" {
				exec(tc.prepare)
			}
			fingerprint := func() string {
				t.Helper()
				var result string
				if err := tx.QueryRowContext(ctx, `SELECT jsonb_build_object(
					'accounts',(SELECT jsonb_agg(to_jsonb(a) ORDER BY id) FROM contest_prize_pool_accounts a),
					'ledger',(SELECT jsonb_agg(to_jsonb(l)-ARRAY['original_ledger_id','lifecycle_event_id','reversal_actor_id'] ORDER BY id) FROM contest_prize_pool_ledger l),
					'participants',(SELECT jsonb_agg(to_jsonb(p)-ARRAY['lifecycle_status','lifecycle_changed_at'] ORDER BY contest_id,user_id) FROM contest_participants p)
				)::text`).Scan(&result); err != nil {
					t.Fatal(err)
				}
				return result
			}
			before := fingerprint()
			exec(up)
			assertUp := func() {
				t.Helper()
				var checks int
				if err := tx.QueryRowContext(ctx, `SELECT count(*) FROM pg_constraint
					WHERE conrelid='contest_prize_pool_ledger'::regclass AND contype='c'`).Scan(&checks); err != nil {
					t.Fatal(err)
				}
				// Policy version, nonnegative balance, unrelated cap, and replacement shape.
				if checks != 4 {
					t.Fatalf("expected exactly four retained/replacement checks, got %d", checks)
				}
				var preserved bool
				if err := tx.QueryRowContext(ctx, `SELECT
					EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='contest_prize_pool_ledger'::regclass AND conname='chk_pool_entry_shape' AND convalidated)
					AND EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='contest_prize_pool_ledger'::regclass AND conname='migration_0119_unrelated_cap')
					AND EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='migration_0119_other'::regclass AND contype='c')`).Scan(&preserved); err != nil {
					t.Fatal(err)
				}
				if !preserved || before != fingerprint() {
					t.Fatal("migration changed historical data or unrelated checks, or omitted the validated replacement")
				}
			}
			assertUp()
			// Check that absent legacy constraints do not leave invalid credits allowed.
			exec("SAVEPOINT invalid_credit")
			_, err = tx.ExecContext(ctx, `INSERT INTO contest_prize_pool_ledger(contest_id,pool_account_id,amount_cents,direction,reason,
				reference_type,reference_id,participant_user_id,policy_version,balance_after_cents,idempotency_key)
				SELECT contest_id,pool_account_id,0,direction,reason,reference_type,'invalid-credit',participant_user_id,
				policy_version,balance_after_cents,'invalid-credit' FROM contest_prize_pool_ledger WHERE idempotency_key='migration-0119'`)
			pgerr, ok := err.(*pgconn.PgError)
			if !ok || pgerr.Code != "23514" || pgerr.ConstraintName != "chk_pool_entry_shape" {
				t.Fatalf("expected replacement check to reject zero credit, got %v", err)
			}
			exec("ROLLBACK TO SAVEPOINT invalid_credit")
			// The existing down migration creates implicit checks; re-up must work too.
			exec(down)
			if before != fingerprint() {
				t.Fatal("down migration changed the pre-reversal fixture")
			}
			exec(up)
			assertUp()
			if err := tx.Rollback(); err != nil {
				t.Fatal(err)
			}
			var unchanged bool
			if err := database.QueryRowContext(ctx, `SELECT to_regclass('contest_participant_lifecycle_events') IS NULL
				AND NOT EXISTS (SELECT 1 FROM users WHERE email='migration-0119@example.test')`).Scan(&unchanged); err != nil {
				t.Fatal(err)
			}
			if !unchanged {
				t.Fatal("rollback left migration objects or fixture data")
			}
		})
	}
}
