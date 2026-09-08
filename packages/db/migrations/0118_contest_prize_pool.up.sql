-- CONTEST-POOL-001: forward-only, per-contest Prize Pool custody.
ALTER TABLE contests
    ADD COLUMN funds_policy_version VARCHAR(32) NOT NULL DEFAULT 'legacy';
ALTER TABLE contests ADD CONSTRAINT chk_contest_funds_policy
    CHECK (funds_policy_version IN ('legacy', 'contest_funds_v1'));

CREATE TABLE contest_prize_pool_accounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contest_id UUID NOT NULL UNIQUE REFERENCES contests(id) ON DELETE RESTRICT,
    balance_cents BIGINT NOT NULL DEFAULT 0 CHECK (balance_cents >= 0),
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    status VARCHAR(16) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'locked')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE contest_prize_pool_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    contest_id UUID NOT NULL REFERENCES contests(id) ON DELETE RESTRICT,
    pool_account_id UUID NOT NULL REFERENCES contest_prize_pool_accounts(id) ON DELETE RESTRICT,
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    direction VARCHAR(8) NOT NULL CHECK (direction = 'credit'),
    reason VARCHAR(40) NOT NULL CHECK (reason = 'contest_admission'),
    reference_type VARCHAR(32) NOT NULL CHECK (reference_type = 'contest_admission'),
    reference_id VARCHAR(160) NOT NULL,
    participant_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    policy_version VARCHAR(32) NOT NULL CHECK (policy_version = 'contest_funds_v1'),
    balance_after_cents BIGINT NOT NULL CHECK (balance_after_cents >= 0),
    idempotency_key VARCHAR(220) NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_contest_pool_admission UNIQUE (contest_id, reference_id),
    CONSTRAINT uq_contest_pool_ledger_owner UNIQUE (id, contest_id, pool_account_id)
);

CREATE INDEX idx_contest_prize_pool_ledger_history
    ON contest_prize_pool_ledger(contest_id, created_at DESC, id DESC);

CREATE FUNCTION provision_modern_contest_prize_pool()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.funds_policy_version = 'contest_funds_v1' THEN
        INSERT INTO contest_prize_pool_accounts(contest_id) VALUES (NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER modern_contest_prize_pool_on_create
    AFTER INSERT ON contests FOR EACH ROW
    EXECUTE FUNCTION provision_modern_contest_prize_pool();

-- Activate modern contests only after their account table and provisioning
-- trigger exist. This ordering is safe even for a non-transactional runner.
ALTER TABLE contests ALTER COLUMN funds_policy_version SET DEFAULT 'contest_funds_v1';

CREATE FUNCTION prevent_contest_prize_pool_ledger_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'contest_prize_pool_ledger is append-only';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contest_prize_pool_ledger_append_only
    BEFORE UPDATE OR DELETE ON contest_prize_pool_ledger
    FOR EACH ROW EXECUTE FUNCTION prevent_contest_prize_pool_ledger_mutation();

CREATE FUNCTION validate_contest_prize_pool_entry()
RETURNS TRIGGER AS $$
DECLARE owner_contest UUID;
BEGIN
    SELECT contest_id INTO owner_contest FROM contest_prize_pool_accounts WHERE id=NEW.pool_account_id;
    IF owner_contest IS DISTINCT FROM NEW.contest_id THEN
        RAISE EXCEPTION 'Prize Pool ledger contest/account ownership mismatch';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contest_prize_pool_entry_owner
    BEFORE INSERT ON contest_prize_pool_ledger
    FOR EACH ROW EXECUTE FUNCTION validate_contest_prize_pool_entry();

CREATE FUNCTION protect_contest_prize_pool_account()
RETURNS TRIGGER AS $$
DECLARE ledger_balance BIGINT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'contest Prize Pool accounts cannot be deleted';
    END IF;
    IF NEW.contest_id <> OLD.contest_id OR NEW.currency <> OLD.currency OR NEW.created_at <> OLD.created_at OR NEW.status <> OLD.status THEN
        RAISE EXCEPTION 'contest Prize Pool account identity is immutable';
    END IF;
    IF NEW.balance_cents <> OLD.balance_cents THEN
        SELECT COALESCE(SUM(amount_cents),0) INTO ledger_balance FROM contest_prize_pool_ledger
        WHERE pool_account_id=OLD.id;
        IF NEW.balance_cents <> ledger_balance THEN
            RAISE EXCEPTION 'direct contest Prize Pool balance update forbidden';
        END IF;
    ELSIF NEW.updated_at <> OLD.updated_at THEN
        RAISE EXCEPTION 'contest Prize Pool account update requires a ledger movement';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contest_prize_pool_account_protected
    BEFORE UPDATE OR DELETE ON contest_prize_pool_accounts
    FOR EACH ROW EXECUTE FUNCTION protect_contest_prize_pool_account();

ALTER TABLE treasury_ledger DROP CONSTRAINT chk_treasury_entry_shape;
ALTER TABLE treasury_ledger ADD CONSTRAINT chk_treasury_entry_shape CHECK (
    (entry_kind = 'external_deposit' AND amount_cents > 0
        AND payment_intent_id IS NOT NULL AND beneficiary_user_id IS NOT NULL
        AND contest_id IS NULL AND participant_user_id IS NULL
        AND admission_id IS NULL AND fee_kind IS NULL)
    OR
    (entry_kind = 'contest_fee_allocation' AND amount_cents < 0
        AND payment_intent_id IS NULL AND beneficiary_user_id IS NULL
        AND contest_id IS NOT NULL AND participant_user_id IS NOT NULL
        AND admission_id IS NOT NULL
        AND fee_kind IN ('contest_base_fee', 'contest_late_surcharge'))
    OR
    (entry_kind = 'contest_pool_allocation' AND amount_cents < 0
        AND payment_intent_id IS NULL AND beneficiary_user_id IS NULL
        AND contest_id IS NOT NULL AND participant_user_id IS NOT NULL
        AND admission_id IS NOT NULL AND fee_kind IS NULL)
);
CREATE UNIQUE INDEX uq_treasury_contest_pool_allocation
    ON treasury_ledger(admission_id) WHERE entry_kind='contest_pool_allocation';

COMMENT ON COLUMN contests.funds_policy_version IS
    'Explicit forward-only Prize Pool custody boundary; absence of ledger rows never implies legacy.';
COMMENT ON TABLE contest_prize_pool_accounts IS
    'One durable custodial Prize Pool account for each contest_funds_v1 contest.';
COMMENT ON TABLE contest_prize_pool_ledger IS
    'Append-only admission Prize Pool custody movements; snapshots and contest counters are not authority.';
