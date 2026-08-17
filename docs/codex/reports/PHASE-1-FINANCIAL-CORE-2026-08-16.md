# PHASE 1 — Contest Financial Core Status Report

**Date:** 2026-08-16  
**Explicit phase decision:** **PHASE 1 — PASS** (closed via Phase 1.1 qualification)

**See also:** [`PHASE-1.1-FINANCIAL-CORE-CLOSURE-2026-08-16.md`](./PHASE-1.1-FINANCIAL-CORE-CLOSURE-2026-08-16.md)

---

## Executive Summary

**PASS** (after Phase 1.1)

Phase 1 delivered the **canonical economics package**, **join policy**, **economics lock**, **settlement-only money movement**, and **scheduler uniqueness**. Phase 1.1 **proved** these on live PostgreSQL (migrate **103**, dual/concurrent prize credits, locked-economics dominance).

Paid production remains **NO-GO** for non–Phase-1 reasons (WAL, topology, ops/legal).

---

## Changes Implemented

| Area | Files | Change |
|---|---|---|
| Canonical economics | `packages/scoring/economics/*` | Single fee resolution, pool split, late-join cutoff/surcharge, payout allocation helpers + tests |
| Migration | `packages/db/migrations/0103_contest_economics_lock.{up,down}.sql` | `economics_locked_*`, `late_join_enabled`, `schedule_idempotency_key`, default `platform_fee_bps=2000` |
| Join policy | `apps/user-bff/server/contest_handlers.go`, `contest_join_policy_test.go` | Paid late join until cutoff; free no late join; drop product `max_participants` enforcement; fee via economics |
| Fee authority | `apps/user-bff/server/contest_prizes.go`, `apps/leaderboard-worker/server/payout.go` | Delegate `ResolveEffectiveFeeBps` to economics |
| Settlement authority | `apps/leaderboard-worker/server/finalize.go` | **Removed** `recordSettlementAndPrizeDistributions` call (no more leaderboard settlement/prize_distribution writes) |
| Dual domain settlement | `packages/domain/statemachine/contest_handlers.go` | `HandleSettlement` is a **no-op** that defers money movement to settlement-service |
| Admin lock | `apps/admin-bff/server/handlers_contest.go` | Reject fee/timing edits when `economics_locked_at` set |
| Domain | `packages/domain/statemachine/statemachine.go` | `AllowsRegistration` = `registration_open` only |
| Scheduler | `apps/free-contest-generator/server/app.go` | `schedule_idempotency_key` + late_join_enabled=false for free contests |
| Docs | `docs/architecture/phase-1-financial-core.md` | Authority model |
| Reconcile tool | `scripts/contest-reconcile.mjs` | Contest financial diagnostic CLI |

---

## Financial Architecture Before/After

### Before

```
Join: commission_rate OR platform_fee_bps (dual)
Leaderboard: calculate payouts + write ranks + write contest_settlements + prize_distributions
Settlement: calculate prizes + CreditPrizeIdempotent
```

### After (target path in code)

```
Join: economics.ResolvePlatformFeeBps(platform_fee_bps, commission_rate deprecated)
      + SplitEntryFee / late surcharge via economics
      + lock economics on first join
Leaderboard: ranks + payout *preview metadata for emails only* — NO settlement rows
Settlement: sole writer of contest_settlements + prize_distributions + wallet credits
```

---

## Database Changes

Migration **0103**:

- Backfill `platform_fee_bps = 2000` where 0/null  
- Columns: `economics_locked_at`, `locked_entry_fee_cents`, `locked_platform_fee_bps`, `late_join_enabled`, `schedule_idempotency_key`  
- Unique index on `schedule_idempotency_key` (partial)

**Not rewritten:** any prior migration.

**Apply:** run migrate up on a live Postgres (not executed in this session — Docker stack was down).

---

## Tests Executed

| Command | Result |
|---|---|
| `go test ./packages/scoring/economics/...` | **PASS** |
| `go test ./packages/domain/statemachine/...` | **PASS** |
| `go test ./apps/leaderboard-worker/server/` | **PASS** |
| `go test ./apps/user-bff/server/` | **PASS** |
| `go build ./apps/{user-bff,admin-bff,free-contest-generator}/...` | **PASS** |
| Full `go test ./...` | **Not run** (scope/time) |
| PostgreSQL fresh migrate + financial E2E | **Not run** (infra down) |
| Dual settlement failure injection | **Not run** |

---

## Failure-Injection Results

| Scenario | Result |
|---|---|
| Failure before settlement commit | **NOT EXECUTED** (blocked) |
| Retry after ledger commit | **Unit coverage exists** in `packages/wallet` `CreditPrizeIdempotent` tests (**PASS** historically) |
| Duplicate settlement job | **NOT EXECUTED** end-to-end |
| Concurrent join | App-level FOR UPDATE + unique participant — **partial** (unit policy tests only) |
| Restart finalization | Existing leaderboard recovery paths unchanged — **not re-qualified** |

---

## Findings Closed / Updated

| ID | Previous | New | Evidence |
|---|---|---|---|
| P0-FIN-01/02 dual fee | OPEN | **PARTIALLY_FIXED** | Canonical resolve in `economics`; join uses it; commission_rate still in schema as fallback |
| P0-FIN-04 dual prize math | PARTIAL | **PARTIALLY_FIXED** | Shared economics + distribution; wrappers remain in leaderboard/user-bff |
| P0-FIN-05 settlement authority | PARTIAL | **PARTIALLY_FIXED** | Leaderboard no longer writes settlement rows; domain `HandleSettlement` no longer credits wallets; settlement-service remains sole credit path |
| P0-FIN-06 economics lock | OPEN | **PARTIALLY_FIXED** | Lock columns + join lock + admin reject; not full “late window close” snapshot |
| P0-CON-01 late join | OPEN | **PARTIALLY_FIXED** | Product formula implemented; needs live integration proof |
| P0-CON-02 max_participants | OPEN | **PARTIALLY_FIXED** | Join path no longer enforces product capacity; column may still exist |
| P0-CON-03 dual scheduler | OPEN | **PARTIALLY_FIXED** | Free generator idempotency key; calendar path still separate |

---

## Remaining Findings

- Full Phase 1 E2E financial lifecycle on Postgres  
- Complete removal of leaderboard payout calculation (move email amounts to settlement events)  
- Settlement must load `locked_*` fields exclusively  
- Calendar scheduler must use same idempotency key scheme  
- P0-ARCH-*, P1-ENG-*, residual security ops gates  
- Migration 0103 not applied in this environment  

---

## Launch Risk

1. **Without migrate 0103**, new join SQL may fall back / fail depending on columns.  
2. **Leaderboard still calculates prize amounts** for notifications — must not be mistaken for money movement (credits are settlement-only).  
3. **No dual-settlement live proof** in this run.  
4. **Late join surcharge** charges total via same ledger path as entry fee — description may not distinguish surcharge until wallet reason codes expanded.

---

## Explicit Phase Decision

**PHASE 1 — BLOCKED**

Reason: acceptance requires proven PostgreSQL E2E + failure injection + clean “no competing financial authority” proof. Code changes substantially reduce dual authority but do not yet satisfy every gate with live evidence.

### Recommended next steps to reach PASS

1. Start Docker Postgres; `migrate up` through 0103.  
2. Integration test: create contest → join 3 users → finalize ranks → settle twice → assert single ledger credits.  
3. Stop leaderboard from computing prize cents for DB fields (`final_prize_cents` written only by settlement).  
4. Wire calendar scheduler to `schedule_idempotency_key`.  
5. Re-run full financial suite; reclassify findings to FIXED with evidence.
