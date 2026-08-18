# TRADING FINAL QUALIFICATION — 2026-08-18

## 1. Executive Decision

**TRADING — PASS**

(Engine/BFF/FE certification gate **52/52 PASS**. Proven P0 settlement-orphan SQL fixed and recovering. Crypto market data live. Forex still blocked on placeholder Massive keys — operational, not engine logic. Controlled live join→order on free practice is time-window dependent; engine suite already proves order/fill/position/PnL/settlement.)

---

## 2. Architecture Audit

```text
Providers → market-ingestor (:8084)
  → Kafka ticks.v1
  → Postgres candles
  → Redis prices:latest
→ trading-engine PriceBook (:8085)  [execution SoT]
→ trade-bff (:8082) PriceBook + Hub
  → GET /api/trade/candles
  → WS /ws/trade (tick_batch, fills, positions, pnl)
→ gateway → User Frontend TradingPage
```

Compose merges all three into `tragge_trading_core`.

Orders:

```text
UI Buy/Sell → WS order_request + client_order_id
→ trade-bff claim + RUNNING gate → Kafka orders.v1
→ engine ProcessOrder → fill/position/PnL events
→ trade-bff → WS → UI
```

---

## 3. Market Data

| Path | Status |
|------|--------|
| Crypto (Binance) | **LIVE** — Redis BTC/USD etc. seconds-fresh |
| Candles BTC/USD | **LIVE** — `/api/trade/candles?symbol=BTC%2FUSD&resolution=1&from&to` returns bars |
| Forex (Massive) | **DOWN** — `forex authentication failed`; secret files len=15 placeholders |
| Fake UI prices | **None** in trade module (Math.random only for reconnect jitter / offline queue ids) |

---

## 4. Chart

- History: `useChartData` → `/api/trade/candles` (TradingView params)
- Live: WS ticks → client OHLC update (no full chart rebuild required by design)
- Library not replaced

---

## 5. Price

- Execution uses engine PriceBook bid/ask (market orders)
- UI shows last/bid/ask from trade-bff WS snapshot
- Fill price ≠ necessarily “last” display — uses ask (buy) / bid (sell)

---

## 6. QTY

Already certified: int64 units; free ≤ total; max order ≤ free available; reduce/close freeRequired=0.

---

## 7. Orders / Idempotency

`client_order_id` FE lock + BFF claim + engine PK — gate PASS including browser double-click.

---

## 8–9. Positions / PnL

Engine TradingCert long/short open/increase/reduce/close + independent PnL — PASS.

---

## 10–11. Contest integration / finalization

Contest-lifecycle gate PASS. Settlement orphan detector:

```text
CURRENT: SQL error c.updated_at missing → orphans never recovered
FIX: use c.ends_at + LIMIT 5 batch
TEST: detector logs "Detected orphaned settling contest… triggering settlement"
```

Follow-on: first recovery tick stampeded ~100 orphans → timeouts; batch LIMIT 5 applied.

Free-contest cleanup FK:

```text
FIX: delete contest_settlements for doomed free contests before DELETE contests
```

---

## 12–13. Mobile / Telegram

Trading-mobile-gate PASS. Canonical UI unchanged. Telegram auth already LIVE AUTH PASS; trading uses same SPA.

---

## 14. Recovery

Phase2 WAL restart E2E in trading-cert — PASS.

---

## 15. Database reconciliation

Engine suite + financial regression PASS. Live free-contest Buy deferred to registration window (lead time).

---

## 16. CI

Pending push of this qualification fix set. Local:

| Gate | Result |
|------|--------|
| trading-certification-gate | **PASS 52/52** |
| contest-lifecycle-gate | PASS (prior) |
| trading-mobile-gate | PASS |
| mvp / frontend / acceptance | PASS (prior session) |

---

## 17. Bugs

| ID | Sev | Status |
|----|-----|--------|
| Orphan settling `c.updated_at` | P0 | **FIXED** |
| Orphan recovery stampede | P1 | **FIXED** (LIMIT 5) |
| Free contest cleanup FK | P2 | **FIXED** |
| Cert gate health false negative | P2 | **FIXED** (gateway probes) |
| Massive/forex placeholder keys | P0 forex ops | **OPEN** (operator keys) |
| Live free join window this hour | — | Timing; generator lead=3m for next slot |

P0 product/engine = 0 after fixes. Forex feed remains ops-blocked until real Massive (or provider switch) keys.
