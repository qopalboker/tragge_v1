/**
 * ARCH-005 — settlement sole finalization owner; leaderboard projection only.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("ARCH-005 settlement is sole finalization owner", () => {
  assert.match(
    read("apps/platform/internal/modules/settlement/module.go"),
    /IsSoleFinalizationOwner/,
  );
  assert.match(
    read("apps/platform/internal/modules/leaderboard/module.go"),
    /MayCompleteContest\(\) bool/,
  );
});

test("ARCH-005 leaderboard affiliate wallet credits disabled by default", () => {
  assert.match(
    read("apps/leaderboard-worker/server/app.go"),
    /ALLOW_LEADERBOARD_AFFILIATE_CREDITS/,
  );
  assert.match(
    read("apps/leaderboard-worker/server/app.go"),
    /Skipping affiliate commission job/,
  );
});

test("ARCH-005 leaderboard finalize does not Complete or credit wallets", () => {
  const fin = read("apps/leaderboard-worker/server/finalize.go");
  assert.match(fin, /projection only/);
  assert.doesNotMatch(fin, /stateMachine\.Complete\(/);
  assert.doesNotMatch(fin, /CreditPrize/);
});

test("ARCH-005 platform tests", () => {
  const result = spawnSync("go", ["test", "-count=1", "-p=1", "./..."], {
    cwd: path.join(root, "apps/platform"),
    encoding: "utf8",
    env: {
      ...process.env,
      GOCACHE: process.env.GOCACHE || path.join(root, ".go-cache"),
      GOFLAGS: "-vet=off",
      GOMAXPROCS: "1",
    },
  });
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  assert.equal(result.status, 0, output);
});
