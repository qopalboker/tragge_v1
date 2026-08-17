#!/usr/bin/env node
/**
 * Phase 3 Test F — PostgreSQL backup + restore drill (local staging)
 *
 * 1) pg_dump active DB
 * 2) create temp database
 * 3) restore dump
 * 4) validate critical tables exist + row counts readable
 *
 * Env:
 *   TRAGGE_E2E_DATABASE_URL or POSTGRES_* + password file
 *   Requires: pg_dump, psql on PATH (or docker exec into postgres container)
 */

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function passFromFile() {
  const p =
    process.env.TRAGGE_E2E_PG_PASS_FILE ||
    path.resolve(
      __dirname,
      "../../infra/docker/secrets/postgres_admin_password.txt"
    );
  if (!fs.existsSync(p)) return null;
  return fs.readFileSync(p, "utf8").trim();
}

function baseURL() {
  if (process.env.TRAGGE_E2E_DATABASE_URL) return process.env.TRAGGE_E2E_DATABASE_URL;
  const pass = process.env.POSTGRES_PASSWORD || passFromFile();
  if (!pass) {
    console.error("[phase3] No DB credentials; set TRAGGE_E2E_DATABASE_URL");
    process.exit(2);
  }
  const user = process.env.POSTGRES_USER || "tragge_admin";
  const host = process.env.POSTGRES_HOST || "127.0.0.1";
  const port = process.env.POSTGRES_PORT || "5432";
  const db = process.env.POSTGRES_DB || "app";
  return `postgres://${user}:${encodeURIComponent(pass)}@${host}:${port}/${db}?sslmode=disable`;
}

function run(cmd, args, env = {}) {
  const r = spawnSync(cmd, args, {
    encoding: "utf8",
    shell: true,
    env: { ...process.env, ...env },
  });
  return r;
}

const url = new URL(baseURL().replace(/^postgres:/, "http:"));
const user = decodeURIComponent(url.username);
const pass = decodeURIComponent(url.password);
const host = url.hostname;
const port = url.port || "5432";
const db = url.pathname.replace(/^\//, "") || "app";
const restoreDB = `tragge_restore_${Date.now()}`;

const work = fs.mkdtempSync(path.join(os.tmpdir(), "tragge-pg-drill-"));
const dumpFile = path.join(work, "backup.sql");

console.log("[phase3] Backup/restore drill");
console.log(`[phase3] source db=${db} host=${host}`);

const env = { PGPASSWORD: pass };

// 1) Backup — prefer host pg_dump; fallback to docker exec into tragge_postgres
function tryDump() {
  let r = run("pg_dump", [
    "-h", host, "-p", port, "-U", user, "-d", db,
    "--no-owner", "--no-acl", "-f", dumpFile,
  ], env);
  if (r.status === 0) return r;
  // docker exec path
  const container = process.env.POSTGRES_CONTAINER || "tragge_postgres";
  console.log(`[phase3] host pg_dump unavailable, trying docker exec ${container}`);
  r = run("docker", [
    "exec", container,
    "pg_dump", "-U", user, "-d", db, "--no-owner", "--no-acl",
  ], env);
  if (r.status === 0 && r.stdout) {
    fs.writeFileSync(dumpFile, r.stdout);
    return { status: 0 };
  }
  return r;
}

let r = tryDump();
if (r.status !== 0) {
  console.error(r.stderr || r.stdout);
  console.error("[phase3] pg_dump failed — install client tools or start Docker postgres");
  process.exit(r.status || 1);
}
const size = fs.statSync(dumpFile).size;
console.log(`[phase3] backup written ${dumpFile} (${size} bytes)`);
if (size < 1000) {
  console.error("[phase3] backup suspiciously small");
  process.exit(1);
}

// 2) Create restore database
r = run("psql", [
  "-h", host, "-p", port, "-U", user, "-d", "postgres",
  "-v", "ON_ERROR_STOP=1",
  "-c", `CREATE DATABASE ${restoreDB};`,
], env);
if (r.status !== 0) {
  console.error(r.stderr || r.stdout);
  process.exit(r.status || 1);
}

// 3) Restore
r = run("psql", [
  "-h", host, "-p", port, "-U", user, "-d", restoreDB,
  "-v", "ON_ERROR_STOP=1",
  "-f", dumpFile,
], env);
if (r.status !== 0) {
  console.error(r.stderr || r.stdout);
  run("psql", ["-h", host, "-p", port, "-U", user, "-d", "postgres", "-c", `DROP DATABASE IF EXISTS ${restoreDB};`], env);
  process.exit(r.status || 1);
}

// 4) Validate critical relations
const checks = `
SELECT
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='users') AS users_tbl,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='contests') AS contests_tbl,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='orders') AS orders_tbl,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='fills') AS fills_tbl,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='positions') AS positions_tbl,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='wallet_ledger') AS ledger_tbl,
  (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public' AND table_name='contest_settlements') AS settlements_tbl;
`;
r = run("psql", [
  "-h", host, "-p", port, "-U", user, "-d", restoreDB,
  "-t", "-A", "-F", ",",
  "-c", checks,
], env);
if (r.status !== 0) {
  console.error(r.stderr || r.stdout);
  process.exit(1);
}
const line = (r.stdout || "").trim().split("\n").pop();
console.log(`[phase3] table presence flags: ${line}`);
const parts = line.split(",").map((x) => Number(x));
if (parts.some((n) => n !== 1)) {
  console.error("[phase3] FAIL: missing critical tables after restore");
  process.exit(1);
}

// Cleanup restore DB (keep dump for operator inspection if KEEP_DUMP=1)
if (process.env.KEEP_RESTORE_DB !== "1") {
  run("psql", ["-h", host, "-p", port, "-U", user, "-d", "postgres", "-c", `DROP DATABASE IF EXISTS ${restoreDB};`], env);
}
if (process.env.KEEP_DUMP !== "1") {
  fs.rmSync(work, { recursive: true, force: true });
} else {
  console.log(`[phase3] dump retained at ${dumpFile}`);
}

console.log("[phase3] PASS: backup + restore drill");
process.exit(0);
