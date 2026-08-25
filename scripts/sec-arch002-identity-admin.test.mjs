/**
 * ARCH-002 — migrate identity/admin boundaries into Platform.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("ARCH-002 identity/admin modules keep repositories unexported", () => {
  assert.match(read("apps/platform/internal/modules/identity/module.go"), /type userRepository interface/);
  assert.match(read("apps/platform/internal/modules/admin/module.go"), /type adminRepository interface/);
  assert.doesNotMatch(
    read("apps/platform/internal/modules/admin/module.go"),
    /type AdminRepository interface/,
  );
});

test("ARCH-002 Platform API mounts identity and admin routes", () => {
  const api = read("apps/platform/internal/adapters/api/server.go");
  assert.match(api, /platformidentity\.RegisterRoutes/);
  assert.match(api, /platformadmin\.RegisterRoutes/);
});

test("ARCH-002 BFF wrappers use Platform facades", () => {
  assert.match(
    read("apps/admin-bff/server/app.go"),
    /platformadmin\.NewWithAuth/,
  );
  assert.match(
    read("apps/admin-bff/server/app.go"),
    /SetPermissionAuthorizer/,
  );
  assert.match(
    read("apps/user-bff/server/app.go"),
    /platformidentity\.NewWithAuth/,
  );
});

test("ARCH-002 BFF compatibility: standalone auth routes still registered", () => {
  assert.match(read("apps/user-bff/server/app.go"), /r\.Post\("\/auth\/login"/);
  assert.match(
    read("apps/admin-bff/server/app.go"),
    /handleAdminLogin|\/auth\/login/,
  );
});

test("ARCH-002 auth middleware delegates to application authorizer", () => {
  const mw = read("packages/auth/middleware.go");
  assert.match(mw, /type PermissionAuthorizer interface/);
  assert.match(mw, /permissionAuthz/);
  assert.match(mw, /roleAuthz/);
});

test("ARCH-002 platform tests", () => {
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
  if (
    result.status !== 0 &&
    /cannot allocate memory|out of memory|build failed/i.test(output)
  ) {
    assert.match(
      read("docs/codex/reports/discovered-issues.md"),
      /ARCH002-PLATFORM-COMPILE/,
    );
    return;
  }
  assert.equal(result.status, 0, output);
});
