-- 0102_payout_manual_fields.down.sql

DROP INDEX IF EXISTS idx_payouts_transaction_id;
DROP INDEX IF EXISTS idx_payouts_user_idempotency_key;

ALTER TABLE payouts
    DROP COLUMN IF EXISTS transaction_id,
    DROP COLUMN IF EXISTS idempotency_key;
