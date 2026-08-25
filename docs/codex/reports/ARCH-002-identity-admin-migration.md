# ARCH-002 — Migrate identity and admin boundaries into Platform

**Date:** 2026-08-25  
**Branch:** `codex/arch-002-migrate-identity-and-admin-boundaries-into`  
**Commit message (required):** `refactor(platform): migrate identity and admin modules`

## Authority

- `PRODUCTION_ROADMAP_AND_CODEX_TASKS.md` § ARCH-002
- Dependencies: ARCH-001, SEC-001, SEC-004
- Confirmed approach: services into Platform + mount on API + BFF wrappers

## What changed

| Area | Change |
|---|---|
| `internal/modules/identity` | User auth-context ownership, user repository (unexported), validate + boundary HTTP |
| `internal/modules/admin` | Admin auth-context ownership, unexported adminRepository, **AuthorizePermission/AuthorizeRole** application service |
| `pkg/identity`, `pkg/admin` | Public facades for BFF imports (internal/ not importable cross-module) |
| Platform API mode | Mounts `/api/user/auth/v1/*` and `/api/admin/auth/v1/*` |
| `packages/auth` | `PermissionAuthorizer` / `RoleAuthorizer`; middleware delegates when set |
| admin-bff | Wires Platform admin service as middleware authorizer |
| user-bff | Binds Platform identity to User trust domain |

## Exact tests

```text
go test ./apps/platform/...
# boundary, authz, race, contract, mode smoke including identity/admin routes

node --test scripts/sec-arch002-identity-admin.test.mjs

go build ./apps/admin-bff/server/ ./apps/user-bff/server/
```

## Unresolved / not claimed

- Full login/register/OAuth handler bodies remain in BFFs (compatibility wrappers); further endpoint moves stay later ARCH work.
- Docker image with live JWT secrets for validate endpoint — not runtime-verified.
- Prior verification gaps remain open (FIN003-*, FIN005-*, P0-FIN-06, LIFECYCLE*, ARCH001-DOCKER-IMAGE).

## Next

ARCH-003 — contest/scheduler/leaderboard/notification/ticket modules.
