#!/usr/bin/env node
/**
 * Explicit cleanup of automated E2E test pollution (emails / contest names).
 * Does NOT run automatically at app startup — ops/dev only.
 *
 * Usage (local Compose Postgres):
 *   node scripts/mvp/cleanup-e2e-test-data.mjs
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
const dockerBin =
  process.env.DOCKER_BIN ||
  (process.platform === "win32"
    ? "C:\\Users\\parsa\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe"
    : "docker");

const passFile = path.join(root, "infra/docker/secrets/postgres_admin_password.txt");
const pass = fs.existsSync(passFile) ? fs.readFileSync(passFile, "utf8").trim() : "";

const sql = `
-- Remove E2E-generated users (wallet/participants cascade as available)
DELETE FROM contest_participants WHERE user_id IN (
  SELECT id FROM users WHERE email ~* '^(p2-|p11-|mvp-|phase11|phase2)'
     OR email LIKE '%@example.com'
);
DELETE FROM wallets WHERE user_id IN (
  SELECT id FROM users WHERE email ~* '^(p2-|p11-|mvp-|phase11|phase2)'
     OR email LIKE '%@example.com'
);
DELETE FROM users WHERE email ~* '^(p2-|p11-|mvp-|phase11|phase2)'
   OR (email LIKE '%@example.com' AND email NOT IN ('admin@tragge.com','user@tragge.com'));

-- Orphan phase2/mvp contests with no real humans
UPDATE contests SET status = 'cancelled'
 WHERE name ~* '^(phase2-e2e|mvp-e2e|mvp-poor|phase11)'
   AND status IN ('registration_open','running','settling')
   AND NOT EXISTS (
     SELECT 1 FROM contest_participants cp
     WHERE cp.contest_id = contests.id AND COALESCE(cp.is_system,false)=false
   );
`;

console.log("E2E test-data cleanup (explicit, not auto-runtime)");
if (!pass) {
  console.error("Missing postgres password file; set DATABASE_URL or create secrets file.");
  process.exit(1);
}

const r = spawnSync(
  dockerBin,
  ["exec", "-e", `PGPASSWORD=${pass}`, "-i", "tragge_postgres", "psql", "-U", "tragge_admin", "-d", "app", "-v", "ON_ERROR_STOP=1"],
  { input: sql, encoding: "utf8", cwd: root }
);
console.log(r.stdout || "");
if (r.stderr) console.error(r.stderr);
process.exit(r.status === 0 ? 0 : 1);
