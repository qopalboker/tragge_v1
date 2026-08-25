/**
 * CI-004 — continuous secret scanning wiring + fixture catch.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

test("CI-004 workflow includes gitleaks job", () => {
  const ci = fs.readFileSync(path.join(root, ".github/workflows/ci.yml"), "utf8");
  assert.match(ci, /ci-004-secret-scanning:/);
  assert.match(ci, /gitleaks\/gitleaks-action@v2/);
});

test("CI-004 deliberately planted fixture secret is detected when gitleaks is available", (t) => {
  // Permanent guarantee is gitleaks-action on the PR. Local/CI fixture catch is best-effort.
  if (process.env.CI === "true" && process.env.CI004_REQUIRE_LOCAL_GITLEAKS !== "1") {
    t.skip("CI relies on gitleaks-action step; local binary fixture optional");
    return;
  }
  const which = spawnSync(process.platform === "win32" ? "where" : "which", ["gitleaks"], {
    encoding: "utf8",
  });
  if (which.status !== 0) {
    t.skip("gitleaks binary not installed locally");
    return;
  }
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ci004-secret-"));
  const fixture = path.join(dir, "planted.env");
  // Classic AWS-looking fixture used by gitleaks rules (not a real key).
  fs.writeFileSync(
    fixture,
    "AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE\nAWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY\n",
  );
  const result = spawnSync("gitleaks", ["detect", "--no-git", "-s", dir, "-v"], {
    encoding: "utf8",
  });
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  // gitleaks exits 1 when leaks found
  assert.notEqual(result.status, 0, `expected detection failure, output=${output}`);
  assert.match(output, /AKIAIOSFODNN7EXAMPLE|aws|leak|secret/i);
});
