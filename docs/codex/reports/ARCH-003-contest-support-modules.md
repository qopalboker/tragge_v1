# ARCH-003 — Migrate contest, scheduler, leaderboard, notification, ticket

**Date:** 2026-08-25  
**Branch:** `codex/arch-003-migrate-contest-scheduler-leaderboard-proj`  
**Commit:** `refactor(platform): migrate contest support modules`

## What changed

| Area | Change |
|---|---|
| `scheduler` module | Sole contest-generation owner; free-practice + lifecycle worker jobs; generation lock |
| `leaderboard` module | Projection-only; `HasSettlementAuthority()==false`; `CreditWallets` rejected |
| `leaderboard-worker` | Stop setting `wallets_credited` from projection finalize |
| `contest` / `notification` / `ticket` | Application ports; ticket create enqueues notification outbox |
| `platform --mode=worker` | Starts module jobs |
| `apps/worker` | Does not start free-contest-generator by default |
| `free-contest-generator` | Disabled unless `PLATFORM_ALLOW_STANDALONE_FREE_GENERATOR=true` |

## Verification

```text
go test ./apps/platform/...
node --test scripts/sec-arch003-contest-modules.test.mjs
```

## Gaps / not claimed

- Full calendar/lifecycle code still lives in `apps/contest-scheduler` (shim cutover).
- Full outbox schema remains ARCH-006 (`ARCH003-OUTBOX-SCHEMA`).
- Affiliate commission still in leaderboard-worker binary (`ARCH003-AFFILIATE-JOB`).
- Prior FIN/LIFECYCLE/ARCH verification gaps remain open.
