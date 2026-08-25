# ARCH-008 decision log

**Date:** 2026-08-25  
**Branch:** `codex/arch-008-resolve-legacy-standalone-service-fate`

## Rule applied

Do **not** delete any standalone merely because it looks legacy.  
`SAFE_TO_DELETE` requires evidence of **zero** remaining callers, Compose/K8s references, and live traffic — not code-reading alone.

## Outcome

**Zero services qualify for `SAFE_TO_DELETE` in this PR.**

| Fate | Services |
|---|---|
| **KEEP** | `trading-engine`, `market-ingestor` (target ADR-0001 images) |
| **REPLACE** (source retained) | `user-bff`, `admin-bff`, `payment-service`, `trade-bff`, `leaderboard-worker`, `settlement-service` |
| **DELETE_AFTER_CUTOVER** | `contest-scheduler`, `free-contest-generator` (still imported by `worker`) |
| **KEEP (ops/routing)** | `shard-router` (Dockerfile + tooling/chaos refs; not in base kustomization — verify before any change) |

## Explicitly not done

- No source deletion
- No K8s overlay “cleanup” that removes patches without traffic proof (INFRA-001/INFRA-002)
- FIN-006 / MD-005A unchanged
