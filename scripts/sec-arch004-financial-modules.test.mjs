/**
 * ARCH-004 — wallet / payment / kyc / withdrawal into Platform.
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("ARCH-004 wallet is sole ledger authority", () => {
  assert.match(
    read("apps/platform/internal/modules/wallet/module.go"),
    /IsSoleLedgerAuthority/,
  );
  assert.doesNotMatch(
    read("apps/platform/internal/modules/wallet/module.go"),
    /admin_funded_deposit/,
  );
});

test("ARCH-004 payment keeps providers as adapters and credits via wallet", () => {
  const src = read("apps/platform/internal/modules/payment/module.go");
  assert.match(src, /type Provider interface/);
  assert.match(src, /CreatePayment/);
  assert.match(src, /ApplyDepositCredit/);
  assert.match(src, /RequestWithdraw/);
  assert.match(src, /wallet\.CreditDeposit/);
  assert.doesNotMatch(src, /UPDATE wallets/);
});

test("ARCH-004 Platform API mounts financial boundaries", () => {
  const api = read("apps/platform/internal/adapters/api/server.go");
  assert.match(api, /platformwallet\.RegisterRoutes/);
  assert.match(api, /platformpayment\.RegisterRoutes/);
  assert.match(api, /platformkyc\.RegisterRoutes/);
});

test("ARCH-004 platform tests", () => {
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
