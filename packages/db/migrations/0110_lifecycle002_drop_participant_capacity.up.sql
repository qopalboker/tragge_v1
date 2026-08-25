-- LIFECYCLE-002: product-level participant capacity does not exist (policy §5.2).
-- Drop the enforcement constraint; clear contest max_participants so joins are uncapped.
-- Column retained nullable for operational/legacy reads; must not gate joins.

ALTER TABLE contests DROP CONSTRAINT IF EXISTS chk_current_participants_lte_max;

UPDATE contests SET max_participants = NULL WHERE max_participants IS NOT NULL;

COMMENT ON COLUMN contests.max_participants IS
  'LIFECYCLE-002: deprecated product capacity; always NULL. Operational circuit breakers are separate.';
