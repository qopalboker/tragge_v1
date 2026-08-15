-- 0101_telegram_auth.up.sql
-- Telegram Mini App identity linkage for SEC-003.
-- Canonical identity is telegram_id; application sessions remain SEC-001 User JWTs.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS telegram_id BIGINT;

-- One Telegram account maps to at most one platform user.
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_telegram_id
    ON users (telegram_id)
    WHERE telegram_id IS NOT NULL;

COMMENT ON COLUMN users.telegram_id IS
'Verified Telegram user id from Mini App initData. Never trust client-supplied telegram_id without server-side signature verification.';
