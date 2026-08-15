# Telegram Mini App Authentication

Status: Implemented for SEC-003 (server-side initData verification + User session exchange).

## Authority

This document follows the
[fixed product and technical policies](../product/FIXED_PRODUCT_AND_TECHNICAL_POLICIES.md)
and preserves [SEC-001 User/Admin isolation](user-admin-authentication-isolation.md)
and [SEC-002 URL credential prohibition](session-authentication-url-policy.md).

The first production product surface in repository policy remains the responsive
web app. Telegram Mini App authentication is an additive User-context login path
for Telegram-first MVP deployments.

## Trust model

```
Telegram Mini App
    → presents WebApp initData once
    → POST /api/user/auth/telegram
    → server verifies HMAC signature with bot token
    → server checks auth_date freshness
    → server finds/creates User by verified telegram_id
    → server issues SEC-001 User access token + refresh cookie
    → Mini App uses Authorization: Bearer for API calls
```

The frontend must **never** send `telegram_id`, `user_id`, or admin claims as
identity. Those fields are rejected if present on the auth request.

## Server verification

Package: [`packages/auth/telegram_webapp.go`](../../packages/auth/telegram_webapp.go)

Endpoint: `POST /api/user/auth/telegram` on user-bff

Verification requires:

1. Non-empty `TELEGRAM_BOT_TOKEN` (server-side only; supports `_FILE` via secrets loader)
2. Telegram WebApp `initData` query string
3. HMAC-SHA-256 validation with secret key `HMAC_SHA256("WebAppData", bot_token)`
4. `auth_date` within `TELEGRAM_AUTH_MAX_AGE_SECONDS` (default 300s)
5. Present verified `user.id` (> 0)
6. Optional Redis replay key `telegram:initdata:used:{telegram_id}:{auth_date}`

Failures return HTTP 401 with non-sensitive codes:

- `telegram_auth_invalid`
- `telegram_auth_expired`
- `telegram_auth_replay`

Missing bot token configuration returns HTTP 503 `telegram_auth_unavailable`
from the endpoint; the web product can still start without Telegram.

## Session and isolation

- Issued tokens use the **User** authentication context only.
- Elevated Admin roles (`support_admin`, `super_admin`, legacy admin/moderator)
  cause the Telegram login path to fail closed.
- Refresh cookies remain `refresh_token_user` (SEC-001).
- Admin endpoints continue to reject User tokens (SEC-001).

## Secrets

| Secret | Location | Notes |
| --- | --- | --- |
| `TELEGRAM_BOT_TOKEN` / `TELEGRAM_BOT_TOKEN_FILE` | server env / secret mount | Never ship to frontend, logs, or API responses |
| User JWT secrets | SEC-001 config | Unchanged |

## Identity storage

Migration `0101_telegram_auth` adds nullable unique `users.telegram_id`.

Telegram-only accounts use a synthetic non-delivery email
`tg_{id}@users.telegram.internal` because `users.email` remains NOT NULL UNIQUE
in the current schema.

## Explicit non-goals

- Full Telegram Bot command framework
- Admin Telegram bot commands
- Password reset / email / SMS account recovery redesign
- Plisio gateway (see payment roadmap)
- Replacing the web User/Admin panels
