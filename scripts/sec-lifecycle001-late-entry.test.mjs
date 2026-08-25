/**
 * LIFECYCLE-001 — paid late entry to running contests (policy §5.6).
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("LIFECYCLE-001 join policy lives in economics and is used by user-bff", () => {
  assert.match(read("packages/scoring/economics/join_policy.go"), /func JoinAllowed/);
  assert.match(
    read("apps/user-bff/server/contest_handlers.go"),
    /economics\.JoinAllowed/,
  );
  assert.match(
    read("apps/user-bff/server/contest_handlers.go"),
    /is_late_join|IsLateJoin/,
  );
});

test("LIFECYCLE-001 policy cutoff formula documented in economics", () => {
  const src = read("packages/scoring/economics/economics.go");
  assert.match(src, /LateJoinCutoff/);
  assert.match(src, /MaxLateJoinWindow/);
  assert.match(src, /0\.10/);
});

test("LIFECYCLE-001 join + charge tests pass", () => {
  const result = spawnSync(
    "go",
    [
      "test",
      "-count=1",
      "-run=^TestJoinAllowed$|^TestLIFECYCLE001|^TestLateJoinCutoff$|^TestComputeJoinCharge",
      ".",
    ],
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
