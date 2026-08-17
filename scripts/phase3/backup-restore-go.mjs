#!/usr/bin/env node
/**
 * Phase 3 backup/restore drill without host pg_dump.
 * Runs a Go test that:
 *  1) counts critical tables on live DB
 *  2) pg_dump via pure SQL CREATE TABLE AS / verification of dump file
 *  3) validates restore path using a second schema snapshot
 *
 * Preferred when pg client tools are not on PATH.
 */

import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");

const r = spawnSync(
  "go",
  [
    "test",
    "./packages/wallet/",
    "-count=1",
    "-timeout",
    "180s",
    "-run",
    "TestPhase3_BackupRestoreDrill",
    "-v",
  ],
  { cwd: root, encoding: "utf8", shell: false }
);
process.stdout.write(r.stdout || "");
process.stderr.write(r.stderr || "");
process.exit(r.status || 0);
