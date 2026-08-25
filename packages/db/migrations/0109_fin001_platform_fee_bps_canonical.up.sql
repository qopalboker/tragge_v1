-- FIN-001: platform_fee_bps is the sole platform-fee authority.
-- Backfill paid contests with unset/0 bps to the canonical default (2000).
-- commission_rate is retained as a deprecated column but must not drive fees.
-- Human financial sign-off (2026-08-25): do NOT convert commission_rate → bps.

UPDATE contests
SET platform_fee_bps = 2000
WHERE COALESCE(is_free, FALSE) = FALSE
  AND COALESCE(entry_fee_cents, 0) > 0
  AND COALESCE(platform_fee_bps, 0) <= 0;

-- Free contests must store zero platform fee.
UPDATE contests
SET platform_fee_bps = 0
WHERE COALESCE(is_free, FALSE) = TRUE
  AND COALESCE(platform_fee_bps, 0) <> 0;

-- Guard: writers cannot leave paid contests without a valid platform_fee_bps.
CREATE OR REPLACE FUNCTION contests_enforce_platform_fee_bps()
RETURNS trigger AS $$
BEGIN
  IF COALESCE(NEW.is_free, FALSE) = TRUE THEN
    NEW.platform_fee_bps := 0;
  ELSIF COALESCE(NEW.entry_fee_cents, 0) > 0 THEN
    IF NEW.platform_fee_bps IS NULL OR NEW.platform_fee_bps <= 0 OR NEW.platform_fee_bps > 10000 THEN
      NEW.platform_fee_bps := 2000;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_contests_enforce_platform_fee_bps ON contests;
CREATE TRIGGER trg_contests_enforce_platform_fee_bps
BEFORE INSERT OR UPDATE OF platform_fee_bps, entry_fee_cents, is_free
ON contests
FOR EACH ROW
EXECUTE FUNCTION contests_enforce_platform_fee_bps();

COMMENT ON FUNCTION contests_enforce_platform_fee_bps() IS
  'FIN-001: enforce platform_fee_bps as sole fee authority (default 2000 for paid contests)';
