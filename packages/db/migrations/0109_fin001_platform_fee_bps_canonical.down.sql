DROP TRIGGER IF EXISTS trg_contests_enforce_platform_fee_bps ON contests;
DROP FUNCTION IF EXISTS contests_enforce_platform_fee_bps();

-- Backfill is not reversed: restored rows keep explicit platform_fee_bps values.
