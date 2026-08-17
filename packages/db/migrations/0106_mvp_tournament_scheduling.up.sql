-- MVP tournament scheduling: enable auto-create for product durations and
-- wire 30-minute templates to a 10-minute recurrence cadence.
-- Does not invent new fee matrices; activates existing templates.

BEGIN;

-- Align duration_type helper bug surface: no schema change required.

-- Quick 30m templates: every 10 minutes, auto-create + auto-start, paid quorum = 2.
UPDATE tournament_templates
SET
    auto_create = TRUE,
    auto_start = TRUE,
    min_participants = 2,
    recurrence_rule = 'EVERY_10_MIN',
    next_occurrence_at = COALESCE(
        next_occurrence_at,
        date_trunc('hour', NOW() AT TIME ZONE 'UTC')
            + ((EXTRACT(MINUTE FROM NOW() AT TIME ZONE 'UTC')::int / 10 + 1) * interval '10 minutes')
    ),
    is_active = TRUE
WHERE is_free = FALSE
  AND (
    duration_minutes = 30
    OR template_key IN (
        'crypto_quick_50k', 'crypto_quick_100k', 'crypto_quick_200k',
        'forex_quick_50k', 'forex_quick_100k', 'forex_quick_200k',
        'crypto_rush_30m', 'forex_rush_30m'
    )
  );

-- Free practice templates: auto-start + min real = 1.
-- Creation remains owned by free-contest-generator (avoid double-materialization).
UPDATE tournament_templates
SET
    auto_start = TRUE,
    min_participants = 1,
    is_free = TRUE,
    entry_fee_cents = 0,
    is_active = TRUE
WHERE is_free = TRUE
   OR template_key IN (
        'crypto_free_1h', 'forex_free_1h',
        'crypto_free_practice', 'forex_free_practice',
        'crypto_free_featured_1h', 'forex_free_featured_1h'
   );

-- Paid hourly / 4h / daily / weekly: auto-start + paid quorum 2 when templates exist.
-- Cadence remains existing recurrence_rule / admin schedules (do not invent new cadences).
UPDATE tournament_templates
SET
    auto_start = TRUE,
    min_participants = GREATEST(COALESCE(min_participants, 2), 2)
WHERE is_free = FALSE
  AND duration_minutes IN (60, 240, 1440, 10080);

COMMIT;
