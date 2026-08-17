#!/usr/bin/env node
/**
 * Phase 6.1 infrastructure inventory.
 * Records whether a REAL production-equivalent VM + block storage + object storage
 * are available. Docker Desktop / local paths are explicitly NOT sufficient.
 *
 * Exit 0 = inventory recorded (may still be BLOCKED for live VM)
 * Exit 2 = cannot even run local preflight tools
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import {
  root,
  dockerBin,
  run,
  writeEvidence,
  evidenceDir,
  walHostPath,
  ensureEvidenceDir,
} from "./lib.mjs";

ensureEvidenceDir();
// Also write under phase61 evidence dir
const phase61Dir = path.join(root, "docs/codex/reports/evidence/phase61");
fs.mkdirSync(phase61Dir, { recursive: true });

function hasCmd(name) {
  const r =
    process.platform === "win32"
      ? spawnSync("where", [name], { encoding: "utf8", shell: true })
      : spawnSync("which", [name], { encoding: "utf8", shell: true });
  return r.status === 0;
}

function envSet(k) {
  return Boolean(process.env[k] && String(process.env[k]).trim());
}

const lines = [];
const ts = new Date().toISOString();
lines.push(`PHASE61_INVENTORY ${ts}`);
lines.push(`kubernetes_required=false`);
lines.push(`docker_desktop_is_not_production_vm=true`);

// Docker context
const di = run(dockerBin, ["info", "--format", "{{.Name}}|{{.OperatingSystem}}|{{.ServerVersion}}"]);
const dockerInfo = (di.stdout || "").trim();
lines.push(`docker_info=${dockerInfo || "unavailable"}`);
const isDockerDesktop = /docker desktop|desktop-linux|Docker Desktop/i.test(dockerInfo + (di.stderr || ""));
lines.push(`is_docker_desktop=${isDockerDesktop}`);

// Cloud / remote
const tools = {
  aws: hasCmd("aws"),
  az: hasCmd("az"),
  gcloud: hasCmd("gcloud"),
  terraform: hasCmd("terraform"),
  ssh: hasCmd("ssh"),
  multipass: hasCmd("multipass"),
  qemu: hasCmd("qemu-system-x86_64"),
};
for (const [k, v] of Object.entries(tools)) lines.push(`tool_${k}=${v ? "PRESENT" : "MISSING"}`);

const envKeys = [
  "TRAGGE_PROD_HOST",
  "TRAGGE_SSH_HOST",
  "TRAGGE_VM_HOST",
  "AWS_ACCESS_KEY_ID",
  "AWS_PROFILE",
  "AWS_REGION",
  "S3_BUCKET",
  "BACKUP_S3_BUCKET",
  "MINIO_ENDPOINT",
  "AZURE_STORAGE_ACCOUNT",
  "GCS_BUCKET",
];
for (const k of envKeys) lines.push(`env_${k}=${envSet(k) ? "set" : "unset"}`);

// Explicit operator declaration
const liveVm =
  process.env.PHASE61_LIVE_VM === "1" ||
  process.env.PHASE61_LIVE_VM === "true" ||
  envSet("TRAGGE_PROD_HOST") ||
  envSet("TRAGGE_SSH_HOST") ||
  envSet("TRAGGE_VM_HOST");
const objectStore =
  envSet("S3_BUCKET") ||
  envSet("BACKUP_S3_BUCKET") ||
  envSet("MINIO_ENDPOINT") ||
  envSet("GCS_BUCKET") ||
  envSet("AZURE_STORAGE_ACCOUNT");
const blockVol =
  process.env.PHASE61_BLOCK_VOLUME === "1" ||
  process.env.PHASE61_BLOCK_VOLUME === "true" ||
  (process.env.TRAGGE_WAL_HOST_PATH &&
    !String(process.env.TRAGGE_WAL_HOST_PATH).includes("var\\lib\\tragge") &&
    !String(process.env.TRAGGE_WAL_HOST_PATH).includes("var/lib/tragge") &&
    process.env.PHASE61_WAL_IS_BLOCK === "1");

lines.push(`operator_declared_live_vm=${liveVm}`);
lines.push(`operator_declared_object_storage=${objectStore}`);
lines.push(`operator_declared_block_volume=${Boolean(blockVol)}`);
lines.push(`wal_host_path=${walHostPath()}`);
lines.push(`os=${process.platform}`);
lines.push(`hostname=${process.env.COMPUTERNAME || process.env.HOSTNAME || "unknown"}`);

// HARD gate availability (this session)
const hard = {
  HARD01_persistent_wal_block: false, // requires real block device, not Desktop path
  HARD02_vm_reboot: false,
  HARD03_vm_replacement: false,
  HARD04_object_backup_upload: false,
  HARD05_backup_restore: false,
  HARD06_restore_reconcile: false,
  HARD07_rollback: false,
  HARD08_single_active_owner: false,
};

if (isDockerDesktop && !liveVm) {
  lines.push(`BLOCKED=LIVE_VM_REQUIRED`);
  lines.push(
    `reason=Docker Desktop (WSL2) is not a production-equivalent VM; no TRAGGE_*_HOST / PHASE61_LIVE_VM declared`
  );
} else if (!liveVm) {
  lines.push(`BLOCKED=LIVE_VM_REQUIRED`);
  lines.push(`reason=No production-equivalent VM host declared`);
} else {
  lines.push(`live_vm_declared=true`);
  lines.push(`NOTE=Operator must still produce drill evidence tokens under phase61/`);
}

if (!objectStore) {
  lines.push(`object_storage=UNAVAILABLE`);
  lines.push(`reason_object=No S3_BUCKET/BACKUP_S3_BUCKET/MINIO_ENDPOINT/GCS/Azure storage env`);
} else {
  lines.push(`object_storage=DECLARED`);
}

for (const [k, v] of Object.entries(hard)) {
  lines.push(`${k}=${v ? "PASS" : "BLOCKED"}`);
}

const out = lines.join("\n") + "\n";
console.log(out);
fs.writeFileSync(path.join(phase61Dir, "inventory-latest.txt"), out);
fs.writeFileSync(path.join(phase61Dir, `inventory-${ts.slice(0, 10)}.txt`), out);
// Also into phase6nk for launch-gate cross-read if needed
writeEvidence("phase61-inventory.txt", out);

const toolsOk = di.status === 0;
process.exit(toolsOk ? 0 : 2);
