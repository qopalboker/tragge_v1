# FIN-002 — Consolidate prize calculation

**Date:** 2026-08-25  
**Branch:** `codex/FIN-002-prize-calculation-path`  
**Status:** Implemented — **requires financial sign-off before merge** (money-path)

## Decision

Sole path: **`packages/scoring/economics` + `prizedistribution`** (human, 2026-08-25).

## What changed

| File | Change |
|---|---|
| `packages/scoring/economics/economics.go` | `NetFromGross`; `CalculatePool` uses it |
| `packages/scoring/economics/fin002_golden_test.go` | Preview/leaderboard/settlement agreement golden |
| `packages/scoring/prize/distribution.go` | `CalculatePrizePoolFromBps`; pool math → economics |
| `packages/scoring/prize/commission.go` | `FractionToPlatformFeeBps` |
| `apps/leaderboard-worker/server/payout.go` | `CalculatePrizePoolNet` → `economics.NetFromGross` |
| `apps/settlement-service/server/settlement.go` | recalculation → `economics.CalculatePool` |
| CI / `test:fin002` | Always-on lock |

## Numeric example (10 × 100 USDT, 2000 bps)

| | Gross | Fee | Net |
|---|---|---|---|
| economics / leaderboard / settlement | 100000 | 20000 | 80000 |

Distribution shares for the same net + winner count are identical (power-law via `prizedistribution`).

## Exact tests

```text
go test ./packages/scoring/economics/ ./packages/scoring/prize/
ok

node --test scripts/sec-fin002-prize-path-check.test.mjs
# pass 4 / fail 0
```

## NOT verified

- Full `go test ./apps/settlement-service/server` on this host (linker OOM). Locked-fee unit test exists; golden suite covers shared math.
- Live end-to-end settlement against Postgres.

## Sign-off request

Please approve merge of FIN-002 (prize math consolidation). After approval, next task is **FIN-003** (single finalization owner).
