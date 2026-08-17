-- 0103_contest_economics_lock.down.sql

DROP INDEX IF EXISTS uq_contests_schedule_idempotency_key;
ALTER TABLE contests DROP COLUMN IF EXISTS schedule_idempotency_key;

DROP INDEX IF EXISTS uq_prize_distributions_contest_user;

ALTER TABLE contests
    DROP COLUMN IF EXISTS late_join_enabled,
    DROP COLUMN IF EXISTS locked_platform_fee_bps,
    DROP COLUMN IF EXISTS locked_entry_fee_cents,
    DROP COLUMN IF EXISTS economics_locked_at;
