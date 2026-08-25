# ARCH-007 — Retire merged wrappers (boundary inventory)

**Branch:** `codex/arch-007-retire-merged-wrappers-and-dead-standalone`  
**Commit:** `refactor(runtime): retire merged legacy applications`

## Fate matrix

| Runtime | Role today | Fate | Target owner | Deletion blocked on |
|---|---|---|---|---|
| `apps/platform` | Modular monolith (api/realtime/worker) | **KEEP** | itself | — |
| `apps/trading-engine` | Engine (also embedded in trading-core) | **KEEP** | itself (standalone image) | — |
| `apps/market-ingestor` | Market Data (also embedded in trading-core) | **KEEP** | itself (standalone image) | `MD001-KAFKA-V2-CUTOVER` for feed contract |
| `apps/api-server` | Merged user/admin/payment | **DELETE_AFTER_CUTOVER** | Platform `--mode=api` | `ARCH004-PAYMENT-HTTP-CUTOVER`, `ARCH007-WRAPPER-DELETE` |
| `apps/trading-core` | Merged engine/ingestor/trade-bff | **DELETE_AFTER_CUTOVER** | Engine + Market Data + Platform trade surface | `ENG001-TRADING-CORE-CUTOVER`, `MD001-KAFKA-V2-CUTOVER`, `ARCH007-WRAPPER-DELETE` |
| `apps/worker` | Merged leaderboard/settlement/scheduler/generator | **DELETE_AFTER_CUTOVER** | Platform `--mode=worker` | `ARCH005-SETTLEMENT-HTTP-CUTOVER`, `ARCH007-WRAPPER-DELETE` |
| `apps/contest-scheduler` | Standalone package, worker-embedded | **DELETE_AFTER_CUTOVER** | Platform scheduler | Platform scheduler cutover, `ARCH007-WRAPPER-DELETE` |
| `apps/free-contest-generator` | Standalone package, worker-embedded | **DELETE_AFTER_CUTOVER** | Platform scheduler | Platform scheduler cutover, `ARCH007-WRAPPER-DELETE` |
| `apps/user-bff` / `admin-bff` / `payment-service` / `trade-bff` / `leaderboard-worker` / `settlement-service` | Still imported by wrappers | **REPLACE** (source retained until module cutover) | Platform modules | Per-service HTTP/job cutovers; final inventory is ARCH-008 |

## What changed in this PR

| Change | Purpose |
|---|---|
| `infra/docker/docker-compose.target.yml` | Preferred Platform + Engine + Market Data topology (`profile=target`) |
| Wrapper Compose profiles include `legacy-wrappers` | Explicit transitional label without breaking `app`/`full` |
| `apps/market-ingestor` cmd + Dockerfile | Independent Market Data image |
| Wrapper `RETIREMENT.md` + DEPRECATED logs | Operator-visible retirement status |
| CI `sec-arch007-runtime-retirement.test.mjs` | Locks inventory + compose target artifacts |

## Rollback

Prior release images/tags for `api-server`, `trading-core`, and `worker` remain
buildable via profiles `app`/`full`/`legacy-wrappers`. Source is not deleted.

## Gaps (not runtime-verified)

- `ARCH007-WRAPPER-DELETE` — physical deletion of wrappers after cutover
- `ARCH007-TARGET-COMPOSE-E2E` — live `profile=target` up/smoke
- Prior gaps including **`MD001-KAFKA-V2-CUTOVER`** and **`MD001-FRONTEND-CUTOVER`** remain open
- FIN-006 / MD-005A not in scope
