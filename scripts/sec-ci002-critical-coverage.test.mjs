/**
 * CI-002 — none of the original 7 critical Go services remains at zero coverage.
 *
 * Services (historical zero-test set from production roadmap):
 * admin-bff, api-server, contest-scheduler, free-contest-generator,
 * settlement-service, trading-core, worker.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const SERVICES = [
  { name: "admin-bff", dir: "apps/admin-bff", packages: ["./server"] },
  { name: "api-server", dir: "apps/api-server", packages: ["."] },
  { name: "contest-scheduler", dir: "apps/contest-scheduler", packages: ["./internal/scheduler"] },
  { name: "free-contest-generator", dir: "apps/free-contest-generator", packages: ["./server"] },
  { name: "settlement-service", dir: "apps/settlement-service", packages: ["./server"] },
  { name: "trading-core", dir: "apps/trading-core", packages: ["."] },
  { name: "worker", dir: "apps/worker", packages: ["."] },
];

function hasTestFiles(absDir) {
  const stack = [absDir];
  while (stack.length) {
    const cur = stack.pop();
    for (const ent of fs.readdirSync(cur, { withFileTypes: true })) {
      if (ent.name === "vendor" || ent.name === "node_modules") continue;
      const p = path.join(cur, ent.name);
      if (ent.isDirectory()) stack.push(p);
      else if (ent.name.endsWith("_test.go")) return true;
    }
  }
  return false;
}

function runCover(service) {
  const cwd = path.join(root, service.dir);
  const env = {
    ...process.env,
    GOCACHE: process.env.GOCACHE || path.join(root, ".go-cache"),
    GOFLAGS: "-vet=off",
  };
  const args = ["test", "-count=1", "-short", "-cover", ...service.packages];
  const result = spawnSync("go", args, { cwd, encoding: "utf8", env, timeout: 600000 });
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  let maxPct = 0;
  let saw = false;
  for (const m of output.matchAll(/coverage:\s+([0-9.]+)%/g)) {
    saw = true;
    maxPct = Math.max(maxPct, Number(m[1]));
  }
  return { status: result.status, output, maxPct, saw };
}

test("CI-002 each critical service has at least one *_test.go", () => {
  const missing = [];
  for (const s of SERVICES) {
    if (!hasTestFiles(path.join(root, s.dir))) missing.push(s.name);
  }
  assert.deepEqual(missing, [], `still zero test files: ${missing.join(", ")}`);
});

test("CI-002 go test -cover is >0% for each critical service", () => {
  const failures = [];
  const report = [];
  for (const s of SERVICES) {
    const { status, output, maxPct, saw } = runCover(s);
    report.push({ name: s.name, maxPct, status, saw });
    if (status !== 0) {
      failures.push(`${s.name}: go test failed\n${output}`);
      continue;
    }
    if (!saw || maxPct <= 0) {
      failures.push(`${s.name}: coverage not >0 (got ${maxPct})\n${output}`);
    }
  }
  console.log("CI-002 coverage summary:", JSON.stringify(report, null, 2));
  // Persist a machine-readable report for CI artifacts / trending.
  const outDir = path.join(root, "docs/codex/reports");
  fs.mkdirSync(outDir, { recursive: true });
  fs.writeFileSync(
    path.join(outDir, "CI-002-coverage-summary.json"),
    JSON.stringify({ generated_at: new Date().toISOString(), services: report }, null, 2) + "\n",
  );
  assert.equal(failures.length, 0, failures.join("\n\n"));
});
