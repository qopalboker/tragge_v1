# CI-001 — Turn on existing frontend test suites in CI

**Date:** 2026-08-25  
**Branch:** `codex/CI-001-frontend-tests-ci` (stacked on DOC-001)  
**Status:** Implemented locally; awaiting human push (no PAT)

## What changed

| File | Change |
|---|---|
| `.github/workflows/ci.yml` | Run Vitest for user + admin frontends in `lint-and-test-frontend`; document Playwright quarantine |
| `apps/user-frontend/src/router/index.ts` | Restore Telegram/miniapp guard: never send to `/user/login`; use `telegram-auth-error` / respect `telegram_authenticating` |
| `docs/codex/reports/discovered-issues.md` | CI-001-PLAYWRIGHT-QUARANTINE (+ INFRA tab YAML note) |
| `docs/codex/AI_AGENT_EXECUTION_ROADMAP.md` | Tracker update |

## Exact test commands and output

### Pre-fix (user Vitest)

```text
FAIL  src/stores/auth_bootstrap.test.ts > ... router never redirects Telegram Mini App to /user/login
AssertionError: expected 'import { createRouter...' to contain 'telegram-auth-error'
Test Files  1 failed | 7 passed (8)
Tests  1 failed | 31 passed (32)
```

### Post-fix

```text
pnpm --filter @tragge/user-frontend test
 Test Files  8 passed (8)
      Tests  32 passed (32)

pnpm --filter @tragge/admin-frontend test
 Test Files  3 passed (3)
      Tests  10 passed (10)
```

## Manual verification

- Confirmed CI workflow previously linted/built frontends but never ran `vitest run`.
- Confirmed Playwright `webServer` is disabled when `CI=1` — unsafe to enable without a stack.

## Explicitly NOT verified

- GitHub Actions run on a real PR (no PAT this session).
- “Intentionally broken PR blocked by GitHub CI” — local Vitest failure mode proven; remote gate pending push + CI-003 for required checks.
- Full Playwright suite in CI (quarantined).

## Questions

None for Vitest enablement. Playwright lift criteria listed in `discovered-issues.md`.
