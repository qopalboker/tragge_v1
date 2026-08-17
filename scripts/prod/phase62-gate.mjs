#!/usr/bin/env node
/**
 * Phase 6.2 gate — external readiness, security, monitoring, pause, first launch.
 * Does NOT require Kubernetes.
 * Does NOT invent provider credentials or human sign-offs.
 *
 * Exit 0 = PHASE 6.2 — PASS (all external readiness gates with evidence)
 * Exit 1 = PHASE 6.2 — BLOCKED
 *
 * Evidence: docs/codex/reports/evidence/phase62/
 * Also reads phase61-local / phase6nk for baseline infra tokens (read-only).
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const evidenceDir = path.join(root, "docs/codex/reports/evidence/phase62");
fs.mkdirSync(evidenceDir, { recursive: true });

const extraDirs = [
  evidenceDir,
  path.join(root, "docs/codex/reports/evidence/phase6nk"),
  path.join(root, "docs/codex/reports/evidence/phase61-local"),
];

function bodies() {
  const out = [];
  for (const dir of extraDirs) {
    if (!fs.existsSync(dir)) continue;
    for (const f of fs.readdirSync(dir)) {
      if (/^phase62-gate/i.test(f) || /^launch-gate/i.test(f)) continue;
      const p = path.join(dir, f);
      if (!fs.statSync(p).isFile()) continue;
      out.push(fs.readFileSync(p, "utf8"));
    }
  }
  return out;
}

function hasToken(token) {
  const re = new RegExp(`(^|\\n)\\s*${token}\\b`, "m");
  return bodies().some((b) => re.test(b));
}

function reportHas(rel, substr) {
  const p = path.join(root, rel);
  if (!fs.existsSync(p)) return false;
  return fs.readFileSync(p, "utf8").includes(substr);
}

function runSec(cmd, args) {
  return spawnSync(cmd, args, { cwd: root, encoding: "utf8", shell: false, timeout: 120000 });
}

const localInfraOk =
  reportHas(
    "docs/codex/reports/PHASE-6.1-LOCAL-INFRA-CLOSURE-2026-08-16.md",
    "PHASE 6.1-LOCAL-INFRA — PASS"
  ) || hasToken("LOCAL_VM_REBOOT_PASS");

const gates = [
  {
    id: "P62-00",
    name: "Prerequisite: local infrastructure fully qualified",
    hard: true,
    status: localInfraOk,
    evidence: "PHASE-6.1-LOCAL-INFRA-CLOSURE PASS",
  },
  {
    id: "P62-01",
    name: "Payment provider non-mock qualification",
    hard: true,
    status: hasToken("PAYMENT_PROVIDER_PASS"),
    evidence: "PAYMENT_PROVIDER_PASS (provider sandbox/prod, not mock)",
  },
  {
    id: "P62-02",
    name: "Market-data production provider qualification",
    hard: true,
    status: hasToken("MARKET_DATA_PROVIDER_PASS") || hasToken("MD_PROVIDER_PASS"),
    evidence: "MARKET_DATA_PROVIDER_PASS (live feed, not placeholder)",
  },
  {
    id: "P62-03",
    name: "Admin MFA production-like enrollment",
    hard: true,
    status: hasToken("MFA_STAGING_PASS") || hasToken("MFA_PROD_PASS"),
    evidence: "MFA_STAGING_PASS or MFA_PROD_PASS (live admin session)",
  },
  {
    id: "P62-04",
    name: "Security regression (auth packages)",
    hard: true,
    status: hasToken("SECURITY_REGRESSION_PASS"),
    evidence: "SECURITY_REGRESSION_PASS from phase62 security run",
  },
  {
    id: "P62-05",
    name: "Emergency pause live operator drill",
    hard: true,
    status: hasToken("EMERGENCY_PAUSE_PASS"),
    evidence: "EMERGENCY_PAUSE_PASS (admin pause or authorized last-resort stop)",
  },
  {
    id: "P62-06",
    name: "Monitoring signals qualified",
    hard: true,
    status: hasToken("MONITORING_PASS"),
    evidence: "MONITORING_PASS (operator-visible unsafe-state signals)",
  },
  {
    id: "P62-07",
    name: "Alerts exercised (fired)",
    hard: true,
    status: hasToken("ALERTS_PASS") || hasToken("MONITORING_ALERTS_PASS"),
    evidence: "ALERTS_PASS (at least one critical alert path fired)",
  },
  {
    id: "P62-08",
    name: "External / legal / provider sign-offs CONFIRMED",
    hard: true,
    status: hasToken("EXTERNAL_SIGNOFF_CONFIRMED"),
    evidence: "EXTERNAL_SIGNOFF_CONFIRMED human matrix",
  },
  {
    id: "P62-09",
    name: "Controlled first production contest + reconcile",
    hard: true,
    status:
      (hasToken("CONTROLLED_CONTEST_PASS") || hasToken("FIRST_PROD_CONTEST_PASS")) &&
      (hasToken("RECONCILE_CLEAN") || hasToken("FIRST_PROD_RECONCILE_PASS")),
    evidence: "CONTROLLED_CONTEST_PASS + RECONCILE_CLEAN",
  },
  {
    id: "P62-10",
    name: "Production launch-gate ready path documented",
    hard: false,
    status: fs.existsSync(path.join(root, "scripts/prod/launch-gate.mjs")),
    evidence: "scripts/prod/launch-gate.mjs exists",
  },
];

console.log("PHASE 6.2 GATE — External Readiness / Security / Ops / First Launch");
console.log("====================================================================");
console.log("kubernetes_required=false");
console.log("");

let hardFail = 0;
let softFail = 0;
const rows = [];
for (const g of gates) {
  const st = g.status ? "PASS" : "BLOCKED";
  if (!g.status) {
    if (g.hard) hardFail++;
    else softFail++;
  }
  console.log(`${st.padEnd(8)} ${g.id}  ${g.name}`);
  console.log(`         evidence: ${g.evidence}`);
  rows.push({ ...g, result: st });
}

const decision =
  hardFail === 0
    ? "PHASE 6.2 — PASS"
    : `PHASE 6.2 — BLOCKED (${hardFail} hard, ${softFail} soft)`;

console.log("");
console.log("====================================================================");
console.log(decision);
console.log("production_go_authorized=" + (hardFail === 0 ? "ONLY_IF_launch-gate_also_0" : "false"));
console.log("not_claimed=PRODUCTION — GO without launch-gate + human sign-off");

fs.writeFileSync(
  path.join(evidenceDir, "phase62-gate-latest.txt"),
  rows.map((r) => `${r.result}  ${r.id}  ${r.name} — ${r.evidence}`).join("\n") +
    `\n\n${decision}\n`
);
fs.writeFileSync(
  path.join(evidenceDir, "phase62-gate-latest.json"),
  JSON.stringify(
    {
      ts: new Date().toISOString(),
      decision: hardFail === 0 ? "PHASE 6.2 — PASS" : "PHASE 6.2 — BLOCKED",
      hard_fail: hardFail,
      soft_fail: softFail,
      rows,
      kubernetes_required: false,
    },
    null,
    2
  )
);

process.exit(hardFail === 0 ? 0 : 1);
