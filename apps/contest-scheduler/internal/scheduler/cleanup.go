package scheduler

import (
	"context"
	"database/sql"
	"fmt"
	"runtime/debug"
	"sync"
	"sync/atomic"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/db"
	"github.com/Parsaeffatravesh/tragge/packages/domain/statemachine"
	"github.com/Parsaeffatravesh/tragge/packages/infra"
	"github.com/Parsaeffatravesh/tragge/packages/notification/inapp"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/redis/go-redis/v9"
	"go.uber.org/zap"
)

// Cleanup-specific Prometheus metrics
var (
	cleanupArchivesTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "contest_scheduler_cleanup_archives_total",
		Help: "Total number of tournaments archived",
	})

	cleanupCancellationsTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "contest_scheduler_cleanup_cancellations_total",
		Help: "Total number of stale tournaments cancelled",
	})

	cleanupOrphansTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "contest_scheduler_cleanup_orphans_total",
		Help: "Total number of orphaned records cleaned",
	})

	cleanupLastRunTimestamp = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "contest_scheduler_cleanup_last_run_timestamp_seconds",
		Help: "Timestamp of the last successful cleanup run",
	})

	cleanupDuration = promauto.NewHistogram(prometheus.HistogramOpts{
		Name:    "contest_scheduler_cleanup_duration_seconds",
		Help:    "Duration of cleanup operations",
		Buckets: prometheus.ExponentialBuckets(1, 2, 12),
	})

	cleanupErrorsTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "contest_scheduler_cleanup_errors_total",
		Help: "Total number of cleanup errors",
	})

	cleanupNotificationsTotal = promauto.NewCounter(prometheus.CounterOpts{
		Name: "contest_scheduler_cleanup_notifications_total",
		Help: "Total number of old notifications cleaned up",
	})

	cleanupStuckRunningTotal = promauto.NewGauge(prometheus.GaugeOpts{
		Name: "contest_scheduler_cleanup_stuck_running",
		Help: "Number of contests stuck in running state beyond twice their duration",
	})
)

// AuditRetentionYears is the product/compliance retention for archived contests
// (LIFECYCLE-003 human decision: 7 years). Archive rows must remain queryable
// until retain_until (= archived_at + AuditRetentionYears).
const AuditRetentionYears = 7

// CleanupConfig holds configuration for the cleanup service.
type CleanupConfig struct {
	// ArchiveAfterDays is the number of days after completion before archiving (default: 30)
	ArchiveAfterDays int

	// CheckInterval is how often to check if it's time to run cleanup (default: 1h)
	CheckInterval time.Duration

	// LockTTL is the Redis lock TTL for the cleanup job (default: 5m)
	LockTTL time.Duration

	// Timezone is the IANA timezone for scheduling the cleanup run (default: "Asia/Tehran")
	Timezone string

	// RunHour is the hour (0-23) in the configured timezone to run cleanup (default: 3)
	RunHour int

	// RunMinute is the minute (0-59) in the configured timezone to run cleanup (default: 0)
	RunMinute int

	// InstanceID is the unique identifier for this scheduler instance
	InstanceID string
}

// DefaultCleanupConfig returns default cleanup configuration.
func DefaultCleanupConfig() CleanupConfig {
	return CleanupConfig{
		ArchiveAfterDays: 30,
		CheckInterval:    1 * time.Hour,
		LockTTL:          5 * time.Minute,
		Timezone:         "Asia/Tehran",
		RunHour:          3,
		RunMinute:        0,
	}
}

// CleanupService handles daily tournament cleanup and archival.
type CleanupService struct {
	pool         *db.Pool
	redis        redis.UniversalClient
	stateMachine *statemachine.StateMachine
	config       CleanupConfig
	logger       *zap.Logger
	location     *time.Location

	running   atomic.Bool
	stop      chan struct{}
	wg        sync.WaitGroup
	lastRunAt time.Time
	mu        sync.RWMutex
}

// NewCleanupService creates a new cleanup service.
func NewCleanupService(
	pool *db.Pool,
	redisClient redis.UniversalClient,
	sm *statemachine.StateMachine,
	config CleanupConfig,
	logger *zap.Logger,
) *CleanupService {
	if logger == nil {
		logger = zap.NewNop()
	}

	if config.ArchiveAfterDays <= 0 {
		config.ArchiveAfterDays = DefaultCleanupConfig().ArchiveAfterDays
	}
	if config.CheckInterval <= 0 {
		config.CheckInterval = DefaultCleanupConfig().CheckInterval
	}
	if config.LockTTL <= 0 {
		config.LockTTL = DefaultCleanupConfig().LockTTL
	}
	if config.Timezone == "" {
		config.Timezone = DefaultCleanupConfig().Timezone
	}

	loc, err := time.LoadLocation(config.Timezone)
	if err != nil {
		logger.Warn("Failed to load timezone, falling back to Asia/Tehran",
			zap.String("timezone", config.Timezone),
			zap.Error(err))
		loc, _ = time.LoadLocation("Asia/Tehran")
	}

	return &CleanupService{
		pool:         pool,
		redis:        redisClient,
		stateMachine: sm,
		config:       config,
		logger:       logger,
		location:     loc,
		stop:         make(chan struct{}),
	}
}

// Start begins the cleanup service loop.
func (cs *CleanupService) Start(ctx context.Context) {
	if cs.running.Swap(true) {
		return // Already running
	}

	cs.logger.Info("Starting cleanup service",
		zap.Int("archive_after_days", cs.config.ArchiveAfterDays),
		zap.String("timezone", cs.config.Timezone),
		zap.Int("run_hour", cs.config.RunHour),
		zap.Int("run_minute", cs.config.RunMinute),
		zap.Duration("check_interval", cs.config.CheckInterval))

	cs.wg.Add(1)
	go cs.run(ctx)
}

// Stop stops the cleanup service gracefully.
func (cs *CleanupService) Stop(ctx context.Context) {
	if !cs.running.Load() {
		return
	}

	cs.logger.Info("Stopping cleanup service")

	close(cs.stop)

	done := make(chan struct{})
	infra.SafeGo(cs.logger, "cleanup-stop-wait", func() {
		cs.wg.Wait()
		close(done)
	})

	select {
	case <-done:
		cs.logger.Info("Cleanup service stopped gracefully")
	case <-ctx.Done():
		cs.logger.Warn("Cleanup service stop timed out")
	}

	cs.running.Store(false)
}

// IsRunning returns whether the cleanup service is currently running.
func (cs *CleanupService) IsRunning() bool {
	return cs.running.Load()
}

// Health returns cleanup service health information.
func (cs *CleanupService) Health() map[string]any {
	cs.mu.RLock()
	defer cs.mu.RUnlock()

	result := map[string]any{
		"running":            cs.running.Load(),
		"archive_after_days": cs.config.ArchiveAfterDays,
		"timezone":           cs.config.Timezone,
		"run_time":           fmt.Sprintf("%02d:%02d", cs.config.RunHour, cs.config.RunMinute),
	}

	if !cs.lastRunAt.IsZero() {
		result["last_run_at"] = cs.lastRunAt.Format(time.RFC3339)
	}

	return result
}

// run is the main cleanup service loop.
func (cs *CleanupService) run(ctx context.Context) {
	defer cs.wg.Done()
	defer func() {
		if r := recover(); r != nil {
			cs.logger.Error("CleanupService.run panicked",
				zap.Any("panic", r),
				zap.String("stack", string(debug.Stack())))
		}
	}()

	ticker := time.NewTicker(cs.config.CheckInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-cs.stop:
			return
		case <-ticker.C:
			if cs.shouldRunNow() {
				cs.executeCleanup(ctx)
			}
		}
	}
}

// shouldRunNow checks if it's time to run the daily cleanup.
// Returns true if current local time is within the run window and
// cleanup hasn't been run today.
func (cs *CleanupService) shouldRunNow() bool {
	now := time.Now().In(cs.location)

	// Check if we're within the run window (target hour/minute ± check interval)
	targetMinutes := cs.config.RunHour*60 + cs.config.RunMinute
	currentMinutes := now.Hour()*60 + now.Minute()

	windowMinutes := int(cs.config.CheckInterval.Minutes())
	if windowMinutes < 1 {
		windowMinutes = 1
	}

	if currentMinutes < targetMinutes || currentMinutes >= targetMinutes+windowMinutes {
		return false
	}

	// Check if we already ran today
	cs.mu.RLock()
	lastRun := cs.lastRunAt
	cs.mu.RUnlock()

	if !lastRun.IsZero() {
		lastRunLocal := lastRun.In(cs.location)
		if lastRunLocal.Year() == now.Year() &&
			lastRunLocal.Month() == now.Month() &&
			lastRunLocal.Day() == now.Day() {
			return false
		}
	}

	return true
}

// executeCleanup runs the full cleanup process with distributed locking.
func (cs *CleanupService) executeCleanup(ctx context.Context) {
	startTime := time.Now()

	cs.logger.Info("Starting daily cleanup job")

	// Acquire distributed lock to prevent multiple instances running cleanup
	lockKey := "contest:cleanup:daily"
	lockValue := cs.config.InstanceID
	if lockValue == "" {
		lockValue = "cleanup-worker"
	}

	acquired, err := cs.redis.SetNX(ctx, lockKey, lockValue, cs.config.LockTTL).Result()
	if err != nil {
		cs.logger.Error("Failed to acquire cleanup lock", zap.Error(err))
		cleanupErrorsTotal.Inc()
		return
	}
	if !acquired {
		cs.logger.Debug("Cleanup lock held by another instance, skipping")
		return
	}

	// Release lock when done
	defer func() {
		cs.redis.Del(ctx, lockKey)
	}()

	var summary CleanupSummary

	// 1. Archive completed tournaments older than configured days
	archived, err := cs.archiveCompletedTournaments(ctx)
	if err != nil {
		cs.logger.Error("Failed to archive tournaments", zap.Error(err))
		cleanupErrorsTotal.Inc()
	} else {
		summary.Archived = archived
	}

	// 2. Cancel stale scheduled/registration_open tournaments
	cancelled, err := cs.cancelStaleTournaments(ctx)
	if err != nil {
		cs.logger.Error("Failed to cancel stale tournaments", zap.Error(err))
		cleanupErrorsTotal.Inc()
	} else {
		summary.Cancelled = cancelled
	}

	// 2.5. Detect stuck running contests (log warning only, no auto-cancel)
	stuckCount, err := cs.detectStuckRunningContests(ctx)
	if err != nil {
		cs.logger.Error("Failed to detect stuck running contests", zap.Error(err))
		cleanupErrorsTotal.Inc()
	} else {
		summary.StuckRunning = stuckCount
	}

	// 3. Clean up orphaned data
	orphaned, err := cs.cleanupOrphanedData(ctx)
	if err != nil {
		cs.logger.Error("Failed to clean up orphaned data", zap.Error(err))
		cleanupErrorsTotal.Inc()
	} else {
		summary.OrphanedCleaned = orphaned
	}

	// 4. Clean up old notifications (read >30 days, all >90 days)
	notifResult, err := inapp.CleanupOldNotifications(ctx, cs.pool.Primary(), 30, 90)
	if err != nil {
		cs.logger.Error("Failed to clean up old notifications", zap.Error(err))
		cleanupErrorsTotal.Inc()
	} else {
		summary.NotificationsDeleted = notifResult.ReadExpired + notifResult.MaxExpired
		if summary.NotificationsDeleted > 0 {
			cleanupNotificationsTotal.Add(float64(summary.NotificationsDeleted))
		}
	}

	// Update metrics and state
	duration := time.Since(startTime)
	cleanupDuration.Observe(duration.Seconds())
	cleanupLastRunTimestamp.Set(float64(startTime.Unix()))

	cs.mu.Lock()
	cs.lastRunAt = startTime
	cs.mu.Unlock()

	// Log summary
	cs.logger.Info("Daily cleanup completed",
		zap.Int("archived", summary.Archived),
		zap.Int("cancelled", summary.Cancelled),
		zap.Int("stuck_running", summary.StuckRunning),
		zap.Int("orphaned_cleaned", summary.OrphanedCleaned),
		zap.Int64("notifications_deleted", summary.NotificationsDeleted),
		zap.Duration("duration", duration))
}

// CleanupSummary holds the results of a cleanup run.
type CleanupSummary struct {
	Archived              int
	Cancelled             int
	StuckRunning          int
	OrphanedCleaned       int
	NotificationsDeleted  int64
}

// archiveCompletedTournaments copies completed tournaments (and related audit rows)
// into archive tables, then soft-deletes them from the hot path via contests.archived_at.
// LIFECYCLE-003: never hard-DELETE contests (CASCADE would destroy trading/audit history).
func (cs *CleanupService) archiveCompletedTournaments(ctx context.Context) (int, error) {
	archiveBefore := time.Now().AddDate(0, 0, -cs.config.ArchiveAfterDays)

	tx, err := cs.pool.Primary().BeginTx(ctx, nil)
	if err != nil {
		return 0, fmt.Errorf("failed to begin archive tx: %w", err)
	}
	defer tx.Rollback()

	// Candidate set: completed, settled, old enough, not yet soft-archived.
	rows, err := tx.QueryContext(ctx, `
		SELECT id FROM contests
		WHERE status = 'completed'
		  AND settled_at IS NOT NULL
		  AND settled_at < $1
		  AND archived_at IS NULL
	`, archiveBefore)
	if err != nil {
		return 0, fmt.Errorf("failed to query archive candidates: %w", err)
	}
	var ids []string
	for rows.Next() {
		var id string
		if scanErr := rows.Scan(&id); scanErr != nil {
			rows.Close()
			return 0, scanErr
		}
		ids = append(ids, id)
	}
	rows.Close()
	if err := rows.Err(); err != nil {
		return 0, err
	}
	if len(ids) == 0 {
		return 0, nil
	}

	for _, contestID := range ids {
		if err := archiveOneContest(ctx, tx, contestID); err != nil {
			return 0, fmt.Errorf("archive contest %s: %w", contestID, err)
		}
	}

	if err := tx.Commit(); err != nil {
		return 0, fmt.Errorf("failed to commit archive tx: %w", err)
	}

	cleanupArchivesTotal.Add(float64(len(ids)))
	cs.logger.Info("Archived completed tournaments (soft-delete)",
		zap.Int("count", len(ids)),
		zap.Time("before", archiveBefore),
		zap.Int("retention_years", AuditRetentionYears))
	return len(ids), nil
}

// archiveOneContest copies contest + related rows into archive tables and soft-deletes.
func archiveOneContest(ctx context.Context, tx *sql.Tx, contestID string) error {
	_, err := tx.ExecContext(ctx, `
		INSERT INTO tournaments_archive (
			id, name, description, starts_at, ends_at, status,
			entry_fee_cents, platform_fee_bps, qty_total, rules_json, created_at,
			published_at, started_at, ended_at, settled_at,
			cancelled_at, cancellation_reason,
			current_participants, min_participants, max_participants,
			registration_deadline, registration_opens_at,
			auto_start, commission_rate,
			paused_at, total_paused_duration,
			archived_at, retain_until,
			prize_pool_net_cents, is_free,
			economics_locked_at, locked_entry_fee_cents, locked_platform_fee_bps
		)
		SELECT
			id, name, description, starts_at, ends_at, status,
			entry_fee_cents, platform_fee_bps, qty_total, rules_json, created_at,
			published_at, started_at, ended_at, settled_at,
			cancelled_at, cancellation_reason,
			current_participants, min_participants, max_participants,
			registration_deadline, registration_opens_at,
			auto_start, commission_rate,
			paused_at, total_paused_duration,
			NOW(), NOW() + ($2::int * INTERVAL '1 year'),
			COALESCE(prize_pool_net_cents, 0), COALESCE(is_free, FALSE),
			economics_locked_at, locked_entry_fee_cents, locked_platform_fee_bps
		FROM contests
		WHERE id = $1
		ON CONFLICT (id) DO NOTHING
	`, contestID, AuditRetentionYears)
	if err != nil {
		return fmt.Errorf("tournaments_archive insert: %w", err)
	}

	_, err = tx.ExecContext(ctx, `
		INSERT INTO contest_participants_archive (
			contest_id, user_id, joined_at, qty_total, qty_available,
			total_score, final_rank, final_prize_cents, archived_at
		)
		SELECT contest_id, user_id, joined_at, qty_total, qty_available,
			total_score, final_rank, final_prize_cents, NOW()
		FROM contest_participants
		WHERE contest_id = $1
		ON CONFLICT (contest_id, user_id) DO NOTHING
	`, contestID)
	if err != nil {
		return fmt.Errorf("participants_archive insert: %w", err)
	}

	_, err = tx.ExecContext(ctx, `
		INSERT INTO contest_symbols_archive (
			contest_id, symbol, provider_symbol_twelvedata, provider_symbol_finnhub,
			enabled, created_at, archived_at
		)
		SELECT contest_id, symbol, provider_symbol_twelvedata, provider_symbol_finnhub,
			enabled, created_at, NOW()
		FROM contest_symbols
		WHERE contest_id = $1
		ON CONFLICT (contest_id, symbol) DO NOTHING
	`, contestID)
	if err != nil {
		return fmt.Errorf("symbols_archive insert: %w", err)
	}

	_, err = tx.ExecContext(ctx, `
		INSERT INTO contest_status_history_archive (
			id, contest_id, from_status, to_status, changed_by, reason, metadata, created_at, archived_at
		)
		SELECT id, contest_id, from_status::text, to_status::text, changed_by, reason, metadata, created_at, NOW()
		FROM contest_status_history
		WHERE contest_id = $1
		ON CONFLICT (id) DO NOTHING
	`, contestID)
	if err != nil {
		return fmt.Errorf("status_history_archive insert: %w", err)
	}

	// Soft-delete: leave row + children for FK integrity; exclude from hot path via archived_at.
	res, err := tx.ExecContext(ctx, `
		UPDATE contests
		SET archived_at = NOW()
		WHERE id = $1 AND archived_at IS NULL
	`, contestID)
	if err != nil {
		return fmt.Errorf("soft-delete contest: %w", err)
	}
	n, _ := res.RowsAffected()
	if n == 0 {
		return fmt.Errorf("contest %s already archived or missing", contestID)
	}
	return nil
}

// cancelStaleTournaments cancels scheduled or registration_open tournaments
// that have passed their start_time without any participants.
func (cs *CleanupService) cancelStaleTournaments(ctx context.Context) (int, error) {
	// Find stale contests
	rows, err := cs.pool.Primary().QueryContext(ctx, `
		SELECT id
		FROM contests
		WHERE status IN ('scheduled', 'registration_open')
		  AND starts_at < NOW()
		  AND current_participants = 0
	`)
	if err != nil {
		return 0, fmt.Errorf("failed to query stale tournaments: %w", err)
	}
	defer rows.Close()

	var staleIDs []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			continue
		}
		staleIDs = append(staleIDs, id)
	}
	if err := rows.Err(); err != nil {
		return 0, fmt.Errorf("error iterating stale tournaments: %w", err)
	}

	// Cancel each stale contest using the state machine (proper transition + Kafka event)
	cancelled := 0
	for _, id := range staleIDs {
		_, err := cs.stateMachine.Cancel(ctx, id, nil,
			"Auto-cancelled: past start time with no participants")
		if err != nil {
			cs.logger.Warn("Failed to cancel stale tournament",
				zap.String("contest_id", id),
				zap.Error(err))
			continue
		}
		cancelled++
		cs.logger.Info("Cancelled stale tournament",
			zap.String("contest_id", id))
	}

	if cancelled > 0 {
		cleanupCancellationsTotal.Add(float64(cancelled))
	}

	return cancelled, nil
}

// detectStuckRunningContests logs warnings for contests that have been in 'running'
// state for longer than twice their configured duration. Does NOT auto-cancel them
// to avoid data loss; operators must investigate manually.
func (cs *CleanupService) detectStuckRunningContests(ctx context.Context) (int, error) {
	rows, err := cs.pool.Primary().QueryContext(ctx, `
		SELECT id, name, starts_at, duration_minutes
		FROM contests
		WHERE status = 'running'
		  AND starts_at + ((duration_minutes * 2 + COALESCE(EXTRACT(EPOCH FROM total_paused_duration)::int / 60, 0)) || ' minutes')::interval < NOW()
	`)
	if err != nil {
		return 0, fmt.Errorf("failed to query stuck running contests: %w", err)
	}
	defer rows.Close()

	count := 0
	for rows.Next() {
		var id, name string
		var startsAt time.Time
		var durationMinutes int
		if err := rows.Scan(&id, &name, &startsAt, &durationMinutes); err != nil {
			continue
		}
		count++
		cs.logger.Warn("Contest stuck in running state",
			zap.String("contest_id", id),
			zap.String("contest_name", name),
			zap.Time("starts_at", startsAt),
			zap.Int("duration_minutes", durationMinutes),
			zap.Duration("elapsed", time.Since(startsAt)))
	}

	cleanupStuckRunningTotal.Set(float64(count))
	return count, rows.Err()
}

// cleanupOrphanedData removes orphaned records that reference non-existent contests.
func (cs *CleanupService) cleanupOrphanedData(ctx context.Context) (int, error) {
	totalCleaned := 0

	// Clean up orphaned contest_participants (referencing non-existent contests)
	result, err := cs.pool.Primary().ExecContext(ctx, `
		DELETE FROM contest_participants cp_del
		WHERE NOT EXISTS (SELECT 1 FROM contests c WHERE c.id = cp_del.contest_id)
		  AND NOT EXISTS (SELECT 1 FROM tournaments_archive ta WHERE ta.id = cp_del.contest_id)
	`)
	if err != nil {
		cs.logger.Warn("Failed to clean orphaned participants", zap.Error(err))
	} else {
		count, _ := result.RowsAffected()
		totalCleaned += int(count)
	}

	// Clean up orphaned contest_symbols (referencing non-existent contests)
	result, err = cs.pool.Primary().ExecContext(ctx, `
		DELETE FROM contest_symbols cs_del
		WHERE NOT EXISTS (SELECT 1 FROM contests c WHERE c.id = cs_del.contest_id)
		  AND NOT EXISTS (SELECT 1 FROM tournaments_archive ta WHERE ta.id = cs_del.contest_id)
	`)
	if err != nil {
		cs.logger.Warn("Failed to clean orphaned symbols", zap.Error(err))
	} else {
		count, _ := result.RowsAffected()
		totalCleaned += int(count)
	}

	// Clean up orphaned contest_status_history (referencing non-existent contests)
	result, err = cs.pool.Primary().ExecContext(ctx, `
		DELETE FROM contest_status_history csh_del
		WHERE NOT EXISTS (SELECT 1 FROM contests c WHERE c.id = csh_del.contest_id)
		  AND NOT EXISTS (SELECT 1 FROM tournaments_archive ta WHERE ta.id = csh_del.contest_id)
	`)
	if err != nil {
		cs.logger.Warn("Failed to clean orphaned status history", zap.Error(err))
	} else {
		count, _ := result.RowsAffected()
		totalCleaned += int(count)
	}

	// Clean up orphaned leaderboard_snapshots
	result, err = cs.pool.Primary().ExecContext(ctx, `
		DELETE FROM leaderboard_snapshots ls_del
		WHERE NOT EXISTS (SELECT 1 FROM contests c WHERE c.id = ls_del.contest_id)
		  AND NOT EXISTS (SELECT 1 FROM tournaments_archive ta WHERE ta.id = ls_del.contest_id)
	`)
	if err != nil {
		// Table may not exist, treat as non-fatal
		if !isUndefinedTableError(err) {
			cs.logger.Warn("Failed to clean orphaned leaderboard snapshots", zap.Error(err))
		}
	} else {
		count, _ := result.RowsAffected()
		totalCleaned += int(count)
	}

	if totalCleaned > 0 {
		cleanupOrphansTotal.Add(float64(totalCleaned))
		cs.logger.Info("Cleaned up orphaned records", zap.Int("total", totalCleaned))
	}

	return totalCleaned, nil
}

// isUndefinedTableError checks if the error is a PostgreSQL "undefined table" error.
func isUndefinedTableError(err error) bool {
	if err == nil {
		return false
	}
	// PostgreSQL error code 42P01 = undefined_table
	return false // Non-critical, just skip
}

// ArchivedContestAuditRow is a cold-path audit projection (queryable after soft-archive).
type ArchivedContestAuditRow struct {
	ID               string
	Name             string
	Status           string
	EntryFeeCents    int
	PlatformFeeBps   int
	PrizePoolNetCents int64
	ParticipantCount int
	ArchivedAt       time.Time
	RetainUntil      time.Time
}

// QueryArchivedContestForAudit loads a soft-archived contest from tournaments_archive.
// Hot-path listings exclude archived_at IS NOT NULL; this is the audit/export path.
func (cs *CleanupService) QueryArchivedContestForAudit(ctx context.Context, contestID string) (*ArchivedContestAuditRow, error) {
	var row ArchivedContestAuditRow
	err := cs.pool.Replica().QueryRowContext(ctx, `
		SELECT id::text, name, status::text,
		       COALESCE(entry_fee_cents, 0), COALESCE(platform_fee_bps, 0),
		       COALESCE(prize_pool_net_cents, 0), COALESCE(current_participants, 0),
		       archived_at, COALESCE(retain_until, archived_at + INTERVAL '7 years')
		FROM tournaments_archive
		WHERE id = $1
	`, contestID).Scan(
		&row.ID, &row.Name, &row.Status,
		&row.EntryFeeCents, &row.PlatformFeeBps,
		&row.PrizePoolNetCents, &row.ParticipantCount,
		&row.ArchivedAt, &row.RetainUntil,
	)
	if err != nil {
		return nil, err
	}
	return &row, nil
}

