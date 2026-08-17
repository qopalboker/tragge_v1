#!/usr/bin/env node
/**
 * Phase 6.1 HARD gate — VM / WAL block / object storage / rollback.
 * Does NOT accept Docker Desktop local-only evidence for HARD VM gates.
 * Does NOT require Kubernetes.
 *
 * Exit 0 = PHASE 6.1 — PASS
 * Exit 1 = PHASE 6.1 — BLOCKED
 *
 * Evidence: docs/codex/reports/evidence/phase61/
 * Affirmative token lines required (see hasToken).
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const evidenceDir = path.join(root, "docs/codex/reports/evidence/phase61");
fs.mkdirSync(evidenceDir, { recursive: true });

function scanBodies() {
  const bodies = [];
  if (!fs.existsSync(evidenceDir)) return bodies;
  for (const f of fs.readdirSync(evidenceDir)) {
    if (/^phase61-gate/i.test(f)) continue; // no self-PASS
    const p = path.join(evidenceDir, f);
    if (!fs.statSync(p).isFile()) continue;
    bodies.push({ file: f, body: fs.readFileSync(p, "utf8") });
  }
  return bodies;
}

function hasToken(token) {
  const reLine = new RegExp(`(^|\\n)\\s*${token}\\s*($|\\n|\\s+PASS)`, "im");
  for (const { body } of scanBodies()) {
    if (reLine.test(body)) return true;
    if (body.split(/\r?\n/).some((l) => l.trim() === token)) return true;
  }
  return false;
}

function hasAny(...tokens) {
  return tokens.some((t) => hasToken(t));
}

// Reject Docker Desktop masquerading as VM replacement
function inventoryBlocksLiveVm() {
  const inv = path.join(evidenceDir, "inventory-latest.txt");
  if (!fs.existsSync(inv)) return true; // missing inventory = blocked
  const b = fs.readFileSync(inv, "utf8");
  if (/BLOCKED=LIVE_VM_REQUIRED/i.test(b)) return true;
  if (/is_docker_desktop=true/i.test(b) && !/operator_declared_live_vm=true/i.test(b)) return true;
  return false;
}

const liveVmBlocked = inventoryBlocksLiveVm();

const gates = [
  {
    id: "HARD-01",
    name: "Persistent WAL on dedicated block storage",
    hard: true,
    status:
      !liveVmBlocked &&
      (hasToken("WAL_BLOCK_STORAGE_PASS") || hasToken("HARD01_PASS")),
    evidence: "WAL_BLOCK_STORAGE_PASS (real block device, not Desktop path)",
  },
  {
    id: "HARD-02",
    name: "VM reboot recovery",
    hard: true,
    status: !liveVmBlocked && (hasToken("VM_REBOOT_PASS") || hasToken("HARD02_PASS")),
    evidence: "VM_REBOOT_PASS with pre/post trade + reconcile",
  },
  {
    id: "HARD-03",
    name: "VM replacement + volume reattach (or documented backup recovery)",
    hard: true,
    status:
      !liveVmBlocked &&
      (hasToken("VM_REPLACEMENT_PASS") ||
        hasToken("HARD03_PASS") ||
        (hasToken("VM_REPLACEMENT_BACKUP_RECOVERY_PASS") && hasToken("RPO_DOCUMENTED"))),
    evidence: "VM_REPLACEMENT_PASS or backup-recovery equivalent + RPO_DOCUMENTED",
  },
  {
    id: "HARD-04",
    name: "Backup uploaded to real object storage",
    hard: true,
    status: hasToken("S3_BACKUP_RESTORE_PASS") || hasToken("OBJECT_STORAGE_BACKUP_PASS") || hasToken("HARD04_PASS"),
    evidence: "OBJECT_STORAGE_BACKUP_PASS / S3_BACKUP_RESTORE_PASS (not local FS)",
  },
  {
    id: "HARD-05",
    name: "Backup restored into clean environment",
    hard: true,
    status: hasToken("BACKUP_RESTORE_CLEAN_PASS") || hasToken("HARD05_PASS") || hasToken("S3_BACKUP_RESTORE_PASS"),
    evidence: "BACKUP_RESTORE_CLEAN_PASS",
  },
  {
    id: "HARD-06",
    name: "Restored DB financial reconciliation",
    hard: true,
    status: hasToken("RESTORE_RECONCILE_PASS") || hasToken("HARD06_PASS") || hasToken("RECONCILE_CLEAN"),
    evidence: "RESTORE_RECONCILE_PASS / RECONCILE_CLEAN after restore",
  },
  {
    id: "HARD-07",
    name: "Rollback drill or proven forward-fix strategy",
    hard: true,
    status:
      hasToken("ROLLBACK_DRILL_PASS") ||
      hasToken("HARD07_PASS") ||
      (hasToken("FORWARD_FIX_PASS") && hasToken("MIGRATION_CLASSIFIED")),
    evidence: "ROLLBACK_DRILL_PASS or FORWARD_FIX_PASS + MIGRATION_CLASSIFIED",
  },
  {
    id: "HARD-08",
    name: "Single-active trading owner during recovery",
    hard: true,
    status: hasToken("SINGLE_ACTIVE_OWNER_PASS") || hasToken("HARD08_PASS"),
    evidence: "SINGLE_ACTIVE_OWNER_PASS (old host down before new engine ready)",
  },
  // Supporting (still required for phase PASS)
  {
    id: "SUP-01",
    name: "Container recreate WAL (production path)",
    hard: false,
    status: hasToken("WAL_HOST_PERSIST_PASS") || hasToken("CONTAINER_RECREATE_PASS"),
    evidence: "WAL_HOST_PERSIST_PASS",
  },
  {
    id: "SUP-02",
    name: "Docker engine restart drill",
    hard: true,
    status: !liveVmBlocked && (hasToken("HOST_DOCKER_RESTART_PASS") || hasToken("DOCKER_ENGINE_RESTART_PASS")),
    evidence: "HOST_DOCKER_RESTART_PASS on production-equivalent host",
  },
  {
    id: "SUP-03",
    name: "Health gate after recovery",
    hard: false,
    status: hasToken("PRODUCTION HEALTH — PASS") || hasToken("HEALTH_AFTER_RECOVERY_PASS"),
    evidence: "PRODUCTION HEALTH — PASS post-recovery",
  },
];

// Optionally pull non-HARD local tokens from phase6nk for SUP-01 only
const phase6nk = path.join(root, "docs/codex/reports/evidence/phase6nk");
if (fs.existsSync(phase6nk)) {
  for (const f of fs.readdirSync(phase6nk)) {
    if (!/wal-persist/i.test(f)) continue;
    const body = fs.readFileSync(path.join(phase6nk, f), "utf8");
    if (/WAL_HOST_PERSIST_PASS/.test(body)) {
      const g = gates.find((x) => x.id === "SUP-01");
      if (g) {
        g.status = true;
        g.evidence += " [phase6nk wal-persist-drill]";
      }
    }
  }
}

console.log("PHASE 6.1 GATE — VM / WAL / Object Storage / Rollback");
console.log("======================================================");
console.log(`live_vm_blocked_by_inventory=${liveVmBlocked}`);
console.log(`evidence_dir=${evidenceDir}`);
console.log("");

let blockedHard = 0;
let blockedAll = 0;
const rows = [];
for (const g of gates) {
  const st = g.status ? "PASS" : "BLOCKED";
  if (!g.status) {
    blockedAll++;
    if (g.hard) blockedHard++;
  }
  console.log(`${st.padEnd(8)} ${g.id}  ${g.name}`);
  console.log(`         evidence: ${g.evidence}`);
  rows.push({ ...g, result: st });
}

// Inventory summary
const invPath = path.join(evidenceDir, "inventory-latest.txt");
if (fs.existsSync(invPath)) {
  console.log("");
  console.log("--- inventory excerpt ---");
  console.log(
    fs
      .readFileSync(invPath, "utf8")
      .split("\n")
      .filter((l) => /BLOCKED|is_docker|object_storage|operator_declared|HARD0|reason=/.test(l))
      .slice(0, 20)
      .join("\n")
  );
}

const decision =
  blockedHard === 0 && blockedAll === 0
    ? "PHASE 6.1 — PASS"
    : `PHASE 6.1 — BLOCKED (${blockedHard} hard, ${blockedAll} total)`;

console.log("");
console.log("======================================================");
console.log(decision);
console.log("next_phase_allowed=" + (blockedHard === 0 && blockedAll === 0 ? "PHASE_6.2" : "NO — remain on 6.1"));

const report = {
  ts: new Date().toISOString(),
  decision: blockedHard === 0 && blockedAll === 0 ? "PHASE 6.1 — PASS" : "PHASE 6.1 — BLOCKED",
  live_vm_blocked_by_inventory: liveVmBlocked,
  blocked_hard: blockedHard,
  blocked_all: blockedAll,
  rows,
  kubernetes_required: false,
  phase_6_2_not_started: true,
};
fs.writeFileSync(path.join(evidenceDir, "phase61-gate-latest.json"), JSON.stringify(report, null, 2));
fs.writeFileSync(
  path.join(evidenceDir, "phase61-gate-latest.txt"),
  rows.map((r) => `${r.result}  ${r.id}  ${r.name} — ${r.evidence}`).join("\n") +
    `\n\n${decision}\n`
);

process.exit(blockedHard === 0 && blockedAll === 0 ? 0 : 1);
