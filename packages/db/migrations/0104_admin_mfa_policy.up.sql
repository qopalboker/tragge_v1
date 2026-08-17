-- Global Admin MFA policy for MVP (default OFF; activatable later).
-- Does not remove per-admin MFA credential tables.

CREATE TABLE IF NOT EXISTS admin_security_settings (
    key TEXT PRIMARY KEY,
    value_bool BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_by UUID NULL
);

INSERT INTO admin_security_settings (key, value_bool)
VALUES ('admin_mfa_enabled', FALSE)
ON CONFLICT (key) DO NOTHING;

COMMENT ON TABLE admin_security_settings IS
  'Authoritative admin-panel security policy flags (MVP: MFA disabled by default).';
