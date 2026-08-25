# FIN-003 — Single owner for contest finalization

**Date:** 2026-08-25  
**Branch:** codex/FIN-003-single-finalization-owner  
**Status:** Done — **financially signed off 2026-08-25**. Postgres dual-service race remains **not runtime-verified** (FIN003-POSTGRES-DUAL-RACE).

## Trace (before)

| Actor | What it did | Race risk |
|---|---|---|
| Settlement | Advisory lock, prize credits, status completed | Primary financial owner |
| Leaderboard | stateMachine.Complete, single-participant wallet refund, rank projection | Status + refund race with settlement |

## Decision

**Settlement is the sole finalization owner** (human, aligned with PRIZE-005).

## What changed

| File | Change |
|---|---|
| pps/leaderboard-worker/server/finalize.go | Removed Complete, wallet refunds, settlement-record helper; ranks/preview only |
| pps/settlement-service/server/settlement.go | Empty → cancelled; single-participant idempotent refund + cancel |
| packages/wallet/fin003_idempotency_test.go | Concurrent prize-key race → one success |
| CI / 	est:fin003 | Ownership + idempotency lock |

## Exact tests

`	ext
node --test scripts/sec-fin003-finalization-owner.test.mjs
ok 1 - FIN-003 leaderboard finalize must not Complete or refund via wallet
ok 2 - FIN-003 settlement owns advisory lock + single-participant refund
ok 3 - FIN-003 concurrent prize idempotency test passes
# pass 3
`

## NOT verified

- Live Postgres dual-service concurrent settle+finalize against a real DB (host linker OOM for heavy packages).
- Full end-to-end Kafka settling event → both consumers.

## Sign-off

FIN-003 approved (Settlement sole finalization owner). Gap tracked: FIN003-POSTGRES-DUAL-RACE.
