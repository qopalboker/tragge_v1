# LIFECYCLE-001 — Valid late entry to running contests

**Date:** 2026-08-25  
**Branch:** `codex/LIFECYCLE-001-late-entry`  
**Status:** Done on branch (regression-locked). Not a money-path formula change beyond existing surcharge.

## Also this turn

- FIN-005 **approved**; verification gaps remain explicitly tracked (not runtime-verified):
  - `FIN003-POSTGRES-DUAL-RACE`
  - `FIN005-COMPOSE-LIFECYCLE`
  - `FIN005-STAGING-SCHEDULE`
  - `FIN005-BRANCH-PROTECTION`

## Product rules confirmed

- Cutoff: `start + min(10% duration, 30 minutes)`
- Paid running joins allowed before cutoff; free contests blocked
- Charge: base + 10% surcharge (platform-only); prize contribution equals on-time
- Scoring: **not pro-rata** — filled trades after join only

## What changed

| File | Change |
|---|---|
| `packages/scoring/economics/join_policy.go` | Shared `JoinAllowed` |
| `packages/scoring/economics/join_policy_test.go` | Start / mid / past-cutoff / free / disabled cases + cutoff examples |
| `apps/user-bff/server/contest_handlers.go` | Delegates to `economics.JoinAllowed` |
| `apps/user-bff/server/app.go` | Join response: `is_late_join`, surcharge, total charged, prize contribution |
| CI `lifecycle-001-late-entry` | Always-on lock |

## Exact tests

```text
go test -run "TestJoinAllowed|TestLIFECYCLE001|TestLateJoin" ./packages/scoring/economics/
ok

node --test scripts/sec-lifecycle001-late-entry.test.mjs
# pass 3
```

## Explicitly NOT done / tracked

| ID | Note |
|---|---|
| `LIFECYCLE001-USERBFF-COMPILE` | Full `go test ./apps/user-bff/server` not run here (host OOM); policy tests live in economics |
| `P0-FIN-06` / economics lock at late-join **cutoff** | Still open — first-join lock exists; cutoff-time freeze of economics snapshot is a separate gap |

## Scoring note

Trade scores are computed per fill after the user is a participant. A mid-contest joiner cannot accumulate score before `joined_at`. Prize eligibility still requires ≥1 filled trade (§11.3).
