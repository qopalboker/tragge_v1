# user-bff — ARCH-008 fate

**Fate:** `REPLACE` (source retained)

**Evidence of remaining callers/refs:**
- Imported by `apps/api-server/main.go`
- Gateway/ingress YAML still name `user-bff` upstream
- No standalone Dockerfile (runs only via merged wrapper today)

**Target:** Platform `identity` / API mode.

**Not SAFE_TO_DELETE:** live wrapper import + ingress names. Deletion requires traffic cutover evidence, then `ARCH007-WRAPPER-DELETE`.
