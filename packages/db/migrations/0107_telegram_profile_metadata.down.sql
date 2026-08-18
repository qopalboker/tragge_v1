DROP INDEX IF EXISTS idx_users_telegram_username;

ALTER TABLE users
    DROP COLUMN IF EXISTS telegram_username,
    DROP COLUMN IF EXISTS telegram_first_name,
    DROP COLUMN IF EXISTS telegram_last_name;
