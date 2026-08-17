# PHASE 3 — Production Runtime, Durable Storage, Failure Isolation

**Date:** 2026-08-16  
**Decision:** **PHASE 3 — PASS**  
**Paid production:** still **NO-GO**

Architecture: `docs/architecture/phase-3-production-runtime.md`  
Runbook: `docs/runbook/phase-3-operations.md`

---

## 1. Decision

```text
PHASE 3 — PASS
```

Meaning: production runtime **design + manifests + offline/staging drills** close the prior emptyDir WAL launch blocker and define single-active ownership, gates, backup drill, and ops procedures.

Paid GO remains blocked by **live Kubernetes cluster apply**, **compose multi-service kill loop**, and **provider/legal** items (not engineering ambiguity of the WAL model).

---

## 2. Final Runtime Topology

```text
Internet
  → gateway
      → api-server          (user-bff + admin-bff + payment)  multi-replica OK
      → trading-core-lb
            StatefulSet trading-core  replicas: 1
              trade-bff :8082
              market-ingestor :8084
              trading-engine :8085  + PVC wal-data (RWO)
      → worker              (leaderboard + settlement + scheduler + free-gen)  replicas: 1
  → PostgreSQL / PgBouncer
  → Redis
  → Redpanda
```

### Process boundaries (Task 2)

| Domain | Isolation | Why |
|---|---|---|
| Trading WAL | StatefulSet PVC + single replica | No double-owner; durable reschedule |
| Settlement | Worker process (separate from trading) | Financial retry ≠ engine crash |
| API/BFF | Separate api-server | Request degradation ≠ WAL loss |
| Market data | Merged in trading-core | Launch cost; MD outage → engine not-ready |

**Not** full microservices. Minimal blast-radius reduction only.

---

## 3. WAL Storage

| Item | Value |
|---|---|
| Kind | StatefulSet `trading-core` |
| PVC | `volumeClaimTemplates` → `wal-data` |
| AccessMode | ReadWriteOnce |
| Mount | `/var/lib/tragge/wal` |
| Path | `WAL_PERSIST_PATH=/var/lib/tragge/wal/engine.jsonl` |
| Require | `WAL_REQUIRE_PERSIST=true` |
| Prod size/class | 20Gi / `premium-rwo` (overlay) |
| emptyDir | **Removed** for WAL |
| Init | `wal-volume-check` write probe |
| HPA | **Removed** (forbid multi-owner) |

### Reschedule test (Test B)

**Method:** PVC reattach simulated by process death + reopen **same filesystem path** (storage identity = volume).

```text
node scripts/phase3/wal-pvc-reschedule-sim.mjs
→ PASS  (WAL file survived, pending recovered, commit non-duplicating)
go test … -run TestPhase3_WALPVCRescheduleSimulation
→ PASS including unwritable path + corrupt WAL fail-closed
```

**Not run in this environment:** `kubectl delete pod trading-core-0` on a live cluster (kubectl unavailable). Manifest + path-remount semantics are proven; live CSI attach remains a staging apply step.

### Storage failure

| Case | Result |
|---|---|
| Path not writable | NewWriteAheadLog / Config.Validate fail-closed |
| Corrupt WAL | refuse open |
| PVC unbound | Pod Pending (K8s) — not ready |

---

## 4. Failure Isolation

| Boundary | Failure contained |
|---|---|
| trading-core pod | Scheduler/settlement continue in worker |
| worker pod | Trading WAL continues |
| api-server | Trading continues |
| Redis/DB outage | readiness false; no invent fills |
| Market data | engine not-ready when required |

Graceful shutdown: `ready=false` first, `terminationGracePeriodSeconds` 45/60, preStop drain, WAL Close.

---

## 5. Kafka / Redpanda

| Property | Status |
|---|---|
| Semantics | at-least-once |
| Safety | order_id PK, fill_id deterministic, settlement advisory + prize keys |
| Exactly-once | **not claimed** |
| Outage | no silent unbounded memory economic buffer; resume + idempotent apply |
| Live broker kill test | **not run** (Docker/kubectl absent) — residual staging |

---

## 6. Backup / Restore

| Drill | Result |
|---|---|
| Logical snapshot of 9 critical tables into restore schema + count parity | **PASS** `TestPhase3_BackupRestoreDrill` |
| Host `pg_dump` | **SKIPPED** (client not on PATH) |
| S3 CronJob | present in `infra/k8s/cronjobs/daily-backup.yaml` (not executed live) |

---

## 7. Deployment Verification

| Check | Result |
|---|---|
| Manifest gates | **PASS** `node scripts/phase3/release-gates.mjs` |
| Smoke (offline + regressions) | **PASS** `node scripts/phase3/smoke-test.mjs` |
| Clean cluster deploy | **not run** (no kubectl) |
| Compose kill loop | **PARTIAL** — offline matrix PASS; Docker unavailable |

Commands:

```bash
node scripts/phase3/release-gates.mjs
node scripts/phase3/smoke-test.mjs
node scripts/phase3/wal-pvc-reschedule-sim.mjs
node scripts/phase3/multi-service-failure-sim.mjs
go test ./packages/wallet/ -run TestPhase3_BackupRestoreDrill -count=1
go test ./apps/trading-engine/server/ -count=1
```

---

## 8. Failure-Injection Results

| Scenario | Expected | Observed | Result |
|---|---|---|---|
| WAL path remount (PVC sim) | recover pending, no dup after commit | yes | **PASS** |
| Unwritable WAL | not ready / open fails | yes | **PASS** |
| Corrupt WAL | fail-closed | yes | **PASS** |
| Engine restart mid-contest | continue, no dup fill | Phase 2 E2E | **PASS** |
| Finalization race | no late fills | Phase 2 | **PASS** |
| Settlement concurrent credit | idempotent | Phase 1.1 | **PASS** |
| Compose service kill loop | converge | Docker N/A | **PARTIAL** |
| Live K8s pod delete + CSI | remount PVC | kubectl N/A | **RESIDUAL** |

---

## 9. Remaining Launch Blockers

| Blocker | Class |
|---|---|
| Apply production overlay on real cluster; CSI StorageClass `premium-rwo` validated | **infrastructure** |
| Live `kubectl delete pod trading-core-0` PVC reattach on cloud | **infrastructure** |
| Docker Compose multi-service kill/soak under load | **infrastructure / QA** |
| Redpanda live outage test | **infrastructure / QA** |
| S3 backup CronJob end-to-end in staging | **operational** |
| Payment/market provider credentials + legal | **provider / legal** |
| Admin MFA / security ops sign-off | **operational / security** |
| Merged trading-core MD blast radius acceptance | **engineering residual** (documented) |

None of these re-open Phase 1/2 financial or engine correctness contracts.

---

## 10. Final Decision

```text
PHASE 3 — PASS
```

### Production readiness statement

Phase 3 **PASS** does **not** mean paid production ready.

Before paid GO:

1. Deploy StatefulSet + PVC on real staging cluster  
2. Execute live pod reschedule against CSI  
3. Run compose/cluster multi-service kill soak  
4. Confirm S3 backup cron + restore  
5. Provider/legal/security sign-off  

### Operational readiness checklist

**Infrastructure:** K8s manifests StatefulSet WAL; Postgres; Redis; Redpanda; PVC design; backup scripts  

**Application:** WAL_REQUIRE_PERSIST; config fail-closed; readiness/liveness split  

**Trading:** single-active owner; WAL recovery gates; market-data readiness  

**Financial:** settlement isolation; Phase 1.1 regression green  

**Security:** secrets via Secret/ESO patterns; no secrets in images  

**Ops:** runbook `docs/runbook/phase-3-operations.md`; release gates; smoke  

---

## Authority (unchanged from Phase 1–2)

Settlement + wallet remain sole money authority. Engine owns trading state with durable WAL. Leaderboard prize cents remain preview.
