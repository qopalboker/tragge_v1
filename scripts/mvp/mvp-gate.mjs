#!/usr/bin/env node
/**
 * MVP Functional Release Gate
 *
 * Does NOT require Kubernetes, cloud VM, payment provider, or legal sign-off.
 * Validates User + Admin + Trading MVP surfaces and financial spine.
 *
 * Exit 0 = MVP — PASS
 * Exit 1 = MVP — BLOCKED
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const evidenceDir = path.join(root, "docs/codex/reports/evidence/mvp");
fs.mkdirSync(evidenceDir, { recursive: true });

const dockerBin =
  process.env.DOCKER_BIN ||
  (process.platform === "win32"
    ? "C:\\Users\\parsa\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe"
    : "docker");

function exists(rel) {
  return fs.existsSync(path.join(root, rel));
}

function read(rel) {
  const p = path.join(root, rel);
  return fs.existsSync(p) ? fs.readFileSync(p, "utf8") : "";
}

function run(cmd, args, opts = {}) {
  return spawnSync(cmd, args, {
    cwd: root,
    encoding: "utf8",
    shell: false,
    env: { ...process.env, ...(opts.env || {}) },
    timeout: opts.timeout || 200000,
  });
}

const results = [];
function gate(cat, name, ok, detail = "") {
  results.push({ cat, name, ok, detail });
  console.log(`${ok ? "PASS" : "FAIL"}  [${cat}] ${name}${detail ? " — " + detail : ""}`);
}

console.log("MVP FUNCTIONAL RELEASE GATE");
console.log("===========================");
console.log("scope=user+admin+trading+wallet+contest (no payment gateway / no cloud GO)");
console.log("");

// --- Source surface gates ---
gate("AUTH", "user login route", exists("apps/user-frontend/src/modules/user/views/LoginPage.vue"));
gate("AUTH", "admin login route", exists("apps/admin-frontend/src/modules/admin/views/LoginPage.vue"));
gate("AUTH", "user-bff login handler", /Post\("\/auth\/login"/.test(read("apps/user-bff/server/app.go")));
gate("AUTH", "admin-bff login handler", /Post\("\/login"/.test(read("apps/admin-bff/server/app.go")));

gate("WALLET", "user wallet page", exists("apps/user-frontend/src/modules/user/views/WalletPage.vue"));
gate("WALLET", "user wallet store", exists("apps/user-frontend/src/modules/user/stores_wallet.ts") || exists("apps/user-frontend/src/stores/wallet.ts"));
gate("WALLET", "admin charge API route", /wallet\/charge/.test(read("apps/admin-bff/server/app.go")));
gate("WALLET", "admin charge handler uses wallet.Service", /CreditIdempotentWithReason/.test(read("apps/admin-bff/server/handlers_withdrawal.go")));
gate("WALLET", "admin charge UI", /chargeUserWallet/.test(read("apps/admin-frontend/src/api/users.ts")));
gate("WALLET", "wallet CreditIdempotent", /func \(s \*Service\) CreditIdempotent/.test(read("packages/wallet/wallet.go")));

gate("ADMIN", "contest create form page", exists("apps/admin-frontend/src/modules/admin/views/ContestFormPage.vue"));
gate("ADMIN", "contests list page", exists("apps/admin-frontend/src/modules/admin/views/ContestsPage.vue"));
gate("ADMIN", "user detail + wallet", exists("apps/admin-frontend/src/modules/admin/views/UserDetailPage.vue"));
gate("ADMIN", "financial page", exists("apps/admin-frontend/src/modules/admin/views/FinancialPage.vue"));
gate("ADMIN", "admin contest handlers", exists("apps/admin-bff/server/handlers_contest.go"));

gate("CONTEST", "user contests page", exists("apps/user-frontend/src/modules/user/views/ContestsPage.vue"));
gate("CONTEST", "contest details page", exists("apps/user-frontend/src/modules/user/views/ContestDetailsPage.vue"));
gate("CONTEST", "contest results page", exists("apps/user-frontend/src/modules/user/views/ContestResultsPage.vue"));
gate("JOIN", "user join route", /Post\("\/contests\/\{id\}\/join"/.test(read("apps/user-bff/server/app.go")));

gate("TRADING", "trading page route", /path: '\/trade\/:contestId'/.test(read("apps/user-frontend/src/modules/trade/routes.ts")));
gate("TRADING", "trade-bff place order", /Post\("\/orders"/.test(read("apps/trade-bff/server/app.go")));
gate("TRADING", "trade-bff positions close", /positions/.test(read("apps/trade-bff/server/app.go")));

gate("FINALIZATION", "settlement tables exist (migrations)", /contest_settlements/.test(read("packages/db/migrations/0019_settlement_tables.up.sql")));
gate("SETTLEMENT", "wallet prize credit", /CreditPrizeIdempotent/.test(read("packages/wallet/wallet.go")));
gate("RECONCILIATION", "contest-reconcile script", exists("scripts/contest-reconcile.mjs"));
gate("SECURITY", "admin charge requires permission", /users\.wallet\.charge/.test(read("apps/admin-bff/server/app.go")));
gate("SECURITY", "sensitive action on wallet charge", /requireSensitiveAction/.test(read("apps/admin-bff/server/app.go")));

// --- Live stack optional ---
const docker = run(dockerBin, ["ps", "--format", "{{.Names}}"]);
const dockerUp = docker.status === 0 && /tragge_postgres/.test(docker.stdout || "");
gate("E2E", "compose postgres running", dockerUp, dockerUp ? "tragge_postgres" : "docker unavailable");

let financialOk = false;
let tradingOk = false;
let mvpOk = false;
let restartOk = false;

if (dockerUp) {
  const passFile = path.join(root, "infra/docker/secrets/postgres_admin_password.txt");
  const pass = fs.existsSync(passFile) ? fs.readFileSync(passFile, "utf8").trim() : "";
  const dsn = `postgres://tragge_admin:${encodeURIComponent(pass)}@127.0.0.1:5432/app?sslmode=disable`;
  const env = { TRAGGE_E2E_DATABASE_URL: dsn };

  let r = run("go", ["test", "./packages/wallet/", "-count=1", "-timeout", "180s", "-run", "TestMVP_AdminCreditJoinSettle_E2E|TestMVP_InsufficientBalance"], { env, timeout: 200000 });
  mvpOk = r.status === 0;
  gate("E2E", "MVP financial spine (admin credit→join→settle)", mvpOk, `exit=${r.status}`);

  r = run("go", ["test", "./packages/wallet/", "-count=1", "-timeout", "180s", "-run", "TestPhase11_FinancialLifecycle_E2E"], { env, timeout: 200000 });
  financialOk = r.status === 0;
  gate("E2E", "Phase 1.1 financial lifecycle regression", financialOk, `exit=${r.status}`);

  r = run("go", ["test", "./apps/trading-engine/server/", "-count=1", "-timeout", "180s", "-run", "TestPhase2_E2E_TradingToSettlement"], { env, timeout: 200000 });
  tradingOk = r.status === 0;
  gate("E2E", "Phase 2 trading→settlement", tradingOk, `exit=${r.status}`);

  r = run("go", ["test", "./apps/trading-engine/server/", "-count=1", "-timeout", "180s", "-run", "TestPhase2_E2E_RestartWALRecovery"], { env, timeout: 200000 });
  restartOk = r.status === 0;
  gate("E2E", "trading restart WAL regression", restartOk, `exit=${r.status}`);

  // HTTP health of BFFs
  const healthUser = run(dockerBin, ["exec", "tragge_api_server", "wget", "-qO-", "http://127.0.0.1:8081/healthz"]);
  gate("E2E", "api user-bff healthz", healthUser.status === 0, (healthUser.stdout || "").slice(0, 40));
  const ready = run(dockerBin, ["exec", "tragge_trading_core", "wget", "-qO-", "http://127.0.0.1:8085/readyz"]);
  gate("E2E", "trading-engine wal_recovery", ready.status === 0 && /wal_recovery.:.ok/.test(ready.stdout || ""), (ready.stdout || "").slice(0, 80));
} else {
  gate("E2E", "live compose tests", false, "skipped — start Docker Compose stack");
}

// Frontend packages present (not full vite build — expensive)
gate("USER RESULT", "contest results view", exists("apps/user-frontend/src/modules/user/views/ContestResultsPage.vue"));
gate("ADMIN RESULT", "contest detail admin", exists("apps/admin-frontend/src/modules/admin/views/ContestDetailPage.vue"));

const failed = results.filter((x) => !x.ok).length;
const decision = failed === 0 ? "MVP — PASS" : "MVP — BLOCKED";

console.log("===========================");
console.log(decision);
console.log(`failed=${failed}`);
console.log("claim_if_pass=MVP — FUNCTIONALLY COMPLETE");
console.log("not_claimed=PRODUCTION — GO");

const out = {
  ts: new Date().toISOString(),
  decision,
  failed,
  results,
  production_go: false,
  payment_gateway: false,
};
fs.writeFileSync(path.join(evidenceDir, "mvp-gate-latest.json"), JSON.stringify(out, null, 2));
fs.writeFileSync(
  path.join(evidenceDir, "mvp-gate-latest.txt"),
  results.map((r) => `${r.ok ? "PASS" : "FAIL"}  [${r.cat}] ${r.name}${r.detail ? " — " + r.detail : ""}`).join("\n") +
    `\n\n${decision}\n`
);

process.exit(failed === 0 ? 0 : 1);
