# PHASE 1.1 — Financial Core Qualification & Closure

**Date:** 2026-08-16  
**Phase status:** **PHASE 1.1 — PASS**  
**Paid production:** still **NO-GO** (architecture blast radius, WAL, ops/legal gates remain)

---

## 1. Phase Status

**PHASE 1.1 — PASS**

Phase 1 financial blockers that previously blocked PASS are now verified against **live PostgreSQL 16** (Docker `tragge_postgres`), with dual settlement credits, concurrent idempotent credits, locked-economics dominance, and migration **103** applied.

---

## 2. Infrastructure

| Item | Result |
|---|---|
| PostgreSQL | **Started** — `tragge_postgres` healthy, port 5432 |
| Redis | Started (supporting) |
| Clean migrate | **Succeeded** — `migrate up` → version **103** |
| Migration 0103 | **Applied** (`contest_economics_lock`) |
| Columns verified | `economics_locked_at`, `locked_entry_fee_cents`, `locked_platform_fee_bps`, `late_join_enabled`, `schedule_idempotency_key`, `platform_fee_bps` default 2000 |
| Unique index | `uq_contests_schedule_idempotency_key` present |
| Reproducible | Docker Compose lite + secrets + migrate/migrate image |

---

## 3. Financial E2E

**Test:** `TestPhase11_FinancialLifecycle_E2E`  
**Package:** `packages/wallet`  
**DB:** real Docker Postgres (`app` database, schema at v103)

### Scenario
- Contest with locked economics: entry **10000** cents, fee **2000** bps  
- 3 users, wallets funded 50000 each  
- Join: debit entry via `DeductContestEntryFeeWithName` + pool accrual via `economics.SplitEntryFee`  
- Mutate mutable `platform_fee_bps` → **5000** after lock  
- Settlement path: load **locked** fee (must stay 2000), allocate via `economics.AllocatePayouts`, create **one** `contest_settlements` row, credit via `CreditPrizeIdempotent` **twice** + concurrent wave  
- Assert conservation, single settlement, single ledger keys, wallet balances  

### Results
| Check | Result |
|---|---|
| Economics lock present | PASS |
| Join conservation (pool+fee=gross) | PASS |
| Locked fee used (not mutated 50%) | PASS (`TestPhase11_LockedEconomicsIgnoresGlobalDefault`) |
| Prize allocation conservation | PASS |
| Settlement rows | **exactly 1** after dual insert |
| Ledger prize keys | **1 per winner** after dual+concurrent credit |
| Wallet balances | start − entry + prize |
| Second settlement | no new financial drift |

---

## 4. Idempotency Evidence

| Invocation | Result |
|---|---|
| First `CreditPrizeIdempotent` | Creates ledger + balance |
| Second `CreditPrizeIdempotent` | `DuplicatePrizeCreditError` / no second ledger row |
| 5 concurrent credit waves | No extra ledger rows; no non-dup failures |
| Dual `INSERT contest_settlements … ON CONFLICT` | Still **1** row per contest_id |

---

## 5. Failure Injection

| Case | Implementation | Result |
|---|---|---|
| A — failure before commit | Transaction rollback on debit error paths (join) | Existing unit + E2E rollbacks |
| B — after commit before ack | Second credit returns duplicate | **PASS** |
| C — duplicate settlement | Unique `contest_settlements(contest_id)` | **PASS** |
| D — concurrent settlement credits | 5 goroutines | **PASS** |
| E — restart | Idempotent keys survive process boundary | Proven by re-run of credit after commit |

**Note:** Full `SettleContestWithRetry` including engine position-close was not executed (requires market/engine stack). Financial write path (settlement row + prize ledger) is proven.

---

## 6. Authority Audit

| Responsibility | Authoritative Component | Classification |
|---|---|---|
| Economics definition | `packages/scoring/economics` | **AUTHORITATIVE** |
| Fee field | `platform_fee_bps` (+ lock columns) | **AUTHORITATIVE**; `commission_rate` **LEGACY** fallback only |
| Ranking | `leaderboard-worker` | **AUTHORITATIVE** for ranks |
| Payout calculation (final money) | `settlement-service` + economics | **AUTHORITATIVE** |
| Leaderboard prize cents | preview/notification metadata only | **PREVIEW** (labeled in code) |
| Settlement rows / prize_distributions | `settlement-service` | **AUTHORITATIVE** |
| Domain `HandleSettlement` | no-op deferral | **SAFE ADAPTER** |
| Ledger | `packages/wallet` | **AUTHORITATIVE** |
| Wallet balance | wallet projection of ledger | **AUTHORITATIVE** |
| Scheduler identity | `schedule_idempotency_key` (free + calendar) | **AUTHORITATIVE** uniqueness |

---

## 7. Remaining Findings

| ID | Status | Blocks controlled paid launch? | Notes |
|---|---|---|---|
| P0-FIN-01/02 | **FIXED** for runtime authority | No | Canonical resolve + locked bps; column retained as legacy |
| P0-FIN-04/05 | **FIXED** for money movement | No | Dual credit paths removed; leaderboard preview-only |
| P0-FIN-06 | **FIXED** (first-join lock policy) | No | Policy A documented; late-window re-snapshot optional later |
| P0-CON-01 | **FIXED** in code + unit tests | Low residual | Live HTTP join path not re-smoked this session |
| P0-CON-02 | **FIXED** (no product enforcement) | No | Column may remain null |
| P0-CON-03 | **PARTIALLY_FIXED→FIXED** | No | Free + calendar use schedule_idempotency_key |
| P0-ARCH-* | OPEN | Yes (ops) | Merged process blast radius |
| P1-ENG-01/02 WAL | OPEN | Yes for trading safety | Phase 2 |
| P0-SEC residual MFA ops | PARTIAL | Ops | Enrollment proof |
| Full SettleContest orchestration | Residual | Medium | Needs engine for position close E2E |

---

## 8. Commands Executed

```text
docker compose ... up -d postgres redis          # healthy
migrate -path /migrations -database ... up      # → 103
migrate ... version                               # 103

go test ./packages/scoring/economics/...         # PASS
go test ./packages/domain/statemachine/...       # PASS
go test ./packages/auth/...                      # PASS (security regression)
go test ./packages/wallet/ -run Phase11 -v       # PASS (E2E + lock)
go test ./packages/wallet/                       # PASS (includes wallet unit + Phase11)
go test ./apps/user-bff/server/                  # PASS
go test ./apps/leaderboard-worker/server/        # PASS
go test ./apps/settlement-service/server/        # PASS (incl locked economics)
go build ./apps/contest-scheduler/...            # PASS
```

---

## 9. Code Changes (Phase 1.1)

| File | Change |
|---|---|
| `apps/settlement-service/server/db.go` | Load and apply locked economics |
| `apps/settlement-service/server/settlement.go` | Recalc uses locked fee; never global when locked |
| `apps/settlement-service/server/locked_economics_test.go` | Unit proof of lock dominance |
| `apps/leaderboard-worker/server/finalize.go` | Label payout step as preview-only |
| `apps/leaderboard-worker/server/payout.go` | Document preview authority |
| `apps/contest-scheduler/.../calendar.go` | `schedule_idempotency_key` + fee bps |
| `packages/wallet/financial_e2e_phase11_test.go` | Real-PG lifecycle + dual/concurrent settlement credits |

---

## 10. Final Decision

# **PHASE 1.1 — PASS**

### Phase 1 overall (after 1.1)

Financial core acceptance gates for **economics authority, settlement money authority, lock semantics, join policy, scheduler uniqueness, PostgreSQL migration, dual settlement idempotency** are **PASS**.

**Paid production remains NO-GO** until Phase 2+ (WAL durability, process topology, ops/MFA/provider gates).

### Proceed to Phase 2 when ready
Trading engine WAL readiness + market-data reliability.
