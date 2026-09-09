-- ECON-ADJ-001: separate immutable economic, joined, and ranking populations.
-- Existing snapshots are deliberately left NULL; historical facts are never inferred.
ALTER TABLE contest_snapshots
    ADD COLUMN joined_participant_count INT CHECK (joined_participant_count >= 0),
    ADD COLUMN economic_participant_count INT CHECK (economic_participant_count >= 0),
    ADD COLUMN leaderboard_eligible_count INT CHECK (leaderboard_eligible_count >= 0),
    ADD COLUMN winner_capacity_shortfall BOOLEAN;

ALTER TABLE contest_snapshots ADD CONSTRAINT chk_economic_cutoff_population
    CHECK (snapshot_type <> 'economics_cutoff' OR (
        joined_participant_count IS NOT NULL
        AND economic_participant_count IS NOT NULL
        AND leaderboard_eligible_count IS NOT NULL
        AND winner_capacity_shortfall IS NOT NULL
        AND economic_participant_count <= joined_participant_count
        AND leaderboard_eligible_count <= joined_participant_count
        AND winner_capacity_shortfall = (leaderboard_eligible_count < planned_winner_count)
    )) NOT VALID;

CREATE TABLE economic_adjustment_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contest_id UUID NOT NULL REFERENCES contests(id) ON DELETE RESTRICT,
    participant_id UUID REFERENCES users(id) ON DELETE RESTRICT,
    event_type VARCHAR(48) NOT NULL CHECK (event_type IN (
        'ECONOMIC_SNAPSHOT_CREATED',
        'PARTICIPANT_REMOVED_BEFORE_CUTOFF',
        'PARTICIPANT_REFUNDED',
        'PARTICIPANT_DISQUALIFIED'
    )),
    previous_state VARCHAR(16),
    new_state VARCHAR(16),
    reason TEXT NOT NULL,
    actor_id UUID REFERENCES users(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_economic_event_shape CHECK (
        (event_type = 'ECONOMIC_SNAPSHOT_CREATED'
            AND participant_id IS NULL AND actor_id IS NULL
            AND previous_state IS NULL AND new_state = 'SNAPSHOT')
        OR
        (event_type <> 'ECONOMIC_SNAPSHOT_CREATED'
            AND participant_id IS NOT NULL AND actor_id IS NOT NULL
            AND previous_state IS NOT NULL AND new_state IS NOT NULL)
    )
);

CREATE UNIQUE INDEX uq_economic_snapshot_created_event
    ON economic_adjustment_events(contest_id, event_type)
    WHERE event_type = 'ECONOMIC_SNAPSHOT_CREATED';
CREATE INDEX idx_economic_adjustment_events_history
    ON economic_adjustment_events(contest_id, created_at, id);

CREATE FUNCTION prevent_economic_adjustment_event_mutation()
RETURNS TRIGGER AS $$ BEGIN
    RAISE EXCEPTION 'economic adjustment events are append-only';
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER economic_adjustment_events_append_only
    BEFORE UPDATE OR DELETE ON economic_adjustment_events
    FOR EACH ROW EXECUTE FUNCTION prevent_economic_adjustment_event_mutation();

COMMENT ON TABLE economic_adjustment_events IS
    'Append-only economic classification history; never an authority for money movement.';
COMMENT ON COLUMN contest_snapshots.economic_participant_count IS
    'Admissions with unreversed committed entry funds at economics cutoff; independent of ranking.';
