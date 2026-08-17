# PHASE 6-NK — Production Architecture Without Kubernetes

**Date:** 2026-08-16  
**Decision:** **PRODUCTION — NO-GO**  
**Architecture:** **VM + Docker Compose** (Kubernetes **not** required)  
**First production contest:** **NOT EXECUTED**  
**Local baseline:** Phase 4.1-Lite **PASS** — `LOCAL STAGING — FULLY QUALIFIED`

---

## Executive Decision

```text
PRODUCTION — NO-GO
```

Phase 6-NK **delivered** the authoritative non-Kubernetes production path and qualified what this operator environment can prove.  
It did **not** achieve production GO: hard gates (VM replacement, object-storage backup E2E, providers, MFA, pause, monitoring, first contest) remain **BLOCKED**.

Launch gate (platform-neutral):

```text
node scripts/prod/launch-gate.mjs
→ PRODUCTION — NO-GO (11 blocked gates)
kubernetes_required=false
```

---

## Architectural decision

| Former requirement | Phase 6-NK |
|---|---|
| Kubernetes cluster | **Removed** from production critical path |
| StatefulSet / PVC / CSI | **Replaced** by host/block WAL bind mount |
| kubectl / Helm | **Not required** |
| Canonical deploy | `infra/docker/docker-compose.production.yml` + `scripts/prod/*` |

Historical `infra/k8s/` retained as **optional / non-canonical** (README updated).

Business logic (economics, wallet, ledger, trading, settlement) was **not** rewritten.

---

## Production topology (target + delivered)

```text
Internet → DNS/TLS/LB → gateway → api-server
                              ├─ trading-core (single active)
                              └─ worker (single active)
                                    │
                    PostgreSQL · Redis · Redpanda
Trading WAL: dedicated host/block path → /var/lib/tragge/wal
             WAL_REQUIRE_PERSIST=true
```

### VM baseline

| Role | Workloads |
|---|---|
| App VM | gateway, api-server, trading-core, worker, frontends |
| Managed/dedicated | PostgreSQL, Redis, Redpanda/Kafka, object storage |

Docs:

- `docs/architecture/production-without-kubernetes.md`  
- `docs/runbook/production-without-kubernetes.md`

---

## Deliverables (Tasks 1–2, 8–12, 18, 25–26)

| Artifact | Purpose |
|---|---|
| `infra/docker/docker-compose.production.yml` | Production overlay: fail-closed WAL bind, no dep host ports, prod env |
| `infra/docker/production.env.example` | Non-secret production env template |
| `scripts/prod/preflight.mjs` | Host/docker/secrets/WAL/compose validation |
| `scripts/prod/deploy.mjs` | Deploy + health fail-closed |
| `scripts/prod/health-gate.mjs` | Core health + `wal_recovery` |
| `scripts/prod/launch-gate.mjs` | K8s-free launch gate with equivalent safety |
| `scripts/prod/rollback.mjs` | App rollback; migrations forward-fix only |
| `scripts/prod/wal-persist-drill.mjs` | Container recreate WAL survival |
| `scripts/prod/emergency-pause-check.mjs` | Pause capability inventory + live evidence hook |
| `infra/k8s/README.md` | Marks K8s non-canonical |

---

## What was proven this session

| Check | Result |
|---|---|
| Production compose `config` valid | **PASS** |
| `scripts/prod/preflight.mjs` | **PASS** (`preflight_critical_ok=true`) |
| `scripts/prod/health-gate.mjs` | **PRODUCTION HEALTH — PASS** |
| WAL host persist drill (container recreate) | **WAL_HOST_PERSIST_PASS** |
| Engine `wal_recovery` | **ok** |
| Phase 3 engineering gates | **PASS** |
| Phase 4.1-Lite baseline (contests, deps, backup local) | **PASS** (prior) |

### Not proven (hard blockers)

| Check | Result |
|---|---|
| Production / prod-equivalent VM provisioned | **NO** |
| VM reboot durability token | **BLOCKED** |
| VM replacement + volume reattach | **BLOCKED** |
| Object storage backup E2E | **BLOCKED** |
| Rollback live drill | **BLOCKED** |
| Emergency pause live | **BLOCKED** |
| Payment provider non-mock | **BLOCKED** |
| Market-data production provider | **BLOCKED** (`market_data.ready=false` on local stack) |
| Admin MFA live | **BLOCKED** |
| Monitoring + alerts fire | **BLOCKED** |
| First production contest | **NOT EXECUTED** |
| External/legal CONFIRMED | **BLOCKED** |

---

## Persistent storage

| Item | Design | Evidence this session |
|---|---|---|
| Provider | Host/block volume bind | Local path writable; not cloud block |
| Path | `TRAGGE_WAL_HOST_PATH` → container `/var/lib/tragge/wal` | Set for drills |
| Config | `WAL_REQUIRE_PERSIST=true` in production overlay | Present |
| Survive container recreate | Required | **PASS** (`WAL_HOST_PERSIST_PASS`) |
| Survive VM reboot / replace | Required | **NOT TESTED** on real VM |

---

## Dependencies

| Dependency | Production intent | This session |
|---|---|---|
| PostgreSQL | Managed preferred | Local Compose healthy |
| Redis | Managed; not ledger authority | Local Compose healthy |
| Redpanda | Managed/dedicated | Local Compose healthy |
| Object storage | Automated backups | **Not configured E2E** |

---

## Failure recovery

| Scenario | Design | Status |
|---|---|---|
| Docker restart trading-core | Compose restart + WAL bind | Proven (local) |
| Worker restart | Idempotent settlement | Proven (4.1-Lite) |
| Redis/Redpanda/PG restart | Fail closed + recover | Proven (4.1-Lite local) |
| VM reboot | Remount WAL + compose up | **Documented, untested** |
| VM replacement | Reattach block + deploy | **Documented, untested** |

---

## Security / providers

| Area | Status |
|---|---|
| Secrets mechanism | Docker secrets files / host SM documented; prod SM not provisioned |
| TLS / public edge | Gateway-only intent; production TLS not live-qualified |
| MFA | **NOT CONFIRMED** live |
| Payment | **NOT CONFIRMED** non-mock |
| Market data | **NOT CONFIRMED** production feed |

---

## Monitoring

Compose-local health endpoints exist. Production monitoring/alert fire tests **not** executed → launch-gate **BLOCKED**.

---

## Controlled contest

**Not executed.** See `docs/codex/reports/FIRST-PRODUCTION-CONTEST-2026-08-16.md`.

---

## Reconciliation

No production contest → no production reconciliation.  
Local durable contest reconcile remains Phase 4.1-Lite evidence only.

---

## Launch gate summary

```text
PASS  Engineering + local staging baseline + prod compose path
PASS  Preflight + WAL persist + trading recovery + container/worker/dep drills + local backup
BLOCKED  Object storage backup E2E
BLOCKED  VM reboot / replacement
BLOCKED  Rollback live
BLOCKED  Emergency pause live
BLOCKED  Payment / MD / MFA
BLOCKED  Monitoring + alerts
BLOCKED  Controlled contest + reconcile
BLOCKED  External sign-offs
```

Full matrix: `docs/release/production-go-no-go.md`

---

## Remaining risks (real)

1. Host-level WAL durability under VM failure unproven  
2. Backup pipeline to object storage unproven  
3. Real payment/MD/MFA/legal exposure unaccepted  
4. No production operator freeze / on-call assignment  
5. Market data not ready on current local stack  

---

## CTO stop conditions (honored)

Did **not** launch despite removing Kubernetes.  
Did **not** weaken gates—replaced K8s checks with equivalent VM/Docker safety.  
Did **not** invent provider or legal approvals.  
Did **not** run a production contest on local Compose and call it production.

---

## Path to PRODUCTION — GO

```text
Local Staging Fully Qualified          ✅
VM / Docker production path delivered  ✅
Persistent WAL (container level)       ✅
VM failure / replacement qualified     ❌
Object storage backup/restore          ❌
Payment / MD / MFA / legal             ❌
Monitoring / alerts / pause / rollback ❌
launch-gate exit 0                     ❌
Controlled first contest + reconcile   ❌
PRODUCTION — GO                        ❌
```

---

## Final Decision

```text
PRODUCTION — NO-GO
```

**Strongest valid claims:**

```text
LOCAL STAGING — FULLY QUALIFIED
PRODUCTION PATH — VM/DOCKER DELIVERED (not yet GO)
```

**Invalid claims:**

```text
PRODUCTION — GO
Kubernetes production certified
```
