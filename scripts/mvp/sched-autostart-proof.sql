-- Controlled scheduler auto-start proof (local/dev only).
-- Creates 2 real users + one short paid contest starting ~2 minutes from now.
-- Quorum = 2 real users. auto_start = true. No Admin Start.

BEGIN;

CREATE TEMP TABLE _proof ON COMMIT DROP AS
SELECT
  gen_random_uuid() AS contest_id,
  gen_random_uuid() AS user_a,
  gen_random_uuid() AS user_b,
  (date_trunc('second', NOW() AT TIME ZONE 'UTC') + interval '120 seconds') AS starts_at,
  (date_trunc('second', NOW() AT TIME ZONE 'UTC') + interval '120 seconds' + interval '5 minutes') AS ends_at;

INSERT INTO users (id, email, password_hash, status, email_verified, username)
SELECT user_a,
       'sched-proof-a-' || substr(contest_id::text, 1, 8) || '@tragge.local',
       crypt('ProofPass1!', gen_salt('bf')),
       'active'::user_status,
       true,
       'sched_proof_a'
FROM _proof
UNION ALL
SELECT user_b,
       'sched-proof-b-' || substr(contest_id::text, 1, 8) || '@tragge.local',
       crypt('ProofPass1!', gen_salt('bf')),
       'active'::user_status,
       true,
       'sched_proof_b'
FROM _proof;

UPDATE wallets w
SET balance_cents = 100000
FROM _proof p
WHERE w.user_id IN (p.user_a, p.user_b);

INSERT INTO contests (
  id, name, status, starts_at, ends_at,
  entry_fee_cents, qty_total, is_free, min_participants,
  auto_start, auto_generated, registration_deadline,
  asset_class, duration_type, duration_minutes,
  schedule_idempotency_key
)
SELECT
  contest_id,
  'SCHED-PROOF-PAID-' || substr(contest_id::text, 1, 8),
  'registration_open',
  starts_at,
  ends_at,
  100,
  100000,
  false,
  2,
  true,
  true,
  starts_at,
  'crypto',
  'rush_30min',
  5,
  'sched-proof:' || contest_id::text
FROM _proof;

INSERT INTO contest_symbols (contest_id, symbol)
SELECT contest_id, 'BTC/USD' FROM _proof
UNION ALL
SELECT contest_id, 'ETH/USD' FROM _proof;

-- Seed T-bot is NOT used for paid quorum.
INSERT INTO contest_participants (contest_id, user_id, is_system, joined_at, qty_total, qty_available)
SELECT contest_id, user_a, false, NOW(), 100000, 100000 FROM _proof
UNION ALL
SELECT contest_id, user_b, false, NOW(), 100000, 100000 FROM _proof;

SELECT
  contest_id,
  starts_at AT TIME ZONE 'UTC' AS starts_utc,
  ends_at AT TIME ZONE 'UTC' AS ends_utc,
  user_a,
  user_b
FROM _proof;

COMMIT;
