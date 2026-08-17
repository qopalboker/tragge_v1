#!/usr/bin/env node
/**
 * MVP Stabilization Acceptance Gate
 *
 * Certifies release-candidate readiness for local MVP usage.
 * Does NOT require cloud, Kubernetes, payment gateway, or legal sign-off.
 *
 * Exit 0 = MVP STABILIZATION — PASS
 * Exit 1 = MVP STABILIZATION — BLOCKED
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const evidenceDir = path.join(root, "docs/codex/reports/evidence/mvp-stabilization");
fs.mkdirSync(evidenceDir, { recursive: true });

const dockerBin =
  process.env.DOCKER_BIN ||
  (process.platform === "win32"
    ? "C:\\Users\\parsa\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe"
    : "docker");

const results = [];
function gate(cat, name, ok, detail = "") {
  results.push({ cat, name, ok, detail: String(detail || "").slice(0, 200) });
  console.log(`${ok ? "PASS" : "FAIL"}  [${cat}] ${name}${detail ? " — " + detail : ""}`);
}

function exists(rel) {
  return fs.existsSync(path.join(root, rel));
}
function read(rel) {
  const p = path.join(root, rel);
  return fs.existsSync(p) ? fs.readFileSync(p, "utf8") : "";
}
function run(cmd, args, opts = {}) {
  return spawnSync(cmd, args, {
    cwd: opts.cwd || root,
    encoding: "utf8",
    shell: opts.shell ?? false,
    env: { ...process.env, ...(opts.env || {}) },
    timeout: opts.timeout || 300000,
  });
}

console.log("MVP STABILIZATION ACCEPTANCE GATE");
console.log("=================================");
console.log("no cloud / k8s / payment gateway required");
console.log("");

// ---- Surface structure ----
gate("AUTH", "user login page", exists("apps/user-frontend/src/modules/user/views/LoginPage.vue"));
gate("AUTH", "admin login page", exists("apps/admin-frontend/src/modules/admin/views/LoginPage.vue"));
gate("AUTH", "user router auth guard", /requiresAuth/.test(read("apps/user-frontend/src/router/index.ts")));
gate("AUTH", "user BFF login", /Post\("\/auth\/login"/.test(read("apps/user-bff/server/app.go")));

gate("WALLET", "user wallet page", exists("apps/user-frontend/src/modules/user/views/WalletPage.vue"));
gate("WALLET", "admin charge API", /wallet\/charge/.test(read("apps/admin-bff/server/app.go")));
gate("WALLET", "CreditIdempotent", /CreditIdempotentWithReason/.test(read("packages/wallet/wallet.go")));
gate("WALLET", "prize credit", /CreditPrizeIdempotent/.test(read("packages/wallet/wallet.go")));

gate("ADMIN", "contest form", exists("apps/admin-frontend/src/modules/admin/views/ContestFormPage.vue"));
gate("ADMIN", "user detail", exists("apps/admin-frontend/src/modules/admin/views/UserDetailPage.vue"));
gate("ADMIN", "wallet charge permission", /users\.wallet\.charge/.test(read("apps/admin-bff/server/app.go")));

gate("CONTEST", "user contests page", exists("apps/user-frontend/src/modules/user/views/ContestsPage.vue"));
gate("CONTEST", "contest details", exists("apps/user-frontend/src/modules/user/views/ContestDetailsPage.vue"));
gate("JOIN", "join route", /Post\("\/contests\/\{id\}\/join"/.test(read("apps/user-bff/server/app.go")));

gate("TRADING", "trading page", exists("apps/user-frontend/src/modules/trade/views/TradingPage.vue"));
gate("TRADING", "trade orders API", /Post\("\/orders"/.test(read("apps/trade-bff/server/app.go")));

gate("FINALIZATION", "settlement migrations", /contest_settlements/.test(read("packages/db/migrations/0019_settlement_tables.up.sql")));
gate("SETTLEMENT", "prize credit path", /CreditPrizeIdempotent/.test(read("packages/wallet/wallet.go")));
gate("RESULT", "contest results page", exists("apps/user-frontend/src/modules/user/views/ContestResultsPage.vue"));

gate("SUPPORT", "tickets API client", /ticketsApi/.test(read("apps/user-frontend/src/modules/user/api/tickets.ts")));
gate("SUPPORT", "dashboard support card", exists("apps/user-frontend/src/modules/user/components/dashboard/SupportTicketCard.vue"));
gate("SUPPORT", "support below challenges", (() => {
  const d = read("apps/user-frontend/src/modules/user/views/DashboardPage.vue");
  const c = d.indexOf("ChallengeRail");
  const s = d.indexOf("SupportTicketCard");
  return c >= 0 && s > c;
})());

gate("CHALLENGES", "challenge rail", exists("apps/user-frontend/src/modules/user/components/dashboard/ChallengeRail.vue"));
gate("CHALLENGES", "uses total_contests", /totalContests|total_contests/.test(
  read("apps/user-frontend/src/modules/user/views/DashboardPage.vue") +
    read("apps/user-frontend/src/modules/user/components/dashboard/ChallengeRail.vue")
));
gate("CHALLENGES", "horizontal scroll", /mvp-h-scroll/.test(
  read("apps/user-frontend/src/modules/user/components/dashboard/ChallengeRail.vue")
));

// Contest list shape: dashboard must accept array OR envelope
const dash = read("apps/user-frontend/src/modules/user/views/DashboardPage.vue");
gate(
  "CONTEST",
  "dashboard parses array contest response",
  /Array\.isArray\(raw\)/.test(dash) || /Array\.isArray\(/.test(dash)
);

// No random fake ranks on free practice
const free = read("apps/user-frontend/src/modules/user/components/dashboard/FreePracticeSection.vue");
gate("SECURITY", "no Math.random ranks on free practice", !/Math\.random\(\)\s*\*\s*50/.test(free));
gate("SECURITY", "admin routes not in user app", !/\/api\/admin/.test(read("apps/user-frontend/src/stores/auth.ts")));

gate("RESPONSIVE", "safe-area bottom nav", /safe-area-inset-bottom/.test(
  read("apps/user-frontend/src/modules/user/components/layout/BottomNav.vue")
));
gate("RTL", "dashboard dir=rtl", /dir=\"rtl\"/.test(dash));
gate("RTL", "design tokens", exists("apps/user-frontend/src/styles/mvp-design-tokens.css"));

// Nested gates
const feGate = run(process.execPath, [path.join(root, "scripts/mvp/frontend-gate.mjs")], { timeout: 360000 });
gate("BROWSER E2E", "frontend-gate", feGate.status === 0, `exit=${feGate.status}`);

const mvpGate = run(process.execPath, [path.join(root, "scripts/mvp/mvp-gate.mjs")], {
  timeout: 400000,
  env: { DOCKER_BIN: dockerBin },
});
gate("FINANCIAL RECONCILIATION", "mvp-gate", mvpGate.status === 0, `exit=${mvpGate.status}`);

// Optional: live docker financial spine if postgres up
const docker = run(dockerBin, ["ps", "--format", "{{.Names}}"]);
const dockerUp = docker.status === 0 && /tragge_postgres/.test(docker.stdout || "");
gate("FINANCIAL RECONCILIATION", "compose postgres available", dockerUp, dockerUp ? "tragge_postgres" : "unavailable");

if (dockerUp) {
  const passFile = path.join(root, "infra/docker/secrets/postgres_admin_password.txt");
  const pass = fs.existsSync(passFile) ? fs.readFileSync(passFile, "utf8").trim() : "";
  const dsn = `postgres://tragge_admin:${encodeURIComponent(pass)}@127.0.0.1:5432/app?sslmode=disable`;
  const env = { TRAGGE_E2E_DATABASE_URL: dsn };

  let r = run("go", ["test", "./packages/wallet/", "-count=1", "-timeout", "180s", "-run", "TestMVP_AdminCreditJoinSettle_E2E|TestMVP_InsufficientBalance"], {
    env,
    timeout: 200000,
  });
  gate("WALLET", "admin credit→join→settle E2E", r.status === 0, `exit=${r.status}`);

  r = run("go", ["test", "./packages/wallet/", "-count=1", "-timeout", "180s", "-run", "TestPhase11_FinancialLifecycle_E2E"], {
    env,
    timeout: 200000,
  });
  gate("SETTLEMENT", "phase1.1 financial lifecycle", r.status === 0, `exit=${r.status}`);

  r = run("go", ["test", "./apps/trading-engine/server/", "-count=1", "-timeout", "180s", "-run", "TestPhase2_E2E_TradingToSettlement"], {
    env,
    timeout: 200000,
  });
  gate("TRADING", "trading→settlement E2E", r.status === 0, `exit=${r.status}`);

  r = run("go", ["test", "./apps/trading-engine/server/", "-count=1", "-timeout", "180s", "-run", "TestPhase2_E2E_RestartWALRecovery"], {
    env,
    timeout: 200000,
  });
  gate("TRADING", "restart WAL recovery", r.status === 0, `exit=${r.status}`);
}

// Browser e2e assets present
gate("BROWSER E2E", "user e2e suite present", exists("apps/user-frontend/e2e/auth.spec.ts"));
gate("BROWSER E2E", "admin e2e suite present", exists("apps/admin-frontend/e2e/contests.spec.ts"));
gate("BROWSER E2E", "mobile home acceptance spec", exists("apps/user-frontend/e2e/mvp-mobile-home.spec.ts") || exists("apps/user-frontend/e2e/tournament-flows.spec.ts"));

const failed = results.filter((x) => !x.ok).length;
const decision = failed === 0 ? "MVP STABILIZATION — PASS" : "MVP STABILIZATION — BLOCKED";
console.log("=================================");
console.log(decision);
console.log(`failed=${failed}`);
console.log("not_claimed=PRODUCTION — GO");

const payload = {
  ts: new Date().toISOString(),
  decision,
  failed,
  results,
  production_go: false,
};
fs.writeFileSync(path.join(evidenceDir, "acceptance-gate-latest.json"), JSON.stringify(payload, null, 2));
fs.writeFileSync(
  path.join(evidenceDir, "acceptance-gate-latest.txt"),
  results.map((r) => `${r.ok ? "PASS" : "FAIL"}  [${r.cat}] ${r.name}${r.detail ? " — " + r.detail : ""}`).join("\n") +
    `\n\n${decision}\n`
);
process.exit(failed === 0 ? 0 : 1);
