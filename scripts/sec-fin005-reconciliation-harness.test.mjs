/**
 * FIN-005 — financial reconciliation harness + Power Law off production path.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

function walk(dir, out = []) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    if (ent.name === "vendor" || ent.name === "node_modules") continue;
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(p, out);
    else if (ent.name.endsWith(".go") && !ent.name.endsWith("_test.go")) out.push(p);
  }
  return out;
}

test("FIN-005 apps production Go must not call Power Law payout helpers", () => {
  const files = walk(path.join(root, "apps"));
  const offenders = [];
  const banned = [
    /CalculatePrizeDistributionPowerLaw\s*\(/,
    /GetWinnersCountPowerLaw\s*\(/,
  ];
  for (const file of files) {
    const text = fs.readFileSync(file, "utf8");
    for (const re of banned) {
      if (re.test(text)) offenders.push(path.relative(root, file).replaceAll("\\", "/"));
    }
  }
  assert.deepEqual(offenders, [], `Power Law leaked into production apps: ${offenders.join(", ")}`);
});

test("FIN-005 settlement/leaderboard use CalculateForContest", () => {
  const settlement = fs.readFileSync(
    path.join(root, "apps/settlement-service/server/settlement.go"),
    "utf8",
  );
  const payout = fs.readFileSync(
    path.join(root, "apps/leaderboard-worker/server/payout.go"),
    "utf8",
  );
  assert.match(settlement, /CalculateForContest/);
  assert.match(payout, /CalculateForContest/);
  assert.doesNotMatch(settlement, /CalculatePrizeDistributionPowerLaw/);
  assert.doesNotMatch(payout, /CalculatePrizeDistributionPowerLaw/);
});

test("FIN-005 reconciliation harness passes", () => {
  const result = spawnSync(
    "go",
    ["test", "-count=1", "-run=^TestFIN005", "."],
    {
      cwd: path.join(root, "packages/scoring/economics"),
      encoding: "utf8",
      env: {
        ...process.env,
        GOCACHE: process.env.GOCACHE || path.join(root, ".go-cache"),
        GOFLAGS: "-vet=off",
      },
    },
  );
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  assert.equal(result.status, 0, output);
  assert.match(output, /ok\s+/);
});
