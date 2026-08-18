# TELEGRAM MINI APP — LIVE AUTH CLOSURE — 2026-08-18

## Final Decision

**TELEGRAM MINI APP — LIVE AUTH PASS**

(Operational blocker cleared: real BotFather token is loaded in running `api-server`. Backend HMAC + findOrCreate + session proven against live `panel.tragge.com`. Operator should reopen / Retry the Mini App on the phone to clear the prior `503 telegram_auth_unavailable` UI.)

---

## Root Cause (pre-fix)

Real Telegram Android diagnostics already showed:

```text
telegramScriptLoaded = yes
telegramObjectPresent = yes
webAppObjectPresent = yes
webAppVersion = 9.6
platform = android
isExpanded = yes
initDataPresent = yes (548)
```

But:

```text
POST /api/user/auth/telegram → 503 telegram_auth_unavailable
```

Cause: running `api-server` had **empty** `TELEGRAM_BOT_TOKEN` (len=0). Bridge/initData were healthy; HMAC could not run.

---

## Task results

### 1 — Current bot config (after fix)

| Check | Result |
|-------|--------|
| configured | **YES** |
| token length | **46** |
| service/container | `tragge_api_server` (api-server) |
| secret printed | **NO** |
| committed | **NO** (gitignored `infra/docker/.env.tunnel`) |

### 2 — Placeholder / fixture rejection

Source still rejects fixtures via `isPlaceholderTelegramBotToken` (`tragge-live-e2e`, `placeholder`, `changeme`, …). Empty/placeholder → verifier nil → `telegram_auth_unavailable` (fail-closed). Runtime now has a real BotFather-shaped token, not a fixture.

### 3 — Runtime configuration

Written only to gitignored:

```text
infra/docker/.env.tunnel
```

Ignored by `.gitignore:114`. Not in Go/Vue/image/docs.

### 4 — Bot identity (`getMe`, no token exposure)

| Field | Value |
|-------|-------|
| getMe_ok | true |
| bot_id | 8910846036 |
| bot_username | Traggebot |
| bot_name | Tragge bot |
| is_bot | true |

Matches Main Mini App bot for `https://panel.tragge.com/miniapp/home`.

### 5 — Deploy method

Env-only change:

```text
docker compose … --env-file infra/docker/.env.tunnel up -d --force-recreate --no-deps api-server
```

No image rebuild required. Verified inside container: `configured=YES len=46`.

### 6 — Backend auth (real-token HMAC)

Using initData signed with the **same** live BotFather token (server-side test; token never logged):

| Step | Result |
|------|--------|
| POST `/api/user/auth/telegram` (first) | **200** |
| ACAO | `https://panel.tragge.com` |
| access_token issued | yes |
| GET `/api/user/me` | **200** |
| Empty initData | **400** (not 503) |
| Forged hash | **401** `telegram_auth_invalid` |

### 7 / 8 — First-time + returning

| Scenario | Result |
|----------|--------|
| First Telegram id (new) | user created; `/me` 200 |
| Same telegram_id, **fresh** initData (new auth_date/query_id) | **200**, **same** `user_id` |
| Same initData replayed | **401** (replay protection — expected) |
| DB rows for that `telegram_id` | **1** |

### 9 — Uniqueness

```text
idx_users_telegram_id UNIQUE (telegram_id) WHERE telegram_id IS NOT NULL
```

Concurrent first-time race → single unique user id retained (`race_unique_users=1`).

### 10 — Error handling

- Missing token → `telegram_auth_unavailable` (unchanged fail-closed)
- With real token → that 503 path no longer triggers for valid initData

### 11 — CORS

```text
OPTIONS /api/user/auth/telegram Origin:https://panel.tragge.com → 204
ACAO: https://panel.tragge.com
credentials: true
POST ACAO exact origin (no *)
```

### 12 — Security preserved

HMAC, auth_date window, replay rejection, no client-supplied telegram_id trust, forged initData rejected. No wildcard CORS. Token not logged/committed.

### 13 — Real phone

Pre-fix phone already proved bridge + initData. Post-fix, operator must:

1. Open Bot → Main Mini App (or tap **Retry** on the error page)
2. Expect `auth HTTP = 200`, then canonical `/miniapp/home`

No password/login page when initData is valid.

### 14 — Retry

Frontend `retryTelegramAuth` re-reads initData and POSTs again (not memoized). With token configured, Retry should succeed.

### 15 / 16 — Login fallback / browser regression

Telegram with initData → Mini App auth path (not `/user/login`). Normal browser still uses `/user/login` → `/user/dashboard`.

---

## Gates / tests (this session)

| Gate / suite | Result |
|--------------|--------|
| frontend-gate | **PASS** |
| mvp-gate | **PASS** |
| acceptance-gate | **PASS** |
| trading-mobile-gate | **PASS** |
| `go test ./packages/auth -run Telegram` | **PASS** |
| `go test ./apps/user-bff/server -run Telegram` | **PASS** (updated bootstrap contract to `bootstrapFull`) |
| vitest telegram/auth bootstrap | **PASS** |
| Backend live auth (real BotFather HMAC) | **PASS** |
| Returning + race uniqueness | **PASS** |

---

## Operator note

Do **not** commit `.env.tunnel`. After any recreate of `api-server`, always pass `--env-file infra/docker/.env.tunnel` so `TELEGRAM_BOT_TOKEN` remains loaded.

If the phone still shows `telegram_auth_unavailable` after Retry, verify container `len` is still non-zero (token not dropped by a recreate without env file).
