-- FEE-WALLET-001: dedicated, system-owned contest fee revenue account.
-- Extend the canonical Treasury journal narrowly so each fee credit has a
-- matching custody debit; Prize Pool allocation remains a later task.
ALTER TABLE treasury_ledger
    ALTER COLUMN payment_intent_id DROP NOT NULL,
    ALTER COLUMN beneficiary_user_id DROP NOT NULL,
    ADD COLUMN contest_id UUID REFERENCES contests(id) ON DELETE RESTRICT,
    ADD COLUMN participant_user_id UUID REFERENCES users(id) ON DELETE RESTRICT,
    ADD COLUMN admission_id VARCHAR(160),
    ADD COLUMN fee_kind VARCHAR(40);

ALTER TABLE treasury_ledger DROP CONSTRAINT chk_treasury_external_deposit_kind;
ALTER TABLE treasury_ledger DROP CONSTRAINT chk_treasury_ledger_amount_positive;
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
);
CREATE UNIQUE INDEX uq_treasury_contest_fee_allocation
    ON treasury_ledger(admission_id, fee_kind)
    WHERE entry_kind = 'contest_fee_allocation';

CREATE TABLE contest_fee_accounts (
    purpose VARCHAR(64) PRIMARY KEY,
    account_kind VARCHAR(32) NOT NULL,
    balance_cents BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_contest_fee_singleton_purpose
        CHECK (purpose = 'contest_fee_wallet'),
    CONSTRAINT chk_contest_fee_system_kind
        CHECK (account_kind = 'system_fee_revenue'),
    CONSTRAINT chk_contest_fee_balance_non_negative
        CHECK (balance_cents >= 0)
);

CREATE TABLE contest_fee_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fee_wallet_purpose VARCHAR(64) NOT NULL
        REFERENCES contest_fee_accounts(purpose) ON DELETE RESTRICT,
    entry_kind VARCHAR(40) NOT NULL,
    amount_cents BIGINT NOT NULL,
    balance_after_cents BIGINT NOT NULL,
    contest_id UUID NOT NULL REFERENCES contests(id) ON DELETE RESTRICT,
    participant_user_id UUID NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    admission_id VARCHAR(160) NOT NULL,
    policy_version VARCHAR(32) NOT NULL,
    platform_fee_bps INT NOT NULL,
    original_entry_id UUID REFERENCES contest_fee_ledger(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_contest_fee_entry_kind CHECK (entry_kind IN (
        'contest_base_fee',
        'contest_late_surcharge',
        'contest_fee_refund_reversal'
    )),
    CONSTRAINT chk_contest_fee_entry_sign CHECK (
        (entry_kind IN ('contest_base_fee', 'contest_late_surcharge') AND amount_cents > 0 AND original_entry_id IS NULL)
        OR
        (entry_kind = 'contest_fee_refund_reversal' AND amount_cents < 0 AND original_entry_id IS NOT NULL)
    ),
    CONSTRAINT chk_contest_fee_balance_after_non_negative CHECK (balance_after_cents >= 0),
    CONSTRAINT chk_contest_fee_policy_version CHECK (policy_version = '2026-09-06.1'),
    CONSTRAINT chk_contest_fee_bps CHECK (platform_fee_bps BETWEEN 1 AND 10000),
    CONSTRAINT uq_contest_fee_reversal_original UNIQUE (original_entry_id)
);

CREATE UNIQUE INDEX uq_contest_fee_inflow_admission_kind
    ON contest_fee_ledger(admission_id, entry_kind)
    WHERE entry_kind IN ('contest_base_fee', 'contest_late_surcharge');

CREATE INDEX idx_contest_fee_ledger_created
    ON contest_fee_ledger(created_at DESC, id DESC);
CREATE INDEX idx_contest_fee_ledger_contest
    ON contest_fee_ledger(contest_id, participant_user_id, created_at DESC);

CREATE FUNCTION prevent_contest_fee_ledger_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'contest_fee_ledger is append-only';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contest_fee_ledger_append_only
    BEFORE UPDATE OR DELETE ON contest_fee_ledger
    FOR EACH ROW EXECUTE FUNCTION prevent_contest_fee_ledger_mutation();

CREATE FUNCTION validate_contest_fee_reversal()
RETURNS TRIGGER AS $$
DECLARE
    original contest_fee_ledger%ROWTYPE;
BEGIN
    IF NEW.entry_kind <> 'contest_fee_refund_reversal' THEN
        RETURN NEW;
    END IF;
    SELECT * INTO STRICT original FROM contest_fee_ledger WHERE id = NEW.original_entry_id;
    IF original.entry_kind NOT IN ('contest_base_fee', 'contest_late_surcharge')
       OR NEW.amount_cents <> -original.amount_cents
       OR NEW.contest_id <> original.contest_id
       OR NEW.participant_user_id <> original.participant_user_id
       OR NEW.admission_id <> original.admission_id
       OR NEW.policy_version <> original.policy_version
       OR NEW.platform_fee_bps <> original.platform_fee_bps THEN
        RAISE EXCEPTION 'contest fee reversal must exactly match its original posting';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contest_fee_reversal_exact_original
    BEFORE INSERT ON contest_fee_ledger
    FOR EACH ROW EXECUTE FUNCTION validate_contest_fee_reversal();

CREATE FUNCTION prevent_contest_fee_account_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'canonical Contest Fee Wallet cannot be deleted';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER contest_fee_account_not_deletable
    BEFORE DELETE ON contest_fee_accounts
    FOR EACH ROW EXECUTE FUNCTION prevent_contest_fee_account_delete();

INSERT INTO contest_fee_accounts (purpose, account_kind, balance_cents, currency)
VALUES ('contest_fee_wallet', 'system_fee_revenue', 0, 'USD')
ON CONFLICT (purpose) DO NOTHING;

COMMENT ON TABLE contest_fee_accounts IS
    'System-owned contest fee revenue account; never a user wallet or prize pool.';
COMMENT ON TABLE contest_fee_ledger IS
    'Append-only canonical base-fee, late-surcharge, and explicit reversal evidence.';
