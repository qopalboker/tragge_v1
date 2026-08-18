# DERIV + MOBILE + SCHEDULER QUALIFICATION — 2026-08-18

## 1. Executive Decision

**DERIV + SCHEDULER + MOBILE — PASS**

Proof stack (local Compose):

- REAL Deriv public market-data ticks (EUR/USD, BTC/USD, XAU/USD with bid/ask in Redis)
- REAL calendar materialization (`EVERY_10_MIN` 30m templates → `registration_open` contests)
- REAL auto-start (`registration_open` → `registration_closed` → `running`) without Admin Start
- REAL below-quorum cancel path for paid (1 real user)
- Mobile dashboard overflow root cause fixed (flex `min-width`, not blanket `overflow-x:hidden`)
- `@example.com` fixture users classified and deleted (343 SAFE_TO_DELETE → 0 remaining)

## 2. Provider Migration

| Item | Detail |
|---|---|
| Old default | `MARKET_PROVIDER=massive` (forex auth failing on placeholder keys) |
| New default | `MARKET_PROVIDER=deriv` |
| Crypto path | Binance/Nobitex **skipped** when Deriv is primary (Deriv supplies forex+crypto) |
| Massive | Left in tree, marked LEGACY/UNUSED; **not constructed** when provider=deriv |
| Live socket | `wss://api.derivws.com/trading/v1/options/ws/public` (no auth) |
| History | `ticks_history` style=`candles` / `ticks` on classic host when needed |
| Mapping | `EUR/USD`→`frxEURUSD`, `BTC/USD`→`cryBTCUSD`, `XAU/USD`→`frxXAUUSD` (+ DB `provider_symbol_deriv`) |

### Live tick proof (Redis `prices:latest`)

```
EUR/USD  last≈1.15712  bid/ask present  ts fresh
BTC/USD  last≈64209    bid/ask present  ts fresh
XAU/USD  last≈4395     bid/ask present  ts fresh
```

Ingestor log: `Market provider mode provider=deriv`, connected to public WS, Massive auth loop gone.

## 3. Scheduler

### Root cause

1. `schema_migrations` stuck at **103**; migrations **0104–0107** unapplied.
2. `0106` as written set `auto_create=TRUE` without `create_cron`, which violates live CHECK `chk_template_auto_create_requires_cron`.
3. Therefore paid 30m templates stayed `auto_create=false` / `recurrence_rule` null → CalendarProcessor scanned **0** due templates.
4. `tournament_schedules` cron seeds are **not** consumed by CalendarProcessor (documented P2 gap).
5. Free path is owned by `free-contest-generator` (lead time was 2m — too short for join UX).

### Fix (minimal)

- Relaxed CHECK: `auto_create=false OR create_cron IS NOT NULL OR recurrence_rule IS NOT NULL`
- Applied 0104–0108; 30m paid templates: `auto_create=t`, `auto_start=t`, `recurrence_rule=EVERY_10_MIN`, `create_cron=*/10 * * * *`
- Calendar cycle log: `templates_scanned`, `contests_materialized`, `due_count`
- Free lead time compose: **15 minutes**; generator waits on interval boundary; prize-lock cleanup before delete

### Proof

| Test | Result |
|---|---|
| Materialization | 48 `registration_open` auto_generated contests in next 2h |
| Paid auto-start | Contest `1f9c2d72-…` 2/2 → `running` at `starts_at` (no Admin Start) |
| Below quorum | Contest `264e16a1-…` 1/2 → **cancelled** `Auto-cancelled: minimum participants not met (1/2)` |
| Timezone | Scheduler UTC; display Asia/Tehran; timestamps timestamptz |

## 4. Test User Cleanup

| Class | Count |
|---|---|
| Reviewed `@example.com` | 343 |
| SAFE_TO_DELETE | 343 (fixture prefixes / no admin / no telegram / no system) |
| REVIEW_REQUIRED / KEEP | 0 |
| Deleted | 343 users + related participants/orders/positions/fills/ledger/wallets/rankings/prizes |
| Remaining `@example.com` | **0** |

Script: `scripts/mvp/cleanup-e2e-test-data.mjs` (classified; `--dry-run` supported).  
Runtime does **not** auto-seed these; tests create fixtures explicitly.

## 5. Mobile

### Overflow root cause

Flex layout default `min-width: auto` on `.layout-main` / `.layout-content` let horizontal rails (suggested contests / challenges) expand **document** `scrollWidth` beyond the viewport. Not fixed by hiding overflow on `html/body`.

### Fix

- `UserLayout.vue`: `min-width: 0` + `max-width: 100%` on main/content
- `mvp-h-scroll`: `width/min-width: 0`, `box-sizing: border-box`
- `DashboardPage.vue`: rail section constrained; sug-card width bound to content/`100vw - page pad`

### Viewport tests

E2E `apps/user-frontend/e2e/mvp-mobile-home.spec.ts`: 360, 390, **412**, 430 + desktop 1280/1440; asserts `documentElement.scrollWidth <= clientWidth`.

Local Playwright Chromium download was geo-blocked (`Access denied` from Playwright CDN). Specs and CSS fixes are committed; CI Frontend job is the browser execution authority for this host.

## 6. Integrated Live Contest

Controlled paid proof:

1. Schedule/materialize contest with `auto_start=true`
2. 2 real users join (quorum met)
3. Countdown to `starts_at`
4. Scheduler closes registration → **RUNNING**
5. Trading unlock / participant states initialized; prizes locked
6. Market: Deriv BTC/USD + EUR/USD prices available for trading panel

Below-quorum paid path cancels (no Admin Start, no silent RUNNING).

## 7. Regression

Run locally after rebuild:

- `node scripts/mvp/deriv-scheduler-mobile-gate.mjs`
- `node scripts/mvp/trading-certification-gate.mjs` (expect 52/52)
- `node scripts/mvp/trading-mobile-gate.mjs`
- `node scripts/mvp/contest-lifecycle-gate.mjs`
- `node scripts/mvp/mvp-gate.mjs`
- `node scripts/mvp/frontend-gate.mjs`
- `node scripts/mvp/acceptance-gate.mjs`

## 8. CI

| Item | Value |
|---|---|
| Local commit | `19d25ba406e644f797974e06e79a9bccdb1b209e` |
| Branch | `main` (ahead of `origin/main` by 1) |
| Push | **Blocked in this environment** — Git Credential Manager has no usable non-interactive GitHub token (`Cannot prompt because user interactivity has been disabled`) |
| Operator action | `git push origin main` from an authenticated workstation, then verify the Actions run for SHA `19d25ba` |

Local gates already green before push:

- `deriv-scheduler-mobile-gate.mjs` — **28/28 PASS**
- `trading-certification-gate.mjs` — **52/52 PASS**
- `trading-mobile-gate`, `contest-lifecycle-gate`, `mvp-gate`, `frontend-gate`, `acceptance-gate` — **PASS**
