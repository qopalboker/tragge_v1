# Telegram bot token Admin settings — decision log

## 2026-08-25 — Regression root cause

**Symptom:** Mini App auth HTTP 503 `telegram_auth_unavailable` with initData present.

**Cause:** `user-bff` builds `telegramVerifier` only when `secrets.Load("TELEGRAM_BOT_TOKEN")` is non-empty. Compose historically exposed only empty `${TELEGRAM_BOT_TOKEN:-}` / `${TELEGRAM_BOT_TOKEN_FILE:-}` and did **not** mount `telegram_bot_token` as a Docker secret (unlike JWT/etc.). Local `telegram_bot_token.txt` was empty and no `.env` was present. This is fail-closed by design (no signature bypass).

**Why it worked before:** Operators had a non-empty `TELEGRAM_BOT_TOKEN` in shell/env for the session. After env reset / web-only stacks, verifier stays nil → 503.

## Product choices

| Topic | Choice |
|---|---|
| Signature validation | Never bypass; HMAC still required |
| Admin DB vs env | **Admin encrypted DB token wins** over env/file |
| Encryption | `enc:system:v1:` AES-GCM; key from `SYSTEM_SETTINGS_ENCRYPTION_KEY` or fallback `ADMIN_MFA_ENCRYPTION_KEY` |
| Hot reload | Redis pubsub `system:telegram_bot_token:reload` + atomic verifier pointer |
| Compose | Mount `/run/secrets/telegram_bot_token` as fallback for ops |
| MFA UI | Remains on System Security page (existing machinery); Telegram section added alongside |
