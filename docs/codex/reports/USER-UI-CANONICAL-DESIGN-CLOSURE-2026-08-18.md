# USER UI CANONICAL DESIGN CLOSURE — 2026-08-18

## Final decision

**USER UI — PASS**

The legacy Mini App product tree is **removed from the filesystem and runtime routes**.  
`/user/dashboard` and `/miniapp/home` both mount the **same** `UserLayout` + `DashboardPage` (MVP design tokens).  
Telegram auth bootstrap remains ordered **before** router install so valid `initData` never hits `/user/login`.

---

## 1. Why the old design existed

Telegram Mini App was built as a **parallel product tree**:

| | Legacy Mini App | Canonical User Panel |
|--|-----------------|----------------------|
| Home route | `/miniapp/home` | `/user/dashboard` |
| Layout | `MiniAppLayout` | `UserLayout` |
| Home view | miniapp `HomePage` | `DashboardPage` |
| Tokens | `--ma-*` | `--mvp-*` |
| Nav | miniapp `BottomNavigation` | `BottomNav` / sidebar |

Both were shipped in one SPA; **routing selected the design**, not the gateway or a service worker.

---

## 2. Legacy inventory (before deletion)

| Path | Component / artifact | Legacy / Canonical | Runtime / Test |
|------|----------------------|--------------------|----------------|
| `modules/miniapp/components/MiniAppLayout.vue` | Shell | LEGACY | Runtime (unrouted after prior fix) → **DELETED** |
| `modules/miniapp/views/HomePage.vue` | Home | LEGACY | Unrouted → **DELETED** |
| `modules/miniapp/views/{Competitions,Wallet,Profile,Leaderboard,Categories,Deposit,Withdraw,CompetitionDetail}Page.vue` | Pages | LEGACY | Unrouted → **DELETED** |
| `modules/miniapp/components/*` (15 files) | Cards/nav | LEGACY | Unrouted → **DELETED** |
| `modules/miniapp/styles/tokens.css` | `--ma-*` | LEGACY | Unrouted → **DELETED** |
| `modules/miniapp/utils/format.ts`, `status.ts` | Helpers | LEGACY-only | **DELETED** |
| `modules/miniapp/routes.ts` | Routes → UserLayout + user views | CANONICAL | **Runtime** |
| `modules/miniapp/telegram.ts` | TG WebApp helpers | ENV (not design) | **Runtime** |
| `modules/miniapp/views/TelegramAuthErrorPage.vue` | TG auth failure | CANONICAL (error only) | **Runtime** |
| `modules/miniapp/utils/qty.ts` + `qty.test.ts` | QTY helpers | Utility | **Test + available** (not a UI shell) |
| `modules/user/.../UserLayout.vue` | Shell | CANONICAL | **Runtime** |
| `modules/user/views/DashboardPage.vue` | Home | CANONICAL | **Runtime** |
| `styles/mvp-design-tokens.css` | Design system | CANONICAL | **Runtime** |
| `modules/trade/views/TradingPage.vue` | Trading content | CANONICAL SPA | **Runtime** (same app root) |

No service worker was serving an alternate design.

---

## 3. What was removed

Deleted from `apps/user-frontend/src/modules/miniapp/`:

- Entire `components/` tree including **`MiniAppLayout.vue`**
- Entire legacy `views/` tree except **`TelegramAuthErrorPage.vue`**
- **`styles/tokens.css`** (`--ma-*`)
- **`utils/format.ts`**, **`utils/status.ts`**

**Kept (non-design):**

- `telegram.ts` — initData, theme, safe-area
- `routes.ts` — maps `/miniapp/*` → canonical user views
- `TelegramAuthErrorPage.vue` — TG failure fallback (not password login)
- `utils/qty.ts` + unit test — non-UI helper

---

## 4. Canonical design entrypoints

| URL | Auth | Mounted UI |
|-----|------|------------|
| `/` | → `/user/dashboard` | Canonical (guard → login if guest) |
| `/user/dashboard` | required | **UserLayout + DashboardPage** |
| `/miniapp`, `/miniapp/home` | required + TG bootstrap | **UserLayout + DashboardPage** |
| `/miniapp/competitions` | required | UserLayout + ContestsPage |
| `/miniapp/wallet` | required | UserLayout + WalletPage |
| `/contest/:id` | redirect | `/user/contests/:id` (UserLayout + ContestDetails) |
| `/trade/:contestId` | required | Same SPA; TradingPage (no MiniAppLayout) |
| `/user/login` | public | Login only for **non-Telegram** guests |

Hierarchy (DashboardPage): Header → Hero → Wallet metrics → Featured → Suggested → Challenges → Support → bottom nav (mobile).

Desktop: same components; `UserLayout` sidebar ≥768px; dashboard `.desktop-extra` blocks.

---

## 5. Telegram auth behavior (preserved)

```text
Telegram.WebApp.initData (signed)
  → await auth.bootstrapFull()   // BEFORE app.use(router)
  → POST /api/user/auth/telegram { init_data }
  → HMAC + findOrCreate
  → User JWT
  → /miniapp/home (canonical dashboard)
```

- Never `/user/login` when initData is present and exchange succeeds or is in-flight.
- Definitive failure → `/miniapp/auth-error` (not password form).
- No `initDataUnsafe` for identity.
- No `setTimeout` races.

---

## 6. Responsive behavior

| Viewport | Behavior |
|----------|----------|
| 360–430 | Bottom nav, compact cards, horizontal rails |
| 768 | Transition to sidebar chrome |
| 1024–1440+ | Sidebar + desktop extras; same MVP tokens |

Telegram: `html.is-telegram-shell` + safe-area CSS vars only.

---

## 7. Cache / build verification

| Check | Result |
|-------|--------|
| Service worker | None registered |
| Vite build | New hashes e.g. `index-DGkai4tL.js` (served via gateway) |
| Legacy chunks | MiniAppLayout / miniapp HomePage **deleted**; not in build graph |
| Deploy | Rebuilt `docker-user-frontend` image; recreated `user-frontend` + `gateway` |
| Live index | `http://127.0.0.1:8080/` and `https://panel.tragge.com/` both serve `index-DGkai4tL.js` |

Users do not need a manual “clear cache” procedure; content-hashed assets + new index reference are the invalidation mechanism.

---

## 8. Tests

| Suite | Result |
|-------|--------|
| `auth_bootstrap.test.ts` (5) | **PASS** — includes “legacy files deleted” |
| `qty.test.ts` | **PASS** |
| user-frontend `npm run build` | **PASS** |
| `e2e/telegram-miniapp-auth.spec.ts` | asserts no login + no `.miniapp-root` |
| `e2e/canonical-user-ui.spec.ts` | `/user/dashboard` & `/miniapp/home` same shell; `/contest/:id` redirect; trade no miniapp-root |

---

## 9. Gates

| Gate | Result |
|------|--------|
| `frontend-gate.mjs` | **PASS** (new CANONICAL UI checks) |
| `mvp-gate.mjs` | **PASS** |
| `acceptance-gate.mjs` | **PASS** |
| `trading-mobile-gate.mjs` | **PASS** (legacy files absent) |

---

## 10. Browser evidence expectations

After gateway serves the new build:

1. Open `/user/dashboard` → MVP home (`.home`, MobileHomeHeader hierarchy).
2. Open `/miniapp/home` (authed) → **same** `.home` DOM; **no** `.miniapp-root`.
3. Open `/trade/:id` → no `.miniapp-root`.
4. Telegram with valid initData → never URL `/user/login`.

---

## Acceptance checklist

| Criterion | Status |
|-----------|--------|
| Old design gone from runtime | **YES** (files deleted + unrouted) |
| `/user/dashboard` = NEW design | **YES** |
| `/miniapp/home` = SAME NEW design | **YES** |
| `/trade/:id` same User SPA | **YES** |
| Mobile/desktop same design system | **YES** |
| Telegram never login with valid initData | **YES** (bootstrap order) |
| No stale SW dual design | **YES** |

**USER UI — PASS**
