#!/usr/bin/env node
/**
 * Documents and verifies emergency pause control surface.
 * Does not invent admin API if missing — records actual capability.
 *
 * Emits EMERGENCY_PAUSE_PASS only when an operator-invokable path is proven.
 */
import fs from "node:fs";
import path from "node:path";
import { root, writeEvidence, docker } from "./lib.mjs";

const findings = [];
function note(s) {
  findings.push(s);
  console.log(s);
}

note("EMERGENCY_PAUSE_CHECK");
note("=====================");

// Code/docs surface
const runbook = path.join(root, "docs/runbook/production-incident-runbook.md");
const hasRunbook = fs.existsSync(runbook);
note(`incident_runbook=${hasRunbook}`);
if (hasRunbook) {
  const b = fs.readFileSync(runbook, "utf8");
  note(`runbook_has_emergency_pause_section=${/Emergency pause/i.test(b)}`);
}

// Search for pause-related admin controls in repo (static)
const product = path.join(root, "docs/product/FIXED_PRODUCT_AND_TECHNICAL_POLICIES.md");
if (fs.existsSync(product)) {
  const b = fs.readFileSync(product, "utf8");
  note(`policy_PAUSE_SYMBOL=${/PAUSE_SYMBOL/.test(b)}`);
}

// Live: cannot claim PASS without authenticated admin action evidence
const liveEvidence = path.join(
  root,
  "docs/codex/reports/evidence/phase6nk/emergency-pause-live.txt"
);
const livePass =
  fs.existsSync(liveEvidence) &&
  /EMERGENCY_PAUSE_PASS|PASS/i.test(fs.readFileSync(liveEvidence, "utf8"));

note(`live_operator_evidence=${livePass}`);
note(
  "Operator procedure (Compose/VM): use admin API/UI to stop joins and pause symbols; " +
    "or stop trading-core as last resort (preserves WAL on bind mount). " +
    "On success write evidence file emergency-pause-live.txt containing a single status line."
);

const pass = livePass;
// Do not embed the success token in failure instructional text (avoids gate false positives).
const out =
  findings.join("\n") +
  `\nresult=${pass ? "PASS" : "BLOCKED"}\n` +
  (pass ? "EMERGENCY_PAUSE_PASS\n" : "need_live_admin_operator_test=true\n");
writeEvidence("emergency-pause-check.txt", out);
process.exit(pass ? 0 : 1);
