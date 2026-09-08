package db

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	prizedistribution "github.com/Parsaeffatravesh/tragge/packages/scoring/distribution"
	_ "github.com/jackc/pgx/v5/stdlib"
)

func TestContestSnapshotMigrationContract(t *testing.T) {
	upRaw, err := os.ReadFile(filepath.Join(migrationDir(), "0117_contest_lifecycle_snapshots.up.sql"))
	if err != nil {
		t.Fatal(err)
	}
	downRaw, err := os.ReadFile(filepath.Join(migrationDir(), "0117_contest_lifecycle_snapshots.down.sql"))
	if err != nil {
		t.Fatal(err)
	}
	up, down := string(upRaw), string(downRaw)
	for _, required := range []string{
		"CREATE TYPE contest_snapshot_type", "'contest_confirmed'", "'economics_cutoff'",
		"'contest_started'", "'contest_finished'", "UNIQUE (contest_id, snapshot_type)",
		"BEFORE UPDATE OR DELETE ON contest_snapshots", "lifecycle_policy_version",
		"DEFAULT 'legacy'", "SET DEFAULT 'contest_snapshot_v1'", "ON DELETE RESTRICT",
		"UNIQUE (id, contest_id)", "FOREIGN KEY (settlement_id, contest_id)",
		"refusing to remove immutable contest lifecycle history",
	} {
		if !strings.Contains(up+down, required) {
			t.Fatalf("snapshot migration missing %q", required)
		}
	}
	for _, forbidden := range []string{"contest_prize_accounts", "contest_prize_ledger", "treasury_to_pool"} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("snapshot migration implements out-of-scope %q", forbidden)
		}
	}
}

func TestContestSnapshotAuthoritativeOwnerContract(t *testing.T) {
	root := filepath.Clean(filepath.Join(migrationDir(), "..", "..", ".."))
	checks := map[string][]string{
		filepath.Join(root, "apps/user-bff/server/contest_handlers.go"): {
			"db.EnsureContestConfirmed(ctx, tx, contestID)",
		},
		filepath.Join(root, "packages/domain/statemachine/statemachine.go"): {
			"modern contest cannot start without confirmation snapshot", "db.EnsureContestStarted(ctx, tx",
		},
		filepath.Join(root, "apps/contest-scheduler/internal/scheduler/scheduler.go"): {
			"db.EnsureEconomicsCutoff(ctx, tx",
		},
		filepath.Join(root, "apps/settlement-service/server/db.go"): {
			"completeContestFinalization", "db.EnsureContestFinished(ctx, tx",
		},
	}
	for file, required := range checks {
		raw, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		for _, token := range required {
			if !strings.Contains(string(raw), token) {
				t.Fatalf("%s missing %q", file, token)
			}
		}
	}
	schedulerRaw, err := os.ReadFile(filepath.Join(root, "apps/contest-scheduler/internal/scheduler/scheduler.go"))
	if err != nil {
		t.Fatal(err)
	}
	for _, forbidden := range []string{"TralentV1PlannedWinners", "COUNT(p.user_id)", "EnsureEconomicsCutoff(ctx, tx, c.id,"} {
		if strings.Contains(string(schedulerRaw), forbidden) {
			t.Fatalf("scheduler retains cutoff authority %q", forbidden)
		}
	}
}

func snapshotPostgres(t *testing.T) *sql.DB {
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
	if err = database.QueryRowContext(ctx, `SELECT to_regclass('public.contest_snapshots') IS NOT NULL`).Scan(&migrated); err != nil || !migrated {
		t.Skip("migration 0117 not applied")
	}
	return database
}

// TestContestSnapshotsPostgresCertification covers the real row locks, unique
// stage constraint, DB clock, immutable trigger, per-admission rounding, and
// retry semantics. Transactions are coordinated by channels, not sleeps.
func TestContestSnapshotsPostgresCertification(t *testing.T) {
	database := snapshotPostgres(t)
	ctx := context.Background()
	stamp := fmt.Sprintf("%d", time.Now().UnixNano())
	var contestID string
	err := database.QueryRowContext(ctx, `INSERT INTO contests
	 (name,starts_at,ends_at,status,entry_fee_cents,platform_fee_bps,min_participants,
	  locked_entry_fee_cents,locked_platform_fee_bps,economics_locked_at,lifecycle_policy_version)
	 VALUES($1,CURRENT_TIMESTAMP-interval '20 minutes',CURRENT_TIMESTAMP+interval '80 minutes',
	 'running',999,1500,2,999,1500,CURRENT_TIMESTAMP,$2) RETURNING id::text`, "snapshot-"+stamp, ContestSnapshotPolicyV1).Scan(&contestID)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		_, _ = database.Exec(`DELETE FROM contest_snapshots WHERE contest_id=$1`, contestID) // trigger intentionally rejects
		_, _ = database.Exec(`DELETE FROM contest_participants WHERE contest_id=$1`, contestID)
	})
	users := make([]string, 3)
	for i := range users {
		if err = database.QueryRowContext(ctx, `INSERT INTO users(email,password_hash) VALUES($1,'x') RETURNING id::text`, fmt.Sprintf("snapshot-%s-%d@example.test", stamp, i)).Scan(&users[i]); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = database.ExecContext(ctx, `INSERT INTO contest_participants(contest_id,user_id,qty_total,qty_available) VALUES($1,$2,100,100)`, contestID, users[0]); err != nil {
		t.Fatal(err)
	}

	locked := make(chan struct{})
	release := make(chan struct{})
	errs := make(chan error, 2)
	var wg sync.WaitGroup
	wg.Add(2)
	go func() {
		defer wg.Done()
		tx, e := database.BeginTx(ctx, nil)
		if e != nil {
			errs <- e
			return
		}
		defer tx.Rollback()
		if _, e = tx.ExecContext(ctx, `SELECT 1 FROM contests WHERE id=$1 FOR UPDATE`, contestID); e != nil {
			errs <- e
			return
		}
		if _, e = tx.ExecContext(ctx, `INSERT INTO contest_participants(contest_id,user_id,qty_total,qty_available) VALUES($1,$2,100,100)`, contestID, users[1]); e != nil {
			errs <- e
			return
		}
		close(locked)
		<-release
		_, e = EnsureContestConfirmed(ctx, tx, contestID)
		if e == nil {
			e = tx.Commit()
		}
		errs <- e
	}()
	<-locked
	go func() {
		defer wg.Done()
		tx, e := database.BeginTx(ctx, nil)
		if e != nil {
			errs <- e
			return
		}
		defer tx.Rollback()
		if _, e = tx.ExecContext(ctx, `SELECT 1 FROM contests WHERE id=$1 FOR UPDATE`, contestID); e != nil {
			errs <- e
			return
		}
		if _, e = tx.ExecContext(ctx, `INSERT INTO contest_participants(contest_id,user_id,qty_total,qty_available) VALUES($1,$2,100,100)`, contestID, users[2]); e != nil {
			errs <- e
			return
		}
		_, e = EnsureContestConfirmed(ctx, tx, contestID)
		if e == nil {
			e = tx.Commit()
		}
		errs <- e
	}()
	close(release)
	wg.Wait()
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatal(e)
		}
	}
	confirmed, err := SnapshotByType(ctx, database, contestID, SnapshotConfirmed)
	if err != nil {
		t.Fatal(err)
	}
	if confirmed.ParticipantCount != 2 {
		t.Fatalf("confirmation count=%d want 2", confirmed.ParticipantCount)
	}
	if _, err = database.ExecContext(ctx, `DELETE FROM contest_participants WHERE contest_id=$1 AND user_id=$2`, contestID, users[2]); err != nil {
		t.Fatal(err)
	}
	again, err := EnsureContestConfirmed(ctx, database, contestID)
	if err != nil {
		t.Fatal(err)
	}
	if again.ID != confirmed.ID || !again.CreatedAt.Equal(confirmed.CreatedAt) {
		t.Fatal("confirmation retry rewrote history")
	}

	for i, u := range users[:2] {
		_, err = database.ExecContext(ctx, `INSERT INTO contest_fee_ledger
		(fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,participant_user_id,
		 admission_id,policy_version,platform_fee_bps) VALUES
		('contest_fee_wallet','contest_base_fee',149,$3,$1,$2,$1::text||':'||$2::text,$4,1500)`, contestID, u, (i+1)*149, ContestFundsPolicyV1)
		if err != nil {
			t.Fatal(err)
		}
	}
	// Restore the third active admission and its independently rounded fee.
	if _, err = database.ExecContext(ctx, `INSERT INTO contest_participants(contest_id,user_id,qty_total,qty_available) VALUES($1,$2,100,100)`, contestID, users[2]); err != nil {
		t.Fatal(err)
	}
	if _, err = database.ExecContext(ctx, `UPDATE contests SET started_at=starts_at WHERE id=$1`, contestID); err != nil {
		t.Fatal(err)
	}
	start1, err := EnsureContestStarted(ctx, database, contestID)
	if err != nil {
		t.Fatal(err)
	}
	start2, err := EnsureContestStarted(ctx, database, contestID)
	if err != nil {
		t.Fatal(err)
	}
	if start1.ID != start2.ID || !start1.EventAt.Equal(start2.EventAt) {
		t.Fatal("start retry rewrote history")
	}
	if _, err = database.ExecContext(ctx, `UPDATE contest_participants SET joined_at=$2 WHERE contest_id=$1`, contestID, start1.EventAt.Add(-time.Second)); err != nil {
		t.Fatal(err)
	}
	if _, err = database.ExecContext(ctx, `UPDATE contest_participants SET joined_at=$3 WHERE contest_id=$1 AND user_id=$2`, contestID, users[2], start1.EventAt.Add(time.Second)); err != nil {
		t.Fatal(err)
	}
	for i, u := range users {
		total := int64(999)
		if i == 2 {
			total = 1098
		}
		if _, err = database.ExecContext(ctx, `INSERT INTO wallet_ledger(user_id,type,amount_cents,balance_after_cents,ref_type,ref_id,reason_code,idempotency_key)
		 VALUES($1,'contest_entry',$2,0,'contest',$3,'CONTEST_ENTRY','contest_entry:'||$3::text||':'||$1::text)`, u, -total, contestID); err != nil {
			t.Fatal(err)
		}
	}
	_, err = database.ExecContext(ctx, `INSERT INTO contest_fee_ledger
	 (fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,participant_user_id,admission_id,policy_version,platform_fee_bps)
	 VALUES('contest_fee_wallet','contest_base_fee',149,447,$1,$2,$1::text||':'||$2::text,$3,1500)`, contestID, users[2], ContestFundsPolicyV1)
	if err != nil {
		t.Fatal(err)
	}
	_, err = database.ExecContext(ctx, `INSERT INTO contest_fee_ledger
	 (fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,participant_user_id,admission_id,policy_version,platform_fee_bps)
	 VALUES('contest_fee_wallet','contest_late_surcharge',99,546,$1,$2,$1::text||':'||$2::text,$3,1500)`, contestID, users[2], ContestFundsPolicyV1)
	if err != nil {
		t.Fatal(err)
	}
	// Mutable display/config values cannot replace the admission-time lock.
	if _, err = database.ExecContext(ctx, `UPDATE contests SET entry_fee_cents=5000,platform_fee_bps=2000 WHERE id=$1`, contestID); err != nil {
		t.Fatal(err)
	}
	tx, err := database.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	cutoff, err := EnsureEconomicsCutoff(ctx, tx, contestID)
	if err == nil {
		err = tx.Commit()
	} else {
		tx.Rollback()
	}
	if err != nil {
		t.Fatal(err)
	}
	if cutoff.GrossBaseEntryCents != 2997 || cutoff.PlatformFeeCents != 447 || cutoff.LateSurchargeCents != 99 || cutoff.PrizePoolCents != 2550 {
		t.Fatalf("rounding got gross=%d fee=%d pool=%d", cutoff.GrossBaseEntryCents, cutoff.PlatformFeeCents, cutoff.PrizePoolCents)
	}
	cutoff2, err := EnsureEconomicsCutoff(ctx, database, contestID)
	if err != nil {
		t.Fatal(err)
	}
	if cutoff2.ID != cutoff.ID {
		t.Fatal("cutoff retry duplicated")
	}
	var otherContest, otherSettlement string
	if err = database.QueryRowContext(ctx, `INSERT INTO contests(name,starts_at,ends_at) VALUES($1,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP+interval '1 hour') RETURNING id::text`, "other-"+stamp).Scan(&otherContest); err != nil {
		t.Fatal(err)
	}
	if err = database.QueryRowContext(ctx, `INSERT INTO contest_settlements(contest_id,status) VALUES($1,'completed') RETURNING id::text`, otherContest).Scan(&otherSettlement); err != nil {
		t.Fatal(err)
	}
	if _, err = EnsureContestFinished(ctx, database, contestID, otherSettlement); err == nil {
		t.Fatal("first finished snapshot accepted another contest's settlement")
	}
	if _, err = SnapshotByType(ctx, database, contestID, SnapshotFinished); !errors.Is(err, sql.ErrNoRows) {
		t.Fatalf("wrong-settlement attempt created history: %v", err)
	}
	var settlementID string
	if err = database.QueryRowContext(ctx, `INSERT INTO contest_settlements(contest_id,status,completed_at,total_participants,prize_pool_gross_cents,prize_pool_net_cents,platform_fee_cents)
	 VALUES($1,'completed',CURRENT_TIMESTAMP,3,2997,2550,447) RETURNING id::text`, contestID).Scan(&settlementID); err != nil {
		t.Fatal(err)
	}
	// A stale row linked to another contest's settlement must not enter history.
	if _, err = database.ExecContext(ctx, `INSERT INTO final_rankings(settlement_id,contest_id,user_id,rank,final_score,total_trades) VALUES($1,$2,$3,99,999,1)`, otherSettlement, contestID, users[0]); err != nil {
		t.Fatal(err)
	}
	for i, u := range users[1:] {
		if _, err = database.ExecContext(ctx, `INSERT INTO final_rankings(settlement_id,contest_id,user_id,rank,final_score,total_trades) VALUES($1,$2,$3,$4,$5,1)`, settlementID, contestID, u, i+1, 300-i); err != nil {
			t.Fatal(err)
		}
	}
	if _, err = database.ExecContext(ctx, `INSERT INTO prize_distributions(settlement_id,contest_id,user_id,rank,final_score,prize_amount_cents,prize_percentage,status)
	 VALUES($1,$2,$3,1,300,2550,100,'credited')`, settlementID, contestID, users[1]); err != nil {
		t.Fatal(err)
	}
	if _, err = database.ExecContext(ctx, `UPDATE contests SET status='completed',settled_at=CURRENT_TIMESTAMP WHERE id=$1`, contestID); err != nil {
		t.Fatal(err)
	}
	finish1, err := EnsureContestFinished(ctx, database, contestID, settlementID)
	if err != nil {
		t.Fatal(err)
	}
	finish2, err := EnsureContestFinished(ctx, database, contestID, settlementID)
	if err != nil {
		t.Fatal(err)
	}
	if finish1.ID != finish2.ID {
		t.Fatal("finish retry duplicated")
	}
	if !strings.Contains(string(finish1.Details), `"rankings"`) || !strings.Contains(string(finish1.Details), `"winners"`) {
		t.Fatal("finished snapshot lacks durable results")
	}
	if strings.Contains(string(finish1.Details), users[0]) {
		t.Fatal("finished snapshot included stale result from another settlement")
	}
	if _, err = database.ExecContext(ctx, `UPDATE contest_snapshots SET participant_count=99 WHERE id=$1`, cutoff.ID); err == nil {
		t.Fatal("snapshot UPDATE succeeded")
	}
	if _, err = database.ExecContext(ctx, `DELETE FROM contest_snapshots WHERE id=$1`, cutoff.ID); err == nil {
		t.Fatal("snapshot DELETE succeeded")
	}
}

func seedCutoffEvidenceContest(t *testing.T, database *sql.DB, label string, entryFee int64, feeBps, participants int) (string, []string, time.Time) {
	t.Helper()
	ctx := context.Background()
	var contestID string
	if err := database.QueryRowContext(ctx, `INSERT INTO contests
	 (name,starts_at,ends_at,status,entry_fee_cents,platform_fee_bps,min_participants,
	  locked_entry_fee_cents,locked_platform_fee_bps,economics_locked_at,lifecycle_policy_version,is_free)
	 VALUES($1,CURRENT_TIMESTAMP-interval '20 minutes',CURRENT_TIMESTAMP+interval '80 minutes',
	 'running',$2,$3,1,$2,$3,CURRENT_TIMESTAMP,$4,$5) RETURNING id::text`,
		label, entryFee, feeBps, ContestSnapshotPolicyV1, entryFee == 0).Scan(&contestID); err != nil {
		t.Fatal(err)
	}
	users := make([]string, participants)
	for i := range users {
		email := fmt.Sprintf("%s-%d-%d@example.test", label, i, time.Now().UnixNano())
		if err := database.QueryRowContext(ctx, `INSERT INTO users(email,password_hash) VALUES($1,'x') RETURNING id::text`, email).Scan(&users[i]); err != nil {
			t.Fatal(err)
		}
		if _, err := database.ExecContext(ctx, `INSERT INTO contest_participants(contest_id,user_id,qty_total,qty_available) VALUES($1,$2,100,100)`, contestID, users[i]); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := database.ExecContext(ctx, `UPDATE contests SET started_at=starts_at WHERE id=$1`, contestID); err != nil {
		t.Fatal(err)
	}
	started, err := EnsureContestStarted(ctx, database, contestID)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = database.ExecContext(ctx, `UPDATE contest_participants SET joined_at=$2 WHERE contest_id=$1`, contestID, started.EventAt.Add(-time.Second)); err != nil {
		t.Fatal(err)
	}
	return contestID, users, started.EventAt
}

func insertWalletAdmissionEvidence(t *testing.T, database *sql.DB, contestID, userID string, total int64) {
	t.Helper()
	_, err := database.Exec(`INSERT INTO wallet_ledger(user_id,type,amount_cents,balance_after_cents,ref_type,ref_id,reason_code,idempotency_key)
	 VALUES($1,'contest_entry',$2,0,'contest',$3,'CONTEST_ENTRY','contest_entry:'||$3::text||':'||$1::text)`, userID, -total, contestID)
	if err != nil {
		t.Fatal(err)
	}
}

func insertBaseFeeEvidence(t *testing.T, database *sql.DB, contestID, userID, contextUser string, amount int64, bps int) {
	t.Helper()
	_, err := database.Exec(`INSERT INTO contest_fee_ledger
	 (fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,participant_user_id,admission_id,policy_version,platform_fee_bps)
	 VALUES('contest_fee_wallet','contest_base_fee',$4,0,$1,$3,$1::text||':'||$2::text,$5,$6)`,
		contestID, userID, contextUser, amount, ContestFundsPolicyV1, bps)
	if err != nil {
		t.Fatal(err)
	}
}

func assertCutoffEvidenceRejected(t *testing.T, database *sql.DB, contestID string) {
	t.Helper()
	ctx := context.Background()
	tx, err := database.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback()
	if _, err = EnsureEconomicsCutoff(ctx, tx, contestID); !errors.Is(err, ErrAdmissionEvidence) {
		t.Fatalf("cutoff error=%v, want ErrAdmissionEvidence", err)
	}
	var count int
	if err = database.QueryRow(`SELECT COUNT(*) FROM contest_snapshots WHERE contest_id=$1 AND snapshot_type='economics_cutoff'`, contestID).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 0 {
		t.Fatal("corrupt evidence created cutoff snapshot")
	}
}

func TestContestSnapshotAdmissionEvidencePostgres(t *testing.T) {
	database := snapshotPostgres(t)
	t.Run("missing base fee", func(t *testing.T) {
		contest, users, _ := seedCutoffEvidenceContest(t, database, "missing-base", 999, 1500, 3)
		for i, u := range users {
			insertWalletAdmissionEvidence(t, database, contest, u, 999)
			if i < 2 {
				insertBaseFeeEvidence(t, database, contest, u, u, 149, 1500)
			}
		}
		assertCutoffEvidenceRejected(t, database, contest)
	})
	t.Run("wrong base amount", func(t *testing.T) {
		contest, users, _ := seedCutoffEvidenceContest(t, database, "wrong-base", 999, 1500, 1)
		insertWalletAdmissionEvidence(t, database, contest, users[0], 999)
		insertBaseFeeEvidence(t, database, contest, users[0], users[0], 148, 1500)
		assertCutoffEvidenceRejected(t, database, contest)
	})
	t.Run("wrong participant context", func(t *testing.T) {
		contest, users, _ := seedCutoffEvidenceContest(t, database, "wrong-context", 999, 1500, 2)
		for _, u := range users {
			insertWalletAdmissionEvidence(t, database, contest, u, 999)
		}
		insertBaseFeeEvidence(t, database, contest, users[0], users[0], 149, 1500)
		insertBaseFeeEvidence(t, database, contest, users[1], users[0], 149, 1500)
		assertCutoffEvidenceRejected(t, database, contest)
	})
	t.Run("zero fee free contest", func(t *testing.T) {
		contest, _, _ := seedCutoffEvidenceContest(t, database, "zero-fee", 0, 0, 1)
		tx, err := database.BeginTx(context.Background(), nil)
		if err != nil {
			t.Fatal(err)
		}
		snapshot, err := EnsureEconomicsCutoff(context.Background(), tx, contest)
		if err == nil {
			err = tx.Commit()
		} else {
			tx.Rollback()
		}
		if err != nil {
			t.Fatal(err)
		}
		if snapshot.PlatformFeeCents != 0 || snapshot.PrizePoolCents != 0 {
			t.Fatal("zero-fee cutoff fabricated economics")
		}
	})
	t.Run("missing late surcharge", func(t *testing.T) {
		contest, users, started := seedCutoffEvidenceContest(t, database, "missing-late", 999, 1500, 1)
		if _, err := database.Exec(`UPDATE contest_participants SET joined_at=$3 WHERE contest_id=$1 AND user_id=$2`, contest, users[0], started.Add(time.Second)); err != nil {
			t.Fatal(err)
		}
		insertWalletAdmissionEvidence(t, database, contest, users[0], 1098)
		insertBaseFeeEvidence(t, database, contest, users[0], users[0], 149, 1500)
		assertCutoffEvidenceRejected(t, database, contest)
	})
	t.Run("unexpected late surcharge", func(t *testing.T) {
		contest, users, _ := seedCutoffEvidenceContest(t, database, "unexpected-late", 999, 1500, 1)
		insertWalletAdmissionEvidence(t, database, contest, users[0], 999)
		insertBaseFeeEvidence(t, database, contest, users[0], users[0], 149, 1500)
		_, err := database.Exec(`INSERT INTO contest_fee_ledger
		 (fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,participant_user_id,admission_id,policy_version,platform_fee_bps)
		 VALUES('contest_fee_wallet','contest_late_surcharge',99,0,$1,$2,$1::text||':'||$2::text,$3,1500)`, contest, users[0], ContestFundsPolicyV1)
		if err != nil {
			t.Fatal(err)
		}
		assertCutoffEvidenceRejected(t, database, contest)
	})
}

func addValidOnTimeAdmissions(t *testing.T, database *sql.DB, contest string, users []string) {
	t.Helper()
	for _, u := range users {
		insertWalletAdmissionEvidence(t, database, contest, u, 999)
		insertBaseFeeEvidence(t, database, contest, u, u, 149, 1500)
	}
}

func TestContestSnapshotJoinVsCutoffPostgres(t *testing.T) {
	database := snapshotPostgres(t)
	ctx := context.Background()
	t.Run("join commits before cutoff lock", func(t *testing.T) {
		contest, users, _ := seedCutoffEvidenceContest(t, database, "join-before-cutoff", 999, 1500, 3)
		addValidOnTimeAdmissions(t, database, contest, users)
		var lateUser string
		if err := database.QueryRow(`INSERT INTO users(email,password_hash) VALUES($1,'x') RETURNING id::text`, fmt.Sprintf("late-%d@example.test", time.Now().UnixNano())).Scan(&lateUser); err != nil {
			t.Fatal(err)
		}
		var discovered int
		if err := database.QueryRow(`SELECT COUNT(*) FROM contest_participants WHERE contest_id=$1`, contest).Scan(&discovered); err != nil {
			t.Fatal(err)
		}
		if discovered != 3 {
			t.Fatalf("discovery count=%d", discovered)
		}
		joinLocked := make(chan struct{})
		releaseJoin := make(chan struct{})
		joinDone := make(chan error, 1)
		go func() {
			tx, err := database.BeginTx(ctx, nil)
			if err != nil {
				joinDone <- err
				return
			}
			defer tx.Rollback()
			if _, err = tx.Exec(`SELECT 1 FROM contests WHERE id=$1 FOR UPDATE`, contest); err != nil {
				joinDone <- err
				return
			}
			close(joinLocked)
			<-releaseJoin
			queries := []struct {
				q string
				a []any
			}{
				{`INSERT INTO contest_participants(contest_id,user_id,qty_total,qty_available) VALUES($1,$2,100,100)`, []any{contest, lateUser}},
				{`INSERT INTO wallet_ledger(user_id,type,amount_cents,balance_after_cents,ref_type,ref_id,reason_code,idempotency_key) VALUES($1,'contest_entry',-1098,0,'contest',$2,'CONTEST_ENTRY','contest_entry:'||$2::text||':'||$1::text)`, []any{lateUser, contest}},
				{`INSERT INTO contest_fee_ledger(fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,participant_user_id,admission_id,policy_version,platform_fee_bps) VALUES('contest_fee_wallet','contest_base_fee',149,0,$1,$2,$1::text||':'||$2::text,$3,1500)`, []any{contest, lateUser, ContestFundsPolicyV1}},
				{`INSERT INTO contest_fee_ledger(fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,participant_user_id,admission_id,policy_version,platform_fee_bps) VALUES('contest_fee_wallet','contest_late_surcharge',99,0,$1,$2,$1::text||':'||$2::text,$3,1500)`, []any{contest, lateUser, ContestFundsPolicyV1}},
			}
			for _, x := range queries {
				if _, err = tx.Exec(x.q, x.a...); err != nil {
					joinDone <- err
					return
				}
			}
			joinDone <- tx.Commit()
		}()
		<-joinLocked
		cutoffStarted := make(chan struct{})
		cutoffDone := make(chan struct {
			snapshot *Snapshot
			err      error
		}, 1)
		go func() {
			tx, err := database.BeginTx(ctx, nil)
			if err != nil {
				cutoffDone <- struct {
					snapshot *Snapshot
					err      error
				}{nil, err}
				return
			}
			defer tx.Rollback()
			close(cutoffStarted)
			s, err := EnsureEconomicsCutoff(ctx, tx, contest)
			if err == nil {
				err = tx.Commit()
			}
			cutoffDone <- struct {
				snapshot *Snapshot
				err      error
			}{s, err}
		}()
		<-cutoffStarted
		close(releaseJoin)
		if err := <-joinDone; err != nil {
			t.Fatal(err)
		}
		result := <-cutoffDone
		if result.err != nil {
			t.Fatal(result.err)
		}
		if result.snapshot.ParticipantCount != 4 || result.snapshot.PlannedWinnerCount != prizedistribution.TralentV1PlannedWinners(4) {
			t.Fatalf("stale cutoff count=%d winners=%d", result.snapshot.ParticipantCount, result.snapshot.PlannedWinnerCount)
		}
		if result.snapshot.PlannedWinnerCount == prizedistribution.TralentV1PlannedWinners(discovered) {
			t.Fatal("cutoff retained discovery-time winner plan")
		}
	})

	t.Run("cutoff commits before later admission", func(t *testing.T) {
		contest, users, _ := seedCutoffEvidenceContest(t, database, "cutoff-before-join", 999, 1500, 3)
		addValidOnTimeAdmissions(t, database, contest, users)
		var laterUser string
		if err := database.QueryRow(`INSERT INTO users(email,password_hash) VALUES($1,'x') RETURNING id::text`, fmt.Sprintf("later-%d@example.test", time.Now().UnixNano())).Scan(&laterUser); err != nil {
			t.Fatal(err)
		}
		tx, err := database.BeginTx(ctx, nil)
		if err != nil {
			t.Fatal(err)
		}
		snapshot, err := EnsureEconomicsCutoff(ctx, tx, contest)
		if err != nil {
			tx.Rollback()
			t.Fatal(err)
		}
		joinAttempted := make(chan struct{})
		joinDone := make(chan error, 1)
		go func() {
			joinTx, e := database.BeginTx(ctx, nil)
			if e != nil {
				joinDone <- e
				return
			}
			defer joinTx.Rollback()
			close(joinAttempted)
			_, e = joinTx.Exec(`SELECT 1 FROM contests WHERE id=$1 FOR UPDATE`, contest)
			if e == nil {
				_, e = joinTx.Exec(`INSERT INTO contest_participants(contest_id,user_id,qty_total,qty_available) VALUES($1,$2,100,100)`, contest, laterUser)
			}
			if e == nil {
				e = joinTx.Commit()
			}
			joinDone <- e
		}()
		<-joinAttempted
		if err = tx.Commit(); err != nil {
			t.Fatal(err)
		}
		if err = <-joinDone; err != nil {
			t.Fatal(err)
		}
		again, err := SnapshotByType(ctx, database, contest, SnapshotEconomicsCutoff)
		if err != nil {
			t.Fatal(err)
		}
		if again.ID != snapshot.ID || again.ParticipantCount != 3 || again.PlannedWinnerCount != prizedistribution.TralentV1PlannedWinners(3) {
			t.Fatal("later admission path mutated cutoff")
		}
	})
}

func TestContestSnapshotConcurrentCutoffCreatorsPostgres(t *testing.T) {
	database := snapshotPostgres(t)
	ctx := context.Background()
	contest, users, _ := seedCutoffEvidenceContest(t, database, "concurrent-cutoff", 999, 1500, 3)
	addValidOnTimeAdmissions(t, database, contest, users)
	locked := make(chan struct{})
	release := make(chan struct{})
	results := make(chan struct {
		s   *Snapshot
		err error
	}, 2)
	go func() {
		tx, err := database.BeginTx(ctx, nil)
		if err != nil {
			results <- struct {
				s   *Snapshot
				err error
			}{nil, err}
			return
		}
		defer tx.Rollback()
		if _, err = tx.Exec(`SELECT 1 FROM contests WHERE id=$1 FOR UPDATE`, contest); err != nil {
			results <- struct {
				s   *Snapshot
				err error
			}{nil, err}
			return
		}
		close(locked)
		<-release
		s, err := EnsureEconomicsCutoff(ctx, tx, contest)
		if err == nil {
			err = tx.Commit()
		}
		results <- struct {
			s   *Snapshot
			err error
		}{s, err}
	}()
	<-locked
	secondStarted := make(chan struct{})
	go func() {
		tx, err := database.BeginTx(ctx, nil)
		if err != nil {
			results <- struct {
				s   *Snapshot
				err error
			}{nil, err}
			return
		}
		defer tx.Rollback()
		close(secondStarted)
		s, err := EnsureEconomicsCutoff(ctx, tx, contest)
		if err == nil {
			err = tx.Commit()
		}
		results <- struct {
			s   *Snapshot
			err error
		}{s, err}
	}()
	<-secondStarted
	close(release)
	a, b := <-results, <-results
	if a.err != nil {
		t.Fatal(a.err)
	}
	if b.err != nil {
		t.Fatal(b.err)
	}
	if a.s.ID != b.s.ID {
		t.Fatal("concurrent cutoff creators returned different history")
	}
}

func TestContestSnapshotConcurrentInitialStartPostgres(t *testing.T) {
	database := snapshotPostgres(t)
	ctx := context.Background()
	var fresh string
	if err := database.QueryRow(`INSERT INTO contests(name,starts_at,ends_at,status,started_at,lifecycle_policy_version,is_free,entry_fee_cents,platform_fee_bps) VALUES($1,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP+interval '1 hour','running',CURRENT_TIMESTAMP,$2,TRUE,0,0) RETURNING id::text`, fmt.Sprintf("concurrent-start-%d", time.Now().UnixNano()), ContestSnapshotPolicyV1).Scan(&fresh); err != nil {
		t.Fatal(err)
	}
	start := make(chan struct{})
	results := make(chan struct {
		s   *Snapshot
		err error
	}, 2)
	var wg sync.WaitGroup
	wg.Add(2)
	for range 2 {
		go func() {
			defer wg.Done()
			tx, err := database.BeginTx(ctx, nil)
			if err != nil {
				results <- struct {
					s   *Snapshot
					err error
				}{nil, err}
				return
			}
			defer tx.Rollback()
			<-start
			s, err := EnsureContestStarted(ctx, tx, fresh)
			if err == nil {
				err = tx.Commit()
			}
			results <- struct {
				s   *Snapshot
				err error
			}{s, err}
		}()
	}
	close(start)
	wg.Wait()
	close(results)
	var id string
	for result := range results {
		if result.err != nil {
			t.Fatal(result.err)
		}
		if id == "" {
			id = result.s.ID
		} else if id != result.s.ID {
			t.Fatal("concurrent starts returned different snapshots")
		}
	}
}
