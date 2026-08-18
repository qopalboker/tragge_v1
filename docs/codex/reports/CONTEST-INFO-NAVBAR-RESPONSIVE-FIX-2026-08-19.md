# CONTEST INFO + NAVBAR RESPONSIVE FIX — 2026-08-19

## Decision

**CONTEST INFO + RESPONSIVE NAVBAR — PASS**

---

## Contest Info Root Cause

```text
FIELD:          qty_total (passed as qtyTotal prop)
SOURCE:         GET /api/user/contests/:id → TournamentDetailsCard.availableQty
EXPECTED TYPE:  number (contest trading allocation)
ACTUAL TYPE:    undefined
WHY UNDEFINED:    ContestDetailsResponse JSON exposed only available_qty.
                Handler scanned c.qty_total INTO AvailableQty and never emitted qty_total.
                FE passed contest.qty_total (undefined) → props.qtyTotal.toLocaleString() crashed.
```

### Fixes

1. **BFF contract**: add `qty_total` to `ContestDetailsResponse`; scan into `QtyTotal`; keep `available_qty` as legacy alias.
2. **FE normalize**: map `qty_total ?? available_qty ?? 0` on details fetch.
3. **UI resilience**: TournamentDetailsCard formats qty/dates with intentional `—` fallback for transitional nulls (not silent optional chaining on a required product field).

---

## Refresh Root Cause

```text
WHY:      setInterval(15s) on ContestDetailsPage to revalidate backend status after countdown
INTERVAL: 15_000 ms when document.visibilityState === 'visible'
API:      GET /api/user/contests/:id
STATE:    previously set loading=true → v-if="loading" unmounted the whole page (looked like a refresh)
```

Not `window.location.reload()` / `router.go(0)`.

### Fix

`fetchContestDetails({ background: true })` keeps the mounted tree; only initial/route loads use the loading skeleton. Transient background errors do not tear down a valid page.

---

## Responsive Root Cause

Contest Info desktop grid used `1fr 340px` without `minmax(0, …)` / `min-width: 0`, so sticky details card and long text could expand document `scrollWidth` on narrow viewports.

### Fix

- `minmax(0, 1fr)` grid + `min-width: 0` columns
- page `max-width: min(1200px, 100%)`, mobile padding for bottom nav
- TournamentDetailsCard `max-width: 100%`

---

## Navbar

| Before | After |
|---|---|
| Dashboard-only `MobileHomeHeader` boxes (Wallet / Notifications / Support) | Canonical `UserNavbar` in `UserLayout` for all User routes |
| Duplicate shortcuts only on home | Single navbar mobile + desktop |
| Support ticket **content** on Dashboard | Unchanged (`SupportTicketCard` remains content, not a nav shortcut) |

Mobile: compact icon actions + wallet pill; respects viewport; no document overflow.  
Desktop: labeled actions + profile affordance; same component.

---

## External Scripts

| Script | Classification | Action |
|---|---|---|
| `telegram-web-app.js` timeout | Expected on normal browser / blocked network; Mini App still loads when available | Soft-load with `async` + `data-tg-load-state` onerror; existing bootstrap already soft-fails |
| Cloudflare Insights `beacon.min.js` CSP | Not required for MVP; Cloudflare edge may inject it | **Option B** — leave CSP intact (do not allow `static.cloudflareinsights.com`); intentional block |
| `console.<computed> Object` | Primarily Vue/devtools + axios rejection paths; app toast interceptor does not dump raw Objects in a loop | No production logger change required; Contest Info no longer throws |

---

## Tests

- `e2e/contest-info-responsive.spec.ts` — viewports + missing qty + no full reload
- `e2e/user-navbar.spec.ts` — mobile/desktop navbar actions
- Updated `mvp-mobile-home.spec.ts` / `rc-browser-user.spec.ts` for UserNavbar
- Gates: frontend / mvp / acceptance / trading-mobile / lifecycle / trading-cert / deriv-scheduler-mobile

---

## CI

| Item | Value |
|---|---|
| Local SHA | `af4a168483db9b8d99eab97ec565d8e1bd4f2f51` |
| Push | Blocked in this environment (Git Credential Manager non-interactive) |
| Operator | `git push origin main` then verify Actions for `af4a168` |

### Local regression

- frontend-gate — PASS
- mvp-gate — PASS
- acceptance-gate — PASS
- trading-mobile-gate — PASS
- contest-lifecycle-gate — PASS
- trading-certification-gate — **52/52 PASS**
- deriv-scheduler-mobile-gate — **28/28 PASS**

Live API check after rebuild: `qty_total` present on contest details.
