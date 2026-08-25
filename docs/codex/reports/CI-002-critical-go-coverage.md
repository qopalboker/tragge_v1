# CI-002 — Critical Go service coverage floor

**Date:** 2026-08-25  
**Branch:** `codex/CI-002-critical-go-coverage`  
**Status:** Implemented on branch

## What changed

- Unit tests for previously zero-coverage wrappers: `trading-core`, `worker`
- Config/unit tests for `free-contest-generator`
- CI gate + JSON summary: `scripts/sec-ci002-critical-coverage.test.mjs` → `docs/codex/reports/CI-002-coverage-summary.json`

## Exact tests

```text
node --test scripts/sec-ci002-critical-coverage.test.mjs
```

## NOT verified

- Deep statement coverage of financial settlement/finalize paths (`CI002-DEPTH`)
- Full (non-`-short`) admin-bff integration suites against live Postgres
