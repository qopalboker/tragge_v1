# LIFECYCLE-003 — Audit-safe archival

**Date:** 2026-08-25  
**Branch:** `codex/LIFECYCLE-003-audit-safe-archival`  
**Status:** Done on branch (soft-delete + archive copies). Postgres E2E archive run **not** runtime-verified.

## Retention policy

**7 years** after `archived_at` (`retain_until`). Human decision 2026-08-25.

## What changed

| Area | Change |
|---|---|
| Migration `0111` | `contests.archived_at`; archive child tables; `retain_until` |
| `cleanup.go` | Copy contest + participants/symbols/status_history; `SET archived_at`; **no** `DELETE FROM contests` |
| Hot path | Listings/feeds filter `archived_at IS NULL` |
| Audit path | `QueryArchivedContestForAudit` reads `tournaments_archive` |
| CI | `lifecycle-003-archival` |

## Exact tests

```text
node --test scripts/sec-lifecycle003-archival.test.mjs
# pass 4

go test -run TestLIFECYCLE003 ./apps/contest-scheduler/internal/scheduler/
ok
```

## Explicitly NOT runtime-verified

| ID / note | Status |
|---|---|
| Postgres E2E: archive then query cold path | **Not runtime-verified** this session (no integration DB) |
| Prior gaps | `FIN003-POSTGRES-DUAL-RACE`, `FIN005-*`, `P0-FIN-06`, `LIFECYCLE001-USERBFF-COMPILE`, `LIFECYCLE002-LOAD-TEST`, `LIFECYCLE002-STATEMACHINE-COMPILE` — still open |

## Next

Phase 2 LIFECYCLE complete on branches. Phase 3 ARCH-* or merge PAT when available.
