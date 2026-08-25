# worker — ARCH-007 retirement status

**Fate:** `DELETE_AFTER_CUTOVER`

Embeds leaderboard-worker, settlement-service, contest-scheduler, and
free-contest-generator.

**Blocked on:** `ARCH005-SETTLEMENT-HTTP-CUTOVER`, Platform worker job cutover,
`ARCH007-WRAPPER-DELETE`.

Prefer `platform --mode=worker` under Compose profile `target`.
