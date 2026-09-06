-- TREASURY-001: forward-only Super Admin Wallet custody foundation.
-- User wallets remain entitlement accounts in wallets/wallet_ledger. This
-- system-owned account records the matching custody asset for new confirmed
-- external deposits after this migration; no historical balance is inferred.

CREATE TABLE treasury_accounts (
    purpose VARCHAR(64) PRIMARY KEY,
    account_kind VARCHAR(32) NOT NULL,
    balance_cents BIGINT NOT NULL DEFAULT 0,
    currency VARCHAR(3) NOT NULL DEFAULT 'USD',
    reconciliation_status VARCHAR(32) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_treasury_singleton_purpose
        CHECK (purpose = 'super_admin_treasury'),
    CONSTRAINT chk_treasury_system_custody_kind
        CHECK (account_kind = 'system_custody'),
    CONSTRAINT chk_treasury_balance_non_negative
        CHECK (balance_cents >= 0),
    CONSTRAINT chk_treasury_forward_only_status
        CHECK (reconciliation_status = 'forward_only_unreconciled')
);

CREATE TABLE treasury_ledger (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    treasury_purpose VARCHAR(64) NOT NULL
        REFERENCES treasury_accounts(purpose) ON DELETE RESTRICT,
    entry_kind VARCHAR(32) NOT NULL,
    amount_cents BIGINT NOT NULL,
    balance_after_cents BIGINT NOT NULL,
    payment_intent_id UUID NOT NULL,
    beneficiary_user_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT uq_treasury_ledger_payment_intent UNIQUE (payment_intent_id),
    CONSTRAINT chk_treasury_external_deposit_kind
        CHECK (entry_kind = 'external_deposit'),
    CONSTRAINT chk_treasury_ledger_amount_positive
        CHECK (amount_cents > 0),
    CONSTRAINT chk_treasury_ledger_balance_non_negative
        CHECK (balance_after_cents >= 0)
);

CREATE INDEX idx_treasury_ledger_beneficiary
    ON treasury_ledger(beneficiary_user_id, created_at DESC);

CREATE FUNCTION prevent_treasury_ledger_mutation()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'treasury_ledger is append-only';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER treasury_ledger_append_only
    BEFORE UPDATE OR DELETE ON treasury_ledger
    FOR EACH ROW EXECUTE FUNCTION prevent_treasury_ledger_mutation();

CREATE FUNCTION prevent_treasury_account_delete()
RETURNS TRIGGER AS $$
BEGIN
    RAISE EXCEPTION 'canonical Super Admin Treasury cannot be deleted';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER treasury_account_not_deletable
    BEFORE DELETE ON treasury_accounts
    FOR EACH ROW EXECUTE FUNCTION prevent_treasury_account_delete();

INSERT INTO treasury_accounts (
    purpose,
    account_kind,
    balance_cents,
    currency,
    reconciliation_status
) VALUES (
    'super_admin_treasury',
    'system_custody',
    0,
    'USD',
    'forward_only_unreconciled'
) ON CONFLICT (purpose) DO NOTHING;

COMMENT ON TABLE treasury_accounts IS
    'System-owned custody asset account. Not a user wallet or user entitlement.';
COMMENT ON COLUMN treasury_accounts.reconciliation_status IS
    'forward_only_unreconciled until controlled external-custody cutover certification';
COMMENT ON TABLE treasury_ledger IS
    'Append-only custody evidence for confirmed external deposits posted atomically with user entitlement.';
