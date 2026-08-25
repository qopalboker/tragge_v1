# INFRA-002 decision log

**Date:** 2026-08-25  
**Branch:** `codex/INFRA-002-k8s-base-overlay-parity-drift-ci` (targets `main`)

## Environment

Local / no-user archive. **No production Kubernetes cluster** is assumed.
INFRA-002 validates **desired-state** consistency only.

## Desired-state model (current main)

| Layer | Workloads |
|---|---|
| `infra/k8s/base` | Consolidated: `api-server`, `trading-core`, `worker`, `frontend`, `gateway` (+ data plane) |
| overlays | May only patch those base resources |

Obsolete standalone Deployment patch targets (`user-bff`, `trade-bff`, …) are removed.

## Deferred

- **INFRA002-POSTGRES-HA-OVERLAY** — merging `base/postgres-ha` with base postgres/pgbouncer ConfigMaps causes ID conflicts; not wired into production overlay until a conflict-free HA base is designed.
- Live-cluster drift vs deployed objects — requires a real cluster (INFRA-001 parked condition).

## Gaps preserved

All prior ARCH/FIN/LIFECYCLE/MD verification gaps remain open; this PR does not close them.
