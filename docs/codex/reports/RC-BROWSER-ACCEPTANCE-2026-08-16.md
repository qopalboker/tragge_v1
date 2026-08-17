# RC Browser Acceptance — 2026-08-16

## Executive Decision

**RC BROWSER — PASS**

Not claimed: `PRODUCTION — GO` · payment gateway · cloud · Kubernetes · legal/provider sign-off.

Architecture rule honored: **no** microservice decomposition; merged `api-server` / `trading-core` / `worker` topology unchanged except local port publishes for Vite.

---

## Environment

| Item | Value |
|---|---|
| OS | Windows |
| Docker Desktop | Running (`tragge_postgres`, `tragge_api_server`, `tragge_trading_core`, `tragge_worker`, redis, redpanda, minio) |
| User BFF | `http://127.0.0.1:8081` (published via compose override for local Vite) |
| Admin BFF | `http://127.0.0.1:8083` |
| Trade BFF | `http://127.0.0.1:8082` |
| User frontend | Vite `http://127.0.0.1:5173` (real API proxy, **no mocks**) |
| Admin frontend | Vite `http://127.0.0.1:5174` |
| Browser | System Google Chrome via `E2E_CHROME_PATH` (Playwright Chromium CDN download failed 400) |
| Credentials | Env-driven: `RC_USER_*`, `RC_ADMIN_*` (defaults from `scripts/create-admin-users`) |
| Admin MFA | Local secret file `var/rc-admin-mfa.json` (gitignored under `var/`) from `scripts/mvp/rc-admin-mfa-enroll.mjs` |

Viewport matrix exercised: **320, 360, 375, 390, 414, 430** + tablet 768 + desktop 1280.

---

## User Flow

| Step | Result | Evidence |
|---|---|---|
| Open login | PASS | Real page load |
| Login (real BFF) | PASS | Redirect dashboard; `$500.00` wallet after seed |
| Refresh persistence | PASS | Dashboard survives reload |
| Protected route redirect | PASS | `/user/wallet` → login when logged out |
| Mobile home hierarchy | PASS (all 6 widths) | Header → Hero → Metrics → Featured rails → Challenges → Support → Bottom nav |
| No page horizontal overflow | PASS after fix | Was P0 (`scrollWidth=720`); fixed |
| Suggested + challenge H-scroll | PASS | `.mvp-h-scroll` present; page stable |
| Support below challenges | PASS | Bounding-box order |
| Wallet page | PASS | Real balance from API |
| Contest list/detail | PASS | Real contests from BFF |
| Join free running contest | PASS | UI + state after join |
| Trading page load | PASS | `/trade/:id` with real session (market quotes may be stale in lab) |
| Bottom nav destinations | PASS | Contests ↔ Home |
| Tablet/desktop | PASS | Screenshots |

Playwright project: `rc-user-integration` — **13/13 passed**.

---

## Admin Flow

| Step | Result | Evidence |
|---|---|---|
| Admin login + MFA | PASS | Super Admin TOTP challenge |
| Session after reload | PASS | Stays off login |
| Users / wallet credit UI | PASS | Authenticated `/admin/users` shell |
| Contests list | PASS | `/admin/contests` |
| Authorization isolation | PASS | Unauthenticated admin API → 401/403/404 |

Playwright project: `rc-admin-integration` — **4/4 passed**.

Admin wallet charge uses existing product path (confirm + password reauth grant). Full ledger credit path remains covered by `TestMVP_AdminCreditJoinSettle_E2E` in mvp-gate.

---

## Trading

| Item | Result |
|---|---|
| Trade route browser load after free join | PASS |
| Trade-bff health | PASS |
| Domain trading→settlement | PASS via mvp-gate Phase2 E2E |
| WAL recovery | PASS via mvp-gate restart test |
| Live market ticks | P2 lab note: `all_quotes_stale` may limit fill realism |

No microservice split performed.

---

## Financial

| Check | Result |
|---|---|
| User wallet API after seed (`50000` cents) | Shown as `$500.00` on home |
| Admin credit→join→settle | mvp-gate Go E2E PASS |
| Phase 1.1 lifecycle | PASS |
| Insufficient balance | PASS (domain) |
| No FE prize invention | Prior stabilization fix retained |

---

## Responsive / Visual

| Viewport | Hierarchy | Overflow | Screenshot |
|---|---|---|---|
| 320–430 (6 sizes) | PASS | PASS (after fix) | `user-home-*.png` |
| Tablet 768 | PASS | PASS | `user-home-tablet.png` |
| Desktop 1280 | PASS | PASS | `user-home-desktop.png` |

RTL: `dir="rtl"` on home; Persian/EN switch available on login.

---

## Browser E2E

```bash
E2E_INTEGRATION=1
E2E_CHROME_PATH="C:\Program Files\Google\Chrome\Application\chrome.exe"
npx playwright test --project=rc-user-integration --project=rc-admin-integration --workers=1
```

**Result: 17 passed (12.1m)**

Specs:

- `apps/user-frontend/e2e/rc-browser-user.spec.ts`
- `apps/admin-frontend/e2e/rc-browser-admin.spec.ts`

Gate:

- `scripts/mvp/browser-rc-gate.mjs`

Helpers:

- `scripts/mvp/rc-admin-mfa-enroll.mjs`

Evidence dir:

- `docs/codex/reports/evidence/mvp-rc-browser/`

---

## Bug Backlog

See `docs/codex/mvp/RC-BROWSER-BUG-BACKLOG.md`.

| Severity | Open |
|---|---|
| P0 | **0** |
| P1 core | **0** |
| P2 | 5 documented |
| P3 | 2 documented |

### Critical fix this phase

**Mobile horizontal overflow** — home used `max-width: 720px` without constraining to viewport width, so `documentElement.scrollWidth` was 720 on all mobile sizes. Fixed with `width:100%`, `max-width:min(720px,100%)`, document `overflow-x:clip`, and non-expanding rails.

---

## Release Candidate

| Field | Value |
|---|---|
| Git HEAD | `478c9331e59c600942b927ce1f1e4a47c5565bed` (+ local RC browser worktree) |
| Migration head | `0103_contest_economics_lock` |
| Compose | Local Docker Desktop app stack |
| Playwright | 17/17 RC integration tests PASS |
| Frontend gate | PASS (nested) |
| MVP gate | PASS (nested) |
| Browser RC gate | `scripts/mvp/browser-rc-gate.mjs` |

---

## Deferred (not blockers)

- Payment gateway  
- Cloud / production VM  
- Kubernetes  
- Runtime service decomposition  
- Fresh market-data provider for non-stale quotes  
- Legal / external sign-off  

---

## How to re-run

```powershell
# 1) Compose healthy + override ports 8081/8082 published
# 2) Vite user:5173 admin:5174
# 3) Seed users + MFA secret
go run ./scripts/create-admin-users   # from module dir if needed
node scripts/mvp/rc-admin-mfa-enroll.mjs

$env:E2E_INTEGRATION=1
$env:E2E_CHROME_PATH="C:\Program Files\Google\Chrome\Application\chrome.exe"
$env:DOCKER_BIN="C:\Users\parsa\AppData\Local\Programs\DockerDesktop\resources\bin\docker.exe"
node scripts/mvp/browser-rc-gate.mjs
```

---

## CTO close

A real browser session against the real local stack completed the user journey (login → home hierarchy → wallet → contests → join → trade route → support/challenges/nav) and the admin journey (MFA login → users → contests → authz isolation) with **zero open P0/P1**.

**RC BROWSER — PASS**
