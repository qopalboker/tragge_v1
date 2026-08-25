-- Development/test rollback only.
BEGIN;
DROP TABLE IF EXISTS engine.dead_letter;
DROP TABLE IF EXISTS engine.inbox;
DROP TABLE IF EXISTS engine.outbox;
DROP TABLE IF EXISTS engine.schema_migrations;
COMMIT;
