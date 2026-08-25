# Service and package inventory (ARCH-009)

**As of:** 2026-08-25 continuity (local staged tree on `codex/*` stack).  
**Not** a live-production deploy inventory.

## Applications (`apps/`)

| Application | Form | Dockerfile | Fate (ARCH-007/008) | Notes |
|---|---|---|---|---|
| `platform` | Modular monolith (`api`/`realtime`/`worker`) | yes | **KEEP** | ADR-0001 Platform |
| `trading-engine` | Engine | yes | **KEEP** | Standalone + still embedded in trading-core |
| `market-ingestor` | Market Data | yes | **KEEP** | Standalone + still embedded in trading-core |
| `user-frontend` | Vue SPA | yes | KEEP (FE) | |
| `admin-frontend` | Vue SPA | yes | KEEP (FE) | |
| `gateway` | Nginx | yes | KEEP (edge) | |
| `api-server` | Merged wrapper | yes | DELETE_AFTER_CUTOVER | DEPRECATED |
| `trading-core` | Merged wrapper | yes | DELETE_AFTER_CUTOVER | DEPRECATED |
| `worker` | Merged wrapper | yes | DELETE_AFTER_CUTOVER | DEPRECATED |
| `user-bff` | Server package | no | REPLACE | Started via api-server |
| `admin-bff` | Server package | no | REPLACE | Started via api-server |
| `payment-service` | Server package | no | REPLACE | Started via api-server |
| `trade-bff` | Server package | no | REPLACE | Started via trading-core |
| `leaderboard-worker` | Server package | no | REPLACE | Started via worker |
| `settlement-service` | Server package | no | REPLACE | Started via worker |
| `contest-scheduler` | Server package | no | DELETE_AFTER_CUTOVER | Started via worker |
| `free-contest-generator` | Server package | no | DELETE_AFTER_CUTOVER | Started via worker |
| `shard-router` | Go app | yes | KEEP (ops TBD) | Not in k8s base resources |

See per-app `FATE.md` / `RETIREMENT.md` for evidence.

## Packages (`packages/`)

Go modules include: `audit`, `auth`, `config`, `contracts`, `db`, `domain`,
`infra`, `kyc`, **`money` (DATA-001)**, `notification`, `observability`, `redis`,
`resilience`, `scoring`, `secrets`, `sms`, `storage`, `ticket`, `validation`,
`wallet`, plus Node `frontend-shared` and `contracts/ts`.

Notable contract additions:

- `contracts/envelope/v1` (ARCH-006)
- `contracts/engine/v1` (ENG-001)
- `contracts/marketdata/v2` (MD-001)
- Legacy `contracts/v1` float ticks remain for rollout

## Database migrations

| Chain | Location | Role |
|---|---|---|
| Legacy | `packages/db/migrations/*.up.sql` | Disposable pre-launch schema (111 ups as of LIFECYCLE stack) |
| Target | `packages/db/migrations/target/` | Schema ownership + outbox/inbox + financial policy comments (`0001`–`0005`) |

## Compose profiles

| Profile | Purpose |
|---|---|
| `target` | Preferred: Platform ×3 + Engine + Market Data |
| `app` / `full` / `legacy-wrappers` | Transitional merged wrappers (rollback) |
| `engine-standalone` | Engine-only helper (ENG-001) |
| `frontend` | Frontends without backend wrappers |

## K8s

| Layer | What it selects |
|---|---|
| `infra/k8s/base` | `api-server`, `trading-core`, `worker` (+ infra) |
| production overlay | Patches obsolete standalone names → **INFRA-002** |
