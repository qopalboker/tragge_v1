-- LIFECYCLE-003: audit-safe archival (policy: 7-year retention).
-- Soft-delete contests via archived_at; copy related rows to archive tables.
-- Do NOT hard-delete contests (CASCADE would destroy audit/trading history).

-- Hot-path soft-delete marker on contests
ALTER TABLE contests
  ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_contests_archived_at_null
  ON contests (starts_at DESC)
  WHERE archived_at IS NULL;

COMMENT ON COLUMN contests.archived_at IS
  'LIFECYCLE-003: when set, contest is off the hot path; row retained for FK/audit. Cold copy also in tournaments_archive.';

-- Retention metadata on primary archive table
ALTER TABLE tournaments_archive
  ADD COLUMN IF NOT EXISTS retain_until TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS prize_pool_net_cents BIGINT,
  ADD COLUMN IF NOT EXISTS is_free BOOLEAN,
  ADD COLUMN IF NOT EXISTS economics_locked_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS locked_entry_fee_cents BIGINT,
  ADD COLUMN IF NOT EXISTS locked_platform_fee_bps INT;

UPDATE tournaments_archive
SET retain_until = archived_at + INTERVAL '7 years'
WHERE retain_until IS NULL AND archived_at IS NOT NULL;

COMMENT ON COLUMN tournaments_archive.retain_until IS
  'LIFECYCLE-003: archive must remain queryable until this timestamp (default archived_at + 7 years).';

-- Participants archive (audit)
CREATE TABLE IF NOT EXISTS contest_participants_archive (
  contest_id UUID NOT NULL,
  user_id UUID NOT NULL,
  joined_at TIMESTAMPTZ NOT NULL,
  qty_total BIGINT NOT NULL,
  qty_available BIGINT NOT NULL,
  total_score NUMERIC(20, 4) NOT NULL DEFAULT 0,
  final_rank INT,
  final_prize_cents INT,
  archived_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (contest_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_contest_participants_archive_archived_at
  ON contest_participants_archive (archived_at);

-- Symbols archive
CREATE TABLE IF NOT EXISTS contest_symbols_archive (
  contest_id UUID NOT NULL,
  symbol VARCHAR(20) NOT NULL,
  provider_symbol_twelvedata VARCHAR(50),
  provider_symbol_finnhub VARCHAR(50),
  enabled BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ,
  archived_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (contest_id, symbol)
);

-- Status history archive
CREATE TABLE IF NOT EXISTS contest_status_history_archive (
  id UUID PRIMARY KEY,
  contest_id UUID NOT NULL,
  from_status TEXT,
  to_status TEXT NOT NULL,
  changed_by UUID,
  reason TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL,
  archived_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_contest_status_history_archive_contest
  ON contest_status_history_archive (contest_id);
