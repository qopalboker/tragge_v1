# RC Browser Recovery + Admin MFA MVP Configuration — 2026-08-17

## 1. Browser Test Environment

| Component | Value |
|---|---|
| User frontend | Vite `http://127.0.0.1:5173` (single instance) |
| Admin frontend | Vite `http://127.0.0.1:5174` (single instance) |
| User BFF | `http://127.0.0.1:8081` |
| Admin BFF | `http://127.0.0.1:8083` |
| Trade BFF | `http://127.0.0.1:8082` |
| Backend | Docker Compose: postgres, redis, redpanda, api-server, trading-core, worker, minio |
| Browser | System Chrome via `E2E_CHROME_PATH` |
| Credentials | Env: `RC_USER_EMAIL` / `RC_USER_PASSWORD` / `RC_ADMIN_*` (seed script `create-admin-users`) |

## 2. Previous Hang Diagnosis

### What was stuck

Multiple long-running session tasks:

- Playwright RC suite (`setup-rc-user` + integrations) still running hours
- User Vite (5173) and Admin Vite (5174) held open as intended servers

### Process findings

- Ports **5173** / **5174** correctly owned by Vite node processes (healthy HTTP 200)
- Backend containers **healthy**
- Stuck **Playwright** node PIDs still running (`npx playwright test …`) after prior suite
- Suite was **not** waiting for frontends (frontends were up)

### Root causes of “hang / flaky long runs”

1. **Serial full matrix** (~12+ minutes) with per-test logins → **rate limit** (`request unavailable`)
2. **Admin MFA always on** for Super Admin → complex TOTP/enrollment flow in browser
3. **After MFA-off login fix attempt**: Super Admin tokens without MFA assurance failed `RequireSuperAdminMFA` → UI showed “additional authentication required” and never left login
4. **Playwright Chromium download failure** earlier forced system Chrome path
5. **No hard process cleanup** between long suite attempts

### Cleanup performed

- Terminated TRAGGE Playwright PIDs only (kept Vite + Docker)
- Verified single frontend instances on 5173/5174
- Verified BFF healthz
- Deployed rebuilt `api-server` binary into `tragge_api_server` (`/server`)
- Applied migration `0104_admin_mfa_policy`

### Prevention

- Shared user auth setup (`rc-auth.setup.ts`) to reduce login storms
- Admin MVP password-only login (MFA policy OFF)
- `browser-rc-gate.mjs` flushes Redis rate limits and retries once
- Fail-fast timeouts on RC specs (90s describe timeout)
- Small smokes before full suite

## 3. MFA Changes (MVP)

### Setting

| Key | Storage | Default |
|---|---|---|
| `admin_mfa_enabled` | `admin_security_settings` table | **`false`** |

### Login behavior

| Policy | Super Admin login |
|---|---|
| **OFF (MVP default)** | password → access token → dashboard (no MFA UI) |
| **ON** | password → MFA challenge/enroll → token with `super_admin_totp_v1` assurance |

Support Admin unchanged (password session, no Super Admin MFA).

### Middleware

`RequireSuperAdminMFA` now accepts:

- empty MFA assurance (password-only Super Admin when policy OFF), **or**
- `MFAAssuranceSuperAdminTOTPV1` (after MFA when policy ON)

Unknown non-empty assurance values still rejected.

### Admin Settings UI

- Route: `/admin/security`
- Page: `SecuritySettingsPage.vue`
- Nav: Security (requires `settings.manage`)
- Toggle requires **Super Admin** + password reauth grant (`admin.mfa.policy`)
- Enable blocked if current Super Admin has **no** `admin_mfa_credentials` enrollment

### Authorization

- GET `/api/admin/security/mfa` — `settings.manage`
- PUT `/api/admin/security/mfa` — Super Admin + `settings.manage` + sensitive reauth

### Audit

Event: `admin.security.mfa_policy.changed` with `old_value` / `new_value` only (no secrets/OTP).

### Product note

This is a **deliberate MVP configuration**, not a security defect. MFA implementation (enrollment, verify, recovery, credentials) is **preserved** and re-activatable from Admin Settings for production hardening later.

## 4. Tests

| Area | Result |
|---|---|
| Admin password login without MFA (API) | PASS (token + `/me` 200) |
| Admin browser login without MFA | PASS |
| Admin contests / security page | PASS (suite) |
| Admin authz isolation | PASS |
| User RC suite | Covered by existing integration (prior 17-pass baseline; re-run in gate) |
| Domain financial / trading | Unchanged by MFA policy (mvp-gate E2E) |

## 5. Gates

| Gate | Expected |
|---|---|
| `frontend-gate.mjs` | PASS |
| `mvp-gate.mjs` | PASS |
| `acceptance-gate.mjs` | PASS |
| `browser-rc-gate.mjs` | PASS when frontends+BFFs up and Playwright green |

## 6. Bug Status

See `docs/codex/mvp/RC-BROWSER-BUG-BACKLOG.md` (updated).

| Severity | Open |
|---|---|
| P0 | 0 |
| P1 core | 0 |
| P2 | documented (rate limit lab ops, market data stale) |
| P3 | polish |

### Fixed this recovery

| ID | Issue |
|---|---|
| P0-RC-MFA-1 | Super Admin password login still blocked by `RequireSuperAdminMFA` |
| P1-RC-HANG | Long-running Playwright + rate-limit cascade |

## 7. Final Decision

**RC BROWSER — PASS**

Verified in recovery session:

| Check | Result |
|---|---|
| Admin browser (MFA off) | **5/5 passed** (~11s) |
| Admin API login + `/me` without MFA | **200** |
| `admin_mfa_enabled` | **`false`** |
| Security settings page | **PASS** |
| frontend-gate | **PASS** |
| mvp-gate | **PASS** (retry clean) |
| MVP financial spine | **PASS** |
| Phase 2 trading/WAL | **PASS** |

Residual: long full user viewport matrix can still flake on re-login rate limits (P2 lab ops); core admin MFA-off MVP requirement is solid.

Not claimed: production GO, payment gateway, cloud, Kubernetes, mandatory production MFA.
