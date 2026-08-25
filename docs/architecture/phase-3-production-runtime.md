# Phase 3 — Production Runtime Architecture

**Date:** 2026-08-16  
**Status:** historical Phase 3 notes; **superseded for target topology by ARCH-007/009**

> **ARCH-009:** Prefer
> [`staged-runtime-topology.md`](./staged-runtime-topology.md) and Compose
> `profile=target` (Platform + standalone Engine + Market Data). Merged
> wrappers remain **transitional rollback** only (`DEPRECATED`). This file’s
> “keep merged for launch” tables are **not** the ADR-0001 end state.

## Launch runtime topology (minimal isolation) — legacy transitional

```text
Internet
  → gateway (nginx)
      → api-server          [user-bff + admin-bff + payment]   # DEPRECATED wrapper
      → trading-core-lb     [StatefulSet trading-core]        # DEPRECATED wrapper
            ├ trade-bff :8082
            ├ market-ingestor :8084
            └ trading-engine :8085  + PVC wal-data
      → worker              [leaderboard + settlement + scheduler + free-gen]  # DEPRECATED
  → PostgreSQL (+ PgBouncer)
  → Redis
  → Redpanda/Kafka
```

### Target path (ADR-0001 / ARCH-007)

```text
Internet
  → gateway
      → platform --mode=api
      → platform --mode=realtime
      → platform --mode=worker
      → trading-engine (standalone)
      → market-ingestor (standalone)
  → PostgreSQL (platform / engine / market_data schemas)
  → Redis / Redpanda
```

### Why wrappers still exist

| Boundary | Decision (ARCH-007/008) | Reason |
|---|---|---|
| trading-core merged | DELETE_AFTER_CUTOVER | Still embeds Engine/MD/trade-bff; cutovers open |
| WAL owner | Engine standalone + PVC strategy | Retain durability requirements from Phase 3 |
| settlement in worker | REPLACE → Platform worker | Authority moved; HTTP/Kafka cutover open |
| api-server | DELETE_AFTER_CUTOVER | Payment/identity HTTP cutover open |
| scheduler / free-gen | DELETE_AFTER_CUTOVER | Still imported by worker |

## Durable WAL storage

| Field | Value |
|---|---|
| Kind | StatefulSet `trading-core` |
| PVC | `volumeClaimTemplates[wal-data]` |
| Access mode | ReadWriteOnce |
| Mount | `/var/lib/tragge/wal` |
| Path env | `WAL_PERSIST_PATH=/var/lib/tragge/wal/engine.jsonl` |
| Require | `WAL_REQUIRE_PERSIST=true` |
| Prod size | 20Gi (`premium-rwo`) |
| emptyDir | **Forbidden** for WAL |
| Init | `wal-volume-check` write probe before start |
| Ownership | single-active (replicas=1, no HPA) |

If PVC cannot bind → Pod Pending → not ready → no trading.

## Single-active ownership

When `SHARD_ENABLED=false`:

- StatefulSet `replicas: 1`
- No HPA for trading-core
- RWO PVC cannot attach to two nodes/pods concurrently
- Engine consumer group is single member

Sharding (later): scale StatefulSet to SHARD_COUNT with partition-aware consumers; each ordinal keeps its own WAL PVC.

## Readiness vs liveness

| Probe | Port | Meaning |
|---|---|---|
| Liveness | trade-bff `/healthz` | Process alive |
| Readiness | trading-engine `/readyz` | WAL recovered, deps OK, optional market data |

Dependency outages set readiness false; liveness does not restart-loop on temporary MD/DB issues.

## Graceful shutdown

- `terminationGracePeriodSeconds: 45` (trading-core), `60` (worker)
- `preStop sleep 5` for LB drain
- Engine: `ready=false` → stop consumers → Compact/Close WAL → HTTP Shutdown → DB close

## Messaging semantics (at-least-once + DB idempotency)

| Event | Delivery | Idempotency |
|---|---|---|
| Orders | at-least-once Kafka | `order_id` PK + engine idempotent ACK |
| Fills | engine-local + emit | deterministic fill_id / PK |
| Settlement jobs | worker restart | advisory lock + settlement row unique + prize keys |
| Contest state | at-least-once | status transitions + gate |

**Not exactly-once.** Safety is DB uniqueness + WAL recovery.

## Compose vs Kubernetes

| Concern | Compose | Kubernetes |
|---|---|---|
| trading-core | single container + named volume `trading_core_wal` | StatefulSet + PVC |
| Process merge | same binaries | same |
| Multi-replica engine | not used | forbidden until shard |

## Backup / restore

- CronJob: `infra/k8s/cronjobs/daily-backup.yaml` → S3 AES256
- Local drill: `node scripts/phase3/backup-restore-drill.mjs`
- App does **not** auto-migrate on every restart; operators run migrate jobs

## Release gates

```bash
node scripts/phase3/release-gates.mjs
node scripts/phase3/smoke-test.mjs
RUN_BACKUP_DRILL=1 node scripts/phase3/backup-restore-drill.mjs
```
