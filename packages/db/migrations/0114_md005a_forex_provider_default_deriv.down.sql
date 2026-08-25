-- 0114_md005a_forex_provider_default_deriv.down.sql
-- Restore pre-MD-005A forex seed (massive). Crypto rows are left unchanged.

UPDATE provider_config
SET active_provider = 'massive',
    updated_at = NOW()
WHERE asset_class = 'forex'
  AND active_provider = 'deriv';
