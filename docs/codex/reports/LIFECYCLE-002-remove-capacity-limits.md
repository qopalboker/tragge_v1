# LIFECYCLE-002 — Remove participant capacity limits

**Date:** 2026-08-25  
**Branch:** `codex/LIFECYCLE-002-remove-capacity-limits`  
**Status:** Done on branch (enforcement + UI removed). Load-test **not** runtime-verified.

## Product rule

Policy §5.2: product-level participant capacity does not exist. Column `max_participants` may remain nullable for legacy/ops reads but must not gate joins.

## Decision (create path)

Human choice: **Force NULL on create** — scheduler and admin-bff always persist `NULL` for `max_participants`; client/template/tier overrides are ignored at contest materialization.

## What changed

| File | Change |
|---|---|
| `packages/db/migrations/0110_lifecycle002_drop_participant_capacity.*` | Drop `chk_current_participants_lte_max`; NULL all max values |
| `packages/domain/statemachine/effects.go` | `ValidateRegistration` / `CheckRegistrationCapacity` uncapped |
| `apps/user-bff/server/contest_handlers.go` | Drop ContestFull mapping for capacity constraint |
| `apps/contest-scheduler/.../calendar.go` | Always insert NULL max |
| `apps/admin-bff/server/handlers_contest.go` | Force `req.MaxParticipants = nil` / NULL on template create |
| User FE ContestCard / TournamentDetailsCard / JoinConfirmModal | Remove slots / max progress UX |
| Admin FE ContestForm / ContestDetail / TierList | Remove max inputs and capacity progress |
| CI `lifecycle-002-capacity` | Always-on static + domain sentinel suite |

## Exact tests

```text
node --test scripts/sec-lifecycle002-capacity.test.mjs
# pass 8

go test -run TestLIFECYCLE002 ./packages/domain/statemachine/
ok
```

## Downstream audit (brief)

- Prize distribution (`tralent_v1`) already scales with participant count (unit-tested to large N).
- Join path never re-checks max after LIFECYCLE-002.
- Operational circuit breakers (infra) are out of scope; product capacity only.

## Explicitly NOT done / tracked

| ID | Note |
|---|---|
| `LIFECYCLE002-LOAD-TEST` | Large synthetic join load against real Postgres **not** runtime-verified this session |
| `LIFECYCLE002-STATEMACHINE-COMPILE` | Local `go test` of domain/statemachine OOM'd; static CI locks still pass |
| Prior gaps (unchanged) | `FIN003-POSTGRES-DUAL-RACE`, `FIN005-COMPOSE-LIFECYCLE`, `FIN005-STAGING-SCHEDULE`, `FIN005-BRANCH-PROTECTION`, `P0-FIN-06-ECONOMICS-LOCK-AT-CUTOFF`, `LIFECYCLE001-USERBFF-COMPILE` — still **not** runtime-verified |

## Next

LIFECYCLE-003 — audit-safe archival instead of hard-delete cleanup.
