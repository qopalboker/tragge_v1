DROP TRIGGER IF EXISTS participant_ranking_transition_valid ON contest_participants;
DROP FUNCTION IF EXISTS validate_participant_ranking_transition();
DROP INDEX IF EXISTS idx_contest_participants_ranking_eligible;
ALTER TABLE contest_participants
    DROP CONSTRAINT IF EXISTS chk_participant_ranking_state,
    DROP COLUMN IF EXISTS ranking_started_at,
    DROP COLUMN IF EXISTS has_started_trading;
