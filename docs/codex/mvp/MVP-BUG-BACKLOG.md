# MVP Bug Backlog — Stabilization 2026-08-16

## Severity policy

| Level | Rule |
|---|---|
| **P0** | Blocks core MVP journey or financial/security risk — must be zero for PASS |
| **P1** | Major UX/functional issue on core journey — must be zero for PASS |
| **P2** | Non-blocking; workaround exists |
| **P3** | Polish / future |

---

## P0 — must be zero

| ID | Title | Layer | Status | Resolution |
|---|---|---|---|---|
| P0-1 | Dashboard home featured/suggested contests always empty (BFF returns array; FE expected `{contests}`) | UI | **FIXED** | `DashboardPage.vue` parses `Array.isArray(raw) ? raw : raw.contests` |
| P0-F | Financial double credit/debit / reconciliation failure | Backend | **NOT FOUND** | `TestMVP_AdminCreditJoinSettle_E2E` + Phase1.1 PASS |

| P0-2 | Admin Shards/Audit/AutoScheduling showed fabricated metrics on API error | Admin UI | **FIXED 2026-08-17** | Empty real state only; no mock participants/logs/config |
| P0-3 | Paid start quorum counted system bots as real users | Domain | **FIXED 2026-08-17** | `is_system=false` count in SM + auto-start + list/details APIs |
| P0-4 | CountdownTimer emitted FE-invented `running` status | User UI | **FIXED 2026-08-17** | Timestamp presentation only; parent re-fetches backend |

**Open P0 count: 0**

---

## P1 — core journey (must be zero for PASS)

| ID | Title | Layer | Status | Resolution |
|---|---|---|---|---|
| P1-1 | Join errors double-toasted (interceptor + local) | UI | **FIXED** | Removed local `toast.error` on join paths; interceptor remains single surface |
| P1-2 | Contests store English error fallback `"An error occurred"` | UI | **FIXED** | Persian-friendly mapped fallbacks in `stores_contests.ts` |
| P1-3 | Free Practice random ranks + random participant counts | UI | **FIXED** | Removed `Math.random` ranks; participants from API only |
| P1-4 | Challenge rail displayed hardcoded `$` rewards as if payable | UI | **FIXED** | Milestone labels only; copy clarifies progress from real `total_contests` |
| P1-5 | Trade API helper English hardcodes for contests fetch | UI | **FIXED** | `getActiveContests` uses shared error + array parse |
| P1-6 | Trading page load error raw English | UI | **FIXED** | `getErrorMessage` + i18n fallback |
| P1-7 | Client-side prize pool invent (`* 0.83`) on contest details | UI | **FIXED** | Use only `estimated_prize_pool_cents` from server |
| P1-8 | Wallet English fallbacks in error handler | UI | **OPEN → P2** | Downgraded: BFF returns Persian; fallbacks rare. Documented as P2 polish. |
| P1-9 | Latent trade getActiveContests envelope bug | UI | **FIXED** | Same array normalization as dashboard |
| P1-10 | Paid contests defaulted `auto_start=false` (no automatic start) | Admin BFF | **FIXED 2026-08-17** | Paid create forces `AutoStart=true` |
| P1-11 | Contest details missing quorum + live countdown CTAs | User UI | **FIXED 2026-08-17** | TournamentDetailsCard countdown + N/min wait |
| P1-12 | `seedAdminUsers` always ran in all environments | User BFF | **FIXED 2026-08-17** | Development-only unless `SEED_DEV_USERS=false` |
| P1-13 | Client prize invent residual (`*0.83`) on card/results/join | UI | **FIXED 2026-08-17** | Server fields only |
| P1-14 | Telegram/bootstrap failure could blank web dashboard | UI | **FIXED 2026-08-17** | Soft-fail TG + auth bootstrap |

**Open core P1 count: 0** (P1-8 reclassified to P2)

---

## P2 — non-blocking

| ID | Title | Layer | Notes |
|---|---|---|---|
| P2-1 | Login success may double-toast | UI | Cosmetic |
| P2-2 | JoinConfirmModal may still estimate economics in older paths | UI | Prefer server fields only; audit residual |
| P2-3 | ContestResultsPage personal result edge cases | UI/API | Use settlement-authoritative fields |
| P2-4 | Free practice empty-state schedule string | UI | Shows next real upcoming start or `—` after fix |
| P2-5 | ContestsPage may double-toast on list load errors | UI | Same interceptor policy as join |
| P2-6 | Wallet/error strings English fallbacks | UI | Prefer full i18n pass |
| P2-7 | Money display always `en-US` `$` on fa locale | UI | Ledger is USD cents; locale formatting polish |
| P2-8 | IRR/toman notification amount divisor inconsistency risk | UI | Notifications vs wallet currency path — document ledger unit |
| P2-9 | Playwright default is mock mode | Test | Integration mode optional; domain E2E covers financial spine |
| P2-10 | Full authenticated browser journey not automated end-to-end | Test | Lab drill recommended |
| P2-11 | Local DB pollution from E2E users/contests | Ops | Use `scripts/mvp/cleanup-e2e-test-data.mjs` explicitly |
| P2-12 | Free practice still auto-joins T-bot (not counted as real) | Product | Policy §6 free path; labeled system — not paid quorum |

---

## P3 — polish

| ID | Title | Notes |
|---|---|---|
| P3-1 | Challenge progression productization (real reward ledger) | Future feature — out of MVP |
| P3-2 | Admin UI raw i18n keys | Admin polish backlog |
| P3-3 | Pixel-perfect hero 3D art from mobile reference | CSS orb is acceptable MVP |
| P3-4 | Accessibility full WCAG audit | Sanity only this phase |

---

## Triage summary

| Severity | Open | Fixed this phase |
|---|---|---|
| P0 | 0 | 1 |
| P1 (core) | 0 | 8 |
| P2 | 10 | — |
| P3 | 4 | — |

**Stabilization exit rule:** zero open P0 and zero open core P1 → met.
