# Telegram bot token — Admin System Settings + safe auth

**Branch:** `codex/telegram-bot-token-admin-settings`  
**Date:** 2026-08-25

## Changes

- Migration `0115_system_encrypted_settings`
- Admin `/api/admin/security/telegram` GET/PUT/DELETE/POST test (Super Admin + reauth)
- user-bff: DB-wins token resolution, atomic verifier reload
- Compose secret mount for `telegram_bot_token`
- Security Settings UI: Telegram section + existing MFA controls

## Tests

```text
node --test scripts/sec-telegram-admin-settings.test.mjs
go test ./packages/auth -run TestSystemSecret
go test ./apps/user-bff/server -run 'TestHandleTelegramMiniAppAuth|TestIsPlaceholder'
go test ./apps/admin-bff/server -run 'TestMaskAndPlaceholder|TestGetTelegram|TestPutTelegram'
```

## NOT verified

- Live BotFather getMe against production Telegram
- End-to-end Mini App login in Telegram client with Admin-rotated token
