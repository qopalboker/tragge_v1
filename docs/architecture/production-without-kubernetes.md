# Production Architecture Without Kubernetes

**Status:** Authoritative production topology (Phase 6-NK)  
**Date:** 2026-08-16  
**Supersedes:** Kubernetes as the required production control plane

---

## Decision

Production TRAGGE runs on **VM + Docker Engine + Docker Compose** with **persistent host/block storage** for the trading WAL and **managed or dedicated** data services.

Kubernetes (StatefulSet, PVC, CSI, Helm, kubectl) is **not** on the production critical path.

Historical manifests under `infra/k8s/` are **retained for optional future use** and are **not** the canonical production method.

---

## Logical topology

```text
                         Internet
                            │
                     DNS + TLS + LB / reverse proxy
                            │
                     ┌──────┴──────┐
                     │   gateway   │   (public edge only)
                     └──────┬──────┘
                            │
                       api-server
                            │
                ┌───────────┴───────────┐
                │                       │
          trading-core                worker
          single active               single active
                │                       │
                └───────────┬───────────┘
                            │
          ┌─────────────────┼─────────────────┐
          │                 │                 │
      PostgreSQL          Redis          Redpanda/Kafka
      managed/preferred   managed         managed/dedicated

Trading WAL:
  Dedicated persistent block volume (or host path on that volume)
  mounted ONLY by trading-core at /var/lib/tragge/wal
  WAL_REQUIRE_PERSIST=true
```

---

## VM baseline

### Preferred

| Role | Workloads |
|---|---|
| **VM-App** | gateway, api-server, trading-core, worker, frontends |
| **Managed PG** | financial truth, migrations |
| **Managed Redis** | cache/sessions (not ledger authority) |
| **Managed/dedicated Redpanda** | orders/ticks/fills events |
| **Object storage** | PostgreSQL backups |

### Minimum self-contained (small production / prod-like staging)

One app VM running Compose with in-stack postgres/redis/redpanda **only if**:

- WAL is on a **separate** disk/volume from Postgres data;
- backups to object storage still run;
- firewall exposes only gateway ports.

Do not co-locate WAL and Postgres data on the same failure domain without documenting the risk.

---

## Single-active trading owner

- Exactly **one** `trading-core` container mounts the WAL path.
- Do **not** `scale` trading-core to N>1 against the same WAL.
- Failover = replace/restart that instance with the **same** bind-mounted volume (or reattach block volume to a replacement VM).

---

## Persistent WAL

| Setting | Value |
|---|---|
| Host path | `TRAGGE_WAL_HOST_PATH` (e.g. `/var/lib/tragge/wal` or `/mnt/tragge-wal`) |
| Container path | `/var/lib/tragge/wal` |
| File | `WAL_PERSIST_PATH=/var/lib/tragge/wal/engine.jsonl` |
| Fail-closed | `WAL_REQUIRE_PERSIST=true` |

If the mount is missing/unwritable, trading-core **must not** become ready for unsafe trade.

Compose overlay: `infra/docker/docker-compose.production.yml` (bind mount, not named volume).

---

## VM failure model

```text
VM failure
  → provision replacement VM (or restore host)
  → reattach persistent block volume (or restore from snapshot/backup)
  → install Docker Engine
  → deploy exact release (scripts/prod/deploy.mjs)
  → trading-core starts → WAL replay → readyz wal_recovery=ok
  → continue / finalize / settle / reconcile
```

If block storage **cannot** reattach cross-VM:

- use volume snapshots + tested restore procedure;
- RPO limited by snapshot interval + last durable DB state;
- do not claim zero-RPO without reattach proof.

---

## Secrets

| Mechanism | Use |
|---|---|
| Docker secrets files under `infra/docker/secrets/` (mode 0400) | Compose default |
| Cloud secret manager → files on host | Preferred production |
| Encrypted env on host (`/etc/tragge/`) | Acceptable if access-controlled |

Never commit production secrets. Never print secrets in reports.

---

## Networking

| Surface | Exposure |
|---|---|
| gateway :80/:443 (or LB) | Public |
| admin gateway port | Restricted IP / VPN preferred |
| PostgreSQL, Redis, Redpanda | Private only |
| trading-engine / worker ports | Internal Docker network only |

TLS terminates at LB or host reverse proxy in front of gateway.

---

## Authoritative deploy path

```text
scripts/prod/preflight.mjs
scripts/prod/deploy.mjs
scripts/prod/health-gate.mjs
scripts/prod/launch-gate.mjs
scripts/prod/rollback.mjs
infra/docker/docker-compose.yml
infra/docker/docker-compose.production.yml
infra/docker/production.env.example
```

Runbook: `docs/runbook/production-without-kubernetes.md`

---

## What this architecture must still prove (gates)

Equivalent to former K8s gates:

1. Persistent WAL survives container recreate + host restart  
2. VM replacement or documented backup recovery  
3. Backup/restore of PostgreSQL  
4. Dependency outages degrade safely  
5. Payment / market-data / MFA real qualification  
6. Emergency pause + rollback  
7. Controlled first contest + clean reconciliation  

See `scripts/prod/launch-gate.mjs`.
