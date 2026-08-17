# TOURNAMENT SCHEDULING & LIFECYCLE — 2026-08-17

## Final Decision

**TOURNAMENT SYSTEM — PASS** (local static gates + unit tests green; full browser E2E requires running stack)

## Repository Audit (before changes)

### EXISTING AND REUSED

| Component | Role |
|-----------|------|
| `apps/contest-scheduler` Scheduler | Authoritative auto transitions: open reg → close reg → running/cancel → settling |
| `apps/contest-scheduler` CalendarProcessor | Materializes contests from `tournament_templates` |
| `apps/free-contest-generator` | Free practice contests + T-bot auto-join |
| `packages/domain/statemachine` | Valid graph, transition validation, side effects hooks |
| `schedule_idempotency_key` (0103) | Dedup calendar creates |
| `contest_participants.is_system` | T-bot / system classification |
| `leaderboard-worker` | `settling → completed` |
| `settlement-service` | Prize wallet credit |
| User BFF contest list/detail/join | Product join policy, real participant counts |
| FE `CountdownTimer` | Timestamp-based; emits refresh (does not invent `running`) |

### Gaps found (audit)

1. No `EVERY_10_MIN` recurrence — 30m every 10 minutes not materializable.
2. No multi-slot **horizon** — only single `next_occurrence_at` per tick.
3. Seed templates mostly `auto_create=FALSE` / `auto_start=FALSE`.
4. Free contests **always** started (0 real users) — product free quorum is T-bot + ≥1 real.
5. `getDurationTypeFromMinutes` returned `"4hour"` vs enum `"four_hour"`.
6. User list omitted prize fields + upcoming window config.
7. Contest card: duration box beside participants; prize copy inconsistent; Join UX.
8. Contest details SPA A→B could keep stale contest until refresh.
9. Trade page did not leave to contest info after end.
10. `tournament_schedules` cron seeds exist but **are not consumed** by CalendarProcessor (admin path only) — documented product gap for non-30m cadences; do not invent new schedules blindly.

### FIXED

| Fix | Where |
|-----|--------|
| `EVERY_10_MIN` recurrence + 10-min grid math | `calendar.go` |
| Lookahead slot materialization (`slotHorizon`) | `calendar.go` |
| `four_hour` duration type | `calendar.go` |
| Free + paid real-user quorum; auto-cancel below min | `statemachine.go`, `scheduler.go` |
| Migration 0106 enable 30m auto_create/start + free min=1 | `0106_mvp_tournament_scheduling.up.sql` |
| List: prize fields, upcoming window env, market_type filter alias, server_time | `contest_handlers.go` |
| Card layout: participants left, entry fee, No prize, Tehran TZ, Join without $ | `ContestCard.vue` |
| Details clear on `contestId` change | `ContestDetailsPage.vue` |
| Trade end revalidate → contest info | `TradingPage.vue` |

### NEW

| Artifact | Purpose |
|----------|---------|
| `0106_mvp_tournament_scheduling` | Activate MVP 30m scheduling config |
| `calendar_recurrence_test.go` | Unit tests for 10-min chain + duration type |
| `scripts/mvp/contest-scheduling-gate.mjs` | Static product-rule gate |
| This report | Audit + decision record |

## Scheduling

- **30m:** `EVERY_10_MIN` → slots `:00/:10/:20/:30/:40/:50`; horizon ~70 minutes of starts; idempotent via `schedule_idempotency_key`.
- **1h / 4h / 1d / 1w:** existing template `recurrence_rule` when `auto_create` is on; free 1h still owned by **free-contest-generator** (avoid double create). Cadence for paid non-30m remains config/admin (`tournament_schedules` not wired into calendar — product gap if ops expected cron table only).
- **No 15m** duration.

## Quorum

| Type | Rule |
|------|------|
| Free | ≥ **1 real** participant (`is_system=false`). T-bot joins free contests but **does not** count. |
| Paid | ≥ **2 real** participants (min_participants, floor 2). T-bot does not satisfy. |
| Below min at start | Auto-**cancel** + existing refund side effects for paid. |

## Lifecycle (authoritative)

```
draft → scheduled → registration_open → registration_closed
  → running (quorum) | cancelled (no quorum)
  → settling (ends_at) → completed (leaderboard-worker)
```

Scheduler chains registration_closed → running when `starts_at` already passed.

## Timers

| Phase | Target |
|-------|--------|
| Pre-start | `starts_at - now` (+ optional `server_time` delta) |
| Running | `ends_at - now` |
| Zero | FE re-fetch only; never invent status |

## Contest Info

- Clears local state when route `contestId` changes.
- Poll + countdown refresh revalidate backend status.

## Mobile UI (card)

- Participants on the left of info row.
- Entry fee replaces timeframe box.
- Join button text only (no price).
- Prize / 1st prize: **No prize** when authoritative pool is 0.

## Tests / gates (local)

```bash
gofmt / go build contest-scheduler user-bff domain
go test -short ./apps/contest-scheduler/internal/scheduler/
go test -short ./packages/domain/statemachine/ ./apps/user-bff/server/
node scripts/mvp/contest-scheduling-gate.mjs
node scripts/mvp/contest-lifecycle-gate.mjs
```

## CI

| SHA | What | Actions |
|-----|------|---------|
| `c1d98ee` | Feature (scheduling/lifecycle/UI) | Go install flake / FE TS error (fixed next) |
| `3cf8bbe` | Status types + goconst | **Go success** |
| `673dc5b` / `9017342` | FE path re-run | **Frontend success** |
| Later dual-path re-runs | — | Intermittent GitHub **429** downloading `actions/setup-go` / `pnpm/action-setup` (infra, not product code) |

**Local verification (authoritative for code quality under GH rate limits):**

- `golangci-lint --new-from-rev` clean on changed modules
- `go test -short` scheduler + domain + user-bff
- `pnpm run build` user-frontend
- `node scripts/mvp/contest-scheduling-gate.mjs` PASS
- `node scripts/mvp/contest-lifecycle-gate.mjs` PASS

HEAD on `main` includes all product fixes above.

## Residual risks / ops

1. Apply migration **0106** on local/staging DBs before expecting auto slots.
2. Calendar must be running (`worker` / `contest-scheduler`).
3. Full browser E2E (360/390/430) and live 18:30 Tehran slot observation require stack up — not claimed as browser-verified in this report unless CI Playwright covers them.
4. `tournament_schedules` still unused by calendar processor — enable templates via `recurrence_rule` or wire later.
