-- Development/test rollback only.
BEGIN;
DROP TABLE IF EXISTS market_data.dead_letter;
DROP TABLE IF EXISTS market_data.inbox;
DROP TABLE IF EXISTS market_data.outbox;
DROP TABLE IF EXISTS market_data.schema_migrations;
COMMIT;
