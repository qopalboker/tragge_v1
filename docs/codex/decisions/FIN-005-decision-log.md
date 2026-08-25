# FIN-005 decision log

## 2026-08-25 — Harness scope

**Question:** Full join→trade→settle needs Postgres/Compose; none available this session. Scope of first mergeable harness?

**Answer (human):** **In-process Go harness** (economics + tralent_v1 + synthetic ledger conservation) + CI job. Document Compose/Postgres lifecycle and scheduled staging as follow-ups.

## Production Power Law ban (from FIN-004 sign-off)

Power Law must remain only for divergence/regression comparison. FIN-005 CI statically fails if `apps/**` non-test Go calls `CalculatePrizeDistributionPowerLaw` / `GetWinnersCountPowerLaw`.

## 2026-08-25 — Human financial sign-off

**Decision:** FIN-005 **approved**. Phase 1 financial work approved. Verification gaps (`FIN003-POSTGRES-DUAL-RACE`, `FIN005-COMPOSE-LIFECYCLE`, `FIN005-STAGING-SCHEDULE`, `FIN005-BRANCH-PROTECTION`) remain **explicitly not runtime-verified** until reproduced.
