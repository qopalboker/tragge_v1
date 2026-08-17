-- Revert MVP scheduling activation (does not restore prior per-row values exactly).
BEGIN;

UPDATE tournament_templates
SET auto_create = FALSE
WHERE template_key LIKE '%quick%'
   OR template_key LIKE '%rush_30%'
   OR template_key LIKE '%free%';

COMMIT;
