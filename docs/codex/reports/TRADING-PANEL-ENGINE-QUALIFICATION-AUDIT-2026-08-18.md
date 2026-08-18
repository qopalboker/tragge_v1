# TRADING PANEL & ENGINE QUALIFICATION — FORENSIC AUDIT

**Date:** 2026-08-18  
**Scope:** Audit only (no code changes per operator direction)  
**Decision for this document:** forensic baseline + defect register (not yet LIVE TRADE PASS)

---

## 1. Runtime topology (Compose)

| Service | Container | Ports | Role |
|---------|-----------|-------|------|
| `trading-core` (merged) | `tragge_trading_core` | 8082 trade-bff, 8084 market-ingestor, 8085 trading-engine | Single binary hosts all three |
| `gateway` | `tragge_gateway` | 8080 user / 8081 admin | Proxies `/api/trade`, `/ws/trade` → `trading-core:8082` |
| `api-server` | `tragge_api_server` | user/admin/payment BFFs | Contests, join, wallets |
| `redpanda` | `tragge_redpanda` | 9092 | Kafka-compatible `ticks.v1`, `orders.v1`, … |
| `postgres` / `redis` | healthy | — | Candles + state / `prices:latest` |
| `worker` | `tragge_worker` | — | Scheduler, settlement-service, free-contest-generator, leaderboard |

**Health (live):**
- `trading-core:8082/healthz` → `{"status":"ok"}`
- `8084/healthz`, `8085/healthz` → ok
- Gateway `/api/trade/me` without JWT → **401** (route alive)
- Note: `/api/trade/healthz` is **not** mounted; gate scripts that probe that path get SPA/404 false negatives

---

## 2. Market-data hop map

```text
Providers (Massive WS / TwelveData / Finnhub / Binance WS / Nobitex REST)
  → market-ingestor (trading-core:8084)
      → Kafka ticks.v1
      → Postgres candles (1m…1w)
      → Redis prices:latest (1Hz)
  → trading-engine PriceBook (execution)
  → trade-bff PriceBook + Hub
      → WS tick_batch @ ~1s
      → GET /api/trade/candles (history)
  → User Frontend TradingPage / MarketChart / useChartData
```

**Candles:** Postgres only (no Kafka candles topic).  
**Live chart bars:** browser aggregates WS ticks client-side after history load.

### Live market status (2026-08-18 ~02:50Z)

| Feed | Status | Evidence |
|------|--------|----------|
| Crypto (Binance) | **LIVE** | Redis `prices:latest` has BTC/USD, ETH/USD, …; tick age ~seconds |
| Candle history BTC/USD | **LIVE** | `GET /api/trade/candles?symbol=BTC%2FUSD&resolution=1&from&to` → 529 bars / 24h |
| Forex/commodities (Massive) | **DOWN** | Logs: `forex authentication failed`; no EUR/USD in Redis |
| Provider secrets | **PLACEHOLDER** | `massive_api_keys.txt`, `twelvedata_api_keys.txt`, `nobitex_token.txt` each **len=15** |

Compose defaults: `MARKET_PROVIDER=massive`, `CRYPTO_PROVIDER=binance`, `NOBITEX_ENABLED=true`.

---

## 3. Order-execution hop map

```text
TradingPage.handleTrade
  → client_order_id (UUID) + UI lock
  → WS order_request (/ws/trade)
  → trade-bff claimClientOrderID + contest RUNNING gate
  → Kafka orders.v1
  → trading-engine ProcessOrder → market fill → position/PnL
  → Kafka fills / positions / pnl_deltas / acks
  → trade-bff → WS fan-out
  → store → BottomPanel / MobileOrdersPage
```

Close/cancel: REST `/api/trade/positions/{id}/close`, `DELETE /api/trade/orders/{id}`.

**Already certified (do not rewrite):**
- int64 QTY model, free-qty reserve/release
- `client_order_id` idempotency (FE + BFF claim + engine PK)
- contest RUNNING lock at FE/BFF/engine
- force-close / cancel-pending at settlement

---

## 4. Contest → Trading live probe

| Check | Result |
|-------|--------|
| Running Free Crypto / Free Forex Practice | Present (2 running) |
| Contest symbols API | **200** (crypto symbols for crypto contest) |
| Join while running (free) | **400** `free_contest_no_late_join` (policy) |
| Trade balance without participation | **403** FORBIDDEN (correct) |
| Candles with unencoded `BTC/USD` | Can yield empty/noData (slash handling) |
| Candles with `BTC%2FUSD` | **200** with real bars |
| Next `starts_at > now()` free slots | **None at probe time** (hourly generator; join window may be short) |
| Contests stuck `settling` | **154** contests; sampled recent free practices have **`has_settlement=false`** (true orphans) |

---

## 5. Defect register (audit-only)

### D1 — Massive / forex market auth failure (P0 for Forex Practice)

```text
CURRENT BEHAVIOR
  Free Forex Practice runs, but Redis has no EUR/USD (etc.).
  Ingestor logs: massive forex authentication failed; reconnect loop.

ROOT CAUSE
  Runtime secrets massive_api_keys / twelvedata_api_keys appear placeholder (15 bytes).
  MARKET_PROVIDER=massive with no failover when not in auto mode.

PROPOSED CHANGE (not applied)
  Operator: set real Massive (or switch MARKET_PROVIDER to a working provider with real keys).
  Optional: enable auto failover Finnhub→TwelveData when Massive auth fails.

REGRESSION RISK
  Low if only secrets/env; medium if provider mode changes.

TEST
  Redis keys include EUR/USD; Free Forex contest WS shows live bid/ask.
```

### D2 — Orphaned settling detector SQL bug (P0 for settlement recovery)

```text
CURRENT BEHAVIOR
  worker logs every ~5m:
  Failed to query orphaned settling contests:
  ERROR: column c.updated_at does not exist

ROOT CAUSE
  apps/settlement-service/server/stuck_detector.go:118
  queries c.updated_at but contests table has created_at / settled_at, not updated_at.

PROPOSED CHANGE (not applied)
  Use c.ends_at or c.settled_at / c.created_at (confirm schema) instead of c.updated_at.

REGRESSION RISK
  Low — detector currently cannot recover orphans.

TEST
  Stuck detector runs without SQL error; orphaned settling contests get settlement triggered.
```

### D3 — Free-contest cleanup FK failure (P2 ops)

```text
CURRENT BEHAVIOR
  free-contest-generator cleanupLoop:
  delete contests violates contest_settlements_contest_id_fkey

ROOT CAUSE
  Cleanup deletes contests that still have settlement rows.

PROPOSED CHANGE (not applied)
  Delete/archive settlements first, or restrict cleanup to contests without settlements.

REGRESSION RISK
  Medium if wrong cascade order.

TEST
  Cleanup completes; no FK errors in worker logs.
```

### D4 — Trading certification gate false negative (P2 tooling)

```text
CURRENT BEHAVIOR
  trading-certification-gate reports trade-bff healthz unreachable / TRADING BLOCKED.

ROOT CAUSE
  Probe path often `/api/trade/healthz` which is not mounted.
  Real health is trading-core `/healthz` on 8082 (and gateway auth’d `/api/trade/me`).

PROPOSED CHANGE (not applied)
  Point gate health check at `/healthz` via docker network or `/api/trade/me` expecting 401.

REGRESSION RISK
  Low (gate-only).

TEST
  Gate PASS when stack healthy.
```

### D5 — Controlled live Buy/Sell not completed this session (acceptance gap)

```text
CURRENT BEHAVIOR
  Architecture ready; crypto prices live; cannot late-join running free contests.
  No future open slot was available at probe time for a full join→trade→end cycle.

ROOT CAUSE
  Timing/policy (free_contest_no_late_join) + audit-only scope (no code/wait loop).

PROPOSED CHANGE (not applied)
  Wait for next Free Crypto Practice registration window → join → Enter Trading → market order → observe fill/position/PnL → wait for end/settlement.

REGRESSION RISK
  N/A (test procedure).

TEST
  Full product path checklist in header of this phase.
```

---

## 6. What already works (do not rewrite)

- Merged `trading-core` topology and gateway routing
- Crypto tick path (Binance → ticks.v1 → PriceBooks → Redis/WS)
- Candle history API (TradingView `symbol/resolution/from/to`)
- Order idempotency / QTY / contest RUNNING locks
- Frontend canonical trading panel (WS place + REST close/cancel)
- Contest lifecycle gate contracts (auto-start, quorum policy, Enter Trading only when running)

---

## 7. Recommended next implementation order (when unblocked)

1. **Fix D2** (`c.updated_at` → correct contests timestamp) — unblocks settlement recovery.
2. **Operator market keys (D1)** — restore Forex Practice prices.
3. **D4 gate health path** — stop false BLOCKED.
4. **D5 live trade** on next Free Crypto Practice (crypto already priced).
5. **D3 cleanup FK** — ops hygiene.

---

## 8. CTO change template (for upcoming fixes)

Every fix PR should include:

```text
CURRENT BEHAVIOR
ROOT CAUSE
PROPOSED CHANGE
REGRESSION RISK
TEST
```

---

## Final decision (this audit deliverable)

**TRADING QUALIFICATION — AUDIT COMPLETE / FIXES DEFERRED**

Not declaring LIVE TRADE PASS until D2 is fixed and a controlled join→order→fill cycle is executed on a joinable contest with live prices.
