# ARCH-002 decision log

**Date:** 2026-08-25  
**Branch:** `codex/arch-002-migrate-identity-and-admin-boundaries-into`

## Migration depth

**Question:** Full handler move vs services + API mount + BFF wrappers?

**Answer (human):** Services into Platform + mount on API + BFF wrappers (recommended).

## Notes

- User/admin auth contexts remain separate (SEC-001).
- RBAC enforcement moved to Platform admin application service; admin-bff middleware delegates via `SetPermissionAuthorizer` / `SetRoleAuthorizer`.
- Admin repository stays unexported; identity must not import admin module (boundary test).
