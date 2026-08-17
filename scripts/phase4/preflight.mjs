#!/usr/bin/env node
/**
 * Phase 4 live infrastructure pre-flight.
 * Records evidence only — does not invent PASS for missing systems.
 *
 * Exit 0 = pre-flight recorded (may still be NO-GO)
 * Exit 2 = critical tools missing for any live qualification
 */

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const evidenceDir = path.join(root, "docs/codex/reports/evidence/phase4");
fs.mkdirSync(evidenceDir, { recursive: true });

function hasCmd(name) {
  // Prefer `where`/`which` so Windows stubs don't look like real clusters.
  const probe =
    process.platform === "win32"
      ? spawnSync("where", [name], { encoding: "utf8", shell: true })
      : spawnSync("which", [name], { encoding: "utf8", shell: true });
  if (probe.status !== 0) return false;
  const r = spawnSync(name, ["version"], { encoding: "utf8", shell: true });
  // kubectl/docker respond to `version`; go/node to --version fallback
  if (r.status === 0) return true;
  const r2 = spawnSync(name, ["--version"], { encoding: "utf8", shell: true });
  return r2.status === 0;
}

function portOpen(port, host = "127.0.0.1", timeoutMs = 800) {
  return new Promise((resolve) => {
    const s = net.connect({ port, host });
    const t = setTimeout(() => {
      s.destroy();
      resolve(false);
    }, timeoutMs);
    s.on("connect", () => {
      clearTimeout(t);
      s.end();
      resolve(true);
    });
    s.on("error", () => {
      clearTimeout(t);
      resolve(false);
    });
  });
}

const lines = [];
const ts = new Date().toISOString();
lines.push(`PHASE4_PREFLIGHT ${ts}`);

const tools = {
  kubectl: hasCmd("kubectl"),
  docker: hasCmd("docker"),
  helm: hasCmd("helm"),
  aws: hasCmd("aws"),
  psql: hasCmd("psql"),
  pg_dump: hasCmd("pg_dump"),
  go: hasCmd("go"),
  node: hasCmd("node"),
};
for (const [k, v] of Object.entries(tools)) {
  lines.push(`${k}=${v ? "PRESENT" : "MISSING"}`);
}

const ports = {
  postgres: 5432,
  redis: 6379,
  kafka: 9092,
  gateway: 8080,
  user_bff: 8081,
  trade_bff: 8082,
  trading_engine: 8085,
  settlement: 8087,
};
for (const [name, port] of Object.entries(ports)) {
  // eslint-disable-next-line no-await-in-loop
  const open = await portOpen(port);
  lines.push(`port_${port}_${name}=${open}`);
}

// kubectl cluster (only if present)
if (tools.kubectl) {
  const kv = spawnSync("kubectl", ["cluster-info"], { encoding: "utf8", shell: true });
  lines.push(`k8s_cluster=${kv.status === 0 ? "REACHABLE" : "UNREACHABLE"}`);
  if (kv.status === 0) {
    const sc = spawnSync("kubectl", ["get", "storageclass", "-o", "name"], {
      encoding: "utf8",
      shell: true,
    });
    lines.push(`storageclasses=${(sc.stdout || "").trim().replace(/\n/g, ",") || "NONE"}`);
  }
} else {
  lines.push("k8s_cluster=UNAVAILABLE");
  lines.push("storageclasses=UNAVAILABLE");
  lines.push("csi=UNAVAILABLE");
}

const mode = (process.env.STAGING_PLATFORM || "").toLowerCase();
const composeMode = mode === "compose" || process.argv.includes("--mode=compose");

const liveReady =
  tools.kubectl &&
  (await portOpen(5432)) &&
  (await portOpen(6379));

// Compose local staging (Phase 5-Lite): not Kubernetes, explicit separate flag.
const composeReady =
  composeMode &&
  tools.docker &&
  (await portOpen(5432)) &&
  (await portOpen(6379)) &&
  (await portOpen(9092));

lines.push(`staging_platform=${composeMode ? "compose" : "kubernetes"}`);
lines.push(`live_qualification_possible=${liveReady}`);
lines.push(`live_compose_qualification_possible=${composeReady}`);
if (composeMode) {
  lines.push(
    composeReady
      ? "NOTE=Compose staging ready for Phase 5-Lite / local Phase 4.1-applicable tests (NOT Kubernetes PVC evidence)"
      : "NOTE=Compose mode requested but deps incomplete (need docker + postgres + redis + kafka ports)"
  );
} else {
  lines.push(
    liveReady
      ? "NOTE=cluster tools present — proceed with deploy/drill scripts"
      : "NOTE=live K8s/app stack unavailable — PRODUCTION NO-GO until staging cluster is provided"
  );
}

const outPath = path.join(evidenceDir, `preflight-${ts.slice(0, 10)}.txt`);
fs.writeFileSync(outPath, lines.join("\n") + "\n");
console.log(lines.join("\n"));
console.log(`evidence=${outPath}`);

if (!tools.kubectl || !tools.docker) {
  process.exit(2);
}
process.exit(0);
