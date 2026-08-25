# ARCH-001 — Platform modular-monolith skeleton

**Date:** 2026-08-25  
**Branch:** `codex/arch-001-create-the-platform-modular-monolith-skele`  
**Commit message (required):** `feat(platform): add modular monolith runtime skeleton`

## Authority

- `docs/codex/PRODUCTION_ROADMAP_AND_CODEX_TASKS.md` § ARCH-001
- ADR-0001 / policy §2.1–2.3
- Scope confirmed: **stub modules + wiring only** (no BFF migration — ARCH-002+)

## What was implemented

| Item | Location |
|---|---|
| Entrypoint | `apps/platform/cmd/platform` (`--mode=api\|realtime\|worker`) |
| Modules (stubs) | identity, contest, wallet, payment, kyc, settlement, leaderboard, notification, ticket, admin, scheduler |
| Composition root | `internal/compose` (only place that constructs module repos) |
| Mode adapters | `internal/adapters/{api,realtime,worker}` with `/healthz` + `/readyz` |
| Import boundary | Unexported `repository`; adapter AST test forbids direct module imports |
| One image | `apps/platform/Dockerfile` + `infra/docker/docker-compose.platform.yml` |
| Workspace | `go.work` includes `./apps/platform` |
| CI | `arch-001-platform-skeleton` |

## Exact tests

```text
go test ./...   # apps/platform — mode, compose, boundary, smoke
node --test scripts/sec-arch001-platform-skeleton.test.mjs
```

## Unresolved risks / not claimed

- Docker image build not runtime-verified this session (`ARCH001-DOCKER-IMAGE`).
- No production traffic cutover; legacy `api-server` / `worker` wrappers remain (ARCH-007).
- Module stubs do not implement product behavior (ARCH-002+).

## Prior verification gaps (unchanged — still not runtime-verified)

FIN003-POSTGRES-DUAL-RACE, FIN005-*, P0-FIN-06, LIFECYCLE001-USERBFF-COMPILE, LIFECYCLE002-LOAD-TEST, LIFECYCLE002-STATEMACHINE-COMPILE, LIFECYCLE003-POSTGRES-E2E.
