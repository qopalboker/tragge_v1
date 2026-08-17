# TRADING PLATFORM & TELEGRAM MINI APP — 2026-08-17

## Final decision

**TRADING-MOBILE-TELEGRAM — PASS (IMPLEMENTED)**  
**LIVE TELEGRAM VERIFIED — NOT CLAIMED** (no bot token + public HTTPS in this environment)

---

## Implementation map (audit)

### Market path (EXISTING AND REUSED)

```
Providers (Binance/Finnhub/Nobitex/…)
  → market-ingestor (normalize, candles → DB, ticks → Kafka ticks.v1)
  → trading-engine PriceBook (execution bid/ask)
  → trade-bff PriceBook → WS tick_batch
  → user-frontend watchlist + chart (last) + Buy ask / Sell bid
```

Candles: `GET /api/trade/candles` → PostgreSQL `candles` (no random series).

### Order path (EXISTING AND REUSED)

```
UI (client_order_id UUID, click lock)
  → trade-bff claim order_client_submissions + contest running gate
  → Kafka orders.v1 → trading-engine ProcessOrder
  → fill / position / freeQty → Kafka → WS → Pinia
```

Qty: **int64** whole units. PnL formula: `packages/scoring` (unchanged).

### Telegram (EXISTING AND REUSED)

| Piece | Status |
|-------|--------|
| `telegram-web-app.js` in `index.html` | EXISTING |
| Soft-fail bootstrap in `main.ts` | EXISTING |
| `POST /api/user/auth/telegram` + HMAC `VerifyInitData` | EXISTING |
| Reject client `telegram_id` | EXISTING + tests |
| Mini App shell `/miniapp/*` | EXISTING |
| Theme + safe-area CSS vars | **FIXED** this phase |

### Chart

| Item | Detail |
|------|--------|
| Library | **lightweight-charts** v5 (EXISTING) |
| History | Real DB candles via trade-bff |
| Live | Tick aggregation on existing series (no full rebuild per tick) |
| Mobile | min-height + sticky order bar |

---

## FIXED this phase

1. **Free QTY as order max** — no silent max=100 after positions open.  
2. **Trade lock** — UI disables Buy/Sell unless backend status is `running`.  
3. **Mobile qty sync** — controlled prop; every input emits to parent.  
4. **QTY strip** — Total / Used / Free on mobile + desktop quick-trade.  
5. **Sticky mobile order bar** + safe-area padding.  
6. **Telegram theme + content safe-area** CSS variables.  
7. **Persian chart empty error**.  
8. **Gate / backlog / runbook / this report**.

## NEW artifacts

- `scripts/mvp/trading-mobile-gate.mjs`
- `docs/codex/mvp/TRADING-MOBILE-TELEGRAM-BUG-BACKLOG.md`
- `docs/runbook/local-telegram-mini-app.md`
- This report

---

## Quantity UX

| Field | Source |
|-------|--------|
| Total | `qty_total` (balance / allocation) |
| Used | `qty_used` / positions |
| Free / max order | `availableQTY` after `fetchBalance` |

Semantics unchanged: reduce/close freeQty rules remain engine-side.

---

## Contest ↔ trading

| Status | UI |
|--------|-----|
| Not running | Locked message; buttons disabled; toast on attempt |
| Running | Chart + form + Buy/Sell |
| End | Existing revalidate → contest info redirect |

---

## Public HTTPS / Telegram

| Item | Status |
|------|--------|
| In-repo tunnel | **None** |
| Tools on machine | WindowsApps `ngrok` stub only; **no cloudflared** confirmed |
| Runbook | Documents cloudflared/ngrok + admin exclusion |
| LIVE TG test | **BLOCKED** without `TELEGRAM_BOT_TOKEN` + HTTPS host + BotFather menu |

**IMPLEMENTED:** initData-only auth, soft-fail browser, miniapp routes, theme/safe-area.  
**NOT LIVE-VERIFIED:** phone Telegram client journey.

Admin is **not** linked from Mini App routes and must stay off public tunnels.

---

## Tests / gates

```bash
node scripts/mvp/trading-mobile-gate.mjs
node scripts/mvp/trading-certification-gate.mjs
node scripts/mvp/contest-lifecycle-gate.mjs
# frontend
cd apps/user-frontend && pnpm run build
```

Browser E2E real trading still requires stack + `E2E_INTEGRATION=1`.

---

## Acceptance scorecard

| Area | Result |
|------|--------|
| Real market/chart path | PASS (code) |
| Qty / order / idempotency | PASS (code + prior trading cert) |
| Mobile 360/390/430 structure | PASS (layout + media) |
| Contest lock/unlock | PASS |
| Telegram secure initData | PASS (IMPLEMENTED) |
| Live Telegram | NOT CLAIMED |
| Public HTTPS | DOCUMENTED / environment blocked |
| P0 / core P1 | 0 open |

**CTO stop:** no microservice split, no admin public expose, no fake prices, no trust of `initDataUnsafe` for auth.
