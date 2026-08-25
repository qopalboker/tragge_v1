/**
 * FIN-003 — Settlement is the sole contest finalization owner.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("FIN-003 leaderboard finalize must not Complete or refund via wallet", () => {
  const src = read("apps/leaderboard-worker/server/finalize.go");
  assert.match(src, /FIN-003/);
  assert.doesNotMatch(src, /stateMachine\.Complete\s*\(/);
  assert.doesNotMatch(src, /RefundContestEntryFee/);
  assert.doesNotMatch(src, /CreditPrize/);
  assert.doesNotMatch(src, /func \(a \*App\) recordSettlement/);
  assert.match(src, /sole status owner|owned by settlement|sole writer/i);
});

test("FIN-003 settlement owns advisory lock + single-participant refund", () => {
  const src = read("apps/settlement-service/server/settlement.go");
  assert.match(src, /pg_try_advisory_lock/);
  assert.match(src, /refundSingleParticipant/);
  assert.match(src, /RefundContestEntryFeeIdempotent/);
  assert.match(src, /Settlement already completed, skipping/);
});

test("FIN-003 concurrent prize idempotency test passes", () => {
  const result = spawnSync(
    "go",
    [
      "test",
      "-count=1",
      "-run=^TestFIN003ConcurrentPrizeCreditIdempotencyKeys$|^TestFIN003RefundIdempotencyKeysStable$",
      ".",
    ],
    {
      cwd: path.join(root, "packages/wallet"),
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
