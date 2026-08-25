/**
 * FIN-001 — platform_fee_bps is the sole fee authority.
 * Locks resolver + migration + critical writer comments.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("FIN-001 migration backfills paid contests to 2000 bps and adds guard trigger", () => {
  const up = read(
    "packages/db/migrations/0109_fin001_platform_fee_bps_canonical.up.sql",
  );
  assert.match(up, /platform_fee_bps = 2000/);
  assert.match(up, /contests_enforce_platform_fee_bps/);
  assert.match(up, /trg_contests_enforce_platform_fee_bps/);
  assert.doesNotMatch(up, /commission_rate\s*\*\s*100/);
});

test("FIN-001 economics resolver ignores commission_rate", () => {
  const src = read("packages/scoring/economics/economics.go");
  assert.match(src, /func ResolvePlatformFeeBps\(platformFeeBps int, _ float64\)/);
  assert.match(src, /PlatformFeeBpsForPaidWrite/);
  assert.doesNotMatch(src, /commissionRatePercent\s*>\s*0/);
});

test("FIN-001 critical writers do not derive bps from commission_rate", () => {
  const calendar = read(
    "apps/contest-scheduler/internal/scheduler/calendar.go",
  );
  assert.doesNotMatch(calendar, /CommissionRate\s*\*\s*100/);
  assert.match(calendar, /FIN-001/);

  const admin = read("apps/admin-bff/server/handlers_contest.go");
  assert.doesNotMatch(admin, /CommissionRate\s*\*\s*100/);
  assert.match(admin, /FIN-001/);
});

test("FIN-001 Go conflict test passes", () => {
  const result = spawnSync(
    "go",
    [
      "test",
      "-count=1",
      "-run=^TestFIN001ConflictingLegacyFieldsDeterministic$|^TestPlatformFeeBpsForPaidWrite$|^TestResolvePlatformFeeBps$",
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
