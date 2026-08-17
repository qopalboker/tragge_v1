# Phase 2 — Trading Engine Durability Contract

**Date:** 2026-08-16  
**Status:** implemented (see Phase 2 report for evidence)

## Target guarantee

A trading-engine failure must never silently create, lose, duplicate, or corrupt an economically meaningful order/fill/position state.

## Startup path

```text
process start
  → Config.Validate()  (prod/staging: WAL_PERSIST_PATH required)
  → NewEngine / NewWriteAheadLog
       → load WAL file (fail-closed on corrupt/unreadable)
       → open WAL file for append (fail-closed; never silently memory-only)
  → InitWAL (StateOperator + divergence callback)
  → ReplayWAL (fail-closed on DB check / apply error)
  → reload pending order book
  → if recovery OK: start trading consumers + ready=true
  → else: ready=false, trading consumers NOT started
```

## Durability ordering

For WAL-protected state mutations (`ExecuteWithWAL`):

```text
1. serialize intent
2. WAL Write + fsync          ← durable intent
3. DB transaction + commit
4. in-memory mutate
5. WAL MarkCommitted
6. acknowledge / emit events
```

Contract:

| Crash point | Outcome |
|---|---|
| A — before WAL append | No durable intent; no DB change |
| B — after WAL, before DB commit | Pending entry recovered; DB check false → rolled back (no phantom state) |
| C — after DB commit, before ack | Pending recovered; DB check true → apply memory once + commit mark |
| D — after fill committed | No pending; DB is source of truth |
| E/F/G — mid position/finalization | Pending close/update recovered; apply or discard via DB existence; no silent continue |

**Never:** log a replay warning and continue trading.

## Configuration

| Env | Meaning |
|---|---|
| `WAL_PERSIST_PATH` | Filesystem path for JSONL WAL |
| `WAL_REQUIRE_PERSIST` | Default true in production/staging; empty path fails closed |
| `WAL_SYNC_ON_WRITE` | Default true; entry records fsynced before Write returns |
| `ENVIRONMENT` | Drives default require-persist |

Development/test may use empty path (in-memory) when `WAL_REQUIRE_PERSIST=false`.

## Readiness vs liveness

| Endpoint | Meaning |
|---|---|
| `/healthz` | Process is alive |
| `/readyz` | Safe to accept trading traffic: recovery OK, WAL healthy, DB/Redis OK, circuits OK, shard ready |

## Order / fill identity

- **Order:** `order_id` is the durable logical identity (PK). Duplicate submit/retry acknowledges existing non-terminal state without second reservation/fill.
- **Fill:** market fill uses deterministic `fill_id = UUID-SHA1(order_id)` so Crash C retries cannot insert a second fill for the same logical event.

## Market data staleness

- Per asset class open/close thresholds (`MAX_PRICE_AGE_*`).
- Fresh: `age <= max` (exactly-at-threshold allowed).
- Stale: `age > max` → reject / no pending trigger execution.
- Anomaly: future-dated timestamps (age < −2s) → fail closed as stale/reject.

## Financial representation policy

| Domain | Representation |
|---|---|
| Quantity | `int64` |
| Score / PnL calc | `shopspring/decimal` via `packages/scoring` |
| Wire/market last-mile | `float64` validated before use (positive, finite, bounds) |
| Fees / money cents | integer cents / bps (settlement path) |

## Market data timestamp safety

Internal clock: Unix **milliseconds UTC**. Seconds-scale values (`ts < 1e12`) are normalized.

Rejected as non-authoritative market state:

| Condition | Reason |
|---|---|
| zero / missing ts | `missing_or_zero_timestamp` |
| future beyond 2s skew | `future_timestamp` |
| age > 24h | `extremely_old_timestamp` |
| unit absurdity (`ts > 1e15`) | `timestamp_unit_mismatch` |
| NaN/Inf/negative prices, crossed book | `invalid_price` |
| `ts < stored quote ts` | `backward_timestamp` (no stale override) |

Trading staleness uses tighter `MAX_PRICE_AGE_*` thresholds after acceptance into the book.

## Market-data readiness

When `REQUIRE_MARKET_DATA_READY=true` (default production/staging):

- `/readyz` fails if no valid tick / all quotes stale;
- market orders reject with `market data not ready`.

Liveness (`/healthz`) stays independent of feed health.

## Provider failure / source switching

Market-ingestor retains primary→fallback failover. Trading engine enforces **monotonic book time**: older ticks from any source cannot overwrite newer state. Duplicate/out-of-order events are dropped, not applied.

## Contest finalization boundary (product policy)

Actual path:

```text
contest → settling
  → stop new trading (status + contestTrading gate)
  → cancel pending orders
  → force-close open positions at mark (Redis → fill → entry fallback)
  → rankings / leaderboard
  → settlement-service: prizes + CreditPrizeIdempotent
```

Authority:

| Step | Owner |
|---|---|
| Force close at end | domain `HandleContestEnd` + settlement `closeAllPositions` (Kafka to engine) |
| Money settlement | settlement-service + wallet |
| Leaderboard ranks | leaderboard-worker (preview labels on prize cents) |

Cutoff rule for engine orders: `ends_at` is **exclusive** (`!now.Before(endsAt)` rejects). Status `settling|completed|cancelled|paused` rejects. Contest trading gate disables trading on state events.

## Order / fill identity

- Order: `orders.order_id` PK; duplicate non-terminal → idempotent ACK
- Fill: deterministic `fill_id = UUID-SHA1(order_id)` for full market fills
- Constraints: `chk_order_qty_positive`, `chk_fill_price_positive`, fill/order PKs

## Related

- Phase 0: `docs/codex/reports/PHASE-0-FORENSIC-AUDIT-2026-08-16.md` (P1-ENG-01/02)
- Phase 1.1: financial core closed; settlement money path separate from engine WAL
- Phase 2 reliability report: `docs/codex/reports/PHASE-2-TRADING-RELIABILITY-2026-08-16.md`
