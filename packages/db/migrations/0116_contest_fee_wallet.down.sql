DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM contest_fee_ledger) THEN
        RAISE EXCEPTION 'cannot roll back FEE-WALLET-001 after fee postings exist';
    END IF;
END $$;

DROP TABLE contest_fee_ledger;
DROP TABLE contest_fee_accounts;
DROP FUNCTION prevent_contest_fee_ledger_mutation();
DROP FUNCTION prevent_contest_fee_account_delete();
DROP FUNCTION validate_contest_fee_reversal();

DROP INDEX uq_treasury_contest_fee_allocation;
ALTER TABLE treasury_ledger DROP CONSTRAINT chk_treasury_entry_shape;
ALTER TABLE treasury_ledger
    DROP COLUMN contest_id,
    DROP COLUMN participant_user_id,
    DROP COLUMN admission_id,
    DROP COLUMN fee_kind,
    ALTER COLUMN payment_intent_id SET NOT NULL,
    ALTER COLUMN beneficiary_user_id SET NOT NULL;
ALTER TABLE treasury_ledger ADD CONSTRAINT chk_treasury_external_deposit_kind
    CHECK (entry_kind = 'external_deposit');
ALTER TABLE treasury_ledger ADD CONSTRAINT chk_treasury_ledger_amount_positive
    CHECK (amount_cents > 0);
