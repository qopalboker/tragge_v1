DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM contest_snapshots) THEN
        RAISE EXCEPTION 'refusing to remove immutable contest lifecycle history';
    END IF;
END $$;

DROP TRIGGER IF EXISTS contest_snapshots_immutable ON contest_snapshots;
DROP FUNCTION IF EXISTS prevent_contest_snapshot_mutation();
DROP TABLE IF EXISTS contest_snapshots;
ALTER TABLE contest_settlements
    DROP CONSTRAINT IF EXISTS uq_contest_settlements_id_contest;
DROP TRIGGER IF EXISTS contest_confirmation_one_way ON contests;
DROP FUNCTION IF EXISTS prevent_contest_confirmation_rewrite();
ALTER TABLE contests DROP CONSTRAINT IF EXISTS chk_contest_lifecycle_policy;
ALTER TABLE contests DROP COLUMN IF EXISTS confirmed_at;
ALTER TABLE contests DROP COLUMN IF EXISTS lifecycle_policy_version;
DROP TYPE IF EXISTS contest_snapshot_type;
