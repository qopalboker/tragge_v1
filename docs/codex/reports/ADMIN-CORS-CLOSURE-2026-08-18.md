# ADMIN CORS CLOSURE — 2026-08-18

## Root Cause

`https://manage.tragge.com` was rejected by **api-server CORS middleware** on the Admin edge context because runtime `ADMIN_CORS_ALLOWED_ORIGINS` (and related allow-lists) did not include the canonical public Admin origin.

Failure signature:

```text
Origin: https://manage.tragge.com
→ 403
→ {"error":"cors_origin_denied","code":"CORS_ORIGIN_DENIED"}
```

Layer that rejected: **api-server** (`ADMIN_CORS_ALLOWED_ORIGINS` / Admin BFF CORS), not Cloudflare, not the gateway rewrite, and not Admin MFA.

Admin MFA was not involved (`admin_mfa_enabled=false`).

---

## Request path (verified)

```text
https://manage.tragge.com
→ Cloudflare
→ cloudflared / tunnel
→ gateway (admin entry / :8081 surface)
→ api-server Admin handlers (/api/admin/*)
```

- Public hostname: `manage.tragge.com`
- Admin frontend uses same-origin relative `/api/admin/*` through the gateway
- CORS is enforced in api-server (exact origin allow-list; credentials allowed; no wildcard)

---

## Runtime Configuration

Applied via gitignored `infra/docker/.env.tunnel` (no secrets committed; no hardcoded domain in Go/Vue source):

```text
ALLOWED_ORIGINS=...,https://panel.tragge.com,https://manage.tragge.com
ADMIN_CORS_ALLOWED_ORIGINS=http://127.0.0.1:8081,http://localhost:8081,http://127.0.0.1:5174,http://localhost:5174,https://manage.tragge.com
ADMIN_FRONTEND_ORIGIN=https://manage.tragge.com
USER_CORS_ALLOWED_ORIGINS=...,https://panel.tragge.com
PAYMENT_CORS_ALLOWED_ORIGINS=...,https://panel.tragge.com
TRADE_CORS_ALLOWED_ORIGINS=...,https://panel.tragge.com
```

Regression helper: `scripts/mvp/reapply-tunnel-cors.ps1` also seeds `https://manage.tragge.com` into Admin CORS.

Automated unit coverage:

- `TestAdminCORSAllowsCanonicalManageOriginWhenConfigured` in `packages/validation/edge_security_test.go`
  - manage origin → allowed
  - `https://evil.example` → denied
  - manage origin not accepted on User CORS surface
  - no `*`

---

## Deployment

| Change | Rebuild needed? | What ran |
|--------|-----------------|----------|
| Admin CORS env only | No image rebuild for CORS logic | `docker compose ... --env-file infra/docker/.env.tunnel up -d --force-recreate --no-deps api-server user-frontend gateway` |
| CSP `https://telegram.org` (User Mini App, parallel) | Yes — nginx.conf in image | `docker compose build user-frontend` (+ gateway recreate to serve updated assets/headers) |

Lesson retained from MFA incident: `--force-recreate` alone does **not** bake source/nginx changes into an image.

Live container env confirmed:

```text
ADMIN_CORS_ALLOWED_ORIGINS=...https://manage.tragge.com
ADMIN_FRONTEND_ORIGIN=https://manage.tragge.com
```

---

## Verification

### OPTIONS `/api/admin/auth/login`

```text
Origin: https://manage.tragge.com
→ HTTP/1.1 204 No Content
Access-Control-Allow-Origin: https://manage.tragge.com
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET, POST, PUT, PATCH, DELETE, OPTIONS
```

### POST `/api/admin/auth/login`

```text
Origin: https://manage.tragge.com
→ HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://manage.tragge.com
Access-Control-Allow-Credentials: true
→ access_token + admin refresh cookie (no MFA challenge)
```

### GET `/api/admin/me`

```text
Origin: https://manage.tragge.com
Authorization: Bearer <access_token>
→ HTTP/1.1 200 OK
Access-Control-Allow-Origin: https://manage.tragge.com
→ super_admin identity payload
```

### Evil origin

```text
Origin: https://evil.example
POST /api/admin/auth/login
→ HTTP/1.1 403 Forbidden
→ CORS_ORIGIN_DENIED
→ no Access-Control-Allow-Origin reflection / no wildcard
```

### Browser (real Chromium/Edge channel)

```text
https://manage.tragge.com/admin/login
→ POST /api/admin/auth/login 200 (ACAO=https://manage.tragge.com)
→ GET /api/admin/me 200 (SPA bootstrap)
→ /admin/dashboard
→ /admin/contests
```

Observed:

- no CORS denial
- MFA fields = 0 (MVP off)
- dashboard + contests routes render after password login
- evidence screenshots:
  - `docs/codex/reports/evidence/mvp-rc-browser/admin-manage-login-2026-08-18.png`
  - `docs/codex/reports/evidence/mvp-rc-browser/admin-manage-contests-2026-08-18.png`

Note: Playwright bundled Chromium download is geo-blocked on this host; verification used system Edge via Playwright `channel: "msedge"`.

---

## Security

- Exact origin allow-list only (no `*`, no subdomain wildcards)
- Evil origin denied with `CORS_ORIGIN_DENIED`
- Credentials require explicit ACAO match (not `*`)
- User and Admin origin sets remain distinct (manage not accepted on User CORS)

---

## MFA

Confirmed in live DB after recreate:

```text
admin_mfa_enabled|f
```

Successful Admin login remains:

```text
password → admin session → dashboard
```

MFA policy was not modified as a side effect of CORS work.

---

## User Regression

```text
GET  https://panel.tragge.com/api/user/healthz          → 200
OPTIONS https://panel.tragge.com/api/user/auth/telegram
  Origin: https://panel.tragge.com                      → 204
```

User/panel CORS allow-list still includes `https://panel.tragge.com` and does not use a shared wildcard with Admin.

---

## Gates

```text
node scripts/mvp/mvp-gate.mjs          → MVP — PASS
node scripts/mvp/frontend-gate.mjs     → FRONTEND — PASS
node scripts/mvp/acceptance-gate.mjs   → MVP STABILIZATION — PASS
go test ./packages/validation -run TestAdminCORSAllowsCanonicalManageOriginWhenConfigured → ok
```

## Final Decision

**ADMIN CORS — PASS**

Verified with:

- live OPTIONS / login / `/me` for `Origin: https://manage.tragge.com`
- evil origin denied
- MFA remains off
- panel.tragge.com User CORS still healthy
- real browser (system Edge) password login → `/admin/dashboard` → `/admin/contests` without CORS errors
