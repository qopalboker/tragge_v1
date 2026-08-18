# Telegram Mini App — `telegram_bridge_absent` forensic + CSP fix — 2026-08-18

## Launch mode (Task 1)

Operator-confirmed BotFather configuration:

- **Main Mini App** launch (not “opened outside Telegram” browser)
- Canonical Mini App URL remains: `https://panel.tragge.com/miniapp/home`
- URL was **not** changed as part of this fix

---

## Root cause of `bridge: no` / `code: telegram_bridge_absent`

Inside the real Telegram WebView, `window.Telegram.WebApp` was absent because the official script:

```text
https://telegram.org/js/telegram-web-app.js
```

was **blocked by Content-Security-Policy**.

Live response for `https://panel.tragge.com/miniapp/home` previously allowed only:

```text
script-src 'self' https://widget.arcaptcha.co
```

So the WebView could not execute Telegram’s bridge script → `window.Telegram` never appeared → frontend reported `telegram_bridge_absent` **before** any HMAC / `POST /api/user/auth/telegram`.

This is **not** “user opened Chrome”. It is a CSP allow-list miss for Telegram’s official script host.

---

## HTML / script loading (Tasks 2, 6)

Served HTML head contains (production bundle verified):

```html
<script src="https://telegram.org/js/telegram-web-app.js"></script>
```

Bundle markers after rebuild:

- `index.html` → `telegram-web-app.js`
- hashed app JS → `waitForSignedInitData`, `telegramScriptLoaded`

No duplicate dynamic injection path required; script is static in `apps/user-frontend/index.html`.

---

## CSP / security headers (Task 5)

After fix, both FE nginx and gateway emit CSP including Telegram:

```text
script-src 'self' https://widget.arcaptcha.co https://telegram.org
```

Other headers observed (unchanged policy intent):

| Header | Value |
|--------|--------|
| Cross-Origin-Embedder-Policy | credentialless |
| Cross-Origin-Opener-Policy | same-origin |
| X-Frame-Options | DENY |
| frame-ancestors | 'none' |

Notes:

- Mini App loads as the WebView **top-level document**, so `X-Frame-Options: DENY` / `frame-ancestors 'none'` do not block Telegram’s WebView navigation.
- `COEP: credentialless` allows classic cross-origin script tags without credentials; CSP was the blocker, not COEP.
- Security was **not** globally weakened (no `script-src *`, no CSP removal).

Patched configs:

- `apps/user-frontend/nginx.conf`
- `apps/gateway/nginx.conf`
- `apps/gateway/nginx.prod.conf`

Deployment required **image rebuild** of `user-frontend` (+ gateway recreate). Force-recreate alone is insufficient for nginx.conf baked into the image.

---

## Initialization order (Task 3)

Required sequence (now enforced in frontend):

```text
HTML
→ telegram-web-app.js loads (script readiness)
→ window.Telegram.WebApp exists
→ WebApp.initData becomes non-empty
→ POST /api/user/auth/telegram
→ JWT/session
→ /miniapp/home
```

`waitForSignedInitData()`:

- waits for script readiness via script `load`/`error` + `requestAnimationFrame`
- then polls bridge/initData with rAF budget
- **no `setTimeout` delays**

Normal browser visiting `/miniapp/*` without Telegram UA/bridge continues on **normal web auth** (no forced Telegram error page).

---

## Safe diagnostics (Task 4)

Error page / store now expose only:

- `telegramScriptLoaded`
- `telegramObjectPresent`
- `webAppObjectPresent`
- `webAppVersion`
- `platform`
- `isExpanded`
- `initDataPresent` (+ length only)

Never logged: raw initData, bot token, JWT, cookies, secrets.

---

## Auth logic (Task 8)

`POST /api/user/auth/telegram` HMAC path was **not** rewritten for this bug.

Current failure mode before CSP fix was pre-HMAC (`bridge=no`, `initData=no`).

---

## Remaining operator blocker for full Mini App PASS

Live api-server still has:

```text
TELEGRAM_BOT_TOKEN=set len=0
secret_file=absent
```

After CSP fix, real Telegram should get `bridge=yes` / `initData=yes`, but HMAC exchange will fail until a **real BotFather token** is set in gitignored runtime env and `api-server` is recreated:

```powershell
# infra/docker/.env.tunnel (gitignored)
TELEGRAM_BOT_TOKEN=<numeric_id>:<secret_from_BotFather>

docker compose -f infra/docker/docker-compose.yml -f infra/docker/docker-compose.lite.yml `
  --env-file infra/docker/.env.tunnel --profile app `
  up -d --force-recreate --no-deps api-server
```

---

## Acceptance status

| Check | Status |
|-------|--------|
| BotFather Main Mini App launch mode recorded | PASS |
| HTML contains official Telegram script | PASS |
| CSP allows `https://telegram.org` on live panel | PASS |
| Deterministic script/bridge readiness (no setTimeout) | PASS |
| Safe diagnostics fields | PASS |
| Normal browser still uses web auth | PASS |
| Real Telegram mobile: bridge=yes, initData=yes, auth 200, `/miniapp/home` dashboard | **PENDING operator token + phone retest** |

### Decision for bridge-absent CSP defect

**TELEGRAM BRIDGE CSP — PASS (deployed)**

### Decision for end-to-end Mini App auth

**TELEGRAM MINI APP E2E — BLOCKED on empty `TELEGRAM_BOT_TOKEN`** until BotFather token is applied and retested from the real Telegram mobile app.
