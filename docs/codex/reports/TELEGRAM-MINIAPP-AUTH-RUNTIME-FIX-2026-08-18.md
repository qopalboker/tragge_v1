# Telegram Mini App auth runtime fix — 2026-08-18

## Root causes (exact)

### 1. Server HMAC key was a lab fixture (primary)

Live `api-server` had:

```text
TELEGRAM_BOT_TOKEN=123456:TRAGGE-LIVE-E2E-BOT-TOKEN-NOT-PROD
```

Real Telegram clients sign `initData` with the **BotFather** secret.  
Verification with the E2E fixture always fails → `401 telegram_auth_invalid` → frontend error page.

Automated tests passed earlier because they signed with the **same** fixture key.

### 2. Retry was a no-op (secondary)

`TelegramAuthErrorPage` Retry:

- returned silently when `!isTelegramMiniApp()` or empty initData;
- did not surface HTTP status/code;
- did not re-enter a dedicated retry path (bootstrap was `createBootstrap`-memoized).

### 3. Empty initData treated as immediate terminal failure (tertiary)

Bootstrap read `initData` once. If the WebApp bridge was not bound yet, it set `telegram_initdata_missing` without a readiness wait.

### 4. Username uniqueness (latent 500 after HMAC success)

`findOrCreateTelegramUser` used Telegram `@username` as `users.username`.  
Collisions with existing rows produced `idx_users_username` unique violations (seen in logs).

---

## Fixes

| Area | Change |
|------|--------|
| `telegram.ts` | `waitForSignedInitData()` via `requestAnimationFrame` budget; bridge vs initData phases; safe diagnostics |
| `auth.ts` | Wait for initData before terminal error; `retryTelegramAuth()` (not memoized); inflight dedup; diagnostics (no secrets) |
| `TelegramAuthErrorPage.vue` | Real Retry → `retryTelegramAuth()`; shows bridge/initData/HTTP/code/phase/retries |
| `telegram_auth.go` | Username always `tg_<id>`; reject placeholder bot tokens so real Mini App is not verified with fixtures |
| Runtime env | Removed fake `TELEGRAM_BOT_TOKEN` from `.env.tunnel` |

---

## Operator requirement (real Telegram)

Set the **real** BotFather token before reopening the Mini App:

```powershell
# gitignored
# infra/docker/.env.tunnel
TELEGRAM_BOT_TOKEN=<numeric_id>:<secret_from_BotFather>

docker compose -f infra/docker/docker-compose.yml -f infra/docker/docker-compose.lite.yml `
  --env-file infra/docker/.env.tunnel --profile app `
  up -d --force-recreate --no-deps api-server
```

Without a real token the API correctly returns **`503 telegram_auth_unavailable`** (clear on error page), not a silent HMAC mismatch.

---

## Expected happy path after token is set

```text
Telegram open → wait initData → POST /api/user/auth/telegram
  → 200 + Set-Cookie + JWT
  → GET /api/user/me
  → /miniapp/home (canonical User Dashboard)
```

Retry re-reads initData and re-POSTs without full page reload.

---

## CORS (verified host-side)

`OPTIONS /api/user/auth/telegram` with `Origin: https://panel.tragge.com` → **204** +  
`Access-Control-Allow-Origin: https://panel.tragge.com` + `credentials: true`.

---

## Tests

- Go: placeholder token + untrusted/forged initData handlers — PASS  
- Vitest: bootstrap contracts + telegram readiness source contracts — PASS  
- user-frontend production build — PASS  

Live BotFather open requires the real token on the host (not committed).
