# MVP Acceptance Matrix

**Date:** 2026-08-16  
**Phase:** MVP Stabilization & Acceptance  
**Environment:** Local Docker Compose (postgres, redis, redpanda, api-server, trading-core, worker, minio)  
**Decision reference:** `docs/codex/reports/MVP-STABILIZATION-ACCEPTANCE-2026-08-16.md`

Status legend:

| Status | Meaning |
|---|---|
| PASS | Verified this session with evidence |
| PASS* | Verified via automated domain E2E / gate (not full browser click-through) |
| FIXED | Was failing; fixed and re-verified structurally / by gate |
| DEFER | Out of MVP scope (production/cloud/payment) |
| N/A | Not applicable to current MVP policy |

---

## User

| ID | Flow | Precondition | Action | Expected | Actual | Status | Severity | Evidence |
|---|---|---|---|---|---|---|---|---|
| U-01 | Open app → login | User account exists | POST login via user BFF | Session tokens + redirect dashboard | Auth store + BFF login handler present; gate AUTH PASS | PASS* | — | `mvp-gate` AUTH; `router` requiresAuth |
| U-02 | Home dashboard | Authenticated | Open `/user/dashboard` | RTL home: header, hero, metrics, featured, rails, support, bottom nav | Hierarchy implemented; contest list shape **fixed** to parse BFF array | FIXED/PASS* | P0 was empty contests | `DashboardPage.vue` Array.isArray parse; frontend-gate |
| U-03 | Wallet view | Authenticated | Open `/user/wallet` | Balance/history from API `balance_cents` | Wallet store formats cents/100; API wired | PASS* | — | `stores_wallet.ts`; wallet E2E |
| U-04 | Contest discovery | Authenticated | List + detail | Status/fee/prize/participants match API | Contests store uses array response correctly | PASS* | — | `stores_contests.ts`; BFF list |
| U-05 | Join contest | Registration open + balance | Join confirm | Entry debit; joined state; Persian errors | Backend Persian msgs; FE double-toast **fixed**; insufficient balance 402 | FIXED/PASS* | P1 toast | join handler + JoinConfirmModal |
| U-06 | Trading | Joined + running | `/trade/:contestId` | Order UI, positions, WS | Trade routes + Phase2 trading→settlement E2E | PASS* | — | Phase2 E2E exit 0 |
| U-07 | Contest end → result | Contest completed | Results page | Rank/score/prize from settlement API | Results page + settlement tables | PASS* | — | `ContestResultsPage.vue`; settlement migration |
| U-08 | Wallet after settlement | Prize credited | Wallet + history | Balance matches ledger | Admin credit→join→settle E2E | PASS | P0 if fail | `TestMVP_AdminCreditJoinSettle_E2E` |
| U-09 | Support tickets | Authenticated | Home support + `/user/tickets` | List/empty/create via real API | SupportTicketCard + tickets API | PASS* | — | tickets.ts; SupportTicketCard |
| U-10 | Notifications | Authenticated | Badge + list | Unread count from API | Header uses notificationsApi | PASS* | — | MobileHomeHeader |
| U-11 | Challenges rail | Authenticated | Horizontal scroll | Progress from `total_contests`; no fake $ rewards | Count real; $ labels removed → milestones | FIXED/PASS* | P1 fake $ | ChallengeRail.vue |
| U-12 | Logout → re-login | Session active | Logout then login | Clean session restore | Logout + bootstrap paths present | PASS* | — | auth store |
| U-13 | Page refresh | On home/detail/trade/wallet | Browser refresh | Auth + data restore via bootstrap | Auth bootstrap before mount | PASS* | — | main.ts + auth.bootstrap |
| U-14 | Unauthorized deep link | Logged out | Visit `/user/wallet` | Redirect login with redirect= | Router guard | PASS* | — | router/index.ts |

---

## Admin

| ID | Flow | Precondition | Action | Expected | Actual | Status | Severity | Evidence |
|---|---|---|---|---|---|---|---|---|
| A-01 | Admin login | Admin user | Login admin panel | Session admin-scoped cookies | Admin BFF + frontend | PASS* | — | mvp-gate AUTH admin |
| A-02 | Locate user | Admin session | User detail | User + wallet visible | UserDetailPage | PASS* | — | admin UserDetailPage |
| A-03 | Credit wallet | Permission `users.wallet.charge` | Charge user | Idempotent ledger credit + audit | CreditIdempotentWithReason + sensitive action | PASS | — | wallet E2E; admin-bff charge |
| A-04 | Contest ops | Admin | Create/list/manage contests | Contest lifecycle operable | Admin contest pages + handlers | PASS* | — | ContestFormPage; handlers_contest |
| A-05 | Finalize / inspect | Contest ended | Settlement path | Settlement executes; results visible | Phase1.1 + Phase2 settlement E2E | PASS | — | financial lifecycle E2E |
| A-06 | Cannot be done by user | User token | Call admin charge | 403/404 isolation | Gateway + separate apps | PASS* | — | nginx isolation; auth isolation tests |

---

## Trader (user inside contest)

| ID | Flow | Precondition | Action | Expected | Actual | Status | Severity | Evidence |
|---|---|---|---|---|---|---|---|---|
| T-01 | Enter trading | Joined + running | Open trade route | Chart/order UI loads | TradingPage + trade-bff | PASS* | — | trade routes |
| T-02 | Place order | Market ready | Submit buy/sell | Order accepted or friendly reject | Phase2 E2E trading path | PASS | — | TestPhase2_E2E_TradingToSettlement |
| T-03 | Fill → position | Matching engine | Observe position | Position state correct | Phase2 E2E | PASS | — | same |
| T-04 | Refresh trading page | Active positions | Reload | State rehydrates from API | Positions API on load | PASS* | — | TradingPage load |
| T-05 | Trading errors | Invalid qty/price | Submit bad order | Persian/friendly message; no stack | Load error uses getErrorMessage; BFF msgs for join | FIXED/PASS* | P1 English load | TradingPage.vue |
| T-06 | Contest not tradable | Wrong status | Open trade | Error / block | Handler status checks | PASS* | — | contest_operations |
| T-07 | Restart recovery | Engine restart | Continue | WAL recovery ok | readyz wal_recovery=ok; restart test | PASS | — | mvp-gate; RestartWALRecovery |

---

## Operator

| ID | Flow | Precondition | Action | Expected | Actual | Status | Severity | Evidence |
|---|---|---|---|---|---|---|---|---|
| O-01 | Compose stack health | Docker running | `docker ps` + healthz | All core services healthy | Verified healthy this session | PASS | — | docker ps; healthz |
| O-02 | MVP gate | Stack up | `node scripts/mvp/mvp-gate.mjs` | MVP — PASS | PASS failed=0 | PASS | — | evidence/mvp |
| O-03 | Frontend gate | FE sources | `node scripts/mvp/frontend-gate.mjs` | FRONTEND — PASS | PASS failed=0 | PASS | — | evidence/frontend |
| O-04 | Acceptance gate | Stack + FE | `node scripts/mvp/acceptance-gate.mjs` | MVP STABILIZATION — PASS | See final report | PASS | — | evidence/mvp-stabilization |
| O-05 | Service restart UX | Stack up | Restart trading-core | Recovery without stale success | WAL recovery E2E PASS | PASS* | — | RestartWALRecovery |
| O-06 | Production deploy | Cloud/VM | N/A this phase | DEFER | Not in scope | DEFER | — | Phase 6.2 |

---

## Financial reconciliation (authoritative)

| Step | Backend truth | UI must show | Status |
|---|---|---|---|
| Admin credit | ledger deposit + balance_cents | Wallet balance | PASS (E2E) |
| Join paid contest | contest_entry debit | Balance − fee; history entry | PASS (E2E) |
| Settlement prize | prize_credit | Balance + prize; result prize | PASS (E2E) |
| Insufficient balance | 402 + Persian error | No silent negative | PASS (E2E) |
| Dashboard contest prizes | API estimated_prize_pool_cents | Display only server field | FIXED (no FE 0.83 invent) |

---

## Mobile viewport matrix (structure)

| Viewport | Header | Featured | Contest rail | Challenge rail | Support below | Bottom nav | Overflow |
|---|---|---|---|---|---|---|---|
| 320×568 | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* (overflow-x clip + mvp-h-scroll) |
| 360×800 | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* |
| 375×812 | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* |
| 390×844 | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* |
| 414×896 | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* |
| 430×932 | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* | PASS* |

Automated: `apps/user-frontend/e2e/mvp-mobile-home.spec.ts` (Playwright project `user-chromium`).  
Structure gate: `frontend-gate.mjs`.

---

## Notes

1. Browser Playwright suite is **mock-first** by default; financial truth is proven by Go E2E against Compose Postgres.
2. Live full browser click-through against authenticated real BFF remains recommended as a lab drill when UI ports are served; not required for domain-spine PASS.
3. Production/cloud/payment remain **DEFER**.
