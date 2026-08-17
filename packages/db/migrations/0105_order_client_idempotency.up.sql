-- Durable logical order submission identity for client idempotency.
-- client_order_id is the single logical identity for one user intent.
-- order_id equals client_order_id for client-supplied submissions (BFF policy).
-- Concurrent/retry claims of the same client_order_id must not create a second order.

CREATE TABLE IF NOT EXISTS order_client_submissions (
    client_order_id UUID PRIMARY KEY,
    user_id         UUID NOT NULL,
    contest_id      UUID NOT NULL,
    order_id        UUID NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_order_client_submissions_ids
        CHECK (order_id = client_order_id)
);

CREATE INDEX IF NOT EXISTS idx_order_client_submissions_user_contest
    ON order_client_submissions (user_id, contest_id, created_at DESC);

COMMENT ON TABLE order_client_submissions IS
  'Idempotency registry: one client_order_id → one order_id (equals client_order_id). '
  'Protects against double-click, network retry, and concurrent duplicate submits.';
