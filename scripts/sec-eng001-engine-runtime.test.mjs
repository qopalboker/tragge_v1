/**
 * ENG-001 — independent Trading Engine runtime + Platform contracts.
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

function goTest(cwd, args) {
  const result = spawnSync("go", ["test", "-count=1", "-p=1", ...args], {
    cwd,
    encoding: "utf8",
    env: goEnv,
  });
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  assert.equal(result.status, 0, output);
}

test("ENG-001 independent image and entrypoint exist", () => {
  assert.ok(fs.existsSync(path.join(root, "apps/trading-engine/Dockerfile")));
  assert.ok(fs.existsSync(path.join(root, "apps/trading-engine/cmd/trading-engine/main.go")));
  assert.ok(
    fs.existsSync(path.join(root, "infra/docker/docker-compose.engine-standalone.yml")),
  );
  assert.match(read("apps/trading-engine/Dockerfile"), /POSTGRES_USER=engine/);
  assert.doesNotMatch(read("apps/trading-engine/Dockerfile"), /FINNHUB|NOBITEX|DERIV|JWT_SECRET/);
});

test("ENG-001 runtime boundary forbids provider and JWT secrets", () => {
  const src = read("apps/trading-engine/server/runtime_boundary.go");
  assert.match(src, /ValidateIndependentRuntime/);
  assert.match(src, /ForbiddenProviderEnv/);
  assert.match(src, /ForbiddenPlatformAuthEnv/);
  assert.match(read("apps/trading-engine/server/app.go"), /ValidateIndependentRuntime/);
});

test("ENG-001 engine does not import packages/auth", () => {
  assert.doesNotMatch(read("apps/trading-engine/go.mod"), /packages\/auth/);
});

test("ENG-001 platform-engine contracts exist", () => {
  assert.match(
    read("packages/contracts/engine/v1/commands.go"),
    /ContestConfigurationCommand/,
  );
  assert.match(read("packages/contracts/engine/v1/commands.go"), /ParticipantActivationCommand/);
  assert.match(read("packages/contracts/engine/v1/commands.go"), /OrderCommand/);
  assert.match(read("packages/contracts/engine/v1/commands.go"), /FreezeTradingCommand/);
  assert.match(read("packages/contracts/engine/v1/commands.go"), /CloseContestCommand/);
  assert.match(read("packages/contracts/engine/v1/events.go"), /EngineSnapshotEvent/);
  assert.match(read("packages/contracts/engine/v1/events.go"), /ContestResultEvent/);
  assert.doesNotMatch(
    read("packages/contracts/engine/v1/commands.go"),
    /json:"commission_rate"/,
  );
  assert.doesNotMatch(
    read("packages/contracts/engine/v1/commands.go"),
    /json:"max_participants"/,
  );
  assert.doesNotMatch(
    read("packages/contracts/engine/v1/testdata/contest_configuration.v1.json"),
    /commission_rate|max_participants|participant_capacity/,
  );
});

test("ENG-001 go tests", () => {
  goTest(path.join(root, "packages/contracts"), ["./engine/..."]);
  goTest(path.join(root, "apps/trading-engine"), [
    "./server",
    "-run",
    "TestValidateIndependentRuntime|TestUsesPlatformDBGrants|TestEngineSchemaOwnerBoundary",
  ]);
});
