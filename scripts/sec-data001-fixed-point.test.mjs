/**
 * DATA-001 — canonical fixed-point money/price/rate/score primitives.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

const goEnv = {
  ...process.env,
  GOCACHE: process.env.GOCACHE || path.join(root, ".go-cache"),
  GOFLAGS: "-vet=off",
  GOMAXPROCS: "1",
};

test("DATA-001 money package defines distinct primitives", () => {
  assert.match(read("packages/money/money.go"), /type Money int64/);
  assert.match(read("packages/money/bps.go"), /CanonicalPlatformFeeBPS/);
  assert.match(read("packages/money/fixed.go"), /type Price Fixed/);
  assert.match(read("packages/money/fixed.go"), /type Score Fixed/);
  assert.match(read("packages/money/fixed.go"), /DefaultPriceScale = 8/);
  assert.match(read("packages/money/fixed.go"), /DefaultScoreScale = 6/);
  assert.match(read("packages/money/rational.go"), /type Rational struct/);
  assert.match(read("go.work"), /packages\/money/);
});

test("DATA-001 money package has no float64 financial API", () => {
  const files = fs
    .readdirSync(path.join(root, "packages/money"))
    .filter((n) => n.endsWith(".go") && !n.endsWith("_test.go"));
  for (const name of files) {
    const src = read(path.join("packages/money", name));
    assert.doesNotMatch(src, /\bfloat64\b/, `${name} must not use float64`);
  }
});

test("DATA-001 go tests", () => {
  const result = spawnSync("go", ["test", "-count=1", "-p=1", "./..."], {
    cwd: path.join(root, "packages/money"),
    encoding: "utf8",
    env: goEnv,
  });
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  assert.equal(result.status, 0, output);
});

test("DATA-001 target financial policy migration exists", () => {
  assert.match(
    read("packages/db/migrations/target/0005_shared_financial_type_policy.up.sql"),
    /fixed-point|minor units|scale default/,
  );
});
