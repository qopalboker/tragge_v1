# free-contest-generator — ARCH-008 fate

**Fate:** `DELETE_AFTER_CUTOVER`

**Evidence of remaining callers:**
- Imported by `apps/worker/main.go`
- Platform scheduler comments forbid dual generation once Platform owns it — cutover not runtime-verified

**Not SAFE_TO_DELETE:** worker import remains. Also see `RETIREMENT.md` (ARCH-007).
