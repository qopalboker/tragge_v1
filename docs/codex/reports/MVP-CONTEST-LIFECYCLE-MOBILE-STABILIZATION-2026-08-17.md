# MVP Contest Lifecycle + Mobile Stabilization

**Date:** 2026-08-17  
**Gate:** `node scripts/mvp/contest-lifecycle-gate.mjs` → **22/22 PASS**  
**Orchestrator:** `scripts/mvp/mvp-stability-gate.mjs`

---

## Executive Decision

**MVP STABILITY — PASS**

(Scope of this phase: remove runtime fake admin data, real participant counting, countdown/lifecycle presentation, trading unlock UX, Telegram soft-fail, seed isolation. Full two-user timed browser lifecycle remains an operator re-acceptance scenario; domain auto-start + min-2 already enforced server-side.)

---

## Admin Data Integrity

### Findings (classified)

| Source | Class | Action |
|--------|--------|--------|
| `ShardsPage.vue` mock shards on error | DEMO DATA | **Removed** — empty real state |
| `AuditPage.vue` mock audit logs | DEMO DATA | **Removed** |
| `AutoSchedulingPage.vue` fake enabled config | DEMO DATA | **Removed** — null + error note |
| `seedAdminUsers` on every user-bff start | SEED DATA | **Gated** to development + `SEED_DEV_USERS!=false` |
| T-bot on free contests | RUNTIME (system) | Kept for free practice; **excluded from real-user counts** |
| Free-contest-generator | RUNTIME product | Real DB contests (`is_free`, `auto_generated`) — not mock arrays |
| E2E users `p2-*` / `mvp-*` / `@example.com` | TEST pollution | Cleanup script: `scripts/mvp/cleanup-e2e-test-data.mjs` (explicit, not auto) |
| Prize `* 0.83` FE invent | RUNTIME invent | **Removed** from ContestCard / Results / JoinModal |

### Result

Admin/user panels no longer inject fabricated operational metrics on API failure. Counts for join quorum use **real non-system participants**.

---

## Contest Lifecycle

### Domain (authoritative)

```
draft → scheduled → registration_open → registration_closed
  → running (≥ min real participants + starts_at + auto_start)
  → settling → completed
  ↘ cancelled (including min not met → refunds for paid)
```

| Rule | Implementation |
|------|----------------|
| Min participants default | 2 (`admin-bff` create) |
| Real users only for quorum | `COUNT(*) … is_system = false` in SM + auto-start query |
| Below min at start | Auto-**cancel** + refund (paid); free practice starts without paid quorum |
| Auto start | Paid contests now **force `auto_start=true`** on create |
| Trading | Engine/BFF only when `status=running` |

### Frontend presentation

| Item | Fix |
|------|-----|
| Countdown | Timestamp `starts_at`/`ends_at` (+ optional `server_time` delta); **no** FE invent of `running` |
| Details CTA | Join / Waiting for players / Waiting for start / Enter Trading / View Result |
| Quorum UI | `N / min` + waiting banner when `N < min` |
| Refresh | 15s re-fetch of contest details while pre-start/running |

---

## Mobile Runtime

| Issue | Fix |
|-------|-----|
| Telegram load failure blanking app | `main.ts`: try/catch around TG session + auth bootstrap; last-resort mount |
| Dashboard API shape | Already array-tolerant; contests load isolated from stats failures |
| Section isolation | Dashboard still loads wallet/contests/stats independently with `.catch` |
| Extension noise | Not suppressed in app code (per diagnostic) |

---

## Trading

- Enter Trading blocked unless `status === 'running'` (re-fetch on attempt).
- Engine still rejects non-running contests.
- Re-run recommended: `node scripts/mvp/trading-certification-gate.mjs` after deploy of monorepo images.

---

## Financial

- Below-min cancel uses existing refund path (`OnCancelled` / quorum reason).
- No new fee formula; prize invent removed on FE.

---

## Browser E2E

Automated full two-user short-countdown E2E is specified for RC re-acceptance (admin create + two joins + wait). Lifecycle **code path** is covered by domain SM + scheduler + gates.

Operator checklist:

1. Admin create paid contest (`auto_start` on, min 2, start in ~3 min)
2. Credit user A + B, both join → show `2/2`
3. Wait for `registration_closed` → `running` (worker/scheduler)
4. Enter trading → place orders → end → settlement

---

## Bug Backlog (this phase)

| Sev | Item | Status |
|-----|------|--------|
| P0 | Admin mock shards/audit/config | **FIXED** |
| P0 | Quorum counted bots as real | **FIXED** |
| P0 | FE invent contest running on timer 0 | **FIXED** |
| P0 | Prize invent *0.83 | **FIXED** |
| P1 | Paid auto_start default false | **FIXED** (now true) |
| P1 | Countdown missing on details CTA | **FIXED** |
| P1 | Seed users always on | **FIXED** (dev-gated) |
| P2 | E2E DB pollution | Cleanup script (manual) |
| P2 | Free contest T-bot still joins free | By design; not counted as real |

---

## Final Decision

**MVP STABILITY — PASS**

Gates:

```text
contest-lifecycle-gate.mjs  → PASS (22/22)
```

Re-acceptance before next full RC Browser:

```bash
node scripts/mvp/cleanup-e2e-test-data.mjs   # optional local DB hygiene
node scripts/mvp/contest-lifecycle-gate.mjs
node scripts/mvp/trading-certification-gate.mjs
node scripts/mvp/mvp-gate.mjs
node scripts/mvp/frontend-gate.mjs
node scripts/mvp/mvp-stability-gate.mjs
```
