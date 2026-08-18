# USER UI UNIFICATION + TELEGRAM AUTH BOOTSTRAP — 2026-08-17

## Verdict

**PASS (implementation)** for:

- Telegram Mini App never redirected to `/user/login` while valid `initData` is available (bootstrap completes **before** router install).
- Single canonical User UI path: `UserLayout` + `DashboardPage` (MVP tokens) for both `/user/*` and `/miniapp/*`.
- Normal browser still uses password login when unauthenticated.

**Not claimed:** Live BotFather phone session inside Telegram client (requires real bot + operator device). Simulated via signed initData + Playwright mock path.

---

## 1. Root cause — Telegram login redirect

### Failure sequence (before fix)

1. `main.ts` called `app.use(router)` **before** Telegram `initData` exchange finished (or ran Telegram only after cookie bootstrap while router install could race).
2. Global `beforeEach` treated `/miniapp/*` as `requiresAuth`.
3. Cookie bootstrap alone left cold Telegram users **unauthenticated**.
4. Guard returned `{ path: '/user/login' }`.
5. User saw the normal password login form inside Telegram.

### Fix

1. **`auth.bootstrapFull()`** — phases: `initializing` → `telegram_authenticating` → `authenticated` | `unauthenticated` | `error`.
2. **`await auth.bootstrapFull()` then `app.use(router)`** — no guard evaluation until Telegram exchange is terminal.
3. Guard rules:
   - never send Telegram / miniapp meta to `/user/login`;
   - on definitive Telegram failure → `/miniapp/auth-error` (not password form);
   - while `telegram_authenticating`, block navigation to login.

No `setTimeout` hacks.

---

## 2. Root cause — multiple visual designs

Not a service worker / dual build issue.

| Shell | Route home | Layout | Home view | Tokens |
|-------|------------|--------|-----------|--------|
| Web panel | `/user/dashboard` | `UserLayout` | `DashboardPage` | `--mvp-*` |
| Mini App (old) | `/miniapp/home` | `MiniAppLayout` | miniapp `HomePage` | `--ma-*` |

Two complete product trees shipped in one SPA. Gateway always served the same hashed bundle; **routing chose the design**.

No service worker registration; Vite hashed assets invalidate correctly on rebuild.

---

## 3. Canonical User App entrypoint

| Context | Entry | Shell | Home |
|---------|-------|-------|------|
| Browser (auth) | `/` → `/user/dashboard` | `UserLayout` | `DashboardPage` |
| Browser (guest) | `/user/dashboard` → guard → `/user/login` | — | LoginPage |
| Telegram Mini App | `/miniapp/home` (BotFather URL) | **same** `UserLayout` | **same** `DashboardPage` |
| Trade | `/trade/:contestId` | TradingPage (same SPA app root) | — |

---

## 4. Removed / retired dual paths

| Change | Status |
|--------|--------|
| Mini app routes mount `UserLayout` + user views | **Done** |
| miniapp `HomePage` / parallel shell no longer routed | **Retired from runtime routing** (files kept for reference/tests; not entry) |
| Mini app deposit/withdraw → wallet (unified) | **Redirect** |
| `TelegramAuthErrorPage` | **Added** for TG auth failure |

---

## 5. Auth bootstrap sequence

```text
createApp + pinia + i18n + theme
  → await auth.bootstrapFull()
       → cookie session (session hint + /refresh + /me)
       → if unauthenticated && Telegram.WebApp.initData:
            phase=telegram_authenticating
            POST /api/user/auth/telegram { init_data }
            set JWT + fetchUser
       → phase=authenticated | unauthenticated | error
  → app.use(router)
  → if Telegram && authenticated && path is / or login → replace /miniapp/home
  → router.isReady()
  → mount
```

Identity: **server HMAC on signed `initData` only** — never `initDataUnsafe`.

---

## 6. Responsive desktop / mobile strategy

- **One** layout: `UserLayout` (sidebar ≥768px, bottom nav &lt;768px).
- **One** home: `DashboardPage` hierarchy (Header → Hero → Wallet metrics → Featured → Suggested → Challenges → Support).
- Desktop: same components; extra leaderboard/win-rate cards in `.desktop-extra`.
- Telegram: `html.is-telegram-shell` + safe-area / theme vars only — not a second product UI.

Breakpoints covered by existing layout CSS: 320–430 (mobile), 768 (tablet), 1024+ (desktop).

---

## 7. Telegram behavior

| Case | Expected |
|------|----------|
| First-time TG identity | create user + JWT → `/miniapp/home` |
| Returning TG identity | same `telegram_id` → same user → `/miniapp/home` |
| Valid initData | **never** `/user/login` |
| Failed / missing initData | `/miniapp/auth-error` + retry |
| Normal browser | unauthenticated → `/user/login` |

---

## 8. Cache / stale bundle findings

| Check | Result |
|-------|--------|
| Service worker | None registered (PWA stub disabled) |
| Vite build | Hashed assets (`DashboardPage-*.js`, `index-*.js`) |
| Gateway | Single SPA `try_files` → user-frontend |
| Dual design cause | Routing, not cache |

After deploy: rebuild `user-frontend` image / static dist so gateway serves new hashes.

---

## 9. Evidence

### Unit / contract (vitest)

`src/stores/auth_bootstrap.test.ts` — **4/4 PASS**

- router installed after `bootstrapFull`
- guard Telegram rules
- miniapp uses UserLayout + DashboardPage

### Build

`npm run build` (user-frontend) — **PASS**

### Gates

| Gate | Result |
|------|--------|
| `frontend-gate.mjs` | **PASS** |
| `mvp-gate.mjs` | **PASS** |
| `trading-mobile-gate.mjs` | **PASS** (bootstrap ordering + unified Mini App UI) |
| `acceptance-gate.mjs` | **PASS** |
| `trading-certification-gate.mjs` | **BLOCKED** (lab: Vite/trade-bff not reachable for Playwright slice; not UI-auth regression) |

### Playwright

`e2e/telegram-miniapp-auth.spec.ts`:

- mocks `Telegram.WebApp.initData` + POST `/auth/telegram`
- asserts URL never matches `/user/login`
- asserts normal browser `/user/dashboard` → login

---

## 10. Files touched

- `apps/user-frontend/src/main.ts`
- `apps/user-frontend/src/router/index.ts`
- `apps/user-frontend/src/stores/auth.ts`
- `apps/user-frontend/src/modules/miniapp/routes.ts`
- `apps/user-frontend/src/modules/miniapp/views/TelegramAuthErrorPage.vue`
- `apps/user-frontend/src/modules/user/components/layout/UserLayout.vue`
- `apps/user-frontend/src/modules/user/components/layout/BottomNav.vue`
- `apps/user-frontend/src/styles/mvp-design-tokens.css` (Telegram safe-area shell)
- `apps/user-frontend/src/stores/auth_bootstrap.test.ts`
- `apps/user-frontend/e2e/telegram-miniapp-auth.spec.ts`
- `scripts/mvp/trading-mobile-gate.mjs`
- this report

---

## Acceptance checklist

| Criterion | Status |
|-----------|--------|
| Telegram → User Panel without password login | **Fixed in code** |
| First-time TG auto profile | Server path unchanged (0101 + findOrCreate) |
| Returning TG same profile | Unique `telegram_id` |
| One User UI | Miniapp mounts DashboardPage/UserLayout |
| Desktop/mobile responsive same system | UserLayout + DashboardPage |
| Mini App same UI | Yes |
| No random design switch | Single routed shell |
| No stale SW design | N/A |
| Gates | frontend + mvp PASS |

**FINAL: PASS (code + gates). Live Telegram client open remains operator verification on `https://panel.tragge.com/miniapp/home`.**
