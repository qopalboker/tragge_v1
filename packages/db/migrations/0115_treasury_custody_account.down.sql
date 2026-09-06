-- Refuse rollback after financial postings exist; deleting custody evidence is
-- never a safe automated rollback. An unused forward-only account can be removed.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM treasury_ledger) THEN
        RAISE EXCEPTION 'cannot roll back TREASURY-001 after custody postings exist';
    END IF;
END $$;

DROP TABLE treasury_ledger;
DROP TABLE treasury_accounts;
DROP FUNCTION prevent_treasury_ledger_mutation();
DROP FUNCTION prevent_treasury_account_delete();
