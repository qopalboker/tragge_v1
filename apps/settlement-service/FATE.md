# settlement-service — ARCH-008 fate

**Fate:** `REPLACE` (source retained)

**Evidence of remaining callers/refs:**
- Imported by `apps/worker/main.go`
- Platform `settlement` module owns authority in-process; Kafka/HTTP serving cutover incomplete

**Blocked on:** **`ARCH005-SETTLEMENT-HTTP-CUTOVER`**

**Not SAFE_TO_DELETE:** worker still starts this package.
