-- RANK-001: durable, one-way ranking eligibility. Existing participants remain
-- NOT_STARTED; historical activity is not inferred from mutable score data.
ALTER TABLE contest_participants
    ADD COLUMN has_started_trading BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN ranking_started_at TIMESTAMPTZ,
    ADD CONSTRAINT chk_participant_ranking_state CHECK (
        (has_started_trading = FALSE AND ranking_started_at IS NULL)
        OR (has_started_trading = TRUE AND ranking_started_at IS NOT NULL)
    );

CREATE INDEX idx_contest_participants_ranking_eligible
    ON contest_participants(contest_id, total_score DESC, user_id)
    WHERE lifecycle_status = 'ACTIVE' AND has_started_trading = TRUE;

CREATE FUNCTION validate_participant_ranking_transition()
RETURNS TRIGGER AS $$ BEGIN
    IF OLD.has_started_trading AND NOT NEW.has_started_trading THEN
        RAISE EXCEPTION 'participant ranking activation is permanent';
    END IF;
    IF OLD.ranking_started_at IS NOT NULL
       AND NEW.ranking_started_at IS DISTINCT FROM OLD.ranking_started_at THEN
        RAISE EXCEPTION 'participant ranking activation timestamp is immutable';
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

CREATE TRIGGER participant_ranking_transition_valid
    BEFORE UPDATE OF has_started_trading,ranking_started_at ON contest_participants
    FOR EACH ROW EXECUTE FUNCTION validate_participant_ranking_transition();
