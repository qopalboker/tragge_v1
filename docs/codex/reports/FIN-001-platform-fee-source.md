# FIN-001 — Platform fee single source of truth

**Date:** 2026-08-25  
**Branch:** `codex/FIN-001-platform-fee-source`  
**Status:** Done on branch — **human financial sign-off received 2026-08-25**

## Sign-off

Approved numeric behavior (entry 100 USDT = 10000 cents):

| Inputs | Before | After (approved) |
|---|---|---|
| bps=2000, commission=50% | 20/80 | 20/80 |
| bps=0, commission=50% | 50/50 | **20/80 (default 2000)** |
| bps=0, commission=17% | 17/83 | **20/80 (default 2000)** |

Backfill choice (approved): paid contests with unset/0 `platform_fee_bps` → **2000** (do not convert `commission_rate`).

## Inventory (fee-authority paths)

| Area | Role | FIN-001 action |
|---|---|---|
| `packages/scoring/economics.ResolvePlatformFeeBps` | Sole runtime fee resolver | Ignores `commission_rate` |
| `user-bff` join/preview (`ResolveEffectiveFeeBps`) | Reader | Uses economics |
| `leaderboard-worker` finalize/payout | Reader | Uses economics |
| `contest-scheduler` calendar materialization | Writer | Always writes 2000 for paid (no commission×100) |
| `admin-bff` contest create / from-template | Writer | Defaults/writes `platform_fee_bps`; `commission_rate` persisted as 0 |
| `free-contest-generator` | Writer | Free contests → 0 (already) |
| Migration `0109_…` | Backfill + trigger | Paid unset→2000; enforce on INSERT/UPDATE |
| `tournament_templates.commission_rate` | Template metadata | Still editable in admin templates UI; **not used** when materializing contest fees (logged as follow-up) |

## What changed (this continuation)

| File | Change |
|---|---|
| `packages/scoring/economics/economics.go` | `PlatformFeeBpsForPaidWrite` |
| `packages/db/migrations/0109_fin001_platform_fee_bps_canonical.{up,down}.sql` | Backfill + trigger guard |
| `apps/contest-scheduler/.../calendar.go` | Stop deriving bps from commission |
| `apps/admin-bff/server/handlers_contest.go` | Stop commission defaults/authority; template create uses 2000 |
| `scripts/sec-fin001-platform-fee-check.test.mjs` | CI lock |
| `.github/workflows/ci.yml` | Job `fin-001-platform-fee` |
| `package.json` | `test:fin001` |

## Exact test output

```text
node --test scripts/sec-fin001-platform-fee-check.test.mjs
ok 1 - FIN-001 migration backfills paid contests to 2000 bps and adds guard trigger
ok 2 - FIN-001 economics resolver ignores commission_rate
ok 3 - FIN-001 critical writers do not derive bps from commission_rate
ok 4 - FIN-001 Go conflict test passes
# pass 4
# fail 0
```

## Explicitly NOT done (deferred / discovered)

- Dropping `commission_rate` / `commission_rate_override` columns from DB and API responses.
- Removing template admin UI fields for `commission_rate` (non-authoritative leftover).
- Live migrate apply against a running Postgres (local compose not required for this evidence).

## Questions

None remaining for FIN-001 authority. Ready for human merge after push.
