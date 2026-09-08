package server

import (
	"context"
	"fmt"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
	"github.com/redis/go-redis/v9"
	"github.com/shopspring/decimal"
)

// rankingEvidenceNonZero uses only the canonical decimal event value. Ranking
// activation fails closed rather than treating binary floating point as authority.
func rankingEvidenceNonZero(delta contracts.PnLDelta) (bool, error) {
	if delta.TotalScoreDecimal == "" {
		return false, fmt.Errorf("canonical total_score_decimal is required for ranking activation")
	}
	score, err := decimal.NewFromString(delta.TotalScoreDecimal)
	if err != nil {
		return false, fmt.Errorf("parse total_score_decimal: %w", err)
	}
	return !score.IsZero(), nil
}

// rankingEligible atomically persists the first non-zero P&L observation and
// returns current membership. The conditional update makes concurrent/retried
// activations first-writer-wins; the database trigger prevents reversal.
func (a *App) rankingEligible(ctx context.Context, delta contracts.PnLDelta) (bool, error) {
	nonZero, err := rankingEvidenceNonZero(delta)
	if err != nil {
		return false, err
	}
	if nonZero {
		result, err := a.db.ExecContext(ctx, `
			UPDATE contest_participants
			SET has_started_trading=TRUE, ranking_started_at=NOW()
			WHERE contest_id=$1 AND user_id=$2 AND has_started_trading=FALSE`, delta.ContestID, delta.UserID)
		if err != nil {
			return false, fmt.Errorf("activate ranking: %w", err)
		}
		if affected, err := result.RowsAffected(); err != nil || affected > 1 {
			return false, fmt.Errorf("invalid ranking activation cardinality: affected=%d err=%v", affected, err)
		}
	}

	var eligible bool
	err = a.db.QueryRowContext(ctx, `
		SELECT lifecycle_status='ACTIVE' AND has_started_trading
		FROM contest_participants WHERE contest_id=$1 AND user_id=$2`, delta.ContestID, delta.UserID).Scan(&eligible)
	if err != nil {
		return false, fmt.Errorf("read ranking eligibility: %w", err)
	}
	return eligible, nil
}

func (a *App) removeLeaderboardProjection(ctx context.Context, contestID, userID string) error {
	pipe := a.redis.Pipeline()
	pipe.ZRem(ctx, LeaderboardKey(contestID), userID)
	pipe.HDel(ctx, ScoreBreakdownKey(contestID), userID)
	_, err := pipe.Exec(ctx)
	if err != nil {
		return fmt.Errorf("remove ineligible leaderboard projection: %w", err)
	}
	if a.shardedWorker != nil {
		a.shardedWorker.invalidateCache(contestID)
	}
	return nil
}

// rebuildLeaderboard replaces Redis membership from PostgreSQL ranking state
// and canonical participant scores. Redis contributes no eligibility decision.
func (a *App) rebuildLeaderboard(ctx context.Context, contestID string) error {
	rows, err := a.db.QueryContext(ctx, `
		SELECT user_id::text, total_score::text
		FROM contest_participants
		WHERE contest_id=$1 AND lifecycle_status='ACTIVE' AND has_started_trading=TRUE
		ORDER BY total_score DESC, user_id`, contestID)
	if err != nil {
		return fmt.Errorf("query leaderboard rebuild: %w", err)
	}
	defer rows.Close()

	members := make([]redis.Z, 0)
	for rows.Next() {
		var userID, scoreText string
		if err := rows.Scan(&userID, &scoreText); err != nil {
			return fmt.Errorf("scan leaderboard rebuild: %w", err)
		}
		score, err := decimal.NewFromString(scoreText)
		if err != nil {
			return fmt.Errorf("parse leaderboard rebuild score: %w", err)
		}
		value, _ := score.Float64()
		members = append(members, redis.Z{Member: userID, Score: value})
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("iterate leaderboard rebuild: %w", err)
	}

	key := LeaderboardKey(contestID)
	pipe := a.redis.TxPipeline()
	pipe.Del(ctx, key, ScoreBreakdownKey(contestID))
	if len(members) > 0 {
		pipe.ZAdd(ctx, key, members...)
	}
	if _, err := pipe.Exec(ctx); err != nil {
		return fmt.Errorf("replace leaderboard projection: %w", err)
	}
	if a.shardedWorker != nil {
		a.shardedWorker.invalidateCache(contestID)
	}
	return nil
}

func (a *App) rebuildLiveLeaderboards(ctx context.Context) error {
	rows, err := a.db.QueryContext(ctx, `
		SELECT id::text FROM contests
		WHERE status IN ('running','paused','settling')
		ORDER BY id`)
	if err != nil {
		return fmt.Errorf("query live leaderboard rebuild set: %w", err)
	}
	defer rows.Close()
	contestIDs := make([]string, 0)
	for rows.Next() {
		var contestID string
		if err := rows.Scan(&contestID); err != nil {
			return fmt.Errorf("scan live leaderboard rebuild set: %w", err)
		}
		contestIDs = append(contestIDs, contestID)
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("iterate live leaderboard rebuild set: %w", err)
	}
	for _, contestID := range contestIDs {
		if err := a.rebuildLeaderboard(ctx, contestID); err != nil {
			return err
		}
	}
	return nil
}

// prepareFinalRankings reads final membership and canonical scores only from
// PostgreSQL. Redis is deliberately excluded from final winner authority.
func (a *App) prepareFinalRankings(ctx context.Context, contestID string) ([]LeaderboardEntry, error) {
	rows, err := a.db.QueryContext(ctx, `
		SELECT user_id::text, total_score::text
		FROM contest_participants
		WHERE contest_id=$1 AND lifecycle_status='ACTIVE' AND has_started_trading=TRUE
		ORDER BY total_score DESC, user_id`, contestID)
	if err != nil {
		return nil, fmt.Errorf("query final rankings: %w", err)
	}
	defer rows.Close()

	entries := make([]LeaderboardEntry, 0)
	for rows.Next() {
		var userID, scoreText string
		if err := rows.Scan(&userID, &scoreText); err != nil {
			return nil, fmt.Errorf("scan final rankings: %w", err)
		}
		score, err := decimal.NewFromString(scoreText)
		if err != nil {
			return nil, fmt.Errorf("parse final ranking score: %w", err)
		}
		value, _ := score.Float64()
		entries = append(entries, LeaderboardEntry{Rank: len(entries) + 1, UserID: userID, Score: value})
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate final rankings: %w", err)
	}
	return entries, nil
}
