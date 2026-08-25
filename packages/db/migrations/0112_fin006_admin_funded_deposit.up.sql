-- 0112_fin006_admin_funded_deposit.up.sql
-- FIN-006: Add admin_funded_deposit ledger type (enum only; backfill is 0113).
-- New enum values cannot be used in the same Postgres transaction as ADD VALUE.

ALTER TYPE ledger_type ADD VALUE IF NOT EXISTS 'admin_funded_deposit';

COMMENT ON TYPE ledger_type IS
  'Wallet ledger entry kinds. deposit = gateway/user deposits; admin_funded_deposit = Admin Panel top-ups (excluded from gateway deposit revenue).';
