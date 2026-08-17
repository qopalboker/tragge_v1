#!/usr/bin/env node
/**
 * Phase 4 final launch gate.
 * Every critical live gate must be PASS with evidence path.
 * Missing evidence = BLOCKED (never PASS).
 *
 * Evidence files under docs/codex/reports/evidence/phase4/
 * Optional: set PHASE4_EVIDENCE_DIR
 */

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const evidenceDir =
  process.env.PHASE4_EVIDENCE_DIR ||
  path.join(root, "docs/codex/reports/evidence/phase4");

function hasEvidence(substr) {
  if (!fs.existsSync(evidenceDir)) return false;
  const files = fs.readdirSync(evidenceDir);
  return files.some((f) => {
    const p = path.join(evidenceDir, f);
    if (!fs.statSync(p).isFile()) return false;
    const body = fs.readFileSync(p, "utf8");
    return body.includes(substr) && /PASS|SUCCESS|Bound|OK/.test(body);
  });
}

function preflightOk() {
  const p = path.join(evidenceDir, "preflight-2026-08-16.txt");
  if (!fs.existsSync(p)) return false;
  const body = fs.readFileSync(p, "utf8");
  return (
    body.includes("kubectl=PRESENT") &&
    body.includes("k8s_cluster=REACHABLE")
  );
}

const gates = [
  {
    name: "Persistent WAL (live PVC Bound)",
    status: hasEvidence("PVC_BOUND") || hasEvidence("wal-data.*Bound"),
    evidence: "evidence file containing PVC_BOUND",
  },
  {
    name: "Kubernetes Pod reschedule + WAL recovery",
    status: hasEvidence("POD_RESCHEDULE_PASS") || hasEvidence("WAL_REPLAY_AFTER_POD_DELETE"),
    evidence: "POD_RESCHEDULE_PASS",
  },
  {
    name: "Trading E2E on live deployment",
    status: hasEvidence("CONTROLLED_CONTEST_PASS"),
    evidence: "CONTROLLED_CONTEST_PASS",
  },
  {
    name: "Settlement exactly-once live",
    status: hasEvidence("SETTLEMENT_LIVE_PASS"),
    evidence: "SETTLEMENT_LIVE_PASS",
  },
  {
    name: "Kafka/Redpanda outage recovery",
    status: hasEvidence("KAFKA_OUTAGE_PASS"),
    evidence: "KAFKA_OUTAGE_PASS",
  },
  {
    name: "Backup/restore S3 E2E",
    status: hasEvidence("S3_BACKUP_RESTORE_PASS"),
    evidence: "S3_BACKUP_RESTORE_PASS",
  },
  {
    name: "Security MFA staging",
    status: hasEvidence("MFA_STAGING_PASS"),
    evidence: "MFA_STAGING_PASS",
  },
  {
    name: "Payment provider (non-mock)",
    status: hasEvidence("PAYMENT_PROVIDER_PASS"),
    evidence: "PAYMENT_PROVIDER_PASS",
  },
  {
    name: "Multi-service soak",
    status: hasEvidence("MULTI_SERVICE_SOAK_PASS"),
    evidence: "MULTI_SERVICE_SOAK_PASS",
  },
  {
    name: "Rollback drill",
    status: hasEvidence("ROLLBACK_DRILL_PASS"),
    evidence: "ROLLBACK_DRILL_PASS",
  },
  {
    name: "Live cluster pre-flight",
    status: preflightOk(),
    evidence: "preflight kubectl=PRESENT + k8s_cluster=REACHABLE",
  },
];

// Engineering residual still required green
const eng = spawnSync(
  "node",
  [path.join(root, "scripts/phase3/release-gates.mjs")],
  { cwd: root, encoding: "utf8", shell: false }
);
gates.push({
  name: "Engineering release gates (Phase 3)",
  status: eng.status === 0,
  evidence: "scripts/phase3/release-gates.mjs",
});

console.log("PHASE 4 LAUNCH GATE");
console.log("===================");
let blocked = 0;
for (const g of gates) {
  const st = g.status ? "PASS" : "BLOCKED";
  if (!g.status) blocked++;
  console.log(`${st.padEnd(8)} ${g.name}`);
  console.log(`         evidence: ${g.evidence}`);
}

console.log("===================");
if (blocked > 0) {
  console.log(`PRODUCTION — NO-GO (${blocked} blocked gates)`);
  process.exit(1);
}
console.log("PRODUCTION — GO (all gates PASS with evidence)");
process.exit(0);
