-- Telegram profile metadata (verified initData only).
-- Canonical identity remains users.telegram_id (0101).
-- These columns store display/search metadata, not auth secrets.

ALTER TABLE users
    ADD COLUMN IF NOT EXISTS telegram_username VARCHAR(64),
    ADD COLUMN IF NOT EXISTS telegram_first_name VARCHAR(128),
    ADD COLUMN IF NOT EXISTS telegram_last_name VARCHAR(128);

COMMENT ON COLUMN users.telegram_username IS
'Telegram @username from verified Mini App initData. Nullable; not an auth identity.';

COMMENT ON COLUMN users.telegram_first_name IS
'Telegram first_name from verified Mini App initData. Nullable.';

COMMENT ON COLUMN users.telegram_last_name IS
'Telegram last_name from verified Mini App initData. Nullable.';

CREATE INDEX IF NOT EXISTS idx_users_telegram_username
    ON users (telegram_username)
    WHERE telegram_username IS NOT NULL;
