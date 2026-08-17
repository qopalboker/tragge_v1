BEGIN;
INSERT INTO users (id, email, password_hash, email_verified, terms_accepted_at) VALUES ('22cb18ba-76dd-4812-bdf5-af2dbced34d0', 'p41lite-0-22cb18ba@example.com', 'x', TRUE, NOW()) ON CONFLICT (id) DO NOTHING;
INSERT INTO wallets (user_id, balance_cents, status) VALUES ('22cb18ba-76dd-4812-bdf5-af2dbced34d0', 50000, 'active') ON CONFLICT (user_id) DO UPDATE SET balance_cents = 50000, status='active';
INSERT INTO users (id, email, password_hash, email_verified, terms_accepted_at) VALUES ('eb4dcecf-dcda-440e-bad9-d65cc490eec6', 'p41lite-1-eb4dcecf@example.com', 'x', TRUE, NOW()) ON CONFLICT (id) DO NOTHING;
INSERT INTO wallets (user_id, balance_cents, status) VALUES ('eb4dcecf-dcda-440e-bad9-d65cc490eec6', 50000, 'active') ON CONFLICT (user_id) DO UPDATE SET balance_cents = 50000, status='active';
INSERT INTO users (id, email, password_hash, email_verified, terms_accepted_at) VALUES ('c19d1156-9c3d-4192-abda-57f956a691b0', 'p41lite-2-c19d1156@example.com', 'x', TRUE, NOW()) ON CONFLICT (id) DO NOTHING;
INSERT INTO wallets (user_id, balance_cents, status) VALUES ('c19d1156-9c3d-4192-abda-57f956a691b0', 50000, 'active') ON CONFLICT (user_id) DO UPDATE SET balance_cents = 50000, status='active';

INSERT INTO contests (
  id, name, starts_at, ends_at, status, entry_fee_cents, platform_fee_bps,
  qty_total, commission_rate, is_free, current_participants,
  prize_pool_net_cents, commission_amount,
  economics_locked_at, locked_entry_fee_cents, locked_platform_fee_bps, late_join_enabled
) VALUES (
  'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'phase41lite-durable', NOW() - interval '1 hour', NOW() + interval '1 hour',
  'completed', 10000, 2000,
  10, 20.0, FALSE, 3,
  24000, 6000,
  NOW(), 10000, 2000, TRUE
);
INSERT INTO contest_participants (contest_id, user_id, qty_total, qty_available, total_score) VALUES ('a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', '22cb18ba-76dd-4812-bdf5-af2dbced34d0', 10, 10, 3000);
INSERT INTO wallet_ledger (id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, idempotency_key, description, created_at)
     VALUES ('76f5337a-a70a-497b-8481-2f7d9d1ae333', '22cb18ba-76dd-4812-bdf5-af2dbced34d0', 'contest_entry', -10000, 40000, 'contest', 'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'contest_entry:a89ef75b-14d6-40d2-bdb7-762bba1bd8ef:22cb18ba-76dd-4812-bdf5-af2dbced34d0', 'phase41lite entry a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', NOW());
UPDATE wallets SET balance_cents = balance_cents - 10000 WHERE user_id='22cb18ba-76dd-4812-bdf5-af2dbced34d0';
INSERT INTO contest_participants (contest_id, user_id, qty_total, qty_available, total_score) VALUES ('a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'eb4dcecf-dcda-440e-bad9-d65cc490eec6', 10, 10, 2500);
INSERT INTO wallet_ledger (id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, idempotency_key, description, created_at)
     VALUES ('f02d2923-76f7-4b4e-a6eb-3ab968a86fe1', 'eb4dcecf-dcda-440e-bad9-d65cc490eec6', 'contest_entry', -10000, 40000, 'contest', 'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'contest_entry:a89ef75b-14d6-40d2-bdb7-762bba1bd8ef:eb4dcecf-dcda-440e-bad9-d65cc490eec6', 'phase41lite entry a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', NOW());
UPDATE wallets SET balance_cents = balance_cents - 10000 WHERE user_id='eb4dcecf-dcda-440e-bad9-d65cc490eec6';
INSERT INTO contest_participants (contest_id, user_id, qty_total, qty_available, total_score) VALUES ('a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'c19d1156-9c3d-4192-abda-57f956a691b0', 10, 10, 2000);
INSERT INTO wallet_ledger (id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, idempotency_key, description, created_at)
     VALUES ('4270e84e-43f7-4490-b9b1-cedaccf1a24b', 'c19d1156-9c3d-4192-abda-57f956a691b0', 'contest_entry', -10000, 40000, 'contest', 'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'contest_entry:a89ef75b-14d6-40d2-bdb7-762bba1bd8ef:c19d1156-9c3d-4192-abda-57f956a691b0', 'phase41lite entry a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', NOW());
UPDATE wallets SET balance_cents = balance_cents - 10000 WHERE user_id='c19d1156-9c3d-4192-abda-57f956a691b0';

INSERT INTO contest_settlements (
  id, contest_id, status, started_at, completed_at,
  total_participants, total_winners,
  prize_pool_gross_cents, prize_pool_net_cents,
  total_distributed_cents, platform_fee_cents
) VALUES (
  'e32ea8a1-f3f7-4dc5-a158-ca47600f10c2', 'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'completed', NOW(), NOW(),
  3, 3,
  30000, 24000, 24000, 6000
) ON CONFLICT (contest_id) DO NOTHING;

INSERT INTO prize_distributions (id, settlement_id, contest_id, user_id, rank, final_score, prize_amount_cents, prize_percentage, status, credited_at)
     VALUES ('8e0dae12-82b8-4258-97d2-e0c1842f2c50', 'e32ea8a1-f3f7-4dc5-a158-ca47600f10c2', 'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', '22cb18ba-76dd-4812-bdf5-af2dbced34d0', 1, 3000, 12000, 50.000000, 'credited', NOW());
INSERT INTO wallet_ledger (id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, idempotency_key, description, created_at)
     VALUES ('f544a8da-e9bc-434e-b458-5575596d3b80', '22cb18ba-76dd-4812-bdf5-af2dbced34d0', 'prize_credit', 12000, 52000, 'contest', 'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'finalization:a89ef75b-14d6-40d2-bdb7-762bba1bd8ef:22cb18ba-76dd-4812-bdf5-af2dbced34d0:1', 'phase41lite prize a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', NOW());
UPDATE wallets SET balance_cents = balance_cents + 12000 WHERE user_id='22cb18ba-76dd-4812-bdf5-af2dbced34d0';
INSERT INTO prize_distributions (id, settlement_id, contest_id, user_id, rank, final_score, prize_amount_cents, prize_percentage, status, credited_at)
     VALUES ('d093c5ab-e7c2-4848-baf4-d17db553cc59', 'e32ea8a1-f3f7-4dc5-a158-ca47600f10c2', 'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'eb4dcecf-dcda-440e-bad9-d65cc490eec6', 2, 2500, 7200, 30.000000, 'credited', NOW());
INSERT INTO wallet_ledger (id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, idempotency_key, description, created_at)
     VALUES ('f4650d08-7a10-4351-b661-39a6cb7b95aa', 'eb4dcecf-dcda-440e-bad9-d65cc490eec6', 'prize_credit', 7200, 47200, 'contest', 'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'finalization:a89ef75b-14d6-40d2-bdb7-762bba1bd8ef:eb4dcecf-dcda-440e-bad9-d65cc490eec6:2', 'phase41lite prize a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', NOW());
UPDATE wallets SET balance_cents = balance_cents + 7200 WHERE user_id='eb4dcecf-dcda-440e-bad9-d65cc490eec6';
INSERT INTO prize_distributions (id, settlement_id, contest_id, user_id, rank, final_score, prize_amount_cents, prize_percentage, status, credited_at)
     VALUES ('ad0d5501-b7b3-491f-a566-a2ea8a77d746', 'e32ea8a1-f3f7-4dc5-a158-ca47600f10c2', 'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'c19d1156-9c3d-4192-abda-57f956a691b0', 3, 2000, 4800, 20.000000, 'credited', NOW());
INSERT INTO wallet_ledger (id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, idempotency_key, description, created_at)
     VALUES ('465e2eec-c5b4-4a42-b00e-58b3a3dc7c1a', 'c19d1156-9c3d-4192-abda-57f956a691b0', 'prize_credit', 4800, 44800, 'contest', 'a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', 'finalization:a89ef75b-14d6-40d2-bdb7-762bba1bd8ef:c19d1156-9c3d-4192-abda-57f956a691b0:3', 'phase41lite prize a89ef75b-14d6-40d2-bdb7-762bba1bd8ef', NOW());
UPDATE wallets SET balance_cents = balance_cents + 4800 WHERE user_id='c19d1156-9c3d-4192-abda-57f956a691b0';
COMMIT;