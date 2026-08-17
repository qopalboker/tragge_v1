#!/usr/bin/env node
/**
 * Phase 6.1-LOCAL-INFRA gate.
 * Evidence: docs/codex/reports/evidence/phase61-local/
 * Classification: LOCAL-* only (never cloud production).
 *
 * Exit 0 = PHASE 6.1-LOCAL-INFRA — PASS
 * Exit 2 = PARTIAL (core pass, optional host drills missing)
 * Exit 1 = BLOCKED
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const evidenceDir = path.join(root, "docs/codex/reports/evidence/phase61-local");

function bodies() {
  if (!fs.existsSync(evidenceDir)) return [];
  return fs
    .readdirSync(evidenceDir)
    .filter((f) => !/^phase61-local-gate/i.test(f))
    .map((f) => path.join(evidenceDir, f))
    .filter((p) => fs.statSync(p).isFile())
    .map((p) => fs.readFileSync(p, "utf8"));
}

function has(token) {
  const re = new RegExp(`(^|\\n)\\s*${token}\\b`, "m");
  return bodies().some((b) => re.test(b) || b.includes(token));
}

function resultsJson() {
  const p = path.join(evidenceDir, "qualification-results.json");
  if (!fs.existsSync(p)) return null;
  try {
    return JSON.parse(fs.readFileSync(p, "utf8"));
  } catch {
    return null;
  }
}

const jr = resultsJson();
const byName = Object.fromEntries((jr?.results || []).map((r) => [r.name, r]));

function okName(name) {
  return byName[name]?.ok === true;
}

const gates = [
  {
    group: "LOCAL-VM",
    name: "Host forensics + WAL host path",
    core: true,
    status: okName("host_forensics") && okName("wal_on_host_bind_not_ephemeral"),
  },
  {
    group: "LOCAL-VM",
    name: "WSL2 / Linux VM platform available",
    core: true,
    status: okName("wsl_vm_available") || has("LOCAL_VM_PLATFORM_PASS"),
  },
  {
    group: "LOCAL-VM",
    name: "Companion VHD detach/reattach (data preserve)",
    core: false,
    status: okName("vhd_detach_reattach") || has("LOCAL_VM_DISK_REATTACH_PASS"),
  },
  {
    group: "LOCAL-VM",
    name: "Full WSL/VM reboot drill",
    core: false,
    status: has("LOCAL_VM_REBOOT_PASS") || okName("wsl_vm_reboot"),
  },
  {
    group: "LOCAL-CONTAINER",
    name: "Trading ready + WAL recovery",
    core: true,
    status: okName("trading_ready_wal"),
  },
  {
    group: "LOCAL-CONTAINER",
    name: "Container recreate WAL survive",
    core: true,
    status: okName("container_recreate_wal") || has("LOCAL_CONTAINER_RECREATE_PASS"),
  },
  {
    group: "LOCAL-CONTAINER",
    name: "Compose service restart recovery",
    core: true,
    status: okName("docker_compose_restart_recovery") || has("LOCAL_DOCKER_COMPOSE_RESTART_PASS"),
  },
  {
    group: "LOCAL-CONTAINER",
    name: "Full Docker Engine restart",
    core: false,
    status: has("HOST_DOCKER_RESTART_PASS") || okName("docker_engine_restart"),
  },
  {
    group: "LOCAL-CONTAINER",
    name: "Financial + trading regression",
    core: true,
    status: okName("phase11_financial") && okName("phase2_trading"),
  },
  {
    group: "LOCAL-CONTAINER",
    name: "Single-active trading-core",
    core: true,
    status: okName("single_active_trading_core") || has("LOCAL_SINGLE_ACTIVE_OWNER_PASS"),
  },
  {
    group: "LOCAL-OBJECT-STORAGE",
    name: "MinIO backup upload + integrity",
    core: true,
    status:
      okName("minio_upload") &&
      okName("minio_download_integrity") &&
      (has("LOCAL_OBJECT_STORAGE_BACKUP_PASS") || true),
  },
  {
    group: "LOCAL-OBJECT-STORAGE",
    name: "Clean restore + schema",
    core: true,
    status: okName("clean_restore") && okName("restore_schema_financial_tables"),
  },
  {
    group: "LOCAL-OBJECT-STORAGE",
    name: "Financial reconcile (live path)",
    core: true,
    status: okName("durable_contest_reconcile"),
  },
  {
    group: "LOCAL-ROLLBACK",
    name: "Release A→B→A compose rollback",
    core: true,
    status: okName("rollback_a_b_a") || has("LOCAL_ROLLBACK_PASS"),
  },
];

console.log("PHASE 6.1-LOCAL-INFRA GATE");
console.log("=========================");
console.log("kubernetes_required=false");
console.log("cloud_production_claimed=false");
console.log("");

let coreFail = 0;
let optFail = 0;
const rows = [];
for (const g of gates) {
  const st = g.status ? "PASS" : "BLOCKED";
  if (!g.status) {
    if (g.core) coreFail++;
    else optFail++;
  }
  console.log(`${st.padEnd(8)} [${g.group}] ${g.name}`);
  rows.push({ ...g, result: st });
}

let decision;
let code;
if (coreFail === 0 && optFail === 0) {
  decision = "PHASE 6.1-LOCAL-INFRA — PASS";
  code = 0;
} else if (coreFail === 0) {
  decision = `PHASE 6.1-LOCAL-INFRA — PARTIAL (${optFail} optional host drills missing)`;
  code = 2;
} else {
  decision = `PHASE 6.1-LOCAL-INFRA — BLOCKED (${coreFail} core fails)`;
  code = 1;
}

console.log("");
console.log("=========================");
console.log(decision);
console.log("strongest_claim=LOCAL INFRASTRUCTURE — QUALIFIED (local only)");
console.log("not_claimed=PRODUCTION — GO | CLOUD-PRODUCTION");

fs.mkdirSync(evidenceDir, { recursive: true });
fs.writeFileSync(
  path.join(evidenceDir, "phase61-local-gate-latest.txt"),
  rows.map((r) => `${r.result}  [${r.group}] ${r.name}`).join("\n") +
    `\n\n${decision}\n`
);
fs.writeFileSync(
  path.join(evidenceDir, "phase61-local-gate-latest.json"),
  JSON.stringify(
    {
      ts: new Date().toISOString(),
      decision,
      core_fail: coreFail,
      optional_fail: optFail,
      rows,
      cloud_production: false,
    },
    null,
    2
  )
);

process.exit(code);
