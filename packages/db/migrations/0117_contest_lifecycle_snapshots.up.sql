-- CONTEST-SNAPSHOT-001: immutable lifecycle facts for modern contests.
CREATE TYPE contest_snapshot_type AS ENUM (
    'contest_confirmed', 'economics_cutoff', 'contest_started', 'contest_finished'
);

ALTER TABLE contests
    ADD COLUMN lifecycle_policy_version VARCHAR(32) NOT NULL DEFAULT 'legacy',
    ADD COLUMN confirmed_at TIMESTAMPTZ;
ALTER TABLE contests ALTER COLUMN lifecycle_policy_version SET DEFAULT 'contest_snapshot_v1';
ALTER TABLE contests ADD CONSTRAINT chk_contest_lifecycle_policy
    CHECK (lifecycle_policy_version IN ('legacy', 'contest_snapshot_v1'));

ALTER TABLE contest_settlements
    ADD CONSTRAINT uq_contest_settlements_id_contest UNIQUE (id, contest_id);

CREATE TABLE contest_snapshots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contest_id UUID NOT NULL REFERENCES contests(id) ON DELETE RESTRICT,
    snapshot_type contest_snapshot_type NOT NULL,
    snapshot_version VARCHAR(40) NOT NULL,
    event_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    policy_version VARCHAR(32) NOT NULL DEFAULT '2026-09-06.1',
    minimum_participants INT,
    participant_count INT NOT NULL CHECK (participant_count >= 0),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    entry_fee_cents BIGINT NOT NULL CHECK (entry_fee_cents >= 0),
    platform_fee_bps INT NOT NULL CHECK (platform_fee_bps BETWEEN 0 AND 10000),
    late_join_enabled BOOLEAN NOT NULL,
    gross_base_entry_cents BIGINT CHECK (gross_base_entry_cents >= 0),
    platform_fee_cents BIGINT CHECK (platform_fee_cents >= 0),
    late_surcharge_cents BIGINT CHECK (late_surcharge_cents >= 0),
    prize_pool_cents BIGINT CHECK (prize_pool_cents >= 0),
    planned_winner_count INT CHECK (planned_winner_count >= 0),
    settlement_id UUID,
    details JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(details) = 'object'),
    CONSTRAINT uq_contest_snapshot_stage UNIQUE (contest_id, snapshot_type),
    CONSTRAINT chk_contest_snapshot_version CHECK (snapshot_version = snapshot_type::text || '_v1'),
    CONSTRAINT chk_contest_snapshot_dates CHECK (ends_at > starts_at),
    CONSTRAINT chk_contest_snapshot_stage_fields CHECK (
      (snapshot_type = 'contest_confirmed' AND minimum_participants IS NOT NULL)
      OR (snapshot_type = 'economics_cutoff' AND gross_base_entry_cents IS NOT NULL
          AND platform_fee_cents IS NOT NULL AND late_surcharge_cents IS NOT NULL
          AND prize_pool_cents IS NOT NULL AND planned_winner_count IS NOT NULL)
      OR snapshot_type IN ('contest_started', 'contest_finished')
    ),
    CONSTRAINT chk_finished_snapshot_settlement CHECK (
      snapshot_type <> 'contest_finished' OR settlement_id IS NOT NULL
    ),
    CONSTRAINT fk_contest_snapshot_settlement_owner
      FOREIGN KEY (settlement_id, contest_id)
      REFERENCES contest_settlements(id, contest_id) ON DELETE RESTRICT
);

CREATE INDEX idx_contest_snapshots_history
    ON contest_snapshots (contest_id, event_at, created_at, id);

CREATE FUNCTION prevent_contest_snapshot_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'contest lifecycle snapshots are immutable';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contest_snapshots_immutable
    BEFORE UPDATE OR DELETE ON contest_snapshots
    FOR EACH ROW EXECUTE FUNCTION prevent_contest_snapshot_mutation();

CREATE FUNCTION prevent_contest_confirmation_rewrite()
RETURNS TRIGGER AS $$
BEGIN
    IF OLD.confirmed_at IS NOT NULL AND NEW.confirmed_at IS DISTINCT FROM OLD.confirmed_at THEN
        RAISE EXCEPTION 'contest confirmation is a one-way historical fact';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contest_confirmation_one_way
    BEFORE UPDATE OF confirmed_at ON contests
    FOR EACH ROW EXECUTE FUNCTION prevent_contest_confirmation_rewrite();

COMMENT ON TABLE contest_snapshots IS
    'Immutable contest-state history. Financial ledgers remain authoritative for money.';
COMMENT ON COLUMN contests.lifecycle_policy_version IS
    'Explicit legacy/modern boundary; missing snapshots never imply legacy.';
