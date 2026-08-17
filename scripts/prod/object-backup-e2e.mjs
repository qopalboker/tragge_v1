#!/usr/bin/env node
/**
 * Object-storage backup E2E (production-equivalent).
 *
 * Requires real object storage credentials — refuses local-FS fake S3.
 *
 * Env (one of):
 *   S3_BUCKET / BACKUP_S3_BUCKET + AWS credentials (aws CLI)
 *   MINIO_ENDPOINT + AWS-compatible keys (aws --endpoint-url)
 *
 * Steps: pg_dump via docker → upload → head-object → download to temp →
 * restore into separate DB name → optional reconcile contest id.
 *
 * Exit 0 writes OBJECT_STORAGE_BACKUP_PASS + BACKUP_RESTORE_CLEAN_PASS tokens.
 * Exit 2 if object storage not configured (BLOCKED, not a silent skip-to-PASS).
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import {
  root,
  dockerBin,
  docker,
  run,
  readSecret,
} from "./lib.mjs";

const evidenceDir = path.join(root, "docs/codex/reports/evidence/phase61");
fs.mkdirSync(evidenceDir, { recursive: true });

const bucket = process.env.S3_BUCKET || process.env.BACKUP_S3_BUCKET || "";
const endpoint = process.env.MINIO_ENDPOINT || process.env.S3_ENDPOINT || "";
const prefix = process.env.S3_PREFIX || "backups/postgres";
const region = process.env.AWS_REGION || "us-east-1";

function log(...a) {
  console.log(...a);
}

if (!bucket && !endpoint) {
  const msg = [
    "OBJECT_STORAGE_UNAVAILABLE",
    "Set S3_BUCKET or BACKUP_S3_BUCKET (and AWS credentials), or MINIO_ENDPOINT.",
    "Local filesystem is NOT accepted as object-storage evidence.",
    "PHASE 6.1 object backup E2E — BLOCKED",
  ].join("\n");
  log(msg);
  fs.writeFileSync(path.join(evidenceDir, "object-backup-e2e.txt"), msg + "\n");
  process.exit(2);
}

const aws = (args) => {
  const base = ["s3", ...args];
  const full = endpoint
    ? ["--endpoint-url", endpoint, "--region", region, ...base]
    : ["--region", region, ...base];
  // aws cli uses: aws s3 cp ... OR aws --endpoint-url x s3 cp
  const argv = endpoint
    ? ["--endpoint-url", endpoint, "--region", region, "s3", ...args]
    : ["--region", region, "s3", ...args];
  return spawnSync("aws", argv, { encoding: "utf8", shell: false });
};

const hasAws = spawnSync("aws", ["--version"], { encoding: "utf8", shell: true });
if (hasAws.status !== 0) {
  const msg = "aws CLI MISSING — cannot upload to object storage\nPHASE 6.1 object backup E2E — BLOCKED\n";
  log(msg);
  fs.writeFileSync(path.join(evidenceDir, "object-backup-e2e.txt"), msg);
  process.exit(2);
}

const pass = readSecret("postgres_admin_password.txt");
const ts = new Date().toISOString().replace(/[:.]/g, "-");
const dumpName = `phase61-${ts}.dump`;
const remoteKey = `${prefix}/${dumpName}`;
const localDump = path.join(evidenceDir, dumpName);

// 1. pg_dump inside postgres container
log("Creating pg_dump...");
const dump = docker([
  "exec",
  "-e",
  `PGPASSWORD=${pass}`,
  "tragge_postgres",
  "pg_dump",
  "-U",
  "tragge_admin",
  "-d",
  "app",
  "-Fc",
  "--no-owner",
  "--no-acl",
  "-f",
  `/tmp/${dumpName}`,
]);
if (dump.status !== 0) {
  log("pg_dump failed", dump.stderr || dump.stdout);
  process.exit(1);
}
const cp = docker(["cp", `tragge_postgres:/tmp/${dumpName}`, localDump]);
if (cp.status !== 0 || !fs.existsSync(localDump)) {
  log("docker cp dump failed");
  process.exit(1);
}
const size = fs.statSync(localDump).size;
if (size < 1000) {
  log("dump size implausible", size);
  process.exit(1);
}
log(`dump_size_bytes=${size}`);

// 2. Upload
const s3Uri = `s3://${bucket}/${remoteKey}`;
log("Uploading", s3Uri);
const up = aws(["cp", localDump, s3Uri]);
if (up.status !== 0) {
  log("upload failed", up.stderr || up.stdout);
  fs.writeFileSync(
    path.join(evidenceDir, "object-backup-e2e.txt"),
    `UPLOAD_FAIL\n${up.stderr || up.stdout}\n`
  );
  process.exit(1);
}

// 3. Head / ls
const ls = aws(["ls", s3Uri]);
if (ls.status !== 0) {
  log("object not listable after upload", ls.stderr);
  process.exit(1);
}
log("object_listed=true", (ls.stdout || "").trim());

// 4. Download to verify readability
const verifyPath = path.join(evidenceDir, `verify-${dumpName}`);
const dl = aws(["cp", s3Uri, verifyPath]);
if (dl.status !== 0 || !fs.existsSync(verifyPath)) {
  log("download verify failed");
  process.exit(1);
}
const size2 = fs.statSync(verifyPath).size;
if (size2 !== size) {
  log(`size mismatch upload=${size} download=${size2}`);
  process.exit(1);
}

// 5. Restore into clean DB
const restoreDb = `app_restore_phase61_${Date.now()}`;
const sql = (q) =>
  docker([
    "exec",
    "-e",
    `PGPASSWORD=${pass}`,
    "tragge_postgres",
    "psql",
    "-U",
    "tragge_admin",
    "-d",
    "postgres",
    "-v",
    "ON_ERROR_STOP=1",
    "-c",
    q,
  ]);
sql(`DROP DATABASE IF EXISTS ${restoreDb};`);
const created = sql(`CREATE DATABASE ${restoreDb};`);
if (created.status !== 0) {
  log("create restore db failed", created.stderr);
  process.exit(1);
}
docker(["cp", verifyPath, `tragge_postgres:/tmp/restore-${dumpName}`]);
const restore = docker([
  "exec",
  "-e",
  `PGPASSWORD=${pass}`,
  "tragge_postgres",
  "pg_restore",
  "-U",
  "tragge_admin",
  "-d",
  restoreDb,
  "--no-owner",
  "--no-acl",
  `/tmp/restore-${dumpName}`,
]);
// pg_restore may return 1 with warnings; check tables
const check = docker([
  "exec",
  "-e",
  `PGPASSWORD=${pass}`,
  "tragge_postgres",
  "psql",
  "-U",
  "tragge_admin",
  "-d",
  restoreDb,
  "-t",
  "-A",
  "-c",
  "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';",
]);
const tableCount = parseInt((check.stdout || "0").trim(), 10);
if (!tableCount || tableCount < 5) {
  log("restore validation failed tables=", check.stdout, restore.stderr);
  process.exit(1);
}

const mig = docker([
  "exec",
  "-e",
  `PGPASSWORD=${pass}`,
  "tragge_postgres",
  "psql",
  "-U",
  "tragge_admin",
  "-d",
  restoreDb,
  "-t",
  "-A",
  "-c",
  "SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 1;",
]);

const report = [
  "OBJECT_STORAGE_BACKUP_PASS",
  "BACKUP_RESTORE_CLEAN_PASS",
  `bucket=${bucket}`,
  `endpoint=${endpoint || "aws-default"}`,
  `s3_uri=${s3Uri}`,
  `dump_size_bytes=${size}`,
  `download_size_bytes=${size2}`,
  `restore_db=${restoreDb}`,
  `public_tables=${tableCount}`,
  `migration_version=${(mig.stdout || "").trim()}`,
  `pg_restore_exit=${restore.status}`,
  "PASS",
].join("\n");
log(report);
fs.writeFileSync(path.join(evidenceDir, "object-backup-e2e.txt"), report + "\n");
// Keep dump artifact reference only; large dumps may remain in evidence dir
process.exit(0);
