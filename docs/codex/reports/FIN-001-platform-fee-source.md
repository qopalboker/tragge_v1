# FIN-001 — Platform fee single source of truth (increment 1)

**Date:** 2026-08-25  
**Branch:** `codex/FIN-001-platform-fee-source`  
**Status:** Implemented locally — **requires explicit human financial sign-off before merge**

## What changed

| File | Change |
|---|---|
| `packages/scoring/economics/economics.go` | `ResolvePlatformFeeBps` ignores `commission_rate`; only `platform_fee_bps` (else default 2000) |
| `packages/scoring/economics/economics_test.go` | Updated expectations + `TestFIN001ConflictingLegacyFieldsDeterministic` |
| `apps/leaderboard-worker/server/payout_test.go` | Align with ignore-commission semantics |
| `apps/user-bff/server/contest_prizes_test.go` | Same |
| `apps/user-bff/server/contest_prizes.go` / `finalize.go` comments | Document FIN-001 |
| `docs/codex/decisions/FIN-001-decision-log.md` | Scope + numeric before/after |

Critical join/finalize readers already call `economics.ResolvePlatformFeeBps` / `ResolveEffectiveFeeBps` wrappers — behavior change is centralized.

## Numeric before/after (100 USDT entry = 10000 cents)

| Inputs | Before | After |
|---|---|---|
| bps=2000, commission=50% | 20/80 | 20/80 |
| bps=0, commission=50% | **50/50** | **20/80 (default)** |
| bps=0, commission=17% | **17/83** | **20/80 (default)** |

## Exact test output

```text
go test -count=1 -run "TestResolvePlatformFeeBps|TestFIN001|TestSplitEntryFee" ./packages/scoring/economics/
ok  github.com/Parsaeffatravesh/tragge/packages/scoring/economics
```

## Explicitly NOT in this increment

- Dropping `commission_rate` DB column / write paths / admin UI
- Full repo sweep deleting every `commission_rate` mention
- DB trigger/generated column guard (follow-up)
- Leaderboard-worker package test compile on this machine hit OOM; economics package is the authority and passed

## Sign-off request

Please confirm the numeric table above is acceptable for production economics, then approve merge of `codex/FIN-001-platform-fee-source`.
