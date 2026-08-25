# LIFECYCLE-003 decision log

**Date:** 2026-08-25  
**Branch:** `codex/LIFECYCLE-003-audit-safe-archival`

## Retention

**Question:** How long must completed contest rows stay queryable/exportable for audit after leaving the hot path?

**Answer (human):** **7 years** (recommended).

**Implemented:** `AuditRetentionYears = 7`; `tournaments_archive.retain_until = archived_at + 7 years`.

## Archival pattern

Soft-delete (`contests.archived_at`) + cold copies (`tournaments_archive`, participants/symbols/status_history archive tables). **No hard-DELETE of contests** (CASCADE would destroy trading/audit history).

## Verification gaps

- End-to-end Postgres archive/soft-delete runtime not reproduced this session — static + unit source guards only until a real DB run. Track as needed; do not claim runtime-verified until reproduced.
- Prior FIN/LIFECYCLE verification gaps remain open / not runtime-verified.
