# TRADING CORRECTNESS CERTIFICATION

**Date:** 2026-08-17  
**Repository:** tragge_v1 (local monorepo)  
**Gate:** `scripts/mvp/trading-certification-gate.mjs`  
**Evidence:** `docs/codex/reports/evidence/trading-correctness/`

---

## 1. Executive Decision

**TRADING — PASS**

**P1 DUPLICATE ORDER — CLOSED**

Core trading path (quantity, order, fill, position, long/short, PnL score, client_order_id idempotency, WAL restart, contest cutoff, stale price rejection, browser Buy clickability) is certified against real Postgres + trading-engine + local Compose.

---

## 2. Trading Architecture

```text
Trading Panel (Vue)
  → client_order_id = crypto.randomUUID()  // one per logical intent
  → WebSocket order_request (primary) | REST POST /api/trade/orders
  → trade-bff claimClientOrderID → order_client_submissions (PK)
  → order_id := client_order_id
  → Kafka OrderRequest
  → trading-engine ProcessOrder (idempotent by order_id PK)
  → validateOrderRequest (qty int64, prices)
  → freeQtyRequiredForOrder + ReserveQty
  → executeMarketOrder (full fill) | pending book
  → fill (deterministic fill_id) + position update
  → PostgreSQL orders / fills / positions / participants
  → Kafka acks / PnL → UI refresh
```

### Logical identity (post P1 closure)

| Field | Role |
| ----- | ---- |
| `client_order_id` | Durable logical submission UUID from client |
| `order_id` | Equals `client_order_id` when client supplies it |
| `request_id` | WS ack correlation only (not durable) |

Uniqueness: `order_client_submissions.client_order_id` PRIMARY KEY; `orders.order_id` PRIMARY KEY.

No microservice decomposition performed.

---

## 3. Quantity Semantics

| Layer | Representation | Example |
| ----- | -------------- | ------- |
| UI input | whole number, step=1, min=1 | `5` |
| API / WS | JSON number → Go `int64` | `5` |
| Trade BFF | `Qty int64` | `5` |
| Engine | `int64` whole QTY units | `5` |
| Order DB | `BIGINT` | `5` |
| Fill DB | `BIGINT` | `5` |
| Position DB | `qty_open` / `qty_used` `BIGINT` | `5` |
| UI display | integer QTY | `5` |

**Policy (product §5.5):** integer-only; minimum order QTY = 1; contest allocation 5/10/20. **Decimals not supported** (not tested as product feature).

**Price:** wire/engine float64 last-mile; DB `numeric(20,8)`; scores via shopspring/decimal (`qty_used * pct_change`).

---

## 4. Quantity Test Results

| Qty | Engine round-trip | Notes |
| --- | ----------------- | ----- |
| 1 | PASS | order=fill=position |
| 2 | PASS | |
| 5 | PASS | |
| 10 | PASS | |
| 0 / negative / Max+1 | PASS reject | no fill |
| Concurrent 7+6 | PASS | sum fills 13 |
| Over-reserve race | PASS | no fill > allocation |

**P0 fixes applied:** min QTY default 1; max % default 100%; free QTY for reduce/close.

---

## 5. Order Results

| Type | Supported | Notes |
| ---- | --------- | ----- |
| MARKET | Yes | Primary UI path; full fill |
| BUY/SELL LIMIT | Engine/BFF | UI advanced stub only |
| BUY/SELL STOP | Engine/BFF | UI advanced stub only |
| TP/SL | Engine fields | Directional validation |

Partial **order** fills: schema-only; execution full-fill. Partial **position** close: supported.

---

## 6. Position Results

| Scenario | Long | Short |
| -------- | ---- | ----- |
| Open | PASS | PASS |
| Increase same side | PASS | PASS |
| Reduce opposite | PASS (after freeQty fix) | PASS |
| Full close | PASS | PASS |
| Reverse/flip | Supported via overflow; free QTY = overflow only | |

---

## 7. PnL Results

Independent LONG close check (fill bid/ask path):

- expected ≈ `qty * (exit-entry)/entry * 100`
- actual `realized_score` matched within float tolerance (evidence in engine test log).

Contest score is **not** currency PnL.

---

## 8. Restart / Recovery

`TestPhase2_E2E_RestartWALRecovery`: PASS — second fill after restart; no duplicate fill on replayed order_id.

---

## 9. Browser Evidence

### Layout defect (fixed)

- **Symptom:** `.tp-nright` / `.tp-nav` intercepted `button.tp-qtbb` (Playwright pointer-events).
- **Root cause:** missing structural CSS for `.tp-*` trading classes (tokens only in `main.css`).
- **Fix:** `apps/user-frontend/src/modules/trade/styles/trading-panel.css` + import in `TradingPage.vue`.
- **Regression:** `apps/user-frontend/e2e/trading-buy-minimal.spec.ts` (elementFromPoint + geometry + click without `force`).

### Hit-test (post-fix)

```json
{
  "topClass": "tp-qtbb",
  "isBuyOrChild": true,
  "navRightCovers": false,
  "navHeight": 52,
  "gap": 135.5
}
```

### Minimal journey

`login → join running contest → /trade/{id} → qty 1 → Buy click` — **PASS** (toast after click; EXIT 0).

Fail-fast: project `retries: 0`, `timeout: 90s`, `actionTimeout: 8s`.

---

## 10. Database Consistency

Orders/fills/positions use `BIGINT` qty; Phase2 E2E asserts fill count=1, open position=1, no late fill after settling, no duplicate fill on same order_id.

---

## 11. Bug Backlog

See `docs/codex/mvp/TRADING-BUG-BACKLOG.md`.

| Sev | Open core? |
| --- | ---------- |
| P0 | **0** |
| P1 core flow | **0** (layout + qty + **duplicate order CLOSED**) |
| P2+ | Partial fills N/A; i18n keys; float price last-mile |

### Duplicate-order evidence

| Test | Result |
| ---- | ------ |
| Concurrent same `order_id` (engine, 8 goroutines) | 1 fill, position qty preserved |
| Concurrent DB claim `client_order_id` (16 workers) | 1 row, same order_id |
| REST POST ×2 same `client_order_id` | 202/202, identical `order_id` |
| Browser double-click Buy | PASS (UI lock; ≤1 logical id) |

---

## 12. Certification

**P1 DUPLICATE ORDER — CLOSED**

**TRADING — PASS**

Gate validates: QUANTITY, PRICE, ORDER, FILL, POSITION, PNL, RESERVATION, CANCELLATION surface, LONG, SHORT, CONTEST CUTOFF, STALE MARKET, DUPLICATE ORDER (`client_order_id` + order_id PK), RESTART RECOVERY, BROWSER TRADING, DB CONSISTENCY, RECONCILIATION.

Does **not** require cloud, Kubernetes, payment gateway, legal, or production market providers.

---

## Run commands

```bash
# Engine domain cert
go test ./apps/trading-engine/server -run 'TradingCert|Phase2_E2E' -count=1 -v

# Minimal browser (fail-fast)
E2E_INTEGRATION=1 npx playwright test --project=trading-buy-minimal --workers=1 --retries=0

# Full gate
node scripts/mvp/trading-certification-gate.mjs
```
