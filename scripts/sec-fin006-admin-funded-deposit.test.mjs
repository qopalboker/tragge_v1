/**
 * FIN-006 — admin top-ups classified as admin_funded_deposit (not gateway deposit revenue).
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

function read(rel) {
  return fs.readFileSync(path.join(root, rel), "utf8");
}

test("FIN-006 wallet type + revenue predicate exist", () => {
  const types = read("packages/wallet/types.go");
  assert.match(types, /LedgerTypeAdminFundedDeposit\s+LedgerType\s*=\s*"admin_funded_deposit"/);
  assert.match(types, /GatewayDepositRevenueSQLPredicate/);
  assert.match(types, /WALLET_TOPUP/);
  assert.match(types, /admin_action/);
});

test("FIN-006 admin charge credits use admin_funded_deposit", () => {
  const charge = read("apps/admin-bff/server/handlers_withdrawal.go");
  assert.match(charge, /LedgerTypeAdminFundedDeposit/);
  assert.doesNotMatch(
    charge,
    /CreditIdempotentWithReason\([\s\S]*?LedgerTypeDeposit/,
  );
  assert.match(charge, /"ledger_type"/);
  assert.match(charge, /user\.wallet\.charged/);
});

test("FIN-006 dashboard deposits metric uses gateway revenue predicate", () => {
  const dash = read("apps/admin-bff/server/handlers_user_management.go");
  assert.match(dash, /GatewayDepositRevenueSQLPredicate/);
});

test("FIN-006 migrations add enum and backfill historical admin top-ups", () => {
  const add = read("packages/db/migrations/0112_fin006_admin_funded_deposit.up.sql");
  const backfill = read("packages/db/migrations/0113_fin006_backfill_admin_funded_deposit.up.sql");
  assert.match(add, /ADD VALUE IF NOT EXISTS 'admin_funded_deposit'/);
  assert.match(backfill, /SET type = 'admin_funded_deposit'/);
  assert.match(backfill, /reason_code = 'WALLET_TOPUP'/);
  assert.match(backfill, /ref_type = 'admin_action'/);
});

test("FIN-006 payment gateway deposit path still uses deposit", () => {
  const inquiry = read("apps/payment-service/server/inquiry.go");
  assert.match(inquiry, /LedgerTypeDeposit/);
  assert.doesNotMatch(inquiry, /LedgerTypeAdminFundedDeposit/);
});

test("FIN-006 wallet unit tests for classification pass", () => {
  const result = spawnSync(
    "go",
    ["test", "-count=1", "-run=^TestFIN006", "."],
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
