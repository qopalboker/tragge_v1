-- 0103_contest_economics_lock.up.sql
-- Canonical platform_fee_bps authority + immutable economics lock fields.
-- commission_rate remains as a deprecated read-only fallback column.

-- Ensure every contest has an explicit platform_fee_bps (default 20%).
UPDATE contests
SET platform_fee_bps = 2000
WHERE platform_fee_bps IS NULL OR platform_fee_bps = 0;

ALTER TABLE contests
    ALTER COLUMN platform_fee_bps SET DEFAULT 2000;

-- Immutable economics snapshot (set at first real join / lock point).
ALTER TABLE contests
    ADD COLUMN IF NOT EXISTS economics_locked_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS locked_entry_fee_cents BIGINT,
    ADD COLUMN IF NOT EXISTS locked_platform_fee_bps INT,
    ADD COLUMN IF NOT EXISTS late_join_enabled BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN contests.platform_fee_bps IS
    'Canonical platform fee in basis points (2000 = 20%). Sole runtime fee authority.';
COMMENT ON COLUMN contests.commission_rate IS
    'DEPRECATED. Legacy percent fee; ignored when platform_fee_bps > 0. Do not write new values.';
COMMENT ON COLUMN contests.economics_locked_at IS
    'When set, entry fee and platform_fee_bps are immutable for this contest instance.';
COMMENT ON COLUMN contests.locked_entry_fee_cents IS
    'Frozen entry fee used for settlement after economics lock.';
COMMENT ON COLUMN contests.locked_platform_fee_bps IS
    'Frozen platform fee bps used for settlement after economics lock.';
COMMENT ON COLUMN contests.late_join_enabled IS
    'When false, paid contests reject joins after start. Free contests never allow late join.';

-- Unique schedule key for free-contest generator / calendar (idempotent creation).
ALTER TABLE contests
    ADD COLUMN IF NOT EXISTS schedule_idempotency_key TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS uq_contests_schedule_idempotency_key
    ON contests (schedule_idempotency_key)
    WHERE schedule_idempotency_key IS NOT NULL AND schedule_idempotency_key <> '';
