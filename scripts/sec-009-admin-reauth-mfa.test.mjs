/**
 * SEC-009 — Independently verify + regression-lock:
 *  1. Sensitive admin action without fresh reauth grant is rejected
 *  2. Super Admin action without MFA is rejected when MFA policy is ON
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

function goTest(runPattern) {
  const result = spawnSync(
    "go",
    ["test", "-count=1", `-run=${runPattern}`, "."],
    {
      cwd: path.join(root, "packages/auth"),
      encoding: "utf8",
      env: {
        ...process.env,
        GOCACHE: process.env.GOCACHE || path.join(root, ".go-cache"),
      },
    },
  );
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  if (result.status !== 0) {
    throw new Error(`go test failed (${runPattern}):\n${output}`);
  }
  return output;
}

test("SEC-009 source: reauth middleware rejects missing grant", () => {
  const reauth = read("apps/admin-bff/server/reauthentication.go");
  assert.match(reauth, /grant_missing/);
  assert.match(reauth, /requireSensitiveAction/);
  assert.match(reauth, /X-Admin-Reauth-Grant/);
  assert.match(reauth, /sensitive action denied/);
});

test("SEC-009 source: Super Admin MFA is policy-gated at login and middleware", () => {
  const helpers = read("apps/admin-bff/server/handlers_helpers.go");
  assert.match(helpers, /isAdminMFAEnabled/);
  assert.match(helpers, /MFARequired:\s*true/);
  assert.match(helpers, /admin_mfa_enabled setting is true/);

  const app = read("apps/admin-bff/server/app.go");
  assert.match(app, /SetSuperAdminMFAPolicy/);
  assert.match(app, /isAdminMFAEnabled/);

  const middleware = read("packages/auth/middleware.go");
  assert.match(middleware, /SuperAdminMFAAllowed/);
  assert.match(middleware, /SetSuperAdminMFAPolicy/);
});

test("SEC-009 Go: missing reauth grant rejected", () => {
  assert.match(goTest("^TestSEC009ReauthenticationMissingGrantRejected$"), /ok\s+/);
});

test("SEC-009 Go: Super Admin without MFA rejected when policy ON", () => {
  assert.match(
    goTest("^TestSEC009SuperAdminMFAPolicyGating$|^TestSEC009SuperAdminActionWithoutMFARejectedWhenPolicyOn$"),
    /ok\s+/,
  );
});
