-- DATA-001: document canonical fixed-point policy in owner schemas.
-- No domain business tables. Scales are enforced in packages/money.

BEGIN;

COMMENT ON SCHEMA platform IS
    'Platform modular monolith owned state; money=int64 minor units; fee=bps; price/rate/pnl scale default 8; score scale default 6; no float financial storage';
COMMENT ON SCHEMA engine IS
    'Trading Engine owned state; qty=int64; price/pnl/score fixed-point int64+scale; no float financial storage';
COMMENT ON SCHEMA market_data IS
    'Market Data Service owned state; ticks/candles use fixed-point int64+scale (default 8); no float financial storage';

COMMIT;
