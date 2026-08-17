# Trading / Mobile / Telegram — Bug Backlog (2026-08-17)

## Severity

| Level | Rule |
|-------|------|
| **P0** | Wrong money/qty/price, false chart series, trade in wrong contest state |
| **P1** | Core trade/mobile/TG journey broken |
| **P2** | Polish |

## P0

| ID | Title | Status | Resolution |
|----|-------|--------|------------|
| P0-TM-1 | Order maxQTY defaulted to 100 / contest allocation instead of free remaining | **FIXED** | `maxQty` tracks `tradingStore.availableQTY` after balance load |
| P0-TM-2 | Buy/Sell remained clickable when contest not `running` | **FIXED** | `tradingUnlocked` + disabled controls + toast |
| P0-TM-3 | Fake chart/candles in runtime | **NOT FOUND** | History from DB candles; ticks from WS; no random series |

**Open P0: 0**

## P1

| ID | Title | Status | Resolution |
|----|-------|--------|------------|
| P1-TM-1 | Mobile qty input desynced from parent trade qty | **FIXED** | Controlled `quantity` prop + emit on every input |
| P1-TM-2 | Mobile missing Available/Used/Total QTY | **FIXED** | Qty strip on mobile chart + desktop quick-trade |
| P1-TM-3 | Order bar not safe-area sticky on mobile | **FIXED** | Sticky trade bar + `env(safe-area-inset-bottom)` |
| P1-TM-4 | Telegram themeParams unused | **FIXED** | `applyTelegramTheme` / safe-area CSS vars |
| P1-TM-5 | Advanced order / edit TP-SL UI stubs | **OPEN → P2** | Backend paths exist; hide/implement later |
| P1-TM-6 | Stale e2e POM selectors (`.buy-btn`) | **OPEN → P2** | Prefer `tp-qtbb` / `tp-mchart-buy` suites |

**Open core P1: 0** (stubs/POM are P2)

## P2

| ID | Title | Status |
|----|-------|--------|
| P2-TM-1 | Synthetic bid/ask when provider omits book (10 bps) | Documented (deterministic, not fake last) |
| P2-TM-2 | Live Telegram client verification | Blocked without bot token + public HTTPS |
| P2-TM-3 | Public tunnel not provisioned in-repo | Runbook documents cloudflared/ngrok |
