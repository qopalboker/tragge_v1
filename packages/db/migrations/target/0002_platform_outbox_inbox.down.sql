-- Development/test rollback only.
BEGIN;
DROP TABLE IF EXISTS platform.dead_letter;
DROP TABLE IF EXISTS platform.inbox;
DROP TABLE IF EXISTS platform.outbox;
DROP TABLE IF EXISTS platform.schema_migrations;
COMMIT;
