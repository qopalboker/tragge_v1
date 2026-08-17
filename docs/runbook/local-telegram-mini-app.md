# Local / Staging Telegram Mini App (HTTPS)

## Goal

Expose only the **user + trading web surface** over **HTTPS** so Telegram can launch the Mini App.

## Do NOT expose

| Surface | Reason |
|---------|--------|
| `/admin` and admin Vite port | Admin is private; never Mini App |
| PostgreSQL / Redis / Redpanda | Internal data plane |
| Direct `trading-engine` / BFF raw ports without gateway | Prefer single SPA origin + reverse proxy |

## Preferred public surface

```text
https://<public-host>/          → user-frontend (includes /user, /trade/:id, /miniapp/*)
https://<public-host>/api/user  → user-bff
https://<public-host>/api/trade → trade-bff
```

Admin remains on a private host/port (e.g. `localhost:5174`).

## Tunnel options (local machine)

### Cloudflare Tunnel (`cloudflared`)

If `cloudflared` is installed:

```bash
# Example: forward public HTTPS to local Vite user-frontend
cloudflared tunnel --url http://127.0.0.1:5173
```

Then reverse-proxy API paths on the same origin in Vite `server.proxy` (already typical for local) so the Mini App origin matches cookies/JWT.

### ngrok

If a real ngrok client is installed and authenticated:

```bash
ngrok http 5173
```

**Windows note:** `C:\Users\…\WindowsApps\ngrok.exe` may be a Store stub without a working tunnel. Prefer a real install or cloudflared.

## Environment

| Variable | Purpose |
|----------|---------|
| `TELEGRAM_BOT_TOKEN` | user-bff HMAC verification of `initData` (required for TG login) |
| `VITE_API_BASE_URL` | Same-origin `/api` preferred in Mini App |

## BotFather (external; not completed by this repo)

1. Create bot → **Bot Settings → Menu Button → Configure** → set HTTPS Mini App URL.
2. Optional: Direct Mini App link (`t.me/bot/app?startapp=…`) per Telegram docs.

Repository **implements** initData exchange and Mini App shell. **LIVE TELEGRAM VERIFIED** requires a real bot token + HTTPS URL + phone Telegram client.

## Auth model (implemented)

```text
Telegram WebApp.initData (signed)
  → POST /api/user/auth/telegram { init_data }
  → user-bff HMAC verify (packages/auth TelegramWebAppVerifier)
  → reject client-supplied telegram_id
  → issue User JWT + refresh cookie
  → /miniapp/home or /trade/:contestId
```

Normal browser continues to work without Telegram script features.

## Status legend

| Claim | Meaning |
|-------|---------|
| **IMPLEMENTED** | Code paths exist in monorepo |
| **LIVE TELEGRAM VERIFIED** | Tested inside Telegram client with real bot + HTTPS |
