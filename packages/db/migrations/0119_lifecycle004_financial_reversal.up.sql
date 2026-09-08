-- LIFECYCLE-004: durable participant state and exact, append-only reversals.
ALTER TABLE contest_participants
    ADD COLUMN lifecycle_status VARCHAR(16) NOT NULL DEFAULT 'ACTIVE',
    ADD COLUMN lifecycle_changed_at TIMESTAMPTZ,
    ADD CONSTRAINT chk_participant_lifecycle_status CHECK (
        lifecycle_status IN ('ACTIVE','REMOVED','REFUNDED','DISQUALIFIED','CANCELLED')
    );

CREATE INDEX idx_contest_participants_active
    ON contest_participants(contest_id, user_id) WHERE lifecycle_status = 'ACTIVE';

CREATE FUNCTION validate_participant_lifecycle_transition()
RETURNS TRIGGER AS $$ BEGIN
    IF NEW.lifecycle_status IS DISTINCT FROM OLD.lifecycle_status THEN
        IF OLD.lifecycle_status <> 'ACTIVE' OR NEW.lifecycle_status = 'ACTIVE' THEN
            RAISE EXCEPTION 'participant lifecycle status is terminal';
        END IF;
        IF NEW.lifecycle_changed_at IS NULL THEN
            RAISE EXCEPTION 'participant lifecycle transition requires timestamp';
        END IF;
    ELSIF NEW.lifecycle_changed_at IS DISTINCT FROM OLD.lifecycle_changed_at THEN
        RAISE EXCEPTION 'participant lifecycle timestamp is immutable';
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER participant_lifecycle_transition_valid
    BEFORE UPDATE OF lifecycle_status,lifecycle_changed_at ON contest_participants
    FOR EACH ROW EXECUTE FUNCTION validate_participant_lifecycle_transition();

CREATE TABLE contest_participant_lifecycle_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contest_id UUID NOT NULL REFERENCES contests(id) ON DELETE RESTRICT,
    participant_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    actor_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    event_type VARCHAR(32) NOT NULL CHECK (event_type IN (
        'PARTICIPANT_REMOVED','PARTICIPANT_REFUNDED',
        'CONTEST_CANCELLED','CONTEST_REFUND_COMPLETED'
    )),
    reason TEXT NOT NULL,
    refund_decision BOOLEAN NOT NULL,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (jsonb_typeof(metadata) = 'object'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_participant_lifecycle_event UNIQUE (contest_id, participant_id, event_type)
);

CREATE FUNCTION prevent_participant_lifecycle_event_mutation()
RETURNS TRIGGER AS $$ BEGIN
    RAISE EXCEPTION 'contest participant lifecycle events are append-only';
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER participant_lifecycle_events_append_only
    BEFORE UPDATE OR DELETE ON contest_participant_lifecycle_events
    FOR EACH ROW EXECUTE FUNCTION prevent_participant_lifecycle_event_mutation();

ALTER TABLE wallet_ledger
    ADD COLUMN original_transaction_id UUID REFERENCES wallet_ledger(id) ON DELETE RESTRICT,
    ADD COLUMN lifecycle_event_id UUID REFERENCES contest_participant_lifecycle_events(id) ON DELETE RESTRICT,
    ADD COLUMN reversal_actor_id UUID REFERENCES users(id) ON DELETE RESTRICT;
CREATE UNIQUE INDEX uq_wallet_reversal_original ON wallet_ledger(original_transaction_id)
    WHERE original_transaction_id IS NOT NULL;

ALTER TABLE contest_fee_ledger
    ADD COLUMN lifecycle_event_id UUID REFERENCES contest_participant_lifecycle_events(id) ON DELETE RESTRICT,
    ADD COLUMN reversal_actor_id UUID REFERENCES users(id) ON DELETE RESTRICT;

ALTER TABLE contest_prize_pool_ledger
    DROP CONSTRAINT chk_contest_prize_pool_ledger_amount_cents_check,
    DROP CONSTRAINT contest_prize_pool_ledger_direction_check,
    DROP CONSTRAINT contest_prize_pool_ledger_reason_check,
    DROP CONSTRAINT contest_prize_pool_ledger_reference_type_check,
    ADD COLUMN original_ledger_id UUID REFERENCES contest_prize_pool_ledger(id) ON DELETE RESTRICT,
    ADD COLUMN lifecycle_event_id UUID REFERENCES contest_participant_lifecycle_events(id) ON DELETE RESTRICT,
    ADD COLUMN reversal_actor_id UUID REFERENCES users(id) ON DELETE RESTRICT,
    ADD CONSTRAINT chk_pool_entry_shape CHECK (
        (direction='credit' AND amount_cents > 0 AND reason='contest_admission'
            AND reference_type='contest_admission' AND original_ledger_id IS NULL)
        OR
        (direction='debit' AND amount_cents < 0 AND reason='participant_refund'
            AND reference_type='lifecycle_event' AND original_ledger_id IS NOT NULL
            AND lifecycle_event_id IS NOT NULL AND reversal_actor_id IS NOT NULL)
    ),
    ADD CONSTRAINT uq_pool_reversal_original UNIQUE (original_ledger_id);

CREATE OR REPLACE FUNCTION validate_contest_prize_pool_entry()
RETURNS TRIGGER AS $$
DECLARE owner_contest UUID; original contest_prize_pool_ledger%ROWTYPE;
BEGIN
    SELECT contest_id INTO owner_contest FROM contest_prize_pool_accounts WHERE id=NEW.pool_account_id;
    IF owner_contest IS DISTINCT FROM NEW.contest_id THEN
        RAISE EXCEPTION 'Prize Pool ledger contest/account ownership mismatch';
    END IF;
    IF NEW.original_ledger_id IS NOT NULL THEN
        SELECT * INTO STRICT original FROM contest_prize_pool_ledger WHERE id=NEW.original_ledger_id;
        IF original.direction <> 'credit' OR NEW.amount_cents <> -original.amount_cents
           OR NEW.contest_id <> original.contest_id OR NEW.pool_account_id <> original.pool_account_id
           OR NEW.participant_user_id <> original.participant_user_id THEN
            RAISE EXCEPTION 'Prize Pool reversal must exactly match its original posting';
        END IF;
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;

ALTER TABLE treasury_ledger
    ADD COLUMN original_ledger_id UUID REFERENCES treasury_ledger(id) ON DELETE RESTRICT,
    ADD COLUMN lifecycle_event_id UUID REFERENCES contest_participant_lifecycle_events(id) ON DELETE RESTRICT,
    ADD COLUMN reversal_actor_id UUID REFERENCES users(id) ON DELETE RESTRICT;
ALTER TABLE treasury_ledger DROP CONSTRAINT chk_treasury_entry_shape;
ALTER TABLE treasury_ledger ADD CONSTRAINT chk_treasury_entry_shape CHECK (
    (entry_kind='external_deposit' AND amount_cents>0 AND payment_intent_id IS NOT NULL AND beneficiary_user_id IS NOT NULL
        AND contest_id IS NULL AND participant_user_id IS NULL AND admission_id IS NULL AND fee_kind IS NULL AND original_ledger_id IS NULL)
    OR (entry_kind IN ('contest_fee_allocation','contest_pool_allocation') AND amount_cents<0
        AND payment_intent_id IS NULL AND beneficiary_user_id IS NULL AND contest_id IS NOT NULL
        AND participant_user_id IS NOT NULL AND admission_id IS NOT NULL AND original_ledger_id IS NULL
        AND ((entry_kind='contest_fee_allocation' AND fee_kind IN ('contest_base_fee','contest_late_surcharge'))
          OR (entry_kind='contest_pool_allocation' AND fee_kind IS NULL)))
    OR (entry_kind='treasury_reversal' AND amount_cents>0 AND payment_intent_id IS NULL AND beneficiary_user_id IS NULL
        AND contest_id IS NOT NULL AND participant_user_id IS NOT NULL AND admission_id IS NOT NULL
        AND original_ledger_id IS NOT NULL AND lifecycle_event_id IS NOT NULL AND reversal_actor_id IS NOT NULL)
);
CREATE UNIQUE INDEX uq_treasury_reversal_original ON treasury_ledger(original_ledger_id)
    WHERE original_ledger_id IS NOT NULL;

CREATE FUNCTION validate_treasury_reversal()
RETURNS TRIGGER AS $$ DECLARE original treasury_ledger%ROWTYPE;
BEGIN
    IF NEW.entry_kind <> 'treasury_reversal' THEN RETURN NEW; END IF;
    SELECT * INTO STRICT original FROM treasury_ledger WHERE id=NEW.original_ledger_id;
    IF original.entry_kind NOT IN ('contest_fee_allocation','contest_pool_allocation')
       OR NEW.amount_cents <> -original.amount_cents OR NEW.contest_id <> original.contest_id
       OR NEW.participant_user_id <> original.participant_user_id OR NEW.admission_id <> original.admission_id
       OR NEW.fee_kind IS DISTINCT FROM original.fee_kind THEN
        RAISE EXCEPTION 'Treasury reversal must exactly match its original posting';
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER treasury_reversal_exact_original BEFORE INSERT ON treasury_ledger
    FOR EACH ROW EXECUTE FUNCTION validate_treasury_reversal();

CREATE FUNCTION prevent_active_participant_delete()
RETURNS TRIGGER AS $$ BEGIN
    RAISE EXCEPTION 'contest participants are immutable; transition lifecycle_status instead';
END; $$ LANGUAGE plpgsql;
CREATE TRIGGER contest_participants_no_delete BEFORE DELETE ON contest_participants
    FOR EACH ROW EXECUTE FUNCTION prevent_active_participant_delete();

CREATE OR REPLACE FUNCTION trigger_update_contest_participant_count()
RETURNS TRIGGER AS $$ BEGIN
    IF TG_OP='INSERT' AND NEW.lifecycle_status='ACTIVE' THEN
        UPDATE contests SET current_participants=current_participants+1 WHERE id=NEW.contest_id;
    ELSIF TG_OP='UPDATE' AND OLD.lifecycle_status='ACTIVE' AND NEW.lifecycle_status<>'ACTIVE' THEN
        UPDATE contests SET current_participants=GREATEST(0,current_participants-1) WHERE id=NEW.contest_id;
    END IF;
    RETURN NEW;
END; $$ LANGUAGE plpgsql;
DROP TRIGGER trg_update_participant_count ON contest_participants;
CREATE TRIGGER trg_update_participant_count AFTER INSERT OR UPDATE OF lifecycle_status ON contest_participants
    FOR EACH ROW EXECUTE FUNCTION trigger_update_contest_participant_count();
