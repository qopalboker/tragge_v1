# ARCH-005 — Settlement sole finalization owner

**Branch:** `codex/arch-005-migrate-settlement-and-remove-finalization`  
**Commit:** `refactor(settlement): establish single finalization owner`

## Changes

- Platform `settlement` module: `IsSoleFinalizationOwner`, settle idempotency, worker job
- Leaderboard: `MayCompleteContest()==false`; finalize path documented as projection-only
- Leaderboard affiliate wallet-credit job disabled by default (`ALLOW_LEADERBOARD_AFFILIATE_CREDITS`)
- Worker mode starts settlement orchestrator job

## Gaps

- Full settlement-service code move into Platform (HTTP/Kafka cutover) — `ARCH005-SETTLEMENT-HTTP-CUTOVER`
- Prior open verification gaps remain open
