DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM contest_prize_pool_ledger) THEN
        RAISE EXCEPTION 'refusing to remove contest Prize Pool financial history';
    END IF;
END $$;

DROP INDEX IF EXISTS uq_treasury_contest_pool_allocation;
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
);
DROP TRIGGER IF EXISTS contest_prize_pool_entry_owner ON contest_prize_pool_ledger;
DROP FUNCTION IF EXISTS validate_contest_prize_pool_entry();
DROP TRIGGER IF EXISTS contest_prize_pool_account_protected ON contest_prize_pool_accounts;
DROP FUNCTION IF EXISTS protect_contest_prize_pool_account();
DROP TRIGGER IF EXISTS contest_prize_pool_ledger_append_only ON contest_prize_pool_ledger;
DROP FUNCTION IF EXISTS prevent_contest_prize_pool_ledger_mutation();
DROP TRIGGER IF EXISTS modern_contest_prize_pool_on_create ON contests;
DROP FUNCTION IF EXISTS provision_modern_contest_prize_pool();
DROP TABLE IF EXISTS contest_prize_pool_ledger;
DROP TABLE IF EXISTS contest_prize_pool_accounts;
ALTER TABLE contests DROP CONSTRAINT IF EXISTS chk_contest_funds_policy;
ALTER TABLE contests DROP COLUMN IF EXISTS funds_policy_version;
