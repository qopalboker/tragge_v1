-- Revert MVP scheduling activation (does not restore prior per-row values exactly).
BEGIN;

UPDATE tournament_templates
SET auto_create = FALSE,
    create_cron = NULL
WHERE template_key LIKE '%quick%'
   OR template_key LIKE '%rush_30%'
   OR template_key LIKE '%free%';

ALTER TABLE tournament_templates
    DROP CONSTRAINT IF EXISTS chk_template_auto_create_requires_cron;

ALTER TABLE tournament_templates
    ADD CONSTRAINT chk_template_auto_create_requires_cron
    CHECK (auto_create = FALSE OR create_cron IS NOT NULL);

COMMIT;
