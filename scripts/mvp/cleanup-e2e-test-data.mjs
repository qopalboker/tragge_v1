#!/usr/bin/env node
/**
 * Explicit cleanup of automated E2E / gate fixture users (@example.com).
 * Does NOT run automatically at app startup — ops/dev only.
 *
 * Safety classes:
 *   SAFE_TO_DELETE  — fixture prefixes / @example.com with no admin/system/telegram
 *   REVIEW_REQUIRED — would match email pattern but has admin role, telegram, or system flag
 *   KEEP            — never touched (admins, system accounts, real telegram users)
 *
 * Usage (local Compose Postgres):
 *   node scripts/mvp/cleanup-e2e-test-data.mjs
 *   node scripts/mvp/cleanup-e2e-test-data.mjs --dry-run
 *
 * Env:
 *   DATABASE_URL or TRAGGE_E2E_DATABASE_URL
 *   DOCKER_BIN (Windows default Docker Desktop path)
 */
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const dryRun = process.argv.includes("--dry-run");
const dockerBin =
  process.env.DOCKER_BIN ||
  (process.platform === "win32"
    ? "C:\\Users\\parsa\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe"
    : "docker");

const passFile = path.join(root, "infra/docker/secrets/postgres_admin_password.txt");
const pass = fs.existsSync(passFile) ? fs.readFileSync(passFile, "utf8").trim() : "";

/** Fixture-like emails only. Never broad-delete without the safety CTE below. */
const sql = `
BEGIN;

CREATE TEMP TABLE _e2e_targets ON COMMIT DROP AS
WITH candidates AS (
  SELECT u.id, u.email, u.username, u.telegram_id, u.is_system_account
  FROM users u
  WHERE
    u.email ~* '^(p2-|p11-|p41lite-|mvp-|e2e|live_e2e|test|qa-|gate-|cert-|phase11|phase2)'
    OR (
      u.email ILIKE '%@example.com'
      AND u.email NOT IN ('admin@tragge.com', 'user@tragge.com')
    )
),
classified AS (
  SELECT
    c.*,
    EXISTS (
      SELECT 1
      FROM user_roles ur
      JOIN roles r ON r.id = ur.role_id
      WHERE ur.user_id = c.id
        AND r.name IN ('admin', 'super_admin', 'support_admin', 'moderator')
    ) AS is_admin_role,
    CASE
      WHEN c.is_system_account THEN 'KEEP'
      WHEN c.telegram_id IS NOT NULL THEN 'REVIEW_REQUIRED'
      WHEN EXISTS (
        SELECT 1
        FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = c.id
          AND r.name IN ('admin', 'super_admin', 'support_admin', 'moderator')
      ) THEN 'KEEP'
      ELSE 'SAFE_TO_DELETE'
    END AS safety_class
  FROM candidates c
)
SELECT * FROM classified;

SELECT safety_class, COUNT(*) AS n
FROM _e2e_targets
GROUP BY safety_class
ORDER BY safety_class;

SELECT id, email, username, safety_class
FROM _e2e_targets
WHERE safety_class <> 'SAFE_TO_DELETE'
ORDER BY safety_class, email
LIMIT 50;

-- Dependent rows that use ON DELETE NO ACTION / restrict paths.
DELETE FROM prize_distributions
 WHERE user_id IN (SELECT id FROM _e2e_targets WHERE safety_class = 'SAFE_TO_DELETE');

DELETE FROM final_rankings
 WHERE user_id IN (SELECT id FROM _e2e_targets WHERE safety_class = 'SAFE_TO_DELETE');

-- Trading rows (partitioned tables may not CASCADE from users).
DELETE FROM fills
 WHERE user_id IN (SELECT id FROM _e2e_targets WHERE safety_class = 'SAFE_TO_DELETE');

DELETE FROM positions
 WHERE user_id IN (SELECT id FROM _e2e_targets WHERE safety_class = 'SAFE_TO_DELETE');

DELETE FROM orders
 WHERE user_id IN (SELECT id FROM _e2e_targets WHERE safety_class = 'SAFE_TO_DELETE');

DELETE FROM contest_participants
 WHERE user_id IN (SELECT id FROM _e2e_targets WHERE safety_class = 'SAFE_TO_DELETE');

DELETE FROM wallet_ledger
 WHERE user_id IN (SELECT id FROM _e2e_targets WHERE safety_class = 'SAFE_TO_DELETE');

DELETE FROM wallets
 WHERE user_id IN (SELECT id FROM _e2e_targets WHERE safety_class = 'SAFE_TO_DELETE');

DELETE FROM users
 WHERE id IN (SELECT id FROM _e2e_targets WHERE safety_class = 'SAFE_TO_DELETE');

-- Orphan phase/mvp contests with no remaining real humans
UPDATE contests SET status = 'cancelled'
 WHERE name ~* '^(phase2-e2e|mvp-e2e|mvp-poor|phase11|p41lite)'
   AND status IN ('registration_open', 'scheduled', 'running', 'settling')
   AND NOT EXISTS (
     SELECT 1 FROM contest_participants cp
     WHERE cp.contest_id = contests.id AND COALESCE(cp.is_system, false) = false
   );

SELECT COUNT(*) AS remaining_example_users
FROM users
WHERE email ILIKE '%@example.com';

COMMIT;
`;

const drySql = `
WITH candidates AS (
  SELECT u.id, u.email, u.username, u.telegram_id, u.is_system_account
  FROM users u
  WHERE
    u.email ~* '^(p2-|p11-|p41lite-|mvp-|e2e|live_e2e|test|qa-|gate-|cert-|phase11|phase2)'
    OR (
      u.email ILIKE '%@example.com'
      AND u.email NOT IN ('admin@tragge.com', 'user@tragge.com')
    )
),
classified AS (
  SELECT
    c.*,
    CASE
      WHEN c.is_system_account THEN 'KEEP'
      WHEN c.telegram_id IS NOT NULL THEN 'REVIEW_REQUIRED'
      WHEN EXISTS (
        SELECT 1
        FROM user_roles ur
        JOIN roles r ON r.id = ur.role_id
        WHERE ur.user_id = c.id
          AND r.name IN ('admin', 'super_admin', 'support_admin', 'moderator')
      ) THEN 'KEEP'
      ELSE 'SAFE_TO_DELETE'
    END AS safety_class
  FROM candidates c
)
SELECT safety_class, COUNT(*) AS n
FROM classified
GROUP BY safety_class
ORDER BY safety_class;
`;

console.log(
  dryRun
    ? "E2E test-data cleanup DRY RUN (classify only)"
    : "E2E test-data cleanup (explicit, classified SAFE_TO_DELETE only)",
);
if (!pass) {
  console.error("Missing postgres password file; set DATABASE_URL or create secrets file.");
  process.exit(1);
}

const r = spawnSync(
  dockerBin,
  [
    "exec",
    "-e",
    `PGPASSWORD=${pass}`,
    "-i",
    "tragge_postgres",
    "psql",
    "-U",
    "tragge_admin",
    "-d",
    "app",
    "-v",
    "ON_ERROR_STOP=1",
  ],
  { input: dryRun ? drySql : sql, encoding: "utf8", cwd: root },
);
console.log(r.stdout || "");
if (r.stderr) console.error(r.stderr);
process.exit(r.status === 0 ? 0 : 1);
