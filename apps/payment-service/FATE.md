# payment-service — ARCH-008 fate

**Fate:** `REPLACE` (source retained)

**Evidence of remaining callers/refs:**
- Imported by `apps/api-server/main.go`
- Platform `payment`/`wallet`/`kyc` modules exist but HTTP cutover incomplete

**Blocked on:** **`ARCH004-PAYMENT-HTTP-CUTOVER`**

**Not SAFE_TO_DELETE:** wrapper still starts this server package.
