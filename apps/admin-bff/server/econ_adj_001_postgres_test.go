package server

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/db"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func econADJAdminPostgres(t *testing.T) *sql.DB {
	t.Helper()
	dsn := os.Getenv("TRAGGE_E2E_DATABASE_URL")
	if dsn == "" {
		t.Skip("set TRAGGE_E2E_DATABASE_URL for real PostgreSQL certification")
	}
	database, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { database.Close() })
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err = database.PingContext(ctx); err != nil {
		t.Skipf("PostgreSQL unavailable: %v", err)
	}
	var migrated bool
	if err = database.QueryRowContext(ctx, `SELECT to_regclass('public.economic_adjustment_events') IS NOT NULL`).Scan(&migrated); err != nil || !migrated {
		t.Skip("migration 0122 not applied")
	}
	return database
}

func TestECON_ADJPostgreSQLPostCutoffLifecyclePreservesEconomics(t *testing.T) {
	database := econADJAdminPostgres(t)
	ctx := context.Background()
	stamp := time.Now().UnixNano()
	var contestID, participantID, actorID string
	if err := database.QueryRowContext(ctx, `INSERT INTO contests
		(name,starts_at,ends_at,status,entry_fee_cents,platform_fee_bps,min_participants,
		 locked_entry_fee_cents,locked_platform_fee_bps,economics_locked_at,lifecycle_policy_version,
		 funds_policy_version,is_free,started_at)
		VALUES($1,CURRENT_TIMESTAMP-interval '20 minutes',CURRENT_TIMESTAMP+interval '80 minutes',
		 'running',999,1500,1,999,1500,CURRENT_TIMESTAMP,$2,'legacy',FALSE,CURRENT_TIMESTAMP-interval '20 minutes')
		RETURNING id::text`, fmt.Sprintf("econ-adj-admin-%d", stamp), db.ContestSnapshotPolicyV1).Scan(&contestID); err != nil {
		t.Fatal(err)
	}
	if _, err := db.EnsureContestStarted(ctx, database, contestID); err != nil {
		t.Fatal(err)
	}
	if err := database.QueryRowContext(ctx, `INSERT INTO users(email,password_hash) VALUES($1,'x') RETURNING id::text`, fmt.Sprintf("econ-adj-participant-%d@example.test", stamp)).Scan(&participantID); err != nil {
		t.Fatal(err)
	}
	if err := database.QueryRowContext(ctx, `INSERT INTO users(email,password_hash) VALUES($1,'x') RETURNING id::text`, fmt.Sprintf("econ-adj-actor-%d@example.test", stamp)).Scan(&actorID); err != nil {
		t.Fatal(err)
	}
	if _, err := database.ExecContext(ctx, `INSERT INTO contest_participants
		(contest_id,user_id,qty_total,qty_available,joined_at)
		VALUES($1,$2,100,100,CURRENT_TIMESTAMP-interval '21 minutes')`, contestID, participantID); err != nil {
		t.Fatal(err)
	}
	if _, err := database.ExecContext(ctx, `INSERT INTO wallet_ledger
		(user_id,type,amount_cents,balance_after_cents,ref_type,ref_id,reason_code,idempotency_key)
		VALUES($1,'contest_entry',-999,0,'contest',$2,'CONTEST_ENTRY','contest_entry:'||$2::text||':'||$1::text)`, participantID, contestID); err != nil {
		t.Fatal(err)
	}
	if _, err := database.ExecContext(ctx, `INSERT INTO contest_fee_ledger
		(fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,participant_user_id,
		 admission_id,policy_version,platform_fee_bps)
		VALUES('contest_fee_wallet','contest_base_fee',149,149,$1,$2,$1::text||':'||$2::text,$3,1500)`, contestID, participantID, db.ContestFundsPolicyV1); err != nil {
		t.Fatal(err)
	}
	tx, err := database.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	snapshot, err := db.EnsureEconomicsCutoff(ctx, tx, contestID)
	if err == nil {
		err = tx.Commit()
	} else {
		tx.Rollback()
	}
	if err != nil {
		t.Fatal(err)
	}

	financialCounts := func() [4]int {
		var counts [4]int
		if err := database.QueryRowContext(ctx, `SELECT
			(SELECT COUNT(*) FROM wallet_ledger WHERE user_id=$2 AND ref_id=$1::uuid),
			(SELECT COUNT(*) FROM treasury_ledger WHERE contest_id=$1),
			(SELECT COUNT(*) FROM contest_fee_ledger WHERE contest_id=$1),
			(SELECT COUNT(*) FROM contest_prize_pool_ledger WHERE contest_id=$1)`, contestID, participantID).Scan(&counts[0], &counts[1], &counts[2], &counts[3]); err != nil {
			t.Fatal(err)
		}
		return counts
	}
	before := financialCounts()
	app := &App{pool: db.NewPoolFromDB(database)}
	refund := false
	if _, err := app.removeParticipantAtomic(ctx, contestID, participantID, actorID,
		participantRemovalRequest{Reason: "CHEATING", Refund: &refund}); err != nil {
		t.Fatal(err)
	}
	after := financialCounts()
	if before != after {
		t.Fatalf("post-cutoff disqualification moved funds: before=%v after=%v", before, after)
	}

	var lifecycle string
	var adjustmentEvents int
	if err := database.QueryRowContext(ctx, `SELECT lifecycle_status,
		(SELECT COUNT(*) FROM economic_adjustment_events WHERE contest_id=$1 AND participant_id=$2
		 AND event_type='PARTICIPANT_DISQUALIFIED')
		FROM contest_participants WHERE contest_id=$1 AND user_id=$2`, contestID, participantID).Scan(&lifecycle, &adjustmentEvents); err != nil {
		t.Fatal(err)
	}
	afterSnapshot, err := db.SnapshotByType(ctx, database, contestID, db.SnapshotEconomicsCutoff)
	if err != nil {
		t.Fatal(err)
	}
	if lifecycle != "DISQUALIFIED" || adjustmentEvents != 1 {
		t.Fatalf("lifecycle=%s adjustment_events=%d", lifecycle, adjustmentEvents)
	}
	if afterSnapshot.ID != snapshot.ID || afterSnapshot.EconomicParticipantCount != snapshot.EconomicParticipantCount ||
		afterSnapshot.PlannedWinnerCount != snapshot.PlannedWinnerCount {
		t.Fatal("post-cutoff lifecycle change rewrote economic history")
	}
}
