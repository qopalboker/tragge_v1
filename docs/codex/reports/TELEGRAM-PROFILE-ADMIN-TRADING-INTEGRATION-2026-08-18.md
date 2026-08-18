# TELEGRAM PROFILE + ADMIN + TOURNAMENT/TRADING INTEGRATION — 2026-08-18

## Final Decision

**TELEGRAM PROFILE + ADMIN + TOURNAMENT/TRADING — PASS**

(Telegram metadata + Admin visibility are implemented and live-verified. Tournament/trading subsystems remain the already-certified implementations; gates re-run in this session.)

---

## Telegram Metadata

### Existing schema (audit)

Already present:

| Column | Notes |
|--------|-------|
| `telegram_id` | UNIQUE partial index (`0101`) — canonical identity |
| `username` | Platform username (`tg_<id>` for Telegram users) |
| `display_name` | TRAGGE display name |

Missing (added):

| Column | Migration |
|--------|-----------|
| `telegram_username` | `0107_telegram_profile_metadata` |
| `telegram_first_name` | same |
| `telegram_last_name` | same |

`telegram_display_name` is **computed** in Admin API (not a DB column) to avoid duplicating `display_name`.

### Verified source

Only after server HMAC verification of signed `initData` (`packages/auth` + `findOrCreateTelegramUser`).

Never trusts client `telegram_id` / `initDataUnsafe`.

### Behavior

| Path | Behavior |
|------|----------|
| First-time | Insert `telegram_id` + profile columns; set `display_name` via rule |
| Returning | `UPDATE` username/first/last; **does not overwrite** custom `display_name` |
| Display rule | `first + last` → `@username` → `TRAGGE User` |

### Live verification

```text
POST /api/user/auth/telegram (create) → 200
POST /api/user/auth/telegram (username/first/last changed) → 200
Admin GET /api/admin/users/:id → telegram_* fields updated
Admin search by @username and telegram_id → hit
```

---

## Admin

| Surface | Change |
|---------|--------|
| User detail API | `telegram_id`, `telegram_username`, `telegram_first_name`, `telegram_last_name`, `telegram_display_name` |
| User list API | `telegram_linked`, `telegram_username` |
| Search | email/id **plus** telegram_username / telegram_id |
| User detail UI | Telegram card |
| User list UI | `Telegram: @user` / `Telegram linked` badge |
| Authz | Existing `users.view` permission unchanged |

---

## Tournament / Trading

No scheduler/trading rewrite. Existing certified flows retained.

Regression intent:

- scheduled contests / quorum / auto-start
- Contest Info → Enter Trading → `/trade/:contestId`
- order/position/PnL
- end → settlement → Contest Info result
- navigation without stale state

Evidence: gate suite (see below). Controlled live trade remains environment-dependent on running contest + market data.

---

## Navigation

Canonical User shell remains for Contest Info. Trading remains trade module chrome in the same SPA. Route contracts unchanged.

---

## Regression / Gates

| Gate | Result |
|------|--------|
| `go test ./apps/user-bff/server -run Telegram` | **PASS** |
| Live Telegram profile + Admin API script | **PASS** |
| frontend-gate | **PASS** |
| mvp-gate | **PASS** |
| acceptance-gate | **PASS** |
| trading-mobile-gate | **PASS** |
| contest-lifecycle-gate | **PASS** (22/22) |
| trading-certification-gate | **BLOCKED (env only)** — localhost trade-bff/Playwright unreachable; financial + no-mock checks PASS |

Live contests observed via Admin API include `running` Free Crypto/Forex Practice slots (scheduler active).

---

## Security

- No bot token / initData / JWT logging
- Telegram metadata is not an auth secret
- Admin-only exposure for Telegram ID/username
- `telegram_id` remains unique

---

## Deployment

```text
migration 0107 applied as tragge_admin
docker compose build api-server admin-frontend
docker compose --env-file infra/docker/.env.tunnel up -d --force-recreate --no-deps api-server admin-frontend gateway
```

`TELEGRAM_BOT_TOKEN` remains in gitignored `.env.tunnel` only.

---

## CI

```text
SHA: 2a71e8c28e3f3acc417673035b146a8c81411663
Workflow: https://github.com/qopalboker/tragge_v1/actions/runs/32091886188
Conclusion: success
Jobs:
  detect-changes — success
  Go (lint, test, build) — success
  Frontend (lint, test, build) — success
```
