-- 0113_fin006_backfill_admin_funded_deposit.down.sql
-- Restore historical classification labels only.

UPDATE wallet_ledger
SET type = 'deposit'
WHERE type = 'admin_funded_deposit'
  AND reason_code = 'WALLET_TOPUP'
  AND ref_type = 'admin_action';