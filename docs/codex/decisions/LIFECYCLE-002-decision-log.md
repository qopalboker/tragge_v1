# LIFECYCLE-002 decision log

**Date:** 2026-08-25  
**Branch:** `codex/LIFECYCLE-002-remove-capacity-limits`

## Product

§5.2 — no product participant capacity. Operational/infra circuit breakers are separate.

## Create-path writes

**Question:** Scheduler and admin still wrote `max_participants` from calendar/tiers. How treat those writes?

**Answer (human):** Force NULL on create (recommended). Stop persisting product capacity; keep column for legacy reads only.

**Implemented:** migration nulls existing; create paths always NULL; UI capacity inputs/progress removed; CI locks static invariants.

## Verification gaps

- `LIFECYCLE002-LOAD-TEST` remains open — do **not** mark load/scale as runtime-verified until reproduced.
- Prior FIN/LIFECYCLE verification gaps remain explicitly tracked and unverified until reproduced.
