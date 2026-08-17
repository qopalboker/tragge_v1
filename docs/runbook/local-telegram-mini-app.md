# Local HTTPS tunnel for Telegram Mini App testing

**Not production.** Temporary public HTTPS for phone browser + Telegram Mini App dry-runs.

---

## 1. Local topology (authoritative)

| Surface | Host port | Notes |
|---------|-----------|--------|
| **Public user entry (preferred)** | **8080** | `tragge_gateway` → user SPA + `/api/user` + `/api/trade` + `/ws/*` |
| Admin panel | **8081** | `tragge_gateway` admin vhost — **never tunnel this** |
| Vite user-frontend (optional HMR) | **5173** | Proxies `/api/user`→8081, `/api/trade`→8082, `/ws/trade` |
| Vite admin-frontend | **5174** | Private only |
| user-bff (direct, if published) | 8081 | Conflicts with gateway admin when both published |
| trade-bff (direct, if published) | 8082 | Used by Vite proxy when gateway is off |
| Postgres / Redis / Redpanda | 5432 / 6379 / 9092 | Local infra only — not for tunnel |

### Preferred public entrypoint

```text
Internet (phone / Telegram)
        ↓ HTTPS
   temporary tunnel
        ↓ HTTP
  gateway :8080
        ├── user-frontend static (SPA: /user, /trade, /miniapp)
        ├── /api/user/*  → user-bff
        ├── /api/trade/* → trade-bff
        └── /ws/trade    → trade-bff
```

**Do not** put `VITE_API_BASE_URL` to a hardcoded tunnel URL. SPA uses **relative** `/api` (`baseURL: ''`), so same-origin through the gateway is correct.

Admin stays on **8081** only; gateway returns **404** for `/admin` and `/api/admin/*` on **8080**.

---

## 2. Start the stack

```powershell
cd D:\Grok\tragge_v0-main\tragge_v0-main
$env:Path = "$env:LOCALAPPDATA\Programs\DockerDesktop\resources\bin;" + $env:Path

# Lite app + frontends + gateway
docker compose -f infra/docker/docker-compose.yml -f infra/docker/docker-compose.lite.yml `
  --profile app --profile frontend up -d
```

Verify locally:

```powershell
curl http://127.0.0.1:8080/
curl http://127.0.0.1:8080/api/user/healthz
curl http://127.0.0.1:8080/api/user/contests
# Admin must NOT be on 8080
curl -i http://127.0.0.1:8080/admin
# Admin only on 8081 (keep private)
curl -i http://127.0.0.1:8081/
```

Seed login (dev only; already exists after seed):

```text
email:    user@tragge.com
password: user123456
```

API state-changing requests need browser-style headers:

```text
X-Requested-With: XMLHttpRequest
Origin: <same origin as the page>
```

---

## 3. Tunnel options

### A) ngrok (preferred when available)

```powershell
ngrok http 8080
```

**Observed on this machine:** ngrok agent fails with:

```text
ERR_NGROK_9040
We do not allow agents to connect to ngrok from your IP address
```

So ngrok cannot be used from the current egress IP until the account/region restriction is lifted.

### B) Cloudflare quick tunnel (optional)

```powershell
# Binary can live at var/cloudflared.exe (not committed)
.\var\cloudflared.exe tunnel --url http://127.0.0.1:8080 --no-autoupdate
```

**Observed:** quick tunnel request timed out (`api.trycloudflare.com` unreachable from this network).

### C) localhost.run SSH tunnel (working fallback)

```powershell
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=20 `
  -R 80:127.0.0.1:8080 nokey@localhost.run
```

Example generated URL pattern:

```text
https://<random>.lhr.life
```

**Active verification URL (temporary — dies when SSH stops):**  
See `var/public-tunnel-url.txt` when a session is running (gitignored).

---

## 4. Allowlist the tunnel origin (required for login)

CSRF/CORS use `ALLOWED_ORIGINS`. After you have `https://….lhr.life`:

```powershell
$public = "https://YOUR-subdomain.lhr.life"
$origins = "http://127.0.0.1:8080,http://localhost:8080,http://127.0.0.1:5173,http://localhost:5173,$public"

@"
ALLOWED_ORIGINS=$origins
USER_CORS_ALLOWED_ORIGINS=$origins
TRADE_CORS_ALLOWED_ORIGINS=$origins
USER_FRONTEND_ORIGIN=$public
TELEGRAM_MINI_APP_URL=$public/miniapp
"@ | Set-Content infra/docker/.env.tunnel -Encoding ascii

docker compose -f infra/docker/docker-compose.yml -f infra/docker/docker-compose.lite.yml `
  --env-file infra/docker/.env.tunnel --profile app `
  up -d --force-recreate --no-deps api-server trading-core
```

Do **not** commit `.env.tunnel` or the live tunnel URL into Git.

Without this step, POSTs from the phone origin fail with `CORS_ORIGIN_DENIED` / CSRF origin errors.

---

## 5. Verified checks (this session)

| Check | Result |
|-------|--------|
| Local gateway SPA + contests API | OK |
| Public HTTPS SPA (`/`, `/user/login`, `/miniapp/home`) | OK |
| Public `/api/user/healthz`, `/api/user/contests` | OK |
| Public login `user@tragge.com` / `user123456` after origin allowlist | OK (JWT returned) |
| Public `/admin`, `/api/admin/*` | **404** (not exposed on 8080) |
| Postgres/Redis via tunnel | Not on gateway path |
| ngrok from this IP | **BLOCKED** (ERR_NGROK_9040) |
| Live Telegram Mini App on phone | **Not claimed** (BotFather + real TG client required) |

---

## 6. Phone browser test (required before Telegram)

On a phone **not** using localhost:

1. Open `https://<tunnel-host>/user/login`
2. Login with seed user
3. Navigate Home → Contests → Contest info → Wallet → Trade route

If login fails with CORS/CSRF, re-apply §4 with the **current** tunnel host.

---

## 7. Telegram Mini App configuration

Repo already implements:

```text
Telegram WebApp.initData
  → POST /api/user/auth/telegram { init_data }
  → HMAC verify (packages/auth)
  → User JWT
```

Never send/trust `initDataUnsafe` for auth.

### BotFather (external)

1. Open [@BotFather](https://t.me/BotFather)
2. Select bot → **Bot Settings** → **Menu Button** → **Configure Menu Button**
3. Set URL:

```text
https://<tunnel-host>/miniapp/home
```

(or `/` — app routes Mini App users to miniapp shell when `initData` is present)

4. Set `TELEGRAM_BOT_TOKEN` only in local secrets / compose env — **never commit**.

### LIVE TELEGRAM VERIFIED

Only claim after:

```text
Telegram app → Menu Button → Mini App
  → initData exchange succeeds
  → Home / Contest / Trade works
```

---

## 8. Lifecycle

| Action | Command |
|--------|---------|
| Start tunnel (localhost.run) | `ssh -R 80:127.0.0.1:8080 nokey@localhost.run` |
| Start tunnel (ngrok, if unblocked) | `ngrok http 8080` |
| Stop tunnel | Ctrl+C / kill SSH or ngrok process |
| After URL changes | Re-run origin allowlist recreate (§4) |
| Stop stack | `docker compose … --profile app --profile frontend down` |

When the tunnel process exits, the public URL returns 503/`no tunnel here`. Expected.

---

## 9. Security checklist

| Target | Expected via public tunnel (8080 only) |
|--------|----------------------------------------|
| `/` user SPA | 200 |
| `/api/user/*` | Proxied user API |
| `/api/trade/*` | Proxied trade API |
| `/admin` | **404** |
| `/api/admin/*` | **404** |
| Host :8081 admin | **Not published** through tunnel |
| :5432 / :6379 / :9092 | **Not** on gateway |

---

## 10. Limitations

1. **Tunnel URL is ephemeral** — changes every restart (localhost.run free tier).  
2. **ngrok blocked** from current IP (ERR_NGROK_9040).  
3. **cloudflared quick tunnel** timed out on this network.  
4. **Origin allowlist** must be updated whenever the public hostname changes.  
5. **Phone / Telegram live UI** must be confirmed by the operator on a real device; this runbook documents the path that was automated on the host.

---

## 11. Decision labels

| Label | Meaning |
|-------|---------|
| **PUBLIC HTTPS PATH WORKS** | Tunnel → gateway 8080 → SPA + user API (verified) |
| **IMPLEMENTED** (Telegram auth) | Server-side initData validation exists |
| **LIVE TELEGRAM VERIFIED** | Requires operator test inside Telegram app |
| **NOT production** | Temporary tunnel only |
