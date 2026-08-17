# PHASE 2 — Trading Reliability (Tasks 1–30)

**Date:** 2026-08-16  
**Decision:** **PHASE 2 — PASS**  
**Paid production:** still **NO-GO**

---

## 1. Decision

```text
PHASE 2 — PASS
```

Paid production remains **NO-GO** (topology, ops, legal/provider, full multi-service soak under kill).

Supporting architecture: `docs/architecture/phase-2-trading-engine-durability.md`  
Earlier WAL closure notes: `docs/codex/reports/PHASE-2-TRADING-ENGINE-DURABILITY-2026-08-16.md`

---

## 2. WAL Architecture

| Concern | Implementation |
|---|---|
| Persistence path | `WAL_PERSIST_PATH` (explicit) |
| Production fail-closed | `WAL_REQUIRE_PERSIST` default true for production/staging; empty path rejected by `Config.Validate()` |
| Durability | Entry `Write` + status marks **fsync** before return when path configured |
| Ordering | serialize → durable WAL → DB commit → memory → MarkCommitted → ack |
| Replay | pending only; DB existence check; apply once or discard; **any check/apply error → NOT READY** |
| Corrupt load | refuse open (`ErrWALReplayFailed`) |
| Readiness | `/readyz` requires `walRecoveryOK` + WAL healthy; trading consumers not started on failure |
| Infra | Compose named volume `trading_core_wal`; k8s emptyDir + env (PVC residual for reschedule) |

### Failure behavior

```text
WAL replay succeeds → may become ready
WAL replay fails    → ready=false, no trading consumers, critical log + metric
```

Never: warn and continue.

---

## 3. Trading Guarantees

| Guarantee | Mechanism |
|---|---|
| Order identity | `orders.order_id` PK; duplicate non-terminal → idempotent ACK |
| Fill identity | deterministic `fill_id = UUID-SHA1(order_id)` for full market fills; fill PK |
| Position invariants | DB constraints qty/price; position lock serializes same-symbol mutations |
| Reservation | reserve under lock; release on txn failure; filled qty ≤ order qty (DB check) |
| Invalid qty/price/TP-SL | rejected before DB write (`order_validation.go`) |
| Finalization boundary | status + `ends_at` exclusive + contest trading gate |
| Recovery gate | `CanAcceptTrading()` / unhealthy WAL rejects orders |

Product close policy (not invented): **force-close open positions at contest end** (domain `HandleContestEnd` + settlement `closeAllPositions`), not pure mark-to-market-only leave-open.

---

## 4. Market Data Guarantees

| Guarantee | Mechanism |
|---|---|
| Timestamp units | normalize seconds→ms; reject absurd units |
| Future / extreme old | reject (`MaxFutureSkew=2s`, `MaxAcceptableTickAge=24h`) |
| Backward time | reject older ts overwriting newer quote |
| Invalid prices | NaN/Inf/negative/crossed book rejected |
| Trading staleness | `MAX_PRICE_AGE_*`; age > max rejects execution |
| Clock anomaly on book | future quotes treated stale |
| Provider failover | ingestor primary→fallback; engine monotonic book prevents stale override |
| Readiness | `REQUIRE_MARKET_DATA_READY` (prod/staging default): `/readyz` + order path require valid feed |

---

## 5. Contest Finalization

```text
contest end / settling
  → stop new trading (status + gate + ends_at)
  → cancel pending orders
  → force-close positions (Redis mark → fill → entry)
  → rankings / leaderboard
  → settlement-service: locked economics + prizes + CreditPrizeIdempotent
  → ledger / wallet
```

### Races (A–E)

| Race | Expected | Evidence |
|---|---|---|
| A cutoff | `!now.Before(endsAt)` rejects | unit + order path |
| B finalization begins | gate false + status settling rejects | unit + E2E |
| C concurrent finalize/orders | no panic; no fills after boundary | `TestPhase2_FinalizationRace_ConcurrentOrders` |
| D worker restart mid finalization | settlement advisory lock + idempotent prizes | Phase 1.1 + settlement service |
| E ticks during finalization | book updates ok; orders still blocked by status | design |

---

## 6. Failure Injection Results

| Scenario | Setup | Failure point | Recovery | Result |
|---|---|---|---|---|
| Crash A | durable WAL | before append | reopen empty pending | **PASS** |
| Crash B | pending WAL no DB | after WAL before DB | discard pending | **PASS** |
| Crash C | pending + DB would exist | after DB before ack | apply once / commit mark | **PASS** |
| Crash D–G | create/update/close intents | mid fill/position/finalization | deterministic pending resolve | **PASS** (unit matrix) |
| Restart mid contest | real PG + engine | process stop after fill | ReplayWAL + continue orders | **PASS** `TestPhase2_E2E_RestartWALRecovery` |
| Finalization boundary | real PG | status→settling | late order no fill | **PASS** E2E |
| Prize double credit | wallet | dual CreditPrizeIdempotent | one ledger | **PASS** Phase 1.1 re-run |

---

## 7. End-to-End Evidence

| Item | Value |
|---|---|
| Tests | `TestPhase2_E2E_TradingToSettlement`, `TestPhase2_E2E_RestartWALRecovery`, `TestPhase2_E2E_FailureInjection_CrashMidIntent`, `TestPhase2_FinalizationRace_ConcurrentOrders` |
| Package | `apps/trading-engine/server` |
| DB | Docker PostgreSQL 16, migration **103** (`economics_locked_at`) |
| Path | **real** `Engine.ProcessTick` + `ProcessOrder` (not mocked fills) |
| Flow | seed contest/lock economics → join → ticks → market order → fill → position → (restart/WAL) → settling boundary → close positions → settlement row + prize idempotent |

### Commands

```bash
go test ./apps/trading-engine/server/ -count=1 -timeout 120s
# ok

go test ./packages/wallet/ -count=1 -run "Phase11|Locked|Idempotent|CreditPrize"
# ok  (Phase 1 regression)

go test ./packages/scoring/economics/ ./packages/domain/statemachine/ ./packages/auth/ \
  ./apps/settlement-service/server/ ./apps/leaderboard-worker/server/ ./apps/user-bff/server/
# ok
```

### Key assertions

- exactly one fill per market order identity  
- restart does not duplicate fill  
- late order after settling creates no fill  
- positions closed at end  
- prize credit idempotent  

---

## 8. Remaining P0/P1

| ID | Class | Note |
|---|---|---|
| P1-ENG-03 residual | **launch blocker (ops)** | k8s base WAL is emptyDir — need PVC for reschedule durability |
| Merged-process topology | **launch blocker (arch)** | trading-core multi-service process blast radius |
| Full Kafka multi-service soak under kill | **launch blocker (QA)** | E2E proves engine+PG path; not full redpanda kill matrix in CI this run |
| Wire float64 market last-mile | **non-launch / later** | validated + decimal scoring; full decimal wire rewrite deferred |
| Provider legal/contracts | **later-phase / legal** | out of Phase 2 code scope |
| MFA / ops runbooks | **launch blocker (ops)** | Phase 0 residual |

---

## 9. Production Readiness

Phase 2 **PASS** does **not** mean production-ready.

Still required before paid GO:

1. PVC-backed WAL + proven restart across node reschedule  
2. Merged topology risk acceptance or split  
3. Full stack contest soak (Kafka consumers + settlement worker + engine under kill)  
4. Operational monitoring/alerts on new metrics  
5. Legal/provider readiness  

---

## 10. Final Decision

```text
PHASE 2 — PASS
```

### Global authority (Task 29 summary)

| Path | Classification |
|---|---|
| Engine order insert + fill + position | **AUTHORITATIVE** (contest trading) |
| WAL write/replay | **AUTHORITATIVE** for recovery intent |
| Price book | **AUTHORITATIVE** for executable marks (after validation) |
| Domain HandleContestEnd force-close | **AUTHORITATIVE** for end-of-contest positions (DB path) |
| Settlement closeAllPositions via Kafka | **AUTHORITATIVE** / **RETRY** coordination with engine |
| Settlement prizes + wallet CreditPrizeIdempotent | **AUTHORITATIVE** money |
| Leaderboard prize cents | **PREVIEW ONLY** (Phase 1) |
| Domain HandleSettlement | **SAFE ADAPTER** no-op money |
| Market ingestor publish | **AUTHORITATIVE** feed ingress; failover **RETRY** |

Hidden duplicate economic money path: **not reintroduced** (Phase 1 invariants re-checked).

---

## Observability minimum (Task 26)

Engine metrics added:

- `wal_replay_success_total` / `wal_replay_failure_total`  
- `ready` gauge  
- `market_ticks_accepted_total` / `market_ticks_rejected_total` + reasons  
- `order_processing_errors_total`, `fill_creation_errors_total`, `position_update_errors_total`, `finalization_failures_total`  
- existing stale-price counters  

---

## Regression matrix (Tasks 27–28)

| Package | Result |
|---|---|
| `apps/trading-engine/server` | **ok** |
| `packages/wallet` (Phase11) | **ok** |
| `packages/scoring/economics` | **ok** |
| `packages/domain/statemachine` | **ok** |
| `packages/auth` | **ok** |
| `apps/settlement-service/server` | **ok** |
| `apps/leaderboard-worker/server` | **ok** |
| `apps/user-bff/server` | **ok** |
| `go test ./...` full monorepo | may skip/fail packages needing external services — **run explicitly per critical package above** |

---

**CTO note:** Crash recovery and WAL durability are proven with **real filesystem persistence** and **real PostgreSQL** trading execution for the in-scope engine path. Full multi-broker kill/soak remains an ops launch gate, not a reason to downgrade Phase 2 to BLOCKED under the demonstrated acceptance criteria.
