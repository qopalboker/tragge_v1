-- 0114_md005a_forex_provider_default_deriv.up.sql
-- MD-005A: Align provider_config forex default with product §9.2 (Forex=Deriv, Crypto=Nobitex).

UPDATE provider_config
SET active_provider = 'deriv',
    fallback_provider = COALESCE(NULLIF(fallback_provider, ''), 'twelvedata'),
    updated_at = NOW()
WHERE asset_class = 'forex'
  AND active_provider IS DISTINCT FROM 'deriv';

-- Ensure crypto default remains nobitex for empty/mis-set rows (idempotent).
UPDATE provider_config
SET active_provider = 'nobitex',
    updated_at = NOW()
WHERE asset_class = 'crypto'
  AND (active_provider IS NULL OR active_provider = '' OR active_provider = 'deriv');
