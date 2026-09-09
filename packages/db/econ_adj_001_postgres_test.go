package db

import (
	"context"
	"database/sql"
	"fmt"
	"sync"
	"testing"
	"time"
)

func seedECONADJPostgresContest(t *testing.T, database *sql.DB, participants int) (string, []string) {
	t.Helper()
	ctx := context.Background()
	label := fmt.Sprintf("econ-adj-%d", time.Now().UnixNano())
	var contestID string
	if err := database.QueryRowContext(ctx, `INSERT INTO contests
		(name,starts_at,ends_at,status,entry_fee_cents,platform_fee_bps,min_participants,
		 locked_entry_fee_cents,locked_platform_fee_bps,economics_locked_at,lifecycle_policy_version,
		 funds_policy_version,is_free,started_at)
		VALUES($1,CURRENT_TIMESTAMP-interval '20 minutes',CURRENT_TIMESTAMP+interval '80 minutes',
		 'running',999,1500,1,999,1500,CURRENT_TIMESTAMP,$2,'legacy',FALSE,CURRENT_TIMESTAMP-interval '20 minutes')
		RETURNING id::text`, label, ContestSnapshotPolicyV1).Scan(&contestID); err != nil {
		t.Fatal(err)
	}
	if _, err := EnsureContestStarted(ctx, database, contestID); err != nil {
		t.Fatal(err)
	}
	users := make([]string, participants)
	for i := range users {
		if err := database.QueryRowContext(ctx, `INSERT INTO users(email,password_hash)
			VALUES($1,'x') RETURNING id::text`, fmt.Sprintf("%s-%d@example.test", label, i)).Scan(&users[i]); err != nil {
			t.Fatal(err)
		}
		if _, err := database.ExecContext(ctx, `INSERT INTO contest_participants
			(contest_id,user_id,qty_total,qty_available,joined_at) VALUES($1,$2,100,100,CURRENT_TIMESTAMP-interval '21 minutes')`, contestID, users[i]); err != nil {
			t.Fatal(err)
		}
		insertWalletAdmissionEvidence(t, database, contestID, users[i], 999)
		insertBaseFeeEvidence(t, database, contestID, users[i], users[i], 149, 1500)
	}
	return contestID, users
}

func createECONADJCutoff(t *testing.T, database *sql.DB, contestID string) *Snapshot {
	t.Helper()
	tx, err := database.BeginTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	snapshot, err := EnsureEconomicsCutoff(context.Background(), tx, contestID)
	if err == nil {
		err = tx.Commit()
	} else {
		tx.Rollback()
	}
	if err != nil {
		t.Fatal(err)
	}
	return snapshot
}

func TestECON_ADJPostgreSQLMigrationAndImmutability(t *testing.T) {
	database := snapshotPostgres(t)
	ctx := context.Background()

	var columns, indexes, constraints, triggers int
	if err := database.QueryRowContext(ctx, `SELECT COUNT(*) FROM information_schema.columns
		WHERE table_schema='public' AND table_name='contest_snapshots'
		AND column_name IN ('joined_participant_count','economic_participant_count',
		                    'leaderboard_eligible_count','winner_capacity_shortfall')`).Scan(&columns); err != nil {
		t.Fatal(err)
	}
	if err := database.QueryRowContext(ctx, `SELECT COUNT(*) FROM pg_indexes WHERE schemaname='public'
		AND indexname IN ('uq_economic_snapshot_created_event','idx_economic_adjustment_events_history')`).Scan(&indexes); err != nil {
		t.Fatal(err)
	}
	if err := database.QueryRowContext(ctx, `SELECT COUNT(*) FROM pg_constraint
		WHERE conname IN ('chk_economic_cutoff_population','chk_economic_event_shape')`).Scan(&constraints); err != nil {
		t.Fatal(err)
	}
	if err := database.QueryRowContext(ctx, `SELECT COUNT(*) FROM pg_trigger
		WHERE NOT tgisinternal AND tgname IN ('contest_snapshots_immutable','economic_adjustment_events_append_only')`).Scan(&triggers); err != nil {
		t.Fatal(err)
	}
	if columns != 4 || indexes != 2 || constraints != 2 || triggers != 2 {
		t.Fatalf("migration objects: columns=%d indexes=%d constraints=%d triggers=%d", columns, indexes, constraints, triggers)
	}

	contestID, users := seedECONADJPostgresContest(t, database, 2)
	if _, err := database.ExecContext(ctx, `UPDATE contest_participants
		SET has_started_trading=TRUE,ranking_started_at=CURRENT_TIMESTAMP
		WHERE contest_id=$1 AND user_id=$2`, contestID, users[1]); err != nil {
		t.Fatal(err)
	}
	snapshot := createECONADJCutoff(t, database, contestID)
	if !snapshot.JoinedParticipantCount.Valid || snapshot.JoinedParticipantCount.Int64 != 2 ||
		!snapshot.EconomicParticipantCount.Valid || snapshot.EconomicParticipantCount.Int64 != 2 ||
		!snapshot.LeaderboardEligibleCount.Valid || snapshot.LeaderboardEligibleCount.Int64 != 1 {
		t.Fatalf("unexpected populations: joined=%v economic=%v leaderboard=%v",
			snapshot.JoinedParticipantCount, snapshot.EconomicParticipantCount, snapshot.LeaderboardEligibleCount)
	}
	if _, err := database.ExecContext(ctx, `UPDATE contest_snapshots SET economic_participant_count=999 WHERE id=$1`, snapshot.ID); err == nil {
		t.Fatal("immutable economic snapshot accepted UPDATE")
	}
	if _, err := database.ExecContext(ctx, `DELETE FROM contest_snapshots WHERE id=$1`, snapshot.ID); err == nil {
		t.Fatal("immutable economic snapshot accepted DELETE")
	}

	var eventID string
	if err := database.QueryRowContext(ctx, `SELECT id::text FROM economic_adjustment_events
		WHERE contest_id=$1 AND event_type='ECONOMIC_SNAPSHOT_CREATED'`, contestID).Scan(&eventID); err != nil {
		t.Fatal(err)
	}
	if _, err := database.ExecContext(ctx, `UPDATE economic_adjustment_events SET reason='rewrite' WHERE id=$1`, eventID); err == nil {
		t.Fatal("append-only economic event accepted UPDATE")
	}
	if _, err := database.ExecContext(ctx, `DELETE FROM economic_adjustment_events WHERE id=$1`, eventID); err == nil {
		t.Fatal("append-only economic event accepted DELETE")
	}
}

func TestECON_ADJPostgreSQLTenConcurrentCutoffs(t *testing.T) {
	database := snapshotPostgres(t)
	contestID, _ := seedECONADJPostgresContest(t, database, 3)
	const attempts = 10
	start := make(chan struct{})
	results := make(chan *Snapshot, attempts)
	errs := make(chan error, attempts)
	var wg sync.WaitGroup
	for range attempts {
		wg.Add(1)
		go func() {
			defer wg.Done()
			<-start
			tx, err := database.BeginTx(context.Background(), nil)
			if err != nil {
				errs <- err
				return
			}
			defer tx.Rollback()
			snapshot, err := EnsureEconomicsCutoff(context.Background(), tx, contestID)
			if err == nil {
				err = tx.Commit()
			}
			if err != nil {
				errs <- err
				return
			}
			results <- snapshot
		}()
	}
	close(start)
	wg.Wait()
	close(results)
	close(errs)
	for err := range errs {
		t.Fatal(err)
	}
	var snapshotID string
	returned := 0
	for snapshot := range results {
		returned++
		if snapshotID == "" {
			snapshotID = snapshot.ID
		} else if snapshot.ID != snapshotID {
			t.Fatalf("concurrent caller returned snapshot %s, want %s", snapshot.ID, snapshotID)
		}
	}
	var snapshots, events int
	if err := database.QueryRow(`SELECT
		(SELECT COUNT(*) FROM contest_snapshots WHERE contest_id=$1 AND snapshot_type='economics_cutoff'),
		(SELECT COUNT(*) FROM economic_adjustment_events WHERE contest_id=$1 AND event_type='ECONOMIC_SNAPSHOT_CREATED')`, contestID).Scan(&snapshots, &events); err != nil {
		t.Fatal(err)
	}
	if returned != attempts || snapshots != 1 || events != 1 {
		t.Fatalf("attempts=%d returned=%d snapshots=%d events=%d", attempts, returned, snapshots, events)
	}
}

func TestECON_ADJPostgreSQLRollbackLeavesNoPartialHistory(t *testing.T) {
	database := snapshotPostgres(t)
	contestID, users := seedECONADJPostgresContest(t, database, 1)
	tx, err := database.BeginTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	if _, err = EnsureEconomicsCutoff(context.Background(), tx, contestID); err != nil {
		tx.Rollback()
		t.Fatal(err)
	}
	if _, err = tx.Exec(`UPDATE contest_participants SET lifecycle_status='REFUNDED' WHERE contest_id=$1 AND user_id=$2`, contestID, users[0]); err == nil {
		tx.Rollback()
		t.Fatal("intentional invalid lifecycle transition did not fail")
	}
	if err = tx.Rollback(); err != nil {
		t.Fatal(err)
	}
	var snapshots, events int
	var lifecycle string
	if err = database.QueryRow(`SELECT
		(SELECT COUNT(*) FROM contest_snapshots WHERE contest_id=$1 AND snapshot_type='economics_cutoff'),
		(SELECT COUNT(*) FROM economic_adjustment_events WHERE contest_id=$1),
		(SELECT lifecycle_status FROM contest_participants WHERE contest_id=$1 AND user_id=$2)`, contestID, users[0]).Scan(&snapshots, &events, &lifecycle); err != nil {
		t.Fatal(err)
	}
	if snapshots != 0 || events != 0 || lifecycle != "ACTIVE" {
		t.Fatalf("rollback left snapshot=%d events=%d lifecycle=%s", snapshots, events, lifecycle)
	}
}
