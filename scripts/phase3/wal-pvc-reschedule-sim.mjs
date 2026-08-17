#!/usr/bin/env node
/**
 * Phase 3 Test B — WAL "PVC reschedule" simulation
 *
 * Kubernetes PVC reattach is modeled as:
 *   1) process writes durable WAL to a host path (PVC mount)
 *   2) process exits (pod delete)
 *   3) new process opens the SAME path (reattach volume)
 *   4) recovery must restore pending intent without duplication
 *
 * This is stronger than in-memory restart: the storage identity is the path,
 * matching StatefulSet volumeClaimTemplates remount semantics.
 *
 * Usage:
 *   node scripts/phase3/wal-pvc-reschedule-sim.mjs
 *
 * Optional:
 *   WAL_SIM_DIR=/path/to/volume
 */

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const repoRoot = path.resolve(__dirname, "../..");
const simDir =
  process.env.WAL_SIM_DIR ||
  fs.mkdtempSync(path.join(os.tmpdir(), "tragge-wal-pvc-"));
const walPath = path.join(simDir, "engine.jsonl");

console.log("[phase3] WAL PVC reschedule simulation");
console.log(`[phase3] volume path: ${simDir}`);
console.log(`[phase3] wal file:    ${walPath}`);

// Ensure volume is empty-like (new PVC attach)
if (fs.existsSync(walPath)) fs.unlinkSync(walPath);

const testPkg = path.join(repoRoot, "apps/trading-engine");
const env = {
  ...process.env,
  WAL_PVC_SIM_PATH: walPath,
  WAL_PVC_SIM_DIR: simDir,
};

// Run dedicated Go test that writes → close → reopen same path
const r = spawnSync(
  "go",
  [
    "test",
    "./server/",
    "-count=1",
    "-timeout",
    "60s",
    "-run",
    "TestPhase3_WALPVCRescheduleSimulation",
    "-v",
  ],
  {
    cwd: testPkg,
    env,
    encoding: "utf8",
    shell: true,
  }
);

process.stdout.write(r.stdout || "");
process.stderr.write(r.stderr || "");

if (r.status !== 0) {
  console.error("[phase3] FAIL: WAL PVC reschedule simulation");
  process.exit(r.status || 1);
}

// Prove file still exists after "reschedule"
if (!fs.existsSync(walPath)) {
  console.error("[phase3] FAIL: WAL file missing after recovery");
  process.exit(1);
}
const size = fs.statSync(walPath).size;
console.log(`[phase3] WAL file survived remount, size=${size} bytes`);
console.log("[phase3] PASS: WAL PVC reschedule simulation");
process.exit(0);
