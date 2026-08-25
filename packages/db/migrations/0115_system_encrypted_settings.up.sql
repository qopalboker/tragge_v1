-- 0115_system_encrypted_settings.up.sql
-- Encrypted system secrets (e.g. telegram_bot_token) managed via Admin System Settings.
-- Ciphertext only; never store plaintext tokens.

CREATE TABLE IF NOT EXISTS system_encrypted_settings (
    key TEXT PRIMARY KEY,
    ciphertext TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID REFERENCES users(id) ON DELETE SET NULL,
    CONSTRAINT chk_system_encrypted_settings_cipher
      CHECK (ciphertext LIKE 'enc:system:v1:%')
);

COMMENT ON TABLE system_encrypted_settings IS
  'Admin-managed encrypted system secrets. Values are AES-GCM ciphertext only; never returned in API/logs.';
