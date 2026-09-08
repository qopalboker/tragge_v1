package server

import (
	"context"
	"net/http/httptest"
	"regexp"
	"sync"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
	"github.com/go-chi/chi/v5"
	"github.com/redis/go-redis/v9"
)

const rankActivationSQL = `UPDATE contest_participants
			SET has_started_trading=TRUE, ranking_started_at=NOW()
			WHERE contest_id=$1 AND user_id=$2 AND has_started_trading=FALSE`

const rankEligibilitySQL = `SELECT lifecycle_status='ACTIVE' AND has_started_trading
		FROM contest_participants WHERE contest_id=$1 AND user_id=$2`

func newRANK001TestApp(t *testing.T) (*App, sqlmock.Sqlmock) {
	t.Helper()
	mr, client := setupTestRedis(t)
	t.Cleanup(mr.Close)
	app, mock := newTestApp(t, mr, client)
	return app, mock
}

func expectEligibility(mock sqlmock.Sqlmock, contestID, userID string, activate, eligible bool, affected int64) {
	if activate {
		mock.ExpectExec(regexp.QuoteMeta(rankActivationSQL)).WithArgs(contestID, userID).
			WillReturnResult(sqlmock.NewResult(0, affected))
	}
	mock.ExpectQuery(regexp.QuoteMeta(rankEligibilitySQL)).WithArgs(contestID, userID).
		WillReturnRows(sqlmock.NewRows([]string{"eligible"}).AddRow(eligible))
}

func TestRANK001JoinAndOrderDoNotActivate(t *testing.T) {
	delta := contracts.PnLDelta{ContestID: "contest", UserID: "joined", TotalScoreDecimal: "0.00000000"}
	if nonZero, err := rankingEvidenceNonZero(delta); err != nil || nonZero {
		t.Fatalf("zero P&L must remain rank zero: nonZero=%v err=%v", nonZero, err)
	}
	// No join/order handler calls rankingEligible; activation is reachable only
	// from the P&L consumer and requires non-zero P&L evidence.
}

func TestRANK001UnstartedParticipantHasRankZero(t *testing.T) {
	app, mock := newRANK001TestApp(t)
	mock.ExpectQuery(regexp.QuoteMeta(`SELECT EXISTS(SELECT 1 FROM contest_participants WHERE contest_id=$1 AND user_id=$2)`)).
		WithArgs("contest", "joined").WillReturnRows(sqlmock.NewRows([]string{"exists"}).AddRow(true))
	req := httptest.NewRequest("GET", "/", nil)
	routeCtx := chi.NewRouteContext()
	routeCtx.URLParams.Add("contestID", "contest")
	routeCtx.URLParams.Add("userID", "joined")
	req = req.WithContext(context.WithValue(req.Context(), chi.RouteCtxKey, routeCtx))
	response := httptest.NewRecorder()

	app.handleUserRank(response, req)
	if response.Code != 200 || !regexp.MustCompile(`"rank"\s*:\s*0`).Match(response.Body.Bytes()) {
		t.Fatalf("unstarted participant must have rank zero: status=%d body=%s", response.Code, response.Body.String())
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestRANK001FirstSpreadPnLActivatesPermanently(t *testing.T) {
	app, mock := newRANK001TestApp(t)
	expectEligibility(mock, "contest", "trader", true, true, 1)
	app.processPnLDeltaBatch([]contracts.PnLDelta{{
		ContestID: "contest", UserID: "trader", TotalScore: -0.01, TotalScoreDecimal: "-0.01000000",
	}})

	rank, err := app.shardedWorker.GetUserRank(context.Background(), "contest", "trader")
	if err != nil || rank == nil || rank.Rank != 1 {
		t.Fatalf("spread-affected first trade must be positively ranked: rank=%+v err=%v", rank, err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestRANK001ReturnToZeroRemainsEligibleAndDuplicateActivationIsIdempotent(t *testing.T) {
	app, mock := newRANK001TestApp(t)
	expectEligibility(mock, "contest", "trader", true, true, 1)
	expectEligibility(mock, "contest", "trader", true, true, 0)
	expectEligibility(mock, "contest", "trader", false, true, 0)
	app.processPnLDeltaBatch([]contracts.PnLDelta{{
		ContestID: "contest", UserID: "trader", TotalScoreDecimal: "-0.01000000",
	}})
	app.processPnLDeltaBatch([]contracts.PnLDelta{{
		ContestID: "contest", UserID: "trader", TotalScoreDecimal: "-0.02000000",
	}})
	app.processPnLDeltaBatch([]contracts.PnLDelta{{
		ContestID: "contest", UserID: "trader", TotalScoreDecimal: "0.00000000",
	}})

	rank, err := app.shardedWorker.GetUserRank(context.Background(), "contest", "trader")
	if err != nil || rank == nil || rank.Rank != 1 || rank.Score != 0 {
		t.Fatalf("activated zero-P&L participant must remain ranked: rank=%+v err=%v", rank, err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestRANK001ConcurrentActivationHasOneWinner(t *testing.T) {
	app, mock := newRANK001TestApp(t)
	mock.MatchExpectationsInOrder(false)
	expectEligibility(mock, "contest", "trader", true, true, 1)
	expectEligibility(mock, "contest", "trader", true, true, 0)
	delta := contracts.PnLDelta{ContestID: "contest", UserID: "trader", TotalScoreDecimal: "-0.01000000"}

	var wg sync.WaitGroup
	errs := make(chan error, 2)
	for range 2 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			_, err := app.rankingEligible(context.Background(), delta)
			errs <- err
		}()
	}
	wg.Wait()
	close(errs)
	for err := range errs {
		if err != nil {
			t.Fatal(err)
		}
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestRANK001TerminalParticipantExcludedWithHistoryPreserved(t *testing.T) {
	app, mock := newRANK001TestApp(t)
	seedLeaderboard(t, app.redis, "contest", map[string]float64{"removed": 9})
	expectEligibility(mock, "contest", "removed", false, false, 0)
	app.processPnLDeltaBatch([]contracts.PnLDelta{{
		ContestID: "contest", UserID: "removed", TotalScoreDecimal: "0.00000000",
	}})
	if _, err := app.redis.ZScore(context.Background(), LeaderboardKey("contest"), "removed").Result(); err != redis.Nil {
		t.Fatalf("terminal participant remained in projection: %v", err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}

func TestRANK001RedisRebuildAndFinalRankingUsePostgresAuthority(t *testing.T) {
	app, mock := newRANK001TestApp(t)
	seedLeaderboard(t, app.redis, "contest", map[string]float64{"stale": 999})
	query := regexp.QuoteMeta(`SELECT user_id::text, total_score::text
		FROM contest_participants
		WHERE contest_id=$1 AND lifecycle_status='ACTIVE' AND has_started_trading=TRUE
		ORDER BY total_score DESC, user_id`)
	dbRows := func() *sqlmock.Rows {
		return sqlmock.NewRows([]string{"user_id", "total_score"}).
			AddRow("winner", "5.00000000").AddRow("zero-return", "0.00000000")
	}
	mock.ExpectQuery(query).WithArgs("contest").WillReturnRows(dbRows())
	if err := app.rebuildLeaderboard(context.Background(), "contest"); err != nil {
		t.Fatal(err)
	}
	members, err := app.redis.ZRevRange(context.Background(), LeaderboardKey("contest"), 0, -1).Result()
	if err != nil || len(members) != 2 || members[0] != "winner" || members[1] != "zero-return" {
		t.Fatalf("unexpected rebuilt members: %v err=%v", members, err)
	}

	mock.ExpectQuery(query).WithArgs("contest").WillReturnRows(dbRows())
	ranks, err := app.prepareFinalRankings(context.Background(), "contest")
	if err != nil || len(ranks) != 2 || ranks[0].Rank != 1 || ranks[1].Rank != 2 {
		t.Fatalf("final ranks are not compact/database-backed: %+v err=%v", ranks, err)
	}
	if err := mock.ExpectationsWereMet(); err != nil {
		t.Fatal(err)
	}
}
