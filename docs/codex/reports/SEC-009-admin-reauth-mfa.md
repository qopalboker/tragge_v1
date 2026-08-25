# SEC-009 — Admin reauth + Super Admin MFA (independently verified)

**Date:** 2026-08-25  
**Branch:** `codex/SEC-009-admin-reauth-mfa` (stacked on SEC-008)  
**Verdict:** Independently verified and regression-locked.

## Independent verification

### 1. Sensitive action without fresh reauthentication → rejected

- `apps/admin-bff/server/reauthentication.go` `consumeSensitiveGrant` audits `grant_missing` and returns error when `X-Admin-Reauth-Grant` is empty; `requireSensitiveAction` responds **403** `sensitive action denied`.
- Existing postgres/redis integration coverage in `reauthentication_integration_test.go` (missing grant cases).
- New permanent lock: `TestSEC009ReauthenticationMissingGrantRejected` (empty / unknown grant → `ErrReauthenticationInvalid`).

### 2. Super Admin action without MFA → rejected when policy ON

- Login path (`handlers_helpers.go`): when `admin_mfa_enabled` is true, Super Admin password login returns **202** `MFARequired` and does **not** issue an access token.
- Middleware previously allowed empty MFAAssurance always (MVP OFF). SEC-009 wired `SetSuperAdminMFAPolicy(app.isAdminMFAEnabled)` so:
  - **policy ON** → empty assurance rejected (401 `additional authentication required`)
  - **policy OFF** → password-only Super Admin allowed
- New locks: `TestSEC009SuperAdminMFAPolicyGating`, `TestSEC009SuperAdminActionWithoutMFARejectedWhenPolicyOn`.

## What changed

| File | Change |
|---|---|
| `packages/auth/middleware.go` | `SuperAdminMFAAllowed`, `SetSuperAdminMFAPolicy`, policy-aware `RequireSuperAdminMFA` |
| `apps/admin-bff/server/app.go` | Wire policy callback to `isAdminMFAEnabled` |
| `packages/auth/sec009_regression_test.go` | SEC-009 Go regression tests |
| `packages/auth/admin_mfa_test.go` | Align with policy ON/OFF semantics |
| `scripts/sec-009-admin-reauth-mfa.test.mjs` | Node lock + runs Go tests |
| `.github/workflows/ci.yml` | Always-on `sec-009-admin-reauth-mfa` job |
| `package.json` | `test:sec009` |

## Exact test commands and output

```text
node --test scripts/sec-009-admin-reauth-mfa.test.mjs
ok 1 - SEC-009 source: reauth middleware rejects missing grant
ok 2 - SEC-009 source: Super Admin MFA is policy-gated at login and middleware
ok 3 - SEC-009 Go: missing reauth grant rejected
ok 4 - SEC-009 Go: Super Admin without MFA rejected when policy ON
# pass 4
# fail 0
```

```text
go test -count=1 -run "TestSEC009|TestSuperAdminMFAAssurance" ./packages/auth/
ok  github.com/Parsaeffatravesh/tragge/packages/auth
```

## Explicitly NOT verified

- Full postgres/redis SEC-004/SEC-007 integration suites in this session (`SEC004_POSTGRES_DSN` not set; those tests skip).
- Live GitHub Actions run (no PAT).
- Stale SEC-004 structural string check (`Super Admin password verification establishes only the first factor`) — out of scope; see discovered-issues.

## Questions resolved

- Gate Super Admin MFA on `admin_mfa_enabled` policy flag (ON reject empty; OFF allow). Implemented.
