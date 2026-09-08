package statemachine

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/db"
)

func TestInitialStartSnapshotCallOrderContract(t *testing.T) {
	_, file, _, _ := runtime.Caller(0)
	raw, err := os.ReadFile(filepath.Join(filepath.Dir(file), "statemachine.go"))
	if err != nil {
		t.Fatal(err)
	}
	body := string(raw)
	confirmed := strings.Index(body, "db.SnapshotByType(ctx, tx, req.ContestID, db.SnapshotConfirmed)")
	started := strings.Index(body, "db.EnsureContestStarted(ctx, tx, req.ContestID)")
	cutoff := strings.Index(body, "db.EnsureEconomicsCutoff(ctx, tx, req.ContestID)")
	history := strings.Index(body, "INSERT INTO contest_status_history")
	if confirmed < 0 || started < confirmed || cutoff < started || history < cutoff {
		t.Fatalf("invalid initial START ordering: confirmed=%d started=%d cutoff=%d history=%d", confirmed, started, cutoff, history)
	}
}

func snapshotStateMachinePostgres(t *testing.T) *sql.DB {
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
	if err = database.PingContext(context.Background()); err != nil {
		t.Skipf("PostgreSQL unavailable: %v", err)
	}
	var migrated bool
	if err = database.QueryRow(`SELECT to_regclass('public.contest_snapshots') IS NOT NULL`).Scan(&migrated); err != nil || !migrated {
		t.Skip("migration 0117 not applied")
	}
	return database
}

func seedModernConfirmedStartContest(t *testing.T, database *sql.DB, label string, delayed bool, validEvidence bool) (string, []string) {
	t.Helper()
	ctx := context.Background()
	startExpr := "CURRENT_TIMESTAMP"
	if delayed {
		startExpr = "CURRENT_TIMESTAMP-interval '20 minutes'"
	}
	query := fmt.Sprintf(`INSERT INTO contests(name,starts_at,ends_at,status,entry_fee_cents,platform_fee_bps,min_participants,
	 locked_entry_fee_cents,locked_platform_fee_bps,economics_locked_at,lifecycle_policy_version,is_free)
	 VALUES($1,%s,CURRENT_TIMESTAMP+interval '80 minutes','registration_closed',999,1500,2,999,1500,CURRENT_TIMESTAMP,$2,FALSE) RETURNING id::text`, startExpr)
	var contestID string
	if err := database.QueryRowContext(ctx, query, label, db.ContestSnapshotPolicyV1).Scan(&contestID); err != nil {
		t.Fatal(err)
	}
	users := make([]string, 3)
	for i := range users {
		if err := database.QueryRowContext(ctx, `INSERT INTO users(email,password_hash) VALUES($1,'x') RETURNING id::text`, fmt.Sprintf("%s-%d-%d@example.test", label, i, time.Now().UnixNano())).Scan(&users[i]); err != nil {
			t.Fatal(err)
		}
		if _, err := database.ExecContext(ctx, `INSERT INTO contest_participants(contest_id,user_id,qty_total,qty_available) VALUES($1,$2,100,100)`, contestID, users[i]); err != nil {
			t.Fatal(err)
		}
	}
	tx, err := database.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = db.EnsureContestConfirmed(ctx, tx, contestID); err == nil {
		err = tx.Commit()
	} else {
		tx.Rollback()
	}
	if err != nil {
		t.Fatal(err)
	}
	if delayed {
		for i, userID := range users {
			_, err = database.ExecContext(ctx, `INSERT INTO wallet_ledger(user_id,type,amount_cents,balance_after_cents,ref_type,ref_id,reason_code,idempotency_key) VALUES($1,'contest_entry',-999,0,'contest',$2,'CONTEST_ENTRY','contest_entry:'||$2::text||':'||$1::text)`, userID, contestID)
			if err != nil {
				t.Fatal(err)
			}
			if validEvidence || i < 2 {
				_, err = database.ExecContext(ctx, `INSERT INTO contest_fee_ledger(fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,participant_user_id,admission_id,policy_version,platform_fee_bps) VALUES('contest_fee_wallet','contest_base_fee',149,0,$1,$2,$1::text||':'||$2::text,$3,1500)`, contestID, userID, db.ContestFundsPolicyV1)
				if err != nil {
					t.Fatal(err)
				}
			}
		}
	}
	return contestID, users
}

func snapshotCount(t *testing.T, database *sql.DB, contestID, typ string) int {
	t.Helper()
	var count int
	if err := database.QueryRow(`SELECT COUNT(*) FROM contest_snapshots WHERE contest_id=$1 AND snapshot_type=$2::contest_snapshot_type`, contestID, typ).Scan(&count); err != nil {
		t.Fatal(err)
	}
	return count
}

func TestInitialStartSnapshotOrderingPostgres(t *testing.T) {
	database := snapshotStateMachinePostgres(t)
	contestID, _ := seedModernConfirmedStartContest(t, database, "normal-start", false, false)
	sm := New(db.NewPoolFromDB(database), nil)
	if _, err := sm.Transition(context.Background(), TransitionRequest{ContestID: contestID, ToStatus: StatusRunning, Reason: "snapshot start regression"}); err != nil {
		t.Fatal(err)
	}
	if got := snapshotCount(t, database, contestID, db.SnapshotStarted); got != 1 {
		t.Fatalf("start snapshots=%d", got)
	}
	if got := snapshotCount(t, database, contestID, db.SnapshotEconomicsCutoff); got != 0 {
		t.Fatalf("premature cutoff snapshots=%d", got)
	}
}

func TestDelayedInitialStartCreatesCutoffAtomicallyPostgres(t *testing.T) {
	database := snapshotStateMachinePostgres(t)
	contestID, users := seedModernConfirmedStartContest(t, database, "delayed-start", true, true)
	sm := New(db.NewPoolFromDB(database), nil)
	if _, err := sm.Transition(context.Background(), TransitionRequest{ContestID: contestID, ToStatus: StatusRunning, Reason: "delayed start"}); err != nil {
		t.Fatal(err)
	}
	if snapshotCount(t, database, contestID, db.SnapshotStarted) != 1 || snapshotCount(t, database, contestID, db.SnapshotEconomicsCutoff) != 1 {
		t.Fatal("delayed start did not create both snapshots")
	}
	cutoff, err := db.SnapshotByType(context.Background(), database, contestID, db.SnapshotEconomicsCutoff)
	if err != nil {
		t.Fatal(err)
	}
	if cutoff.ParticipantCount != len(users) || cutoff.PlannedWinnerCount != 1 {
		t.Fatalf("cutoff participants=%d winners=%d", cutoff.ParticipantCount, cutoff.PlannedWinnerCount)
	}
}

func TestDelayedInitialStartCorruptEconomicsRollsBackPostgres(t *testing.T) {
	database := snapshotStateMachinePostgres(t)
	contestID, _ := seedModernConfirmedStartContest(t, database, "delayed-corrupt", true, false)
	sm := New(db.NewPoolFromDB(database), nil)
	_, err := sm.Transition(context.Background(), TransitionRequest{ContestID: contestID, ToStatus: StatusRunning, Reason: "must rollback"})
	if !errors.Is(err, db.ErrAdmissionEvidence) {
		t.Fatalf("error=%v want ErrAdmissionEvidence", err)
	}
	var status string
	if err = database.QueryRow(`SELECT status::text FROM contests WHERE id=$1`, contestID).Scan(&status); err != nil {
		t.Fatal(err)
	}
	if status != "registration_closed" {
		t.Fatalf("status=%s", status)
	}
	if snapshotCount(t, database, contestID, db.SnapshotStarted) != 0 || snapshotCount(t, database, contestID, db.SnapshotEconomicsCutoff) != 0 {
		t.Fatal("failed delayed start left partial snapshots")
	}
}

func TestCutoffMissingStartFailsClosedPostgres(t *testing.T) {
	database := snapshotStateMachinePostgres(t)
	contestID, _ := seedModernConfirmedStartContest(t, database, "missing-start", true, true)
	if _, err := db.EnsureEconomicsCutoff(context.Background(), database, contestID); !errors.Is(err, db.ErrSnapshotIntegrity) {
		t.Fatalf("error=%v want ErrSnapshotIntegrity", err)
	}
}
