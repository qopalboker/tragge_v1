#!/usr/bin/env node
/**
 * Phase 3 release gates — fail closed if launch-critical conditions are not met.
 *
 * Checks:
 *  1) K8s trading-core is StatefulSet with volumeClaimTemplates (no emptyDir WAL)
 *  2) Production config requires WAL_REQUIRE_PERSIST
 *  3) Critical Go tests pass
 *  4) WAL reschedule simulation passes
 *  5) Optional: backup/restore drill if RUN_BACKUP_DRILL=1
 */

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
let failed = 0;

function gate(name, ok, detail = "") {
  if (ok) console.log(`[gate] PASS ${name}${detail ? " — " + detail : ""}`);
  else {
    console.error(`[gate] FAIL ${name}${detail ? " — " + detail : ""}`);
    failed++;
  }
}

// 1) Manifest: no emptyDir for trading WAL
const tradingCore = fs.readFileSync(
  path.join(root, "infra/k8s/base/trading-core.yaml"),
  "utf8"
);
gate(
  "trading-core is StatefulSet",
  /kind:\s*StatefulSet/.test(tradingCore) && /name:\s*trading-core/.test(tradingCore)
);
gate(
  "WAL volumeClaimTemplates present",
  /volumeClaimTemplates:/.test(tradingCore) && /name:\s*wal-data/.test(tradingCore)
);
gate(
  "no emptyDir WAL fallback in trading-core",
  !/wal-data:\s*\n\s*emptyDir:/.test(tradingCore) &&
    !/name:\s*wal-data\s*\n\s*emptyDir:/.test(tradingCore)
);
// More precise: wal-data under volumes: emptyDir should not exist
const walEmptyDir =
  /volumes:[\s\S]*name:\s*wal-data[\s\S]*emptyDir:/.test(tradingCore) &&
  !/volumeClaimTemplates:[\s\S]*name:\s*wal-data/.test(tradingCore);
gate("WAL not emptyDir-only", !walEmptyDir && /volumeClaimTemplates:/.test(tradingCore));
gate("replicas: 1 single-active", /replicas:\s*1/.test(tradingCore));
gate("WAL_REQUIRE_PERSIST=true in manifest", /WAL_REQUIRE_PERSIST[\s\S]*"true"/.test(tradingCore));

// 2) Production overlay storage class for WAL
const storage = fs.readFileSync(
  path.join(root, "infra/k8s/overlays/production/patches/storage.yaml"),
  "utf8"
);
gate(
  "production WAL storageClass patch",
  /trading-core/.test(storage) && /premium-rwo/.test(storage)
);

// 3) HPA not scaling trading-core
const hpa = fs.readFileSync(path.join(root, "infra/k8s/base/hpa.yaml"), "utf8");
gate(
  "no trading-core HPA autoscaler",
  !/name:\s*trading-core-hpa/.test(hpa) || /forbid_hpa:\s*true/.test(hpa)
);

// 4) Critical tests (Windows: avoid shell metacharacters on -run pipes)
function run(cmd, args, { shell = false } = {}) {
  return spawnSync(cmd, args, { cwd: root, encoding: "utf8", shell });
}

let r = run("go", [
  "test",
  "./apps/trading-engine/server/",
  "-count=1",
  "-timeout",
  "120s",
  "-run",
  "TestPhase3_WALPVCRescheduleSimulation|TestWAL_CorruptLineFailClosed|TestConfig_WALRequirePersistFailClosed",
]);
gate("WAL durability unit tests", r.status === 0, r.status ? (r.stderr || r.stdout || "").slice(0, 300) : "");

r = run("go", [
  "test",
  "./packages/wallet/",
  "-count=1",
  "-timeout",
  "120s",
  "-run",
  "Phase11",
]);
gate("Phase 1.1 financial regression", r.status === 0);

r = run("node", [path.join(__dirname, "wal-pvc-reschedule-sim.mjs")], { shell: true });
gate("WAL PVC reschedule simulation", r.status === 0);

// Logical backup/restore (always — uses live Postgres, no pg_dump required)
r = run("go", [
  "test",
  "./packages/wallet/",
  "-count=1",
  "-timeout",
  "180s",
  "-run",
  "TestPhase3_BackupRestoreDrill",
]);
gate("backup/restore logical drill", r.status === 0);

if (process.env.RUN_BACKUP_DRILL === "1") {
  r = run("node", [path.join(__dirname, "backup-restore-drill.mjs")], { shell: true });
  gate("backup/restore pg_dump drill", r.status === 0);
} else {
  console.log("[gate] SKIP pg_dump drill (set RUN_BACKUP_DRILL=1 when client tools available)");
}

if (failed > 0) {
  console.error(`[gate] RELEASE GATES FAILED (${failed})`);
  process.exit(1);
}
console.log("[gate] ALL RELEASE GATES PASSED");
process.exit(0);
