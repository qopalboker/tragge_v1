# PHASE 5 — Staging Infrastructure Provisioning

**Date:** 2026-08-16  
**Decision:** **PHASE 5 — BLOCKED**  
**Purpose:** Enable Phase 4.1 live qualification (not production GO)

---

## 1. Decision

```text
PHASE 5 — BLOCKED
```

**Reason:** No operator tooling and no cloud/Kubernetes credentials were available to provision a real cluster.  
Preflight remains `live_qualification_possible=false`. Evidence was not fabricated.

---

## 2. Infrastructure (actual this session)

| Item | Result |
|---|---|
| Provider / region / cluster | **Not provisioned** |
| Kubernetes version | **N/A** |
| Nodes | **N/A** |
| StorageClass / CSI | **N/A** |
| kubectl | **MISSING** |
| Docker / kind / minikube / k3d | **MISSING** |
| Helm / AWS / gcloud / az / terraform | **MISSING** |
| Cloud env vars (AWS_*, KUBECONFIG, …) | **Absent** |
| Local Postgres :5432 | Open (dev only — **not** Phase 5 staging cluster) |
| Local Redis :6379 | Open (dev only) |
| Kafka :9092 | Closed |
| K8s API :6443 | Closed |

### Commands

```text
node scripts/phase5/provision-checklist.mjs
→ exit 2  phase5_provision_ready=false

node scripts/phase4/preflight.mjs
→ exit 2  live_qualification_possible=false
```

Evidence: `docs/codex/reports/evidence/phase5/provision-checklist-2026-08-16.txt` (written by script when run)

---

## 3. Dependencies (Task 1 audit)

| Dependency | Required by | Exposure | Persistence | Prod-like req |
|---|---|---|---|---|
| PostgreSQL 16 | api, trading-core, worker, ledger | Private | Required | Migrations, locks, financial E2E |
| Redis | cache, sessions, rate limit, prices | Private | Preferred | Not ledger authority |
| Redpanda/Kafka | orders/ticks/fills/settlement signals | Private | Broker disk | Topics from ConfigMap |
| Object storage | backup CronJob, S3 assets | Private IAM | Bucket | Staging ≠ prod bucket |
| WAL PVC | trading-core STS | Volume | **RWO required** | `/var/lib/tragge/wal`, no emptyDir |
| Ingress + TLS | gateway/API/WS | Public edge | Certs | Staging domain |
| Secrets | all workloads | SM / K8s Secrets | — | No Git secrets |

Source: `infra/k8s/base/kustomization.yaml`, `configmap.yaml`, `trading-core.yaml`, `cronjobs/daily-backup.yaml`.

---

## 4. Networking (target, not deployed)

| Component | Target |
|---|---|
| Ingress | Staging hostnames via overlay patches |
| TLS | Let's Encrypt staging issuer |
| DB / Redis / Redpanda | ClusterIP only; NetworkPolicies in base |
| Public exposure | Ingress only |

**Deployed this session:** none.

---

## 5. Secrets

No staging secrets created (no cluster).  
Template guidance: `docs/runbook/staging-environment-runbook.md` § Secrets.  
**No secret values** in this report.

---

## 6. Deployment

| Workload | Status |
|---|---|
| gateway | **NOT DEPLOYED** |
| api-server | **NOT DEPLOYED** |
| trading-core StatefulSet + WAL PVC | **NOT DEPLOYED** |
| worker | **NOT DEPLOYED** |
| postgres / redis / redpanda | **NOT DEPLOYED** (local PG/Redis only) |
| migrations | **NOT RUN** on staging |

### Repository changes supporting future provision

| Artifact | Purpose |
|---|---|
| `infra/k8s/overlays/staging/patches/wal-storage-patch.yaml` | Staging WAL StorageClass (`standard` / 10Gi) |
| staging `kustomization.yaml` | Includes WAL storage component |
| `docs/architecture/staging-environment.md` | Target architecture + matrix |
| `docs/runbook/staging-environment-runbook.md` | kind + managed K8s procedures |
| `scripts/phase5/provision-checklist.mjs` | Fail-closed operator checklist |

---

## 7. Verification (executed)

| Command | Result |
|---|---|
| Tool inventory (kubectl, docker, kind, cloud CLIs) | All **MISSING** except go/node |
| Port 5432 / 6379 | Open (local) |
| Port 9092 / 6443 / 80 / 443 | Closed |
| `node scripts/phase4/preflight.mjs` | `live_qualification_possible=false` |
| `node scripts/phase5/provision-checklist.mjs` | Expected **exit 2** |

---

## 8. Preflight

```text
live_qualification_possible=false
k8s_cluster=UNAVAILABLE
csi=UNAVAILABLE
storageclasses=UNAVAILABLE
```

**Phase 5 acceptance requires `true`.** Therefore **BLOCKED**.

---

## 9. Known limitations / blockers

| Blocker | Remediation |
|---|---|
| No kubectl / Docker / kind | Install operator tools (see staging runbook) |
| No cloud credentials / kubeconfig | Provide org staging cluster access |
| No StorageClass | After cluster up, verify CSI + SC; adjust WAL patch |
| Staging Redis/Kafka name mismatch in overlay | Align ConfigMap to real Service DNS before 4.1 |
| Local PG/Redis ≠ staging topology | Do not treat local ports as Phase 5 PASS |

---

## 10. Next step

```text
PHASE 5 — BLOCKED
→ Provision tools + reachable cluster (kind or managed K8s)
→ Apply infra/k8s/overlays/staging
→ Confirm PVC Bound + Phase 3 pods Ready
→ node scripts/phase4/preflight.mjs → live_qualification_possible=true
→ Proceed to Phase 4.1 Live Qualification
```

**Do not** start Phase 4.1 until Phase 5 PASS.

---

## Platform choice (documented, not executed)

| Choice | Status |
|---|---|
| Preferred minimal: **kind** on operator machine | Blocked: Docker missing |
| Preferred shared: **managed K8s** (EKS/GKE/AKS) | Blocked: no cloud CLI/credentials |
| Selected this session | **None — cannot provision** |

---

## Final Decision

```text
PHASE 5 — BLOCKED
```

Staging infrastructure was **not** provisioned. Repository now contains reproducible docs, WAL staging storage patch, and fail-closed checklist so that when tools and cluster access exist, Phase 5 can be completed without inventing a snowflake environment.
