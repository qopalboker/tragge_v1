-- Development/test rollback only. Restores ARCH-006 schema comments.
BEGIN;
COMMENT ON SCHEMA platform IS
    'Platform modular monolith owned state; no cross-system SQL';
COMMENT ON SCHEMA engine IS
    'Trading Engine owned state; no cross-system SQL';
COMMENT ON SCHEMA market_data IS
    'Market Data Service owned state; no cross-system SQL';
COMMIT;
