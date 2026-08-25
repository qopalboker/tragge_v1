# FIN-005 decision log

## 2026-08-25 — Harness scope

**Question:** Full join→trade→settle needs Postgres/Compose; none available this session. Scope of first mergeable harness?

**Answer (human):** **In-process Go harness** (economics + tralent_v1 + synthetic ledger conservation) + CI job. Document Compose/Postgres lifecycle and scheduled staging as follow-ups.

## Production Power Law ban (from FIN-004 sign-off)

Power Law must remain only for divergence/regression comparison. FIN-005 CI statically fails if `apps/**` non-test Go calls `CalculatePrizeDistributionPowerLaw` / `GetWinnersCountPowerLaw`.
