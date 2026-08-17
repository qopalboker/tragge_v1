# Trading Bug Backlog

**Date:** 2026-08-17  
**Scope:** Trading Panel + Trade BFF + Trading Engine correctness audit

## Severity policy

| Level | Meaning |
|-------|---------|
| P0 | Financial corruption, wrong quantity, duplicate fill, lost order, wrong position, wrong settlement |
| P1 | Major trading workflow broken |
| P2 | UX / noncritical correctness |
| P3 | Polish |

Certification requires: **P0 = 0** and **core-flow P1 = 0**.

---

## Fixed this session

### P0 — Engine min QTY / max % blocked product sizes
- **Was:** `QTY_MIN_PER_TRADE` default 100 and `QTY_MAX_PCT_OF_TOTAL` default 50; live contests use `qty_total` 5/10/20 → product orders rejected.
- **Fix:** Defaults 1 / 100%; compose env `QTY_MIN_PER_TRADE=1`, `QTY_MAX_PCT_OF_TOTAL=100`.

### P0 — Opposite-side reduce/close required free `qty_available`
- **Was:** Reduce/close needed free QTY equal to order size even when position already reserved `qty_used` → could not reduce when most allocation was in a position.
- **Fix:** `freeQtyRequiredForOrder` — pure reduce/close freeRequired=0; flip overflow only reserves net new exposure.

### P1 — Trading panel CSS missing → Buy unclickable
- **Was:** `.tp-*` classes existed without layout CSS; Playwright: `.tp-nright` / `.tp-nav` intercepted `button.tp-qtbb`; screenshot showed logo-only unusable page.
- **Fix:** `apps/user-frontend/src/modules/trade/styles/trading-panel.css` imported from `TradingPage.vue` — nav is 52px top bar in document flow; Buy is topmost at hit-test.
- **Evidence:** `docs/codex/reports/evidence/trading-correctness/buy-hit-test.json` (`navRightCovers: false`, `isBuyOrChild: true`); minimal Playwright **PASS**.

---

## Fixed — P1 DUPLICATE ORDER (2026-08-17 closure)

### P1 — Submit-side idempotency (double-click / retry)
- **Was:** BFF always minted a new `order_id` per HTTP/WS request; engine only deduped identical `order_id`.
- **Fix:**
  - Durable identity: `client_order_id` (UUID) = logical order = engine `order_id`.
  - DB: `order_client_submissions` (migration `0105`) PK on `client_order_id`.
  - BFF: `claimClientOrderID` before Kafka publish (REST + WS).
  - Engine: existing order_id short-circuit + concurrent insert unique-violation path.
  - FE: generate one `clientOrderId` per intent; timeout retry reuses it; `tradeClickLock` + disabled Buy/Sell.
- **Evidence:**
  - `TestClaimClientOrderID_Concurrent` PASS
  - `TestTradingCert_ConcurrentSameOrderID` PASS
  - Playwright API: two POSTs same `client_order_id` → same `order_id` (202/202)
  - Playwright double-click Buy (UI lock + ≤1 logical id)

**Status: P1 DUPLICATE ORDER — CLOSED**

## Open

### P2 — Partial order fills not executed
- Schema has `partially_filled` / `qty_filled`; market path full-fills only.
- Documented product behavior for MVP; do not invent partials.

### P2 — i18n keys raw on trade chrome
- Screenshot shows `watchlist.all`, `order.buy` as missing translation keys in some locales.

### P2 — Price float64 last-mile
- Scores use shopspring/decimal; fill/entry wire float64. Accept residual drift for score path; no rewrite without evidence of wrong settlement.

### P3 — Advanced order UI stub
- Advanced order button is non-functional stub; market path is primary.

---

## Certification status (browser layout gate)

| Item | Status |
|------|--------|
| Buy layout hit-test | PASS |
| Minimal browser: login→trade→qty→Buy | PASS |
| Engine TradingCert qty 1/2/5/10 | PASS (prior run) |
| Full multi-qty + restart gate | Pending re-run after layout fix |

---

## Architecture deferred

`ARCHITECTURE HARDENING — DEFERRED`: no api-server / trading-core / worker split in this task.
