# COMPETITION CARD + PROVIDERS + QTY + ERROR CLOSURE — 2026-08-20

## Decision

**COMPETITION CARD + PROVIDERS + QTY + ERROR CLOSURE — PASS**

---

## 1. Competition card redesign

Canonical component: `ContestCard.vue` (ContestsPage / lists).

Desktop (≥900px): horizontal row columns —

TYPE | TOURNAMENT | START & END | TRADERS | FIRST & TOTAL PRIZE | ENTRY FEE | STARTING IN | JOIN

Mobile: stacked card (same component). Join never embeds fee. Zero prize → **No prize**. Real API fields only.

## 2. Navbar

`UserNavbar.vue`:

- No platform brand title
- Wallet centered (3-zone grid)
- Sharper wallet corners (`10px`)
- Separated bar surface via `layout-topbar` border/background

## 3–5. Providers

| Category | Provider |
|---|---|
| Forex / commodity | **Deriv** (`MARKET_PROVIDER=deriv`) |
| Crypto | **Nobitex** (`CRYPTO_PROVIDER=nobitex`) |

Deriv subscriptions limited to `ForexSymbols`. Nobitex starts alongside Deriv. Massive remains LEGACY/unused when not selected.

## 6. QTY semantics

QTY is tournament allocation — never `$` / currency formatters.

Fixed:

- Admin `ContestTemplatesPage.formatQty` → `N QTY`
- Admin `ContestDetailPage` qty cards/table → `formatQty`
- Admin `ContestFormPage` label `(QTY)`
- User `ContestCard` trading capital → `N QTY`

## 7. Admin errors

| Error | Root cause | Fix |
|---|---|---|
| `.filter is not a function` | API `{templates:[]}` assigned as array | Normalize in `getContestTemplates()` |
| `/financial/summary` 500 | SQL `type='prize'` invalid enum | Use `prize_credit` |
| `/providerconfig` 403 | Needs `market.view` | UI shows permission banner; no toast spam |

## 8. Trading errors

| Error | Fix |
|---|---|
| `candles?symbol=` | Guard empty symbol in `useChartData.fetchHistory` + MarketChart mount |
| WS `/ws/trade` | Gateway already proxies to trading-core:8082 with Upgrade; verify via public panel after CORS/tunnel healthy |

## 9. CSP

- Cloudflare Insights: intentionally blocked (Option B) — CSP not weakened
- Inline telegram `onload`/`onerror` removed from `index.html` (was CSP violation)
- Extension `runtime.lastError`: external noise

## 10–12. Gates / CI

| Gate | Result |
|---|---|
| trading-certification | **52/52 PASS** |
| frontend / mvp / acceptance / lifecycle / deriv-scheduler-mobile | **PASS** |

Live proof after rebuild:

- `MARKET_PROVIDER=deriv`, `CRYPTO_PROVIDER=nobitex`
- Logs: `Provider category split forex=deriv crypto=nobitex` + Nobitex feed started
- Redis: EUR/USD (Deriv) + BTC/USD (Nobitex) both live

Local SHA: `4edf807fd72f3802982582a3055cfc3da0ef5ee0`  
Push requires operator credentials: `git push origin main`
