# FIN-003 decision log

## 2026-08-25 — Sole finalization owner

**Trace summary:**
- **Settlement** already credits prizes (CreditPrizeIdempotent), holds pg_try_advisory_lock, and is idempotent on settlement.status=completed.
- **Leaderboard** still raced status via stateMachine.Complete, refunded single-participant fees via wallet, and retained dead settlement-record helper risk.

**Question:** Confirm Settlement as sole owner and strip Complete + wallet refunds from leaderboard?

**Answer (human):** **Settlement sole owner** — strip Complete + wallet refunds from leaderboard. Leaderboard keeps rank projection/preview only.

**Implemented:**
- Leaderboard: no Complete, no entry-fee refunds, no settlement/prize_distribution writes.
- Settlement: owns empty-contest cancel, single-participant refund (idempotent), prize credits, completed status.
- Concurrent prize credit modeled via stable idempotency keys (32 goroutines → 1 success).

## Related

Aligns with roadmap PRIZE-005 / ARCH-005 (“Make Settlement the sole finalization owner”).

## 2026-08-25 — Human financial sign-off

**Decision:** FIN-003 **approved**.

**Verification gap (explicit):** The dual-service Postgres race (leaderboard finalize + settlement settle against a real PostgreSQL integration environment) is **not** runtime-verified on this host. Do **not** claim full runtime verification until reproduced in a real Postgres integration environment. Tracked as FIN003-POSTGRES-DUAL-RACE in docs/codex/reports/discovered-issues.md.
