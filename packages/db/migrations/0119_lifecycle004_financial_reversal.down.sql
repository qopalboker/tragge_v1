DO $$ BEGIN
    IF EXISTS (SELECT 1 FROM contest_participant_lifecycle_events) OR
       EXISTS (SELECT 1 FROM wallet_ledger WHERE original_transaction_id IS NOT NULL) OR
       EXISTS (SELECT 1 FROM contest_fee_ledger WHERE lifecycle_event_id IS NOT NULL) OR
       EXISTS (SELECT 1 FROM contest_prize_pool_ledger WHERE original_ledger_id IS NOT NULL) OR
       EXISTS (SELECT 1 FROM treasury_ledger WHERE original_ledger_id IS NOT NULL) THEN
        RAISE EXCEPTION 'refusing to remove LIFECYCLE-004 financial history';
    END IF;
END $$;

DROP TRIGGER contest_participants_no_delete ON contest_participants;
DROP FUNCTION prevent_active_participant_delete();
DROP TRIGGER participant_lifecycle_transition_valid ON contest_participants;
DROP FUNCTION validate_participant_lifecycle_transition();
DROP TRIGGER trg_update_participant_count ON contest_participants;
DROP TRIGGER participant_lifecycle_events_append_only ON contest_participant_lifecycle_events;
DROP FUNCTION prevent_participant_lifecycle_event_mutation();
DROP TRIGGER treasury_reversal_exact_original ON treasury_ledger;
DROP FUNCTION validate_treasury_reversal();
DROP INDEX uq_treasury_reversal_original;
ALTER TABLE treasury_ledger DROP CONSTRAINT chk_treasury_entry_shape;
ALTER TABLE treasury_ledger DROP COLUMN reversal_actor_id, DROP COLUMN lifecycle_event_id, DROP COLUMN original_ledger_id;
ALTER TABLE treasury_ledger ADD CONSTRAINT chk_treasury_entry_shape CHECK (
    (entry_kind = 'external_deposit' AND amount_cents > 0 AND payment_intent_id IS NOT NULL AND beneficiary_user_id IS NOT NULL
        AND contest_id IS NULL AND participant_user_id IS NULL AND admission_id IS NULL AND fee_kind IS NULL)
    OR (entry_kind = 'contest_fee_allocation' AND amount_cents < 0 AND payment_intent_id IS NULL AND beneficiary_user_id IS NULL
        AND contest_id IS NOT NULL AND participant_user_id IS NOT NULL AND admission_id IS NOT NULL
        AND fee_kind IN ('contest_base_fee','contest_late_surcharge'))
    OR (entry_kind = 'contest_pool_allocation' AND amount_cents < 0 AND payment_intent_id IS NULL AND beneficiary_user_id IS NULL
        AND contest_id IS NOT NULL AND participant_user_id IS NOT NULL AND admission_id IS NOT NULL AND fee_kind IS NULL)
);
ALTER TABLE contest_prize_pool_ledger DROP CONSTRAINT chk_pool_entry_shape, DROP CONSTRAINT uq_pool_reversal_original,
    DROP COLUMN reversal_actor_id, DROP COLUMN lifecycle_event_id, DROP COLUMN original_ledger_id;
ALTER TABLE contest_prize_pool_ledger ADD CHECK (amount_cents>0), ADD CHECK (direction='credit'),
    ADD CHECK (reason='contest_admission'), ADD CHECK (reference_type='contest_admission');
ALTER TABLE contest_fee_ledger DROP COLUMN reversal_actor_id, DROP COLUMN lifecycle_event_id;
DROP INDEX uq_wallet_reversal_original;
ALTER TABLE wallet_ledger DROP COLUMN reversal_actor_id, DROP COLUMN lifecycle_event_id, DROP COLUMN original_transaction_id;
DROP TABLE contest_participant_lifecycle_events;
DROP INDEX idx_contest_participants_active;
ALTER TABLE contest_participants DROP CONSTRAINT chk_participant_lifecycle_status,
    DROP COLUMN lifecycle_changed_at, DROP COLUMN lifecycle_status;

CREATE OR REPLACE FUNCTION trigger_update_contest_participant_count()
RETURNS TRIGGER AS $$ BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE contests SET current_participants=current_participants+1 WHERE id=NEW.contest_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE contests SET current_participants=GREATEST(0,current_participants-1) WHERE id=OLD.contest_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER trg_update_participant_count AFTER INSERT OR DELETE ON contest_participants
    FOR EACH ROW EXECUTE FUNCTION trigger_update_contest_participant_count();
