/**
 * ARCH-008 — standalone service fate inventory (no unsafe deletes).
 */
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

const services = [
  "trading-engine",
  "market-ingestor",
  "user-bff",
  "admin-bff",
  "payment-service",
  "trade-bff",
  "leaderboard-worker",
  "settlement-service",
  "contest-scheduler",
  "free-contest-generator",
  "shard-router",
];

test("ARCH-008 report and decision log exist", () => {
  const report = read("docs/codex/reports/ARCH-008-standalone-fate.md");
  assert.match(report, /SAFE_TO_DELETE/);
  assert.match(report, /none this PR|Zero services qualify|Not SAFE_TO_DELETE/i);
  assert.match(report, /MD001-KAFKA-V2-CUTOVER/);
  assert.match(report, /MD001-FRONTEND-CUTOVER/);
  assert.match(report, /ARCH007-WRAPPER-DELETE/);
  assert.match(report, /ARCH007-TARGET-COMPOSE-E2E/);
  assert.ok(fs.existsSync(path.join(root, "docs/codex/decisions/ARCH-008-decision-log.md")));
});

test("ARCH-008 every listed service has FATE.md and is not SAFE_TO_DELETE", () => {
  for (const name of services) {
    const fatePath = `apps/${name}/FATE.md`;
    assert.ok(fs.existsSync(path.join(root, fatePath)), fatePath);
    const fate = read(fatePath);
    assert.doesNotMatch(fate, /\*\*Fate:\*\*\s*`SAFE_TO_DELETE`/);
    assert.match(fate, /\*\*Fate:\*\*\s*`(KEEP|REPLACE|DELETE_AFTER_CUTOVER)`/);
    assert.match(fate, /Not SAFE_TO_DELETE/);
  }
});

test("ARCH-008 wrapper callers still exist (blocks deletion)", () => {
  assert.match(read("apps/api-server/main.go"), /apps\/user-bff\/server/);
  assert.match(read("apps/api-server/main.go"), /apps\/admin-bff\/server/);
  assert.match(read("apps/api-server/main.go"), /apps\/payment-service\/server/);
  assert.match(read("apps/trading-core/main.go"), /apps\/trade-bff\/server/);
  assert.match(read("apps/trading-core/main.go"), /apps\/trading-engine\/server/);
  assert.match(read("apps/trading-core/main.go"), /apps\/market-ingestor\/server/);
  assert.match(read("apps/worker/main.go"), /apps\/leaderboard-worker\/server/);
  assert.match(read("apps/worker/main.go"), /apps\/settlement-service\/server/);
  assert.match(read("apps/worker/main.go"), /apps\/contest-scheduler\/server/);
  assert.match(read("apps/worker/main.go"), /apps\/free-contest-generator\/server/);
});

test("ARCH-008 KEEP targets retain standalone images", () => {
  assert.ok(fs.existsSync(path.join(root, "apps/trading-engine/Dockerfile")));
  assert.ok(fs.existsSync(path.join(root, "apps/market-ingestor/Dockerfile")));
});

test("ARCH-008 required open gaps remain tracked", () => {
  const issues = read("docs/codex/reports/discovered-issues.md");
  for (const id of [
    "MD001-KAFKA-V2-CUTOVER",
    "MD001-FRONTEND-CUTOVER",
    "ARCH007-WRAPPER-DELETE",
    "ARCH007-TARGET-COMPOSE-E2E",
    "ARCH008-NO-SAFE-DELETE",
  ]) {
    assert.match(issues, new RegExp(id));
  }
});

test("ARCH-008 does not remove service source trees", () => {
  for (const name of services) {
    assert.ok(fs.existsSync(path.join(root, "apps", name)), `apps/${name} must remain`);
  }
});
