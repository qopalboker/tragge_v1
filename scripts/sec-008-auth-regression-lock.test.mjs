/**
 * SEC-008 — Regression lock for three auth fixes:
 *  1. ?token= URL authentication rejected
 *  2. User/Admin session isolation
 *  3. OTP values never appear in logs
 *
 * Behavioral truth lives in Go tests (packages/auth, packages/sms).
 * This suite asserts those tests exist and remain wired, then runs them.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

function goTest(pkgDir, runPattern) {
  const result = spawnSync(
    "go",
    ["test", "-count=1", `-run=${runPattern}`, "."],
    {
      cwd: path.join(root, pkgDir),
      encoding: "utf8",
      env: {
        ...process.env,
        GOCACHE: process.env.GOCACHE || path.join(root, ".go-cache"),
      },
    },
  );
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  if (result.status !== 0) {
    throw new Error(`go test failed in ${pkgDir} (${runPattern}):\n${output}`);
  }
  return output;
}

test("SEC-008 source locks: query-token reject + isolation + OTP no-log", () => {
  const middleware = read("packages/auth/middleware.go");
  assert.match(middleware, /HasProhibitedCredentialQuery/);
  assert.match(middleware, /"token"/);
  assert.match(middleware, /url_authentication_unsupported/);

  const mock = read("packages/sms/mock.go");
  assert.match(mock, /never logs message/);
  assert.doesNotMatch(mock, /log\.(Print|Fatal|Panic)/);
  assert.doesNotMatch(mock, /zap\./);

  const app = read("apps/user-bff/server/app.go");
  assert.match(app, /KaveNegar only; no mock\/logging fallback/);
  assert.doesNotMatch(app, /sms\.NewFake\s*\(/);
  assert.doesNotMatch(app, /sms\.NewMock\s*\(/);
});

test("SEC-008 Go regression: ?token= rejected", () => {
  const out = goTest(
    "packages/auth",
    "^TestSEC008RejectsTokenQueryAuthentication$",
  );
  assert.match(out, /ok\s+/);
});

test("SEC-008 Go regression: User/Admin isolation", () => {
  const out = goTest(
    "packages/auth",
    "^TestSEC008UserAdminSessionIsolation$",
  );
  assert.match(out, /ok\s+/);
});

test("SEC-008 Go regression: OTP never logged", () => {
  const out = goTest(
    "packages/sms",
    "^TestSEC008FakeProviderNeverLogsOTP$|^TestSEC008SMSSourcesDoNotLogOTPCodes$",
  );
  assert.match(out, /ok\s+/);
});
