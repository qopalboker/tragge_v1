# admin-bff — ARCH-008 fate

**Fate:** `REPLACE` (source retained)

**Evidence of remaining callers/refs:**
- Imported by `apps/api-server/main.go`
- Gateway/ingress YAML still name `admin-bff` upstream

**Target:** Platform `admin` module / API mode.

**Not SAFE_TO_DELETE:** live wrapper import + ingress names.
