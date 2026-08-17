# MVP Stabilization & Acceptance — 2026-08-16

## Executive Decision

**MVP STABILIZATION — PASS**

Claimed:

- `MVP — FUNCTIONALLY COMPLETE` (prior)
- `FRONTEND — PASS` (prior)
- `LOCAL STAGING — FULLY QUALIFIED` (prior)
- **`MVP RELEASE CANDIDATE`** (this phase)

**Not claimed:** `PRODUCTION — GO` · payment gateway · cloud · Kubernetes · legal/provider sign-off.

---

## What this phase did

Stabilization only — no new product features.

1. Built acceptance matrix + bug backlog + acceptance gate  
2. Audited user / admin / trader journeys against real contracts  
3. Found and fixed core P0/P1 blockers  
4. Re-ran financial E2E, frontend gate, MVP gate, acceptance gate  
5. Froze local release-candidate metadata  

---

## User Acceptance

| Journey step | Result |
|---|---|
| Login → home | PASS* (auth guard + bootstrap) |
| Wallet | PASS* (balance_cents API) |
| Contest discovery | **FIXED** empty home rails (array parse) |
| Join | PASS* (Persian BFF errors; single toast) |
| Trading | PASS (Phase2 E2E) |
| Result / ranking / prize | PASS* + settlement E2E |
| Support under challenges | PASS* (real tickets API) |
| Challenges horizontal | PASS* (real total_contests; no fake $) |
| Notifications badges | PASS* |
| Logout / refresh / deep links | PASS* (router + bootstrap) |

Full matrix: `docs/codex/mvp/MVP-ACCEPTANCE-MATRIX.md`

---

## Admin Acceptance

| Journey step | Result |
|---|---|
| Login | PASS* |
| Locate user | PASS* |
| Wallet credit (idempotent) | **PASS** live E2E |
| Contest management surfaces | PASS* |
| Finalize / settlement inspect | **PASS** financial lifecycle E2E |
| User cannot charge wallets | PASS* (origin isolation + permissions) |

Funding path remains:

```text
Admin charge → wallet ledger → user balance → join debit → settlement prize credit
```

No payment gateway.

---

## Trading Acceptance

| Journey step | Result |
|---|---|
| Enter `/trade/:contestId` | PASS* |
| Order → fill → position | **PASS** `TestPhase2_E2E_TradingToSettlement` |
| Engine restart / WAL | **PASS** `TestPhase2_E2E_RestartWALRecovery` + `wal_recovery: ok` |
| Error UX load path | **FIXED** Persian/shared error message |
| Active contests list shape | **FIXED** array parse |

---

## Browser / Mobile

### Gates

| Command | Result |
|---|---|
| `node scripts/mvp/frontend-gate.mjs` | **FRONTEND — PASS** exit 0 |
| `node scripts/mvp/mvp-gate.mjs` | **MVP — PASS** exit 0 |
| `node scripts/mvp/acceptance-gate.mjs` | **MVP STABILIZATION — PASS** exit 0 |

### Mobile hierarchy (preserved)

```text
Header → Hero → Wallet summary → Featured contest
→ Suggested contests (horizontal)
→ Challenges (horizontal)
→ Support ticket
→ Bottom navigation
```

### Viewport matrix

Structural acceptance encoded in `apps/user-frontend/e2e/mvp-mobile-home.spec.ts` for 320 / 360 / 375 / 390 / 414 / 430 widths.  
CSS: `overflow-x: clip` on home; rails use `.mvp-h-scroll`; bottom nav uses `safe-area-inset-bottom`.

### Playwright note

Default browser suite is **mock-first** for determinism. Financial truth is certified by **live Go E2E against Compose Postgres**, not mocks.

---

## Financial Verification

Live Compose Postgres (`TRAGGE_E2E_DATABASE_URL`):

| Test | Exit |
|---|---|
| `TestMVP_AdminCreditJoinSettle_E2E` + insufficient balance | 0 |
| `TestPhase11_FinancialLifecycle_E2E` | 0 |
| `TestPhase2_E2E_TradingToSettlement` | 0 |
| `TestPhase2_E2E_RestartWALRecovery` | 0 |

Invariants covered:

- admin credit balance  
- join debit  
- prize credit  
- no unexplained negative balance  
- insufficient funds rejection  

FE financial display rule enforced this phase:

- do not invent prize pool (`* 0.83` removed from contest details)  
- display server `estimated_prize_pool_cents` only  

---

## Bug Backlog

Full list: `docs/codex/mvp/MVP-BUG-BACKLOG.md`

| Severity | Open | Fixed this phase |
|---|---|---|
| P0 | **0** | 1 (empty dashboard contests) |
| P1 core | **0** | 8 |
| P2 | 10 | documented |
| P3 | 4 | documented |

### Critical fix detail (P0-1)

BFF `GET /api/user/contests` returns a **JSON array**.  
`DashboardPage` previously read `response.data.contests` → always `[]` → empty featured + suggested rails.  
**Fixed** with array/envelope-safe parse (also free tournaments + trade `getActiveContests`).

---

## Release Candidate Freeze

| Field | Value |
|---|---|
| Git HEAD (base commit) | `478c9331e59c600942b927ce1f1e4a47c5565bed` |
| Working tree | Dirty with stabilization + prior MVP/frontend artifacts (not yet committed) |
| Migration head | `0103_contest_economics_lock` |
| Compose | Local Docker Desktop stack (`tragge_postgres`, `tragge_api_server`, `tragge_trading_core`, `tragge_worker`, redis, redpanda, minio) |
| User frontend version | `1.0.0` (`@tragge/user-frontend`) |
| Gates | acceptance-gate · mvp-gate · frontend-gate all exit 0 |
| Known residual | P2/P3 only (see backlog) |

**Freeze rule:** no new feature work until RC report exists — **this document satisfies that**.

Evidence:

- `docs/codex/reports/evidence/mvp-stabilization/acceptance-gate-latest.{txt,json}`  
- `docs/codex/reports/evidence/mvp/mvp-gate-latest.json`  
- `docs/codex/reports/evidence/frontend/frontend-gate-latest.txt`  

---

## Security / authorization (sanity)

- User app does not call `/api/admin`  
- Admin wallet charge requires `users.wallet.charge` + sensitive action  
- Gateway origin isolation (user vs admin) documented in prior phases  
- Free-practice no longer invents ranks with `Math.random`  

---

## Deferred Work (not MVP blockers)

- Payment gateway  
- Cloud / production VM qualification  
- Production S3 / multi-region / HA-DR  
- Kubernetes production path  
- Legal / external provider sign-off  
- Advanced analytics  
- Challenge reward ledger productization  
- Full authenticated Playwright integration mode as default CI  

---

## Commands for re-certification

```bash
# Stack must be healthy (Docker Desktop)
export DOCKER_BIN="C:\Users\parsa\AppData\Local\Programs\DockerDesktop\resources\bin\docker.exe"

node scripts/mvp/frontend-gate.mjs
node scripts/mvp/mvp-gate.mjs
node scripts/mvp/acceptance-gate.mjs
```

---

## CTO close

A real user can complete the MVP path from login through wallet, contest, join, trading, settlement result, support, and challenges without a core functional, financial, or security blocker on the local qualified stack.

A real admin can credit wallets and operate contests without inventing a payment gateway.

A real trader path is covered by trading→settlement and WAL recovery E2E.

**MVP STABILIZATION — PASS**  
**MVP RELEASE CANDIDATE** certified for local use.  
**Not production GO.**
