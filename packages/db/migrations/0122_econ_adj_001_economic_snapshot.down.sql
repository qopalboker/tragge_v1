DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM economic_adjustment_events)
       OR EXISTS (SELECT 1 FROM contest_snapshots WHERE economic_participant_count IS NOT NULL) THEN
        RAISE EXCEPTION 'cannot roll back ECON-ADJ-001 after durable economic history exists';
    END IF;
END $$;

DROP TRIGGER IF EXISTS economic_adjustment_events_append_only ON economic_adjustment_events;
DROP FUNCTION IF EXISTS prevent_economic_adjustment_event_mutation();
DROP TABLE IF EXISTS economic_adjustment_events;
ALTER TABLE contest_snapshots DROP CONSTRAINT IF EXISTS chk_economic_cutoff_population,
    DROP COLUMN IF EXISTS winner_capacity_shortfall,
    DROP COLUMN IF EXISTS leaderboard_eligible_count,
    DROP COLUMN IF EXISTS economic_participant_count,
    DROP COLUMN IF EXISTS joined_participant_count;
