# contest-scheduler — ARCH-008 fate

**Fate:** `DELETE_AFTER_CUTOVER`

**Evidence of remaining callers:**
- Imported by `apps/worker/main.go` (only non-self production starter found)
- No standalone Dockerfile

**Target:** Platform `scheduler` module.

**Not SAFE_TO_DELETE:** worker import remains. Also see `RETIREMENT.md` (ARCH-007).
