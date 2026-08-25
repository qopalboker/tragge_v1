# SEC-008 — Auth regression lock

**Date:** 2026-08-25  
**Branch:** `codex/SEC-008-auth-regression-lock` (cut from `main` @ `d35b4ab`)  
**Status:** Implemented + evidence recorded; awaiting human push (no PAT)

## Independent verification (before locking)

| Concern | Finding in current tree | Prior audit label |
|---|---|---|
| `?token=` URL auth | `RequireAuth` / `OptionalAuth` call `HasProhibitedCredentialQuery` and return `url_authentication_unsupported` | Audit P0-SEC-02 claimed open; forensic report claimed FIXED — **reproduced FIXED** |
| User/Admin isolation | Separate contexts/keys; `TestCrossPanelTokenRejected` + `TestUserAdminAccessAndRefreshIsolation` | Docs claim implemented — **reproduced** |
| OTP in logs | `FakeProvider` never logs; runtime uses KaveNegar only (`app.go`); `sec-003` structural PASS; no `NewFake` in non-test runtime | Audit P0-SEC-03 claimed open — **reproduced FIXED for logging path** |

## What changed

| File | Change |
|---|---|
| `packages/auth/sec008_regression_test.go` | Named SEC-008 Go tests for `?token=` + User/Admin isolation |
| `packages/sms/sec008_regression_test.go` | Named SEC-008 Go tests: FakeProvider never logs OTP + SMS sources must not log codes |
| `scripts/sec-008-auth-regression-lock.test.mjs` | Node suite: structural locks + runs the Go tests |
| `.github/workflows/ci.yml` | Always-on job `sec-008-auth-regression` |
| `package.json` | `test:sec008` |
| `docs/codex/AI_AGENT_EXECUTION_ROADMAP.md` | Tracker + INFRA park + SEC-008 Done |
| `docs/codex/decisions/INFRA-001-decision-log.md` | Updated park rationale |

## Exact test commands and output

### Pre-fix proof (`?token=` guard disabled)

Temporarily commented `HasProhibitedCredentialQuery` in `RequireAuth`, then:

```text
go test -count=1 -run "^TestSEC008RejectsTokenQueryAuthentication$" ./packages/auth/
--- FAIL: TestSEC008RejectsTokenQueryAuthentication (0.00s)
    sec008_regression_test.go:35: missing migration code: {"error":"missing or invalid authorization header"}
FAIL
PRE_FIX_EXIT=1
```

Guard restored immediately after.

### Post-fix suite

```text
node --test scripts/sec-008-auth-regression-lock.test.mjs
```

```text
ok 1 - SEC-008 source locks: query-token reject + isolation + OTP no-log
ok 2 - SEC-008 Go regression: ?token= rejected
ok 3 - SEC-008 Go regression: User/Admin isolation
ok 4 - SEC-008 Go regression: OTP never logged
# tests 4
# pass 4
# fail 0
```

Also:

```text
go test -count=1 -run "TestSEC008" ./packages/auth/ ./packages/sms/
ok  github.com/Parsaeffatravesh/tragge/packages/auth
ok  github.com/Parsaeffatravesh/tragge/packages/sms
```

```text
node scripts/sec-002-query-auth-check.mjs
SEC-002 structural validation PASS

node scripts/sec-003-otp-delivery-check.mjs
SEC-003 structural validation PASS
```

## Manual verification

- Read `packages/auth/middleware.go`, `isolation` docs, `packages/sms/mock.go`, `apps/user-bff/server/app.go` SMS init.
- Confirmed production SMS path is KaveNegar-only with no mock/logging fallback.

## Explicitly NOT verified

- Live GitHub Actions run of `sec-008-auth-regression` (no push/PAT).
- Full `scripts/sec001-auth-isolation.test.mjs` (9/10 pass; one assertion expects `tragge_v0.git` remote URL but repo is `tragge_v1.git` — logged below, not fixed in SEC-008).
- End-to-end HTTP through `api-server` chi routes (middleware-level isolation locked; full HTTP stack is broader).

## Discovered / out of scope

- `scripts/sec001-auth-isolation.test.mjs` fails asserting `.git/config` remote `tragge_v0.git` while origin is `tragge_v1.git`. Track in `discovered-issues.md` if needed; do not expand SEC-008.

## Questions

None.
