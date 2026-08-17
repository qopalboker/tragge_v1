# PHASE 2 — Trading Engine Durability, Market Data Reliability, Position Finalization

**Date:** 2026-08-16  
**Phase status:** **PHASE 2 — PASS (with residual launch gates)**  
**Paid production:** still **NO-GO**

---

## 1. Phase Status

**PHASE 2 — PASS** for the in-scope trading-path safety work:

- durable WAL configuration (fail-closed in prod/staging);
- durable Write + fsync before DB mutate;
- fail-closed WAL load/replay;
- readiness gated on recovery;
- order/fill identity + price/TP-SL validation;
- stale/anomaly market-data rejection;
- crash recovery unit matrix A–G;
- deterministic WAL replay.

**Paid production remains NO-GO** because residual gates outside or only partially covered by Phase 2 still apply:

- full live contest E2E (market + engine + settlement with real positions);
- PVC-backed WAL across pod reschedule (k8s base uses `emptyDir`; production overlay should use PVC);
- topology/ops/legal readiness from Phase 0;
- merged-process readiness probe wiring validated in a live cluster.

---

## 2. Forensic map (Task 1) — verified against code

```text
startup
  → Config.Validate()
  → NewWriteAheadLog(load file fail-closed, open fail-closed)
  → InitWAL (StateOperator)
  → ReplayWAL (fail-closed on DB/apply error)
  → pending book reload (failure clears recovery OK)
  → if recovery OK: consumers + ready=true
  → else: NOT READY, no trading consumers
```

| Finding | Prior | Now |
|---|---|---|
| P1-ENG-01 empty WAL path | OPEN | **CLOSED** for prod/staging (`WAL_REQUIRE_PERSIST`) |
| P1-ENG-02 continue after replay fail | OPEN | **CLOSED** (not ready + no consumers) |
| P1-ENG-03 WAL volume | OPEN | **PARTIAL** — compose volume + k8s emptyDir; PVC residual |
| P1-ENG-04 float64 prices | OPEN | **PARTIAL** — validation + decimal scoring path; wire still float64 |
| P1-ENG-05 crash tests | OPEN | **CLOSED** at unit/recovery matrix level |

---

## 3. Durability contract (Tasks 2–3)

Documented in `docs/architecture/phase-2-trading-engine-durability.md`.

Ordering for `ExecuteWithWAL`:

1. serialize  
2. **WAL Write + fsync**  
3. DB commit  
4. memory mutate  
5. MarkCommitted (+ fsync)  
6. ack  

Config:

| Env | Role |
|---|---|
| `WAL_PERSIST_PATH` | durable path |
| `WAL_REQUIRE_PERSIST` | default true in production/staging |
| `WAL_SYNC_ON_WRITE` | default true |

---

## 4. Fail-closed replay & readiness (Tasks 4–5)

- Corrupt WAL line → `NewWriteAheadLog` error (no silent skip).
- Replay DB/apply error → `ErrWALReplayFailed`, WAL unhealthy, engine not ready.
- `/healthz` = liveness only.
- `/readyz` requires `ready && walRecoveryOK && CanAcceptTrading() && DB/Redis/circuits`.
- Trading consumers start only after recovery OK.
- `ProcessOrder` rejects when `!CanAcceptTrading()`.

---

## 5. Tests run (Tasks 6–7, 12–14, 16)

```text
go test ./apps/trading-engine/server/ -count=1
→ ok
```

Includes:

| Suite | Coverage |
|---|---|
| `TestWAL_*` / crash A–G | durable append, recovery, fail-closed replay |
| `TestWAL_DeterministicReplay` | same sequence → same pending business state |
| `TestConfig_WALRequirePersistFailClosed` | prod empty path rejected |
| `TestValidateOrderRequest_*` | qty/price bounds |
| `TestValidateTPSL_*` | long/short TP/SL rules |
| `TestPriceBook_StaleThresholdAndAnomaly` | fresh / threshold / stale / future clock |
| `TestDecimalScoring_RoundingBoundary` | weighted entry + decimal score path |
| `TestDeterministicFillID_*` | stable fill identity |

**Not executed in this phase run:** full multi-service contest E2E with Kafka + live settlement + forced process kill under load (requires full stack; residual).

---

## 6. Idempotency / positions / reservations (Tasks 8–11)

| Concern | Implementation |
|---|---|
| Order identity | `order_id` PK; duplicate non-terminal → idempotent ACK |
| Fill identity | deterministic `fill_id = UUID-SHA1(order_id)` for market fills |
| Fill uniqueness | `fill_id` PK; DB constraints on qty/price > 0 |
| Position lock | existing position lock around reserve+fill+position |
| Qty reservation | reserve under lock; release on txn failure |
| Concurrent same symbol | position lock serializes |

---

## 7. Market data (Tasks 15–16)

| Item | Behavior |
|---|---|
| Fresh | age ≤ max (strict `>` for stale) |
| Stale | reject market order / skip pending trigger |
| Anomaly (future ts) | fail closed |
| Thresholds | per crypto/forex open/close config |

---

## 8. Infra wiring

- `infra/docker/docker-compose.yml`: `trading_core_wal` volume + `WAL_*` env.
- `infra/k8s/base/trading-core.yaml`: `WAL_PERSIST_PATH`, emptyDir mount, readiness on **trading-engine** `/readyz`.
- `.env.example`: WAL documentation.

**Residual P1-ENG-03:** replace emptyDir with PVC in production overlay for multi-node reschedule durability.

---

## 9. Authority / residual risk

| Risk | Severity | Status |
|---|---|---|
| Engine crash loses in-memory-only WAL | High | Mitigated when path set + require persist |
| Silent trade after bad replay | High | Mitigated fail-closed |
| emptyDir lost on reschedule | Medium | Residual ops |
| Full finalization E2E under kill | Medium | Residual QA |
| Wire float64 market prices | Medium | Validated bounds; not full decimal wire rewrite |

---

## 10. Verdict

| Gate | Result |
|---|---|
| Phase 2 in-scope trading safety | **PASS** |
| Paid production GO | **NO-GO** |

### Command evidence

```bash
cd apps/../  # monorepo root
go test ./apps/trading-engine/server/ -count=1
# ok  github.com/Parsaeffatravesh/tragge/apps/trading-engine/server
```
