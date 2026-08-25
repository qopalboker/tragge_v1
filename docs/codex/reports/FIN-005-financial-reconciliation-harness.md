# FIN-005 — End-to-end financial reconciliation test harness

**Date:** 2026-08-25  
**Branch:** `codex/FIN-005-financial-reconciliation-harness`  
**Status:** Implemented (in-process harness) — **requires financial sign-off before merge**

## Also this turn

- FIN-004 financial sign-off recorded; Power Law production ban enforced in CI.

## What the harness asserts

Stages for each scenario:

1. **join_fee_split** — per-entry `SplitEntryFee` sums match `CalculatePool`
2. **trade_scoring_only** — fills do not change prize-pool liability
3. **preview_equals_settlement_shares** — `CalculateForContest` identical for preview vs settle
4. **prize_sum_equals_pool** — Σ prizes = net pool (`tralent_v1`)
5. **synthetic_ledger_conservation** — user start balances = end balances + platform revenue
6. **cash_identity** — collected = gross + late surcharges; fee + net = gross

## Numeric example (4 × $100, 20% fee)

| | Cents | USD |
|---|---:|---:|
| Gross | 40000 | $400 |
| Platform fee | 8000 | $80 |
| Prize pool | 32000 | $320 |
| 1st / 2nd (`tralent_v1` 80/20) | 25600 / 6400 | $256 / $64 |

## What changed

| File | Change |
|---|---|
| `packages/scoring/economics/fin005_reconciliation_harness_test.go` | Harness + Power Law divergence sanity |
| `scripts/sec-fin005-reconciliation-harness.test.mjs` | CI: harness + apps Power Law ban |
| `.github/workflows/ci.yml` | Job `fin-005-reconciliation-harness` (always-on) |
| `package.json` | `test:fin005` |

## Exact tests

```text
node --test scripts/sec-fin005-reconciliation-harness.test.mjs
# pass 3
```

## Explicitly NOT verified / follow-ups

| ID | Gap |
|---|---|
| `FIN005-COMPOSE-LIFECYCLE` | Real join/trade/finalize/settle against Compose Postgres/Redis services |
| `FIN005-STAGING-SCHEDULE` | Scheduled run against staging-like environment |
| `FIN005-BRANCH-PROTECTION` | Making the job a GitHub required check (CI-003) |

## Sign-off request

Approve FIN-005 in-process harness scope. Phase 1 FIN-* tasks are then complete pending merges; next roadmap phase is **LIFECYCLE-001**.
