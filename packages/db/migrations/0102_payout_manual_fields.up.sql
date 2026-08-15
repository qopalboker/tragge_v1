-- 0102_payout_manual_fields.up.sql
-- Manual withdrawal MVP: idempotency key + payout transaction reference.

ALTER TABLE payouts
    ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR(255),
    ADD COLUMN IF NOT EXISTS transaction_id VARCHAR(255);

-- One client idempotency key per user (prevents double-submit of the same request).
CREATE UNIQUE INDEX IF NOT EXISTS idx_payouts_user_idempotency_key
    ON payouts (user_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL AND idempotency_key <> '';

CREATE INDEX IF NOT EXISTS idx_payouts_transaction_id
    ON payouts (transaction_id)
    WHERE transaction_id IS NOT NULL;

COMMENT ON COLUMN payouts.idempotency_key IS 'Client/server idempotency key for withdrawal create';
COMMENT ON COLUMN payouts.transaction_id IS 'Admin-recorded manual payout reference / crypto tx hash';
