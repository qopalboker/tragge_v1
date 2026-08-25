-- Reverse LIFECYCLE-003 archival tables / soft-delete marker.
DROP TABLE IF EXISTS contest_status_history_archive;
DROP TABLE IF EXISTS contest_symbols_archive;
DROP TABLE IF EXISTS contest_participants_archive;

ALTER TABLE tournaments_archive
  DROP COLUMN IF EXISTS retain_until,
  DROP COLUMN IF EXISTS prize_pool_net_cents,
  DROP COLUMN IF EXISTS is_free,
  DROP COLUMN IF EXISTS economics_locked_at,
  DROP COLUMN IF EXISTS locked_entry_fee_cents,
  DROP COLUMN IF EXISTS locked_platform_fee_bps;

DROP INDEX IF EXISTS idx_contests_archived_at_null;
ALTER TABLE contests DROP COLUMN IF EXISTS archived_at;
