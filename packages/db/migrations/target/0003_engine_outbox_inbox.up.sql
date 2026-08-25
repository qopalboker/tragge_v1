-- ARCH-006: Engine transactional outbox/inbox + migration checksum ledger.
-- Owner: engine. Domain trading tables remain ENG-* tasks.

BEGIN;

CREATE TABLE engine.schema_migrations (
    migration_id TEXT PRIMARY KEY,
    checksum_sha256 TEXT NOT NULL,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    applied_by TEXT NOT NULL,
    duration_ms INTEGER NOT NULL CHECK (duration_ms >= 0)
);

CREATE TABLE engine.outbox (
    event_id UUID PRIMARY KEY,
    correlation_id UUID NOT NULL,
    causation_id UUID,
    schema_name TEXT NOT NULL,
    schema_version INTEGER NOT NULL CHECK (schema_version > 0),
    aggregate_type TEXT NOT NULL,
    aggregate_id TEXT NOT NULL,
    aggregate_version BIGINT NOT NULL CHECK (aggregate_version >= 0),
    ordering_key TEXT NOT NULL,
    occurred_at TIMESTAMPTZ NOT NULL,
    payload JSONB NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'published', 'failed')),
    attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
    next_attempt_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_error TEXT,
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX outbox_pending_relay_idx
    ON engine.outbox (status, next_attempt_at)
    WHERE status = 'pending';

CREATE INDEX outbox_ordering_idx
    ON engine.outbox (ordering_key, aggregate_version);

CREATE TABLE engine.inbox (
    consumer_name TEXT NOT NULL,
    event_id UUID NOT NULL,
    schema_name TEXT NOT NULL,
    schema_version INTEGER NOT NULL CHECK (schema_version > 0),
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (consumer_name, event_id)
);

CREATE TABLE engine.dead_letter (
    dead_letter_id BIGSERIAL PRIMARY KEY,
    event_id UUID NOT NULL,
    consumer_name TEXT NOT NULL DEFAULT '',
    direction TEXT NOT NULL CHECK (direction IN ('outbox', 'inbox')),
    reason TEXT NOT NULL,
    envelope JSONB NOT NULL,
    failed_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX dead_letter_identity_idx
    ON engine.dead_letter (direction, consumer_name, event_id);

COMMENT ON TABLE engine.outbox IS
    'Transactional outbox; write with domain change in one TX';
COMMENT ON TABLE engine.inbox IS
    'Idempotent inbox; unique consumer+event_id prevents duplicate side effects';
COMMENT ON TABLE engine.dead_letter IS
    'Quarantine for incompatible or permanently failed envelopes';
COMMENT ON TABLE engine.schema_migrations IS
    'Per-owner migration checksum ledger; mismatch is a release failure';

COMMIT;
