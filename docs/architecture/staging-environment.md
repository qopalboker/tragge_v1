# Staging Environment Architecture (Phase 5)

**Status:** Target design (authoritative for provisioning)  
**Application topology:** Phase 3 production runtime  
**Qualification consumer:** Phase 4.1 live launch certification  

---

## 1. Dependency matrix (from repository)

| Dependency | Required by | Exposure | Persistence | Production-like requirement |
|---|---|---|---|---|
| **PostgreSQL 16** | api-server, trading-core, worker, migrations, settlement, ledger | **Private** only | Required (PVC or managed) | ACID, advisory locks, migrations 0103+ |
| **PgBouncer** | services via pool (optional staging) | Private | Ephemeral OK | Transaction mode preferred |
| **Redis** | rate limits, sessions, price cache, OTP paths | Private | RDB/AOF preferred | Not financial authority |
| **Redpanda/Kafka** | orders, ticks, fills, settlement signals | Private | Broker disk | Topics per `configmap` (`orders.v1`, `ticks.v1`, …) |
| **Object storage (S3)** | backups CronJob, avatars/KYC | Private API + restricted IAM | Bucket lifecycle | Staging bucket separate from prod |
| **WAL PVC** | trading-core StatefulSet | N/A (volume) | **Required RWO** | Path `/var/lib/tragge/wal`, no emptyDir |
| **Ingress + TLS** | gateway / API / WS | Public edge only | Cert manager | Staging domain + LE staging issuer |
| **Secrets** | all apps | K8s Secrets / SM | — | No secrets in Git |

Authoritative manifests: `infra/k8s/base/*`, overlay `infra/k8s/overlays/staging`.

---

## 2. Target topology

```text
                    Internet (staging DNS only)
                           │
                    Ingress + TLS
                           │
                        gateway
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         api-server   trading-core   (frontend optional)
                      StatefulSet
                      replicas: 1
                      PVC: wal-data
              │            │
              └────┬───────┘
                   ▼
                 worker
                   │
     ┌─────────────┼─────────────┐
     ▼             ▼             ▼
 PostgreSQL      Redis        Redpanda
 (private)     (private)     (private)
     │
     └── backups → Object storage (staging bucket)
```

---

## 3. Platform choice (decision record)

| Option | When to use |
|---|---|
| **kind / k3d on operator workstation** | Local qualification; Docker required; StorageClass `standard` or `local-path` |
| **Managed K8s (EKS/GKE/AKS)** | Shared team staging; use cloud CSI + private DB |
| **Existing company staging cluster** | Prefer if kubeconfig already exists |

**Phase 5 session decision (2026-08-16):**  
**No platform provisioned** — operator tools and cloud credentials were absent.  
Preferred first path when tools arrive: **kind** (smallest) or team **managed K8s** if available.

### Expected resource profile (minimum staging)

| Component | CPU req | Mem req | Notes |
|---|---|---|---|
| trading-core | 250m | 512Mi | + 10Gi WAL PVC |
| api-server | 100m | 128Mi | |
| worker | 100m | 256Mi | |
| postgres | 250m | 512Mi | + 20Gi data PVC |
| redis | 100m | 256Mi | |
| redpanda | 500m | 1Gi | + 20Gi data |
| gateway | 50m | 128Mi | |
| **Node capacity** | ≥ 4 vCPU | ≥ 8 GiB | single node OK for staging |

---

## 4. Storage

| Volume | Access | Size (staging) | Class |
|---|---|---|---|
| trading-core `wal-data` | RWO | 10Gi | `standard` (kind) or cloud gp3/`premium-rwo` |
| postgres data | RWO | 20Gi+ | same |
| redpanda data | RWO | 20Gi+ | same |

Fail-closed: if WAL PVC unbound → trading-core Pending / not ready.

Staging patch: `infra/k8s/overlays/staging/patches/wal-storage-patch.yaml`.

---

## 5. Networking

| Surface | Policy |
|---|---|
| Ingress hostnames | staging domains only (see overlay ingress-patch) |
| Postgres / Redis / Redpanda | ClusterIP only; NetworkPolicy restricted |
| Trading engine | Internal; readiness on :8085 |
| No public DB/broker | Mandatory |

---

## 6. Secrets (names only)

Typical Secret keys (see `infra/k8s/base/secrets.yaml` / ExternalSecrets):

- `postgres-secrets` — DB users/passwords  
- `tragge-secrets` — JWT, app DSNs  
- Redis password  
- Kafka if auth enabled  
- Provider test keys (payment, market-data)  
- Object storage access keys for backup CronJob  

**Never commit values.**

---

## 7. Configuration notes (staging overlay)

| Key | Staging intent |
|---|---|
| Namespace | `tragge-staging` |
| `ENVIRONMENT` | `staging` |
| `WAL_REQUIRE_PERSIST` | `true` |
| `WAL_PERSIST_PATH` | `/var/lib/tragge/wal/engine.jsonl` |
| `KAFKA_BROKERS` | in-cluster Redpanda service name |
| `REDIS_ADDR` | in-cluster Redis (prefer standalone for simple staging) |
| Image tags | `staging` or git SHA — not production digests |

**Known overlay inconsistency:** staging kustomization currently patches `REDIS_ADDR=redis-staging` and `KAFKA_BROKERS=redpanda-staging` while base resources are named `redis` / `redpanda`. When deploying base-in-staging, align names to in-cluster services or deploy matching staging dependency names. Fix before Phase 4.1.

---

## 8. Success criterion for Phase 5

```text
node scripts/phase4/preflight.mjs
→ live_qualification_possible=true
```

Requires: kubectl + reachable API + StorageClass (+ tools for qualification).

Then **stop** and run Phase 4.1 separately.
