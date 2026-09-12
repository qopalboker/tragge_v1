package db

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"reflect"
	"testing"
	"time"
)

// Each stage has its own transaction and prerequisites. A broken start query
// must not prevent the other three production creation queries from executing.
func TestContestSnapshotProjectionPostgreSQL(t *testing.T) {
	database := projectionPostgres(t)
	for _, stage := range []string{SnapshotConfirmed, SnapshotStarted, SnapshotEconomicsCutoff, SnapshotFinished} {
		t.Run(stage, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
			defer cancel()
			tx, err := database.BeginTx(ctx, nil)
			if err != nil {
				t.Fatal(err)
			}
			defer func() {
				if err := tx.Rollback(); err != nil && err != sql.ErrTxDone {
					t.Errorf("rollback: %v", err)
				}
			}()
			contestID := seedProjectionContest(t, ctx, tx)
			var settlementID string
			if stage == SnapshotEconomicsCutoff {
				// Only the prerequisite is seeded directly, so this subtest reaches
				// EnsureEconomicsCutoff even when EnsureContestStarted is broken.
				if _, err := tx.ExecContext(ctx, `INSERT INTO contest_snapshots
					(contest_id,snapshot_type,snapshot_version,event_at,participant_count,
					starts_at,ends_at,entry_fee_cents,platform_fee_bps,late_join_enabled)
					SELECT id,'contest_started','contest_started_v1',started_at,2,
					starts_at,ends_at,entry_fee_cents,platform_fee_bps,late_join_enabled
					FROM contests WHERE id=$1`, contestID); err != nil {
					t.Fatal(err)
				}
			}
			if stage == SnapshotFinished {
				if err := tx.QueryRowContext(ctx, `INSERT INTO contest_settlements
					(contest_id,status,completed_at) VALUES($1,'completed',CURRENT_TIMESTAMP)
					RETURNING id::text`, contestID).Scan(&settlementID); err != nil {
					t.Fatal(err)
				}
				if _, err := tx.ExecContext(ctx, `UPDATE contests SET status='completed',
					settled_at=CURRENT_TIMESTAMP WHERE id=$1`, contestID); err != nil {
					t.Fatal(err)
				}
			}

			create := func() (*Snapshot, error) {
				switch stage {
				case SnapshotConfirmed:
					return EnsureContestConfirmed(ctx, tx, contestID)
				case SnapshotStarted:
					return EnsureContestStarted(ctx, tx, contestID)
				case SnapshotEconomicsCutoff:
					return EnsureEconomicsCutoff(ctx, tx, contestID)
				default:
					return EnsureContestFinished(ctx, tx, contestID, settlementID)
				}
			}
			created, err := create()
			if err != nil {
				t.Fatalf("create %s: %v", stage, err)
			}
			assertProjectionSnapshot(t, ctx, tx, created, contestID, stage, settlementID)
			replayed, err := create()
			if err != nil {
				t.Fatalf("retry %s: %v", stage, err)
			}
			loaded, err := SnapshotByType(ctx, tx, contestID, stage)
			if err != nil {
				t.Fatal(err)
			}
			if !reflect.DeepEqual(created, replayed) || !reflect.DeepEqual(created, loaded) {
				t.Fatalf("creation, retry and stored read differ: created=%+v retry=%+v loaded=%+v", created, replayed, loaded)
			}
			var count int
			if err := tx.QueryRowContext(ctx, `SELECT COUNT(*) FROM contest_snapshots
				WHERE contest_id=$1 AND snapshot_type=$2::contest_snapshot_type`, contestID, stage).Scan(&count); err != nil {
				t.Fatal(err)
			}
			if count != 1 {
				t.Fatalf("retry left %d snapshots, want 1", count)
			}
		})
	}
}

// Exercise populated cutoff fields through the shared RETURNING/outer SELECT
// independently of the cutoff function's parameter inference and event INSERT.
func TestContestSnapshotProjectionValuesPostgreSQL(t *testing.T) {
	database := projectionPostgres(t)
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	tx, err := database.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		if err := tx.Rollback(); err != nil && err != sql.ErrTxDone {
			t.Errorf("rollback: %v", err)
		}
	}()
	contestID := seedProjectionContest(t, ctx, tx)
	// Fixed nonzero values test projection/scan identity, not fee computation.
	row := tx.QueryRowContext(ctx, `WITH inserted AS (
		INSERT INTO contest_snapshots
		(contest_id,snapshot_type,snapshot_version,event_at,participant_count,
		starts_at,ends_at,entry_fee_cents,platform_fee_bps,late_join_enabled,
		gross_base_entry_cents,platform_fee_cents,late_surcharge_cents,prize_pool_cents,
		planned_winner_count,joined_participant_count,economic_participant_count,
		leaderboard_eligible_count,winner_capacity_shortfall)
		SELECT id,'economics_cutoff','economics_cutoff_v1',CURRENT_TIMESTAMP,2,
		starts_at,ends_at,999,1500,TRUE,1998,298,99,1700,1,2,2,1,FALSE
		FROM contests WHERE id=$1 RETURNING `+snapshotColumns+`)
		SELECT `+snapshotColumns+` FROM inserted`, contestID)
	snapshot, err := scanSnapshot(row)
	if err != nil {
		t.Fatal(err)
	}
	if snapshot.GrossBaseEntryCents != 1998 || snapshot.PlatformFeeCents != 298 ||
		snapshot.LateSurchargeCents != 99 || snapshot.PrizePoolCents != 1700 || snapshot.PlannedWinnerCount != 1 {
		t.Fatalf("projected amounts/winners changed: %+v", snapshot)
	}
	loaded, err := SnapshotByType(ctx, tx, contestID, SnapshotEconomicsCutoff)
	if err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(snapshot, loaded) {
		t.Fatalf("CTE and stored projections differ: CTE=%+v stored=%+v", snapshot, loaded)
	}
}

func assertProjectionSnapshot(t *testing.T, ctx context.Context, tx *sql.Tx, created *Snapshot, contestID, stage, settlementID string) {
	t.Helper()
	if created.ID == "" || created.ContestID != contestID || created.Type != stage ||
		created.Version != stage+"_v1" || created.ParticipantCount != 2 ||
		created.GrossBaseEntryCents != 0 || created.PlatformFeeCents != 0 ||
		created.LateSurchargeCents != 0 || created.PrizePoolCents != 0 {
		t.Fatalf("unexpected created snapshot: %+v", created)
	}
	wantWinners := 0
	if stage == SnapshotEconomicsCutoff {
		wantWinners = 1 // Existing tralent_v1 fixture for two real participants.
	}
	if created.PlannedWinnerCount != wantWinners {
		t.Fatalf("planned winners=%d, want %d", created.PlannedWinnerCount, wantWinners)
	}
	if created.SettlementID.Valid != (stage == SnapshotFinished) || created.SettlementID.String != settlementID {
		t.Fatalf("settlement=%v, want %q", created.SettlementID, settlementID)
	}
	// Projection defaults must not replace stored NULLs in non-cutoff stages.
	var raw [5]sql.NullInt64
	if err := tx.QueryRowContext(ctx, `SELECT gross_base_entry_cents,platform_fee_cents,
		late_surcharge_cents,prize_pool_cents,planned_winner_count
		FROM contest_snapshots WHERE id=$1`, created.ID).
		Scan(&raw[0], &raw[1], &raw[2], &raw[3], &raw[4]); err != nil {
		t.Fatal(err)
	}
	for i, value := range raw {
		if value.Valid != (stage == SnapshotEconomicsCutoff) {
			t.Errorf("stored field %d nullability changed: %v", i, value)
		}
	}
}

func projectionPostgres(t *testing.T) *sql.DB {
	t.Helper()
	dsn := os.Getenv("TRAGGE_E2E_DATABASE_URL")
	if dsn == "" {
		t.Skip("set TRAGGE_E2E_DATABASE_URL for the snapshot projection PostgreSQL regression")
	}
	database, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		if err := database.Close(); err != nil {
			t.Errorf("close PostgreSQL: %v", err)
		}
	})
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	var version int
	var dirty bool
	if err := database.QueryRowContext(ctx, `SELECT version,dirty FROM schema_migrations`).Scan(&version, &dirty); err != nil {
		t.Fatalf("configured PostgreSQL unavailable or unmigrated: %v", err)
	}
	if version < 122 || dirty {
		t.Fatalf("snapshot projection requires clean schema >=122, got version=%d dirty=%v", version, dirty)
	}
	return database
}

func seedProjectionContest(t *testing.T, ctx context.Context, tx *sql.Tx) string {
	t.Helper()
	var contestID string
	if err := tx.QueryRowContext(ctx, `INSERT INTO contests
		(name,starts_at,ends_at,status,entry_fee_cents,platform_fee_bps,min_participants,
		lifecycle_policy_version,funds_policy_version,is_free,started_at)
		VALUES($1,CURRENT_TIMESTAMP-interval '20 minutes',CURRENT_TIMESTAMP+interval '80 minutes',
		'running',0,1500,1,$2,'legacy',TRUE,CURRENT_TIMESTAMP-interval '20 minutes')
		RETURNING id::text`, fmt.Sprintf("projection-%d", time.Now().UnixNano()), ContestSnapshotPolicyV1).Scan(&contestID); err != nil {
		t.Fatal(err)
	}
	for i := range 2 {
		var userID string
		if err := tx.QueryRowContext(ctx, `INSERT INTO users(email,password_hash)
			VALUES($1,'x') RETURNING id::text`, fmt.Sprintf("projection-%s-%d@example.test", contestID, i)).Scan(&userID); err != nil {
			t.Fatal(err)
		}
		if _, err := tx.ExecContext(ctx, `INSERT INTO contest_participants
			(contest_id,user_id,qty_total,qty_available,joined_at)
			VALUES($1,$2,100,100,CURRENT_TIMESTAMP-interval '21 minutes')`, contestID, userID); err != nil {
			t.Fatal(err)
		}
	}
	return contestID
}
