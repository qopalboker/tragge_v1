package server

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"sync"
	"testing"
	"time"

	"github.com/DATA-DOG/go-sqlmock"
)

func TestCompleteContestFinalizationRejectsWrongSettlementPair(t *testing.T) {
	database, mock, err := sqlmock.New()
	if err != nil {
		t.Fatal(err)
	}
	defer database.Close()
	app := &App{db: database}

	mock.ExpectBegin()
	mock.ExpectQuery("SELECT lifecycle_policy_version FROM contests").
		WithArgs("contest-a").
		WillReturnRows(sqlmock.NewRows([]string{"lifecycle_policy_version"}).AddRow("contest_snapshot_v1"))
	mock.ExpectExec("UPDATE contest_settlements").
		WithArgs("settlement-b", "contest-a").
		WillReturnResult(sqlmock.NewResult(0, 0))
	mock.ExpectRollback()

	if err := app.completeContestFinalization(context.Background(), "contest-a", "settlement-b"); err == nil {
		t.Fatal("wrong contest/settlement pair completed")
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestCompleteContestFinalizationConcurrentPostgres(t *testing.T) {
	dsn := os.Getenv("TRAGGE_E2E_DATABASE_URL")
	if dsn == "" {
		t.Skip("set TRAGGE_E2E_DATABASE_URL for real PostgreSQL certification")
	}
	database, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatal(err)
	}
	defer database.Close()
	ctx := context.Background()
	if err = database.PingContext(ctx); err != nil {
		t.Skipf("PostgreSQL unavailable: %v", err)
	}
	var migrated bool
	if err = database.QueryRow(`SELECT to_regclass('public.contest_snapshots') IS NOT NULL`).Scan(&migrated); err != nil || !migrated {
		t.Skip("migration 0117 not applied")
	}
	var contestID, settlementID string
	if err = database.QueryRow(`INSERT INTO contests(name,starts_at,ends_at,status,lifecycle_policy_version) VALUES($1,CURRENT_TIMESTAMP-interval '1 hour',CURRENT_TIMESTAMP,'settling','contest_snapshot_v1') RETURNING id::text`, fmt.Sprintf("finish-race-%d", time.Now().UnixNano())).Scan(&contestID); err != nil {
		t.Fatal(err)
	}
	if err = database.QueryRow(`INSERT INTO contest_settlements(contest_id,status) VALUES($1,'in_progress') RETURNING id::text`, contestID).Scan(&settlementID); err != nil {
		t.Fatal(err)
	}
	app := &App{db: database}
	start := make(chan struct{})
	errs := make(chan error, 2)
	var wg sync.WaitGroup
	wg.Add(2)
	for range 2 {
		go func() {
			defer wg.Done()
			<-start
			errs <- app.completeContestFinalization(ctx, contestID, settlementID)
		}()
	}
	close(start)
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	var snapshots int
	if err = database.QueryRow(`SELECT COUNT(*) FROM contest_snapshots WHERE contest_id=$1 AND snapshot_type='contest_finished'`, contestID).Scan(&snapshots); err != nil {
		t.Fatal(err)
	}
	if snapshots != 1 {
		t.Fatalf("finished snapshots=%d want 1", snapshots)
	}
}
