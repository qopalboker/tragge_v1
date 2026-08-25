/**
 * INFRA-002 — desired-state K8s base/overlay parity + drift gate.
 *
 * Validates that overlays only patch resources present in base, and that
 * `kubectl kustomize` builds succeed. Does NOT claim live-cluster parity.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const k8s = path.join(root, "infra", "k8s");

const ALLOWED_WORKLOADS = new Set([
  "api-server",
  "trading-core",
  "worker",
  "frontend",
  "gateway",
  "postgres",
  "redis",
  "redpanda",
  "pgbouncer",
]);

const OBSOLETE_STANDALONES = [
  "user-bff",
  "admin-bff",
  "trade-bff",
  "trading-engine",
  "market-ingestor",
  "leaderboard-worker",
  "payment-service",
  "settlement-service",
  "free-contest-generator",
];

function read(rel) {
  return fs.readFileSync(path.join(root, rel), "utf8");
}

function kubectlKustomize(relDir) {
  const result = spawnSync("kubectl", ["kustomize", path.join(root, relDir)], {
    encoding: "utf8",
    maxBuffer: 20 * 1024 * 1024,
  });
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  // Warnings on stderr are ok; only hard failures fail the gate.
  if (result.status !== 0) {
    return { ok: false, output };
  }
  return { ok: true, output: result.stdout || "" };
}

function collectPatchTargets(dir) {
  const targets = [];
  if (!fs.existsSync(dir)) return targets;
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      targets.push(...collectPatchTargets(full));
      continue;
    }
    if (!entry.name.endsWith(".yaml") && !entry.name.endsWith(".yml")) continue;
    const lines = fs.readFileSync(full, "utf8").split(/\r?\n/);
    let inTarget = false;
    let kind = null;
    let name = null;
    for (const line of lines) {
      if (/^\s*target:\s*$/.test(line)) {
        if (kind && name) {
          targets.push({ kind, name, file: path.relative(root, full) });
        }
        inTarget = true;
        kind = null;
        name = null;
        continue;
      }
      if (!inTarget) continue;
      if (/^\S/.test(line)) {
        // left the indented target block
        if (kind && name) {
          targets.push({ kind, name, file: path.relative(root, full) });
        }
        inTarget = false;
        kind = null;
        name = null;
        continue;
      }
      const kindMatch = line.match(/^\s+kind:\s*(\S+)\s*$/);
      if (kindMatch) kind = kindMatch[1];
      const nameMatch = line.match(/^\s+name:\s*(\S+)\s*$/);
      if (nameMatch) name = nameMatch[1];
    }
    if (inTarget && kind && name) {
      targets.push({ kind, name, file: path.relative(root, full) });
    }
  }
  return targets;
}

function parseWorkloadNames(manifestText) {
  const names = new Set();
  const docs = manifestText.split(/^---$/m);
  for (const doc of docs) {
    if (!/kind:\s*(Deployment|StatefulSet)\b/.test(doc)) continue;
    const meta = doc.match(/metadata:\s*\n(?:  .*\n)*?  name:\s*(\S+)/);
    if (meta) names.add(meta[1]);
  }
  return names;
}

test("INFRA-002 base kustomize build succeeds", () => {
  const { ok, output } = kubectlKustomize("infra/k8s/base");
  assert.ok(ok, output);
  assert.doesNotMatch(output, /found a tab character/);
});

test("INFRA-002 production overlay kustomize build succeeds", () => {
  const { ok, output } = kubectlKustomize("infra/k8s/overlays/production");
  assert.ok(ok, output);
});

test("INFRA-002 staging overlay kustomize build succeeds", () => {
  const { ok, output } = kubectlKustomize("infra/k8s/overlays/staging");
  assert.ok(ok, output);
});

test("INFRA-002 production workloads are consolidated base names only", () => {
  const { ok, output } = kubectlKustomize("infra/k8s/overlays/production");
  assert.ok(ok, output);
  const names = parseWorkloadNames(output);
  for (const obsolete of OBSOLETE_STANDALONES) {
    assert.ok(!names.has(obsolete), `obsolete Deployment/StatefulSet still present: ${obsolete}`);
  }
  for (const required of ["api-server", "trading-core", "worker", "frontend", "gateway"]) {
    assert.ok(names.has(required), `missing required workload: ${required}`);
  }
});

test("INFRA-002 overlay patch targets resolve to base-allowed names", () => {
  const { ok, output } = kubectlKustomize("infra/k8s/base");
  assert.ok(ok, output);
  const baseNames = parseWorkloadNames(output);
  // Also allow HPAs / Ingress / ConfigMaps that exist in base by name scan
  const allBaseNames = new Set(baseNames);
  for (const m of output.matchAll(/^\s+name:\s*(\S+)\s*$/gm)) {
    allBaseNames.add(m[1]);
  }

  for (const overlay of ["production", "staging"]) {
    const targets = collectPatchTargets(
      path.join(k8s, "overlays", overlay),
    );
    for (const t of targets) {
      if (["Deployment", "StatefulSet"].includes(t.kind)) {
        assert.ok(
          ALLOWED_WORKLOADS.has(t.name),
          `${overlay} patches unknown workload ${t.kind}/${t.name} in ${t.file}`,
        );
        assert.ok(
          baseNames.has(t.name),
          `${overlay} patch target missing from base build: ${t.kind}/${t.name} (${t.file})`,
        );
      }
      if (t.kind === "HorizontalPodAutoscaler") {
        assert.doesNotMatch(
          t.name,
          /^(user-bff|trade-bff|admin-bff|trading-engine|market-ingestor|leaderboard-worker|payment-service)-hpa$/,
        );
      }
    }
  }
});

test("INFRA-002 image tags reference consolidated images", () => {
  const prod = read("infra/k8s/overlays/production/kustomization.yaml");
  const staging = read("infra/k8s/overlays/staging/kustomization.yaml");
  for (const text of [prod, staging]) {
    assert.match(text, /tragge\/api-server/);
    assert.match(text, /tragge\/trading-core/);
    assert.match(text, /tragge\/worker/);
    assert.doesNotMatch(text, /tragge\/user-bff/);
    assert.doesNotMatch(text, /tragge\/trade-bff/);
    assert.doesNotMatch(text, /tragge\/market-ingestor/);
  }
});

test("INFRA-002 docs declare desired-state only (not live cluster)", () => {
  const report = read("docs/codex/reports/INFRA-002-k8s-parity.md");
  assert.match(report, /desired-state/i);
  assert.match(report, /live-cluster parity|no production cluster|Not\*\* a production deploy/i);
  assert.match(report, /INFRA002-POSTGRES-HA-OVERLAY/);
});
