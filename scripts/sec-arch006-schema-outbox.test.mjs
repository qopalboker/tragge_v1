/**
 * ARCH-006 — schema ownership + transactional outbox/inbox.
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

test("ARCH-006 target migrations create per-owner outbox/inbox", () => {
  for (const [file, schema] of [
    ["packages/db/migrations/target/0002_platform_outbox_inbox.up.sql", "platform"],
    ["packages/db/migrations/target/0003_engine_outbox_inbox.up.sql", "engine"],
    ["packages/db/migrations/target/0004_market_data_outbox_inbox.up.sql", "market_data"],
  ]) {
    const sql = read(file);
    assert.match(sql, new RegExp(`CREATE TABLE ${schema}\\.outbox`));
    assert.match(sql, new RegExp(`CREATE TABLE ${schema}\\.inbox`));
    assert.match(sql, new RegExp(`CREATE TABLE ${schema}\\.dead_letter`));
    assert.match(sql, new RegExp(`CREATE TABLE ${schema}\\.schema_migrations`));
  }
  const ownership = read("packages/db/migrations/target/0001_schema_ownership.up.sql");
  assert.doesNotMatch(ownership, /GRANT\s+USAGE\s+ON\s+SCHEMA\s+engine\s+TO\s+platform/i);
});

test("ARCH-006 envelope contract exists", () => {
  assert.match(read("packages/contracts/envelope/v1/envelope.go"), /SchemaVersion\s*=\s*1/);
  assert.ok(fs.existsSync(path.join(root, "packages/contracts/schemas/envelope.v1.json")));
});

test("ARCH-006 packages/db events store tests", () => {
  goTest(path.join(root, "packages/db"), ["./events/..."]);
});

test("ARCH-006 packages/contracts envelope tests", () => {
  goTest(path.join(root, "packages/contracts"), ["./envelope/..."]);
});

test("ARCH-006 platform events module tests", () => {
  goTest(path.join(root, "apps/platform"), ["./internal/modules/events/...", "./internal/compose/..."]);
});

test("ARCH-006 engine and market-data ownership markers", () => {
  assert.match(read("apps/trading-engine/server/schema_ownership.go"), /OwnerEngine/);
  assert.match(read("apps/market-ingestor/server/schema_ownership.go"), /OwnerMarketData/);
  goTest(path.join(root, "apps/trading-engine"), [
    "./server",
    "-run",
    "TestEngineSchemaOwnerBoundary",
  ]);
  goTest(path.join(root, "apps/market-ingestor"), [
    "./server",
    "-run",
    "TestMarketDataSchemaOwnerBoundary",
  ]);
});
