-- Migration: 0108_deriv_provider
-- Description: Add provider_symbol_deriv and seed Deriv v3 mappings.
-- Deriv format: forex/metals frxAAABBB (EUR/USD→frxEURUSD, XAU/USD→frxXAUUSD),
-- crypto cryXXXUSD (BTC/USD→cryBTCUSD). Used when MARKET_PROVIDER=deriv.

ALTER TABLE symbols ADD COLUMN IF NOT EXISTS provider_symbol_deriv VARCHAR(50);

COMMENT ON COLUMN symbols.provider_symbol_deriv IS
  'Symbol mapping for Deriv v3 WS (frxEURUSD, cryBTCUSD, frxXAUUSD)';

-- Explicit seeds for common forex majors / metals / crypto
UPDATE symbols SET provider_symbol_deriv = 'frxEURUSD' WHERE symbol = 'EUR/USD';
UPDATE symbols SET provider_symbol_deriv = 'frxGBPUSD' WHERE symbol = 'GBP/USD';
UPDATE symbols SET provider_symbol_deriv = 'frxUSDJPY' WHERE symbol = 'USD/JPY';
UPDATE symbols SET provider_symbol_deriv = 'frxUSDCHF' WHERE symbol = 'USD/CHF';
UPDATE symbols SET provider_symbol_deriv = 'frxAUDUSD' WHERE symbol = 'AUD/USD';
UPDATE symbols SET provider_symbol_deriv = 'frxUSDCAD' WHERE symbol = 'USD/CAD';
UPDATE symbols SET provider_symbol_deriv = 'frxNZDUSD' WHERE symbol = 'NZD/USD';
UPDATE symbols SET provider_symbol_deriv = 'frxEURGBP' WHERE symbol = 'EUR/GBP';
UPDATE symbols SET provider_symbol_deriv = 'frxEURJPY' WHERE symbol = 'EUR/JPY';
UPDATE symbols SET provider_symbol_deriv = 'frxGBPJPY' WHERE symbol = 'GBP/JPY';
UPDATE symbols SET provider_symbol_deriv = 'frxXAUUSD' WHERE symbol = 'XAU/USD';
UPDATE symbols SET provider_symbol_deriv = 'frxXAGUSD' WHERE symbol = 'XAG/USD';

UPDATE symbols SET provider_symbol_deriv = 'cryBTCUSD'  WHERE symbol = 'BTC/USD';
UPDATE symbols SET provider_symbol_deriv = 'cryETHUSD'  WHERE symbol = 'ETH/USD';
UPDATE symbols SET provider_symbol_deriv = 'crySOLUSD'  WHERE symbol = 'SOL/USD';
UPDATE symbols SET provider_symbol_deriv = 'cryDOGEUSD' WHERE symbol = 'DOGE/USD';
UPDATE symbols SET provider_symbol_deriv = 'cryXRPUSD'  WHERE symbol = 'XRP/USD';
UPDATE symbols SET provider_symbol_deriv = 'cryADAUSD'  WHERE symbol = 'ADA/USD';
UPDATE symbols SET provider_symbol_deriv = 'cryLTCUSD'  WHERE symbol = 'LTC/USD';

-- Heuristic backfill for remaining 3-letter forex/metal pairs
UPDATE symbols
SET provider_symbol_deriv = 'frx' || replace(symbol, '/', '')
WHERE provider_symbol_deriv IS NULL
  AND asset_type IN ('forex', 'commodity')
  AND symbol ~ '^[A-Z]{3}/[A-Z]{3}$';

-- Heuristic backfill for remaining crypto pairs (quote normalized to USD)
UPDATE symbols
SET provider_symbol_deriv = 'cry' || split_part(symbol, '/', 1) || 'USD'
WHERE provider_symbol_deriv IS NULL
  AND asset_type = 'crypto'
  AND symbol LIKE '%/%';

CREATE INDEX IF NOT EXISTS idx_symbols_deriv
    ON symbols (provider_symbol_deriv)
    WHERE provider_symbol_deriv IS NOT NULL;
