#!/usr/bin/env node
/**
 * Phase 5 infrastructure readiness checklist.
 * Exit 0 only when operator tools + reachable cluster + StorageClass exist.
 * Does not provision cloud resources; verifies prerequisites for provisioning.
 */

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const evidenceDir = path.join(root, "docs/codex/reports/evidence/phase5");
fs.mkdirSync(evidenceDir, { recursive: true });

function hasCmd(name) {
  const probe =
    process.platform === "win32"
      ? spawnSync("where", [name], { encoding: "utf8", shell: true })
      : spawnSync("which", [name], { encoding: "utf8", shell: true });
  return probe.status === 0;
}

function run(cmd, args) {
  return spawnSync(cmd, args, { encoding: "utf8", shell: false });
}

const lines = [];
const ts = new Date().toISOString();
lines.push(`PHASE5_PROVISION_CHECKLIST ${ts}`);

const tools = ["kubectl", "docker", "helm", "aws", "psql", "kind", "minikube", "k3d"];
const toolState = {};
for (const t of tools) {
  toolState[t] = hasCmd(t);
  lines.push(`tool_${t}=${toolState[t] ? "PRESENT" : "MISSING"}`);
}

let clusterOk = false;
let scOk = false;
if (toolState.kubectl) {
  const ci = run("kubectl", ["cluster-info"]);
  clusterOk = ci.status === 0;
  lines.push(`k8s_cluster=${clusterOk ? "REACHABLE" : "UNREACHABLE"}`);
  if (clusterOk) {
    const nodes = run("kubectl", ["get", "nodes", "-o", "name"]);
    lines.push(`nodes=${(nodes.stdout || "").trim().split("\n").filter(Boolean).length}`);
    const sc = run("kubectl", ["get", "storageclass", "-o", "jsonpath={.items[*].metadata.name}"]);
    const classes = (sc.stdout || "").trim();
    lines.push(`storageclasses=${classes || "NONE"}`);
    scOk = classes.length > 0;
    const csi = run("kubectl", ["get", "csidrivers", "-o", "name"]);
    lines.push(`csidrivers=${(csi.stdout || "").trim().replace(/\n/g, ",") || "NONE"}`);
  }
} else {
  lines.push("k8s_cluster=UNAVAILABLE");
  lines.push("storageclasses=UNAVAILABLE");
  lines.push("csidrivers=UNAVAILABLE");
}

const cloudCreds =
  !!(process.env.AWS_ACCESS_KEY_ID || process.env.AWS_PROFILE || process.env.KUBECONFIG);
lines.push(`cloud_or_kubeconfig_hint=${cloudCreds}`);

const phase5Pass = toolState.kubectl && clusterOk && scOk;
lines.push(`phase5_provision_ready=${phase5Pass}`);
lines.push(
  phase5Pass
    ? "NOTE=operator tools + cluster + StorageClass OK — proceed to deploy Phase 3 topology"
    : "NOTE=PHASE 5 BLOCKED until kubectl + reachable cluster + StorageClass are available"
);

const out = path.join(evidenceDir, `provision-checklist-${ts.slice(0, 10)}.txt`);
fs.writeFileSync(out, lines.join("\n") + "\n");
console.log(lines.join("\n"));
console.log(`evidence=${out}`);
process.exit(phase5Pass ? 0 : 2);
