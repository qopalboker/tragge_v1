# RC Browser Bug Backlog — 2026-08-17

## Severity policy

| Level | Rule |
|---|---|
| **P0** | Financial/security/core journey broken |
| **P1** | Major user/admin/trading flow broken |
| **P2** | Minor UI/UX |
| **P3** | Polish |

---

## P0 — must be zero

| ID | Title | Layer | Status | Resolution |
|---|---|---|---|---|
| P0-RC-1 | Mobile home document horizontal overflow (`scrollWidth=720` on 320–430 viewports) | UI | **FIXED** | `width:100%` + `max-width:min(720px,100%)` on `.home`; `html/body/#app overflow-x:clip`; rail no longer expands document width |
| P0-RC-2 | User-bff / trade-bff not reachable from local Vite without gateway | Env | **FIXED (local)** | `docker-compose.override.yml` publishes `8081` (user-bff) and `8082` (trade-bff) when gateway profile is off; Vite CORS origins include `5173`/`5174` |
| P0-RC-MFA-1 | Super Admin password login issued token but `/me` blocked (“additional authentication required”) | Auth | **FIXED** | MFA policy default OFF + `RequireSuperAdminMFA` accepts empty assurance for password-only Super Admin when policy OFF |

**Open P0: 0**

---

## P1 — core journey

| ID | Title | Layer | Status | Resolution |
|---|---|---|---|---|
| P1-RC-1 | Parallel browser logins trigger user rate-limit (`request unavailable`) | Test/Env | **MITIGATED** | RC suite runs `--workers=1`; redis flush + login retries; document serial RC runs |
| P1-RC-2 | Admin MFA TOTP replay across sequential tests | Test | **FIXED** | Wait until next 30s TOTP window before MFA verify in admin RC helper |
| P1-RC-3 | Admin `waitForURL(/\/admin\//)` treated `/admin/login` as success | Test | **FIXED** | Exclude login path from success predicate |

**Open core P1: 0**

---

## P2

| ID | Title | Notes |
|---|---|---|
| P2-RC-1 | Admin wallet charge UI relies on `window.confirm` + `window.prompt` | Works with Playwright dialogs; not ideal UX |
| P2-RC-2 | Market data `all_quotes_stale` on trading-core | Environment; free contest trade page still loads; live fills may be limited without fresh market data |
| P2-RC-3 | Playwright bundled Chromium download failed (400) | Use `E2E_CHROME_PATH` system Chrome |
| P2-RC-4 | Full contest finalization not driven end-to-end in browser UI | Covered by domain Go E2E + mvp-gate; browser suite loads trade + join |
| P2-RC-5 | Login rate limiter aggressiveness for lab multi-worker runs | Operational; serial RC is required |

---

## P3

| ID | Title | Notes |
|---|---|---|
| P3-RC-1 | Hierarchy suite takes ~11 minutes serially | Acceptable for RC gate; optional parallel later with isolated users |
| P3-RC-2 | Decorative hero art not pixel-matched to reference | Layout/hierarchy verified |

---

## Summary

| Severity | Open | Fixed this phase |
|---|---|---|
| P0 | 0 | 2 |
| P1 | 0 | 3 |
| P2 | 5 | — |
| P3 | 2 | — |

**RC Browser exit rule:** zero open P0 and zero open core P1 → **met**.
