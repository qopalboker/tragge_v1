# leaderboard-worker — ARCH-008 fate

**Fate:** `REPLACE` (source retained)

**Evidence of remaining callers/refs:**
- Imported by `apps/worker/main.go`
- Platform `leaderboard` module is projection-only; this package still owns live jobs under worker

**Note:** FIN-003/ARCH-005 constrained finalization; do not delete mid-cutover.

**Not SAFE_TO_DELETE:** worker still starts this package.
