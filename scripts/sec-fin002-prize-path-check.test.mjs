/**
 * FIN-002 — prize math consolidation onto economics + prizedistribution.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("FIN-002 settlement recalculation uses economics.CalculatePool", () => {
  const src = read("apps/settlement-service/server/settlement.go");
  assert.match(src, /economics\.CalculatePool/);
  assert.doesNotMatch(
    src,
    /prizePoolNet = \(prizePoolGross \* int64\(10000-platformFeeBps\)\) \/ 10000/,
  );
});

test("FIN-002 leaderboard net uses economics.NetFromGross", () => {
  const src = read("apps/leaderboard-worker/server/payout.go");
  assert.match(src, /economics\.NetFromGross/);
});

test("FIN-002 prize package delegates pool math to economics", () => {
  const src = read("packages/scoring/prize/distribution.go");
  assert.match(src, /CalculatePrizePoolFromBps/);
  assert.match(src, /economics\.CalculatePool/);
});

test("FIN-002 golden agreement test passes", () => {
  const result = spawnSync(
    "go",
    ["test", "-count=1", "-run=^TestFIN002PreviewLeaderboardSettlementAgreement$", "."],
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
