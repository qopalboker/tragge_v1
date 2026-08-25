# market-ingestor — ARCH-008 fate

**Fate:** `KEEP`

**Evidence:**
- Standalone Dockerfile + `cmd/market-ingestor` (ARCH-007)
- Compose profile `target`
- Still embedded by `apps/trading-core` until cutover
- Contract cutover still open: **`MD001-KAFKA-V2-CUTOVER`**, **`MD001-FRONTEND-CUTOVER`**

**Not SAFE_TO_DELETE:** required ADR-0001 Market Data image.
