# PHASE 5-LITE — Local Docker Compose Staging Qualification

**Date:** 2026-08-16  
**Decision:** **PHASE 5-LITE — PASS**  
**Readiness label:** **LOCAL STAGING — QUALIFIED**  
**Does NOT mean:** `PRODUCTION — GO` or Kubernetes PVC qualification

---

## 1. Decision

```text
PHASE 5-LITE — PASS
LOCAL STAGING — QUALIFIED
```

Docker Compose multi-service staging runs end-to-end for launch-critical paths that do **not** require Kubernetes.

---

## 2. Environment

| Item | Value |
|---|---|
| OS | Windows (operator machine) |
| Docker | 29.7.2 |
| Compose | v5.3.1 |
| Docker path | `…\DockerDesktop\resources\bin\docker.exe` (not always on PATH) |
| PostgreSQL | `postgres:16-alpine` container `tragge_postgres` :5432 |
| Redis | `redis:7-alpine` `tragge_redis` :6379 |
| Redpanda | `redpandadata/redpanda:v24.1.1` :9092→19092 |
| Migration version | **103** |

### Compose topology (actual)

```text
platform_net (172.30.0.0/24)
  postgres, redis, redpanda, kafka-init
  api-server   (user-bff + admin-bff + payment)  profile: app
  trading-core (trade-bff + engine + market-ingestor)  profile: app
  worker       (leaderboard + settlement + scheduler + free-gen)  profile: app
```

Host ports (override): trade-bff 8085, engine 8093, admin 8083, settlement 8095, …

---

## 3. Deployment / volumes

| Volume | Purpose |
|---|---|
| `docker_postgres_data` | PG data |
| `docker_redis_data` | Redis AOF |
| `docker_redpanda_data` | Broker data |
| **`docker_trading_core_wal`** | **WAL persistence (named volume ≠ emptyDir)** |

WAL path in container: `/var/lib/tragge/wal`  
`WAL_PERSIST_PATH=/var/lib/tragge/wal/engine.jsonl`

### Redis/Kafka DNS (Task 3)

| App env | Compose service | Status |
|---|---|---|
| `REDIS_ADDR=redis:6379` | `redis` | **Match** |
| `KAFKA_BROKERS=redpanda:9092` | `redpanda` | **Match** |

K8s staging overlay still uses `redis-staging` / `redpanda-staging` names — **Compose is correct**; K8s mismatch is out of Phase 5-Lite scope.

---

## 4. Fixes applied during qualification

| Issue | Fix |
|---|---|
| YAML duplicate `SHARD_ENABLED` | Removed duplicate key in `docker-compose.yml` |
| Redpanda partition memory limit | Lite: `TOPIC_PARTITIONS_*=1` + redpanda 512M; wipe volume; 18 topics created |
| `ENVIRONMENT=development` vs `APP_ENV=staging` | Aligned `APP_ENV` default to `ENVIRONMENT` |
| Mailerino fatal with empty From + placeholder keys | Empty email API key secrets for local; email delivery optional |
| WAL volume root ownership vs USER 65534 | Documented; chown volume; compose `user: "0:0"` for local trading-core only |

---

## 5. Tests

### Smoke / readiness

| Check | Result |
|---|---|
| All required containers healthy | **PASS** |
| trade-bff `/healthz` | **PASS** `{"status":"ok"}` |
| trading-engine `/readyz` (in-container) | **PASS** `wal_recovery=ok`, db/redis/kafka healthy |
| market_data ready | **false** (`all_quotes_stale` / no valid Massive forex key) — expected without real provider; `REQUIRE_MARKET_DATA_READY=false` so engine still ready |
| admin `/healthz` | **PASS** after api-server fix |

### Financial (Compose PostgreSQL)

| Test | Result |
|---|---|
| `TestPhase11_FinancialLifecycle_E2E` ×3 sequential | **PASS** (3/3) |
| After postgres container restart | **PASS** Phase11 |
| `TestPhase3_BackupRestoreDrill` | **PASS** (gate) |

### Trading (real engine package path against Compose PG)

| Test | Result |
|---|---|
| `TestPhase2_E2E_TradingToSettlement` | **PASS** (multiple runs) |
| `TestPhase2_E2E_RestartWALRecovery` | **PASS** (gate) |
| `TestPhase3_WALPVCRescheduleSimulation` | **PASS** (local path; not K8s PVC) |

### Restart / failure (Compose)

| Scenario | Result |
|---|---|
| trading-core recreate + **named WAL volume** retains proof file | **PASS** |
| redis restart → stack healthy | **PASS** |
| worker restart → healthy | **PASS** |
| redpanda restart → healthy + apps recover | **PASS** |
| postgres restart → healthy + financial E2E | **PASS** |

### Multi-contest

Three sequential financial E2E contests + trading E2E waves: **PASS** (3/3 financial).

### Gate

```text
node scripts/phase5lite/compose-gate.mjs
→ LOCAL STAGING — QUALIFIED
→ exit 0

STAGING_PLATFORM=compose node scripts/phase4/preflight.mjs
→ live_compose_qualification_possible=true
→ live_qualification_possible=false   # correctly does NOT claim K8s
```

---

## 6. Failures encountered (and closed)

| Failure | Root cause | Fix | Retest |
|---|---|---|---|
| `compose config` parse error | duplicate `SHARD_ENABLED` | remove dupe | config OK |
| kafka-init 0 topics | partition count > redpanda memory limit | 1 partition lite + wipe volume | 18 topics OK |
| api-server crash loop | ENV vs APP_ENV mismatch | align APP_ENV | healthy |
| api-server Mailerino fatal | empty From + non-empty placeholder keys | empty keys for local | healthy |
| WAL write permission denied | volume root-owned vs UID 65534 | chown + compose user 0 for local | persist proof OK |

---

## 7. Current readiness

```text
LOCAL STAGING — QUALIFIED
```

```text
NOT PRODUCTION — GO
NOT Kubernetes PVC / StatefulSet / CSI qualified
```

---

## 8. Proven locally vs still unproven

### Proven (Compose)

- Multi-service topology (merged processes as designed)  
- PostgreSQL, Redis, Redpanda connectivity  
- Named-volume WAL persistence across container recreate  
- Migrations to 103  
- Financial E2E + settlement idempotency against live PG  
- Trading E2E path (ProcessOrder/ProcessTick tests)  
- Service / broker / DB restarts  
- Local logical backup/restore drill  
- Compose qualification gate exit 0  

### Still unproven (deferred)

- Kubernetes StatefulSet + CSI PVC bind  
- Pod delete / reschedule / CSI remount  
- Cluster networking / NetworkPolicy at scale  
- S3 CronJob production backup E2E  
- Real market-data provider credentials (Massive forex auth fails; crypto path used in logs)  
- Payment provider non-mock / legal / MFA live sign-off  
- Full HTTP multi-user contest through gateway UI  

---

## 9. How to reproduce

```powershell
$env:Path = "C:\Users\parsa\AppData\Local\Programs\DockerDesktop\resources\bin;" + $env:Path
cd <repo>/infra/docker
docker compose -f docker-compose.yml -f docker-compose.lite.yml -f docker-compose.override.yml up -d postgres redis redpanda
docker compose -f docker-compose.yml -f docker-compose.lite.yml -f docker-compose.override.yml run --rm kafka-init
# migrate to 103
docker compose -f docker-compose.yml -f docker-compose.lite.yml -f docker-compose.override.yml --profile app up -d --build
cd ../..
$env:STAGING_PLATFORM="compose"
node scripts/phase4/preflight.mjs
node scripts/phase5lite/compose-gate.mjs
```

---

## 10. Next steps

1. Use this Compose stack for **Phase 4.1-applicable** local qualification (restart/failure/contest tests already partially covered).  
2. Separately provision **Kubernetes** for Phase 5 / Phase 4.1 K8s-only gates (PVC, CSI, pod reschedule).  
3. Do **not** treat this PASS as production launch authority.

---

## Final Decision

```text
PHASE 5-LITE — PASS
LOCAL STAGING — QUALIFIED
```
