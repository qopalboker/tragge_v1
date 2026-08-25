# trading-engine — ARCH-008 fate

**Fate:** `KEEP`

**Evidence:**
- Standalone Dockerfile + `cmd/trading-engine` (ENG-001)
- Compose profiles `target` / `engine-standalone`
- Still embedded by `apps/trading-core` until `ENG001-TRADING-CORE-CUTOVER`

**Not SAFE_TO_DELETE:** required ADR-0001 Trading Engine image.
