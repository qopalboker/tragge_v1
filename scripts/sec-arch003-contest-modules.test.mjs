/**
 * ARCH-003 — contest / scheduler / leaderboard / notification / ticket into Platform.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("ARCH-003 scheduler owns free-practice generation", () => {
  const src = read("apps/platform/internal/modules/scheduler/module.go");
  assert.match(src, /OwnsContestGeneration/);
  assert.match(read("apps/platform/internal/modules/scheduler/jobs.go"), /free_practice|FreePractice/);
});

test("ARCH-003 worker skips standalone free generator by default", () => {
  const worker = read("apps/worker/main.go");
  assert.match(worker, /PLATFORM_ALLOW_STANDALONE_FREE_GENERATOR/);
  assert.match(worker, /skipping free-contest-generator/);
  assert.match(
    read("apps/free-contest-generator/server/app.go"),
    /Platform scheduler owns generation/,
  );
});

test("ARCH-003 leaderboard has no settlement authority", () => {
  const lb = read("apps/platform/internal/modules/leaderboard/module.go");
  assert.match(lb, /HasSettlementAuthority/);
  assert.match(lb, /ErrNoSettlementAuthority/);
  const fin = read("apps/leaderboard-worker/server/finalize.go");
  assert.match(fin, /must not claim wallet-credit authority/);
  assert.doesNotMatch(
    fin.slice(fin.indexOf("func (a *App) markRanksAndWalletsCredited")),
    /wallets_credited = TRUE/,
  );
});

test("ARCH-003 notification/ticket use outbox port", () => {
  assert.match(
    read("apps/platform/internal/modules/notification/module.go"),
    /EnqueueOutbox/,
  );
  assert.match(
    read("apps/platform/internal/modules/ticket/module.go"),
    /EnqueueOutbox/,
  );
});

test("ARCH-003 platform tests", () => {
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
