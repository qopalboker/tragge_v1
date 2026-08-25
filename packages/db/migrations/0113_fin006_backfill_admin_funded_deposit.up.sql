-- 0113_fin006_backfill_admin_funded_deposit.up.sql
-- FIN-006: One-time classification correction for historical admin top-ups.
-- Amounts, balance_after, timestamps, and audit_logs are unchanged.
-- Authorized exception to §13.1 row immutability for the `type` label only
-- (see docs/codex/decisions/FIN-006-decision-log.md).

UPDATE wallet_ledger
SET type = 'admin_funded_deposit'
WHERE type = 'deposit'
  AND reason_code = 'WALLET_TOPUP'
  AND ref_type = 'admin_action';
