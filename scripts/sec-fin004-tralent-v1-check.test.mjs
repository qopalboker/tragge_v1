/**
 * FIN-004 — production prize distribution is policy tralent_v1.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("FIN-004 policy names tralent_v1 with decay 0.80", () => {
  const policy = read("docs/product/FIXED_PRODUCT_AND_TECHNICAL_POLICIES.md");
  assert.match(policy, /distribution_version:\s*tralent_v1/);
  assert.match(policy, /decay_factor:\s*0\.80/);
});

test("FIN-004 production callers use CalculateForContest", () => {
  assert.match(
    read("apps/settlement-service/server/settlement.go"),
    /CalculateForContest/,
  );
  assert.match(
    read("apps/leaderboard-worker/server/payout.go"),
    /CalculateForContest/,
  );
  assert.match(
    read("packages/scoring/economics/economics.go"),
    /CalculateForContest/,
  );
});

test("FIN-004 tralent_v1 + divergence tests pass", () => {
  const result = spawnSync(
    "go",
    ["test", "-count=1", "-run=^TestFIN004", "."],
    {
      cwd: path.join(root, "packages/scoring/distribution"),
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
