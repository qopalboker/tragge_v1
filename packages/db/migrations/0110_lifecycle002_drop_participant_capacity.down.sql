-- Re-add capacity check (does not restore prior max_participants values).
ALTER TABLE contests DROP CONSTRAINT IF EXISTS chk_current_participants_lte_max;
ALTER TABLE contests ADD CONSTRAINT chk_current_participants_lte_max
    CHECK (max_participants IS NULL OR current_participants <= max_participants);
