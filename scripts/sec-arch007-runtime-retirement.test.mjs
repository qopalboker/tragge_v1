/**
 * ARCH-007 — runtime retirement boundary (no hard-delete of live wrappers).
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("ARCH-007 fate matrix and retirement docs exist", () => {
  const report = read("docs/codex/reports/ARCH-007-runtime-retirement.md");
  assert.match(report, /DELETE_AFTER_CUTOVER/);
  assert.match(report, /apps\/trading-core/);
  assert.match(report, /apps\/api-server/);
  assert.match(report, /apps\/worker/);
  assert.match(report, /MD001-KAFKA-V2-CUTOVER/);
  assert.match(report, /MD001-FRONTEND-CUTOVER/);
  for (const rel of [
    "apps/api-server/RETIREMENT.md",
    "apps/trading-core/RETIREMENT.md",
    "apps/worker/RETIREMENT.md",
    "apps/contest-scheduler/RETIREMENT.md",
    "apps/free-contest-generator/RETIREMENT.md",
    "docs/codex/decisions/ARCH-007-decision-log.md",
  ]) {
    assert.ok(fs.existsSync(path.join(root, rel)), rel);
  }
});

test("ARCH-007 target compose defines Platform/Engine/Market Data only", () => {
  const target = read("infra/docker/docker-compose.target.yml");
  assert.match(target, /profiles:\s*\[["']target["']/);
  assert.match(target, /platform-api/);
  assert.match(target, /platform-realtime/);
  assert.match(target, /platform-worker/);
  assert.match(target, /trading-engine/);
  assert.match(target, /market-ingestor/);
  assert.doesNotMatch(target, /^\s+api-server:/m);
  assert.doesNotMatch(target, /^\s+trading-core:/m);
  assert.doesNotMatch(target, /^\s+worker:/m);
});

test("ARCH-007 legacy wrappers labeled and not deleted", () => {
  const compose = read("infra/docker/docker-compose.yml");
  assert.match(compose, /legacy-wrappers/);
  assert.match(compose, /api-server:/);
  assert.match(compose, /trading-core:/);
  assert.match(compose, /worker:/);
  assert.match(read("apps/api-server/main.go"), /DEPRECATED wrapper/);
  assert.match(read("apps/trading-core/main.go"), /DEPRECATED wrapper/);
  assert.match(read("apps/worker/main.go"), /DEPRECATED wrapper/);
  assert.ok(fs.existsSync(path.join(root, "apps/api-server/main.go")));
  assert.ok(fs.existsSync(path.join(root, "apps/trading-core/main.go")));
  assert.ok(fs.existsSync(path.join(root, "apps/worker/main.go")));
});

test("ARCH-007 Market Data standalone image exists", () => {
  assert.ok(fs.existsSync(path.join(root, "apps/market-ingestor/Dockerfile")));
  assert.ok(
    fs.existsSync(path.join(root, "apps/market-ingestor/cmd/market-ingestor/main.go")),
  );
  assert.match(read("apps/market-ingestor/Dockerfile"), /POSTGRES_USER=market_data/);
});

test("ARCH-007 compose config validates when docker is available", () => {
  const docker = spawnSync("docker", ["compose", "version"], { encoding: "utf8" });
  if (docker.status !== 0) {
    // Environment without docker: skip without failing the gate.
    return;
  }
  const result = spawnSync(
    "docker",
    [
      "compose",
      "-f",
      "infra/docker/docker-compose.yml",
      "-f",
      "infra/docker/docker-compose.target.yml",
      "--profile",
      "target",
      "config",
    ],
    { cwd: root, encoding: "utf8" },
  );
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  assert.equal(result.status, 0, output);
  assert.match(output, /platform-api/);
  assert.match(output, /trading-engine/);
  assert.match(output, /market-ingestor/);
});

test("ARCH-007 MD-001 cutover gaps remain explicitly tracked", () => {
  const issues = read("docs/codex/reports/discovered-issues.md");
  assert.match(issues, /MD001-KAFKA-V2-CUTOVER/);
  assert.match(issues, /MD001-FRONTEND-CUTOVER/);
  assert.match(issues, /Open — \*\*not runtime-verified\*\*/);
});
