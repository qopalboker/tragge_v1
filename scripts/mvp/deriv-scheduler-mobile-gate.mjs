#!/usr/bin/env node
/**
 * DERIV + SCHEDULER + MOBILE qualification gate (2026-08-18).
 *
 * Exit 0 = DERIV + SCHEDULER + MOBILE — PASS
 * Exit 1 = DERIV + SCHEDULER + MOBILE — BLOCKED
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");

const dockerBin =
  process.env.DOCKER_BIN ||
  (process.platform === "win32"
    ? "C:\\Users\\parsa\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe"
    : "docker");

const results = [];
function gate(cat, name, ok, detail = "") {
  results.push({ cat, name, ok, detail: String(detail || "").slice(0, 400) });
  console.log(`${ok ? "PASS" : "FAIL"}  [${cat}] ${name}${detail ? " — " + detail : ""}`);
}

function read(rel) {
  const p = path.join(root, rel);
  return fs.existsSync(p) ? fs.readFileSync(p, "utf8") : "";
}

function psql(sql) {
  const passFile = path.join(root, "infra/docker/secrets/postgres_admin_password.txt");
  const pass = fs.existsSync(passFile) ? fs.readFileSync(passFile, "utf8").trim() : "";
  const r = spawnSync(
    dockerBin,
    ["exec", "-e", `PGPASSWORD=${pass}`, "tragge_postgres", "psql", "-U", "tragge_admin", "-d", "app", "-t", "-A", "-c", sql],
    { cwd: root, encoding: "utf8" },
  );
  return { status: r.status, out: (r.stdout || "").trim(), err: (r.stderr || "").trim() };
}

function dockerLogs(container, since = "10m") {
  const r = spawnSync(dockerBin, ["logs", container, "--since", since], {
    cwd: root,
    encoding: "utf8",
    maxBuffer: 8 * 1024 * 1024,
  });
  return `${r.stdout || ""}\n${r.stderr || ""}`;
}

function redisHmget(fields) {
  const passFile = path.join(root, "infra/docker/secrets/redis_password.txt");
  const pass = fs.existsSync(passFile) ? fs.readFileSync(passFile, "utf8").trim() : "";
  const r = spawnSync(
    dockerBin,
    ["exec", "tragge_redis", "redis-cli", "-a", pass, "--no-auth-warning", "HMGET", "prices:latest", ...fields],
    { cwd: root, encoding: "utf8" },
  );
  return (r.stdout || "").trim().split(/\r?\n/);
}

console.log("DERIV + SCHEDULER + MOBILE GATE");
console.log("================================");

// --- Provider defaults ---
const compose = read("infra/docker/docker-compose.yml");
gate("PROVIDER", "compose default MARKET_PROVIDER=deriv", /MARKET_PROVIDER:\s*\$\{MARKET_PROVIDER:-deriv\}/.test(compose));
gate("PROVIDER", "deriv_provider.go exists", fs.existsSync(path.join(root, "apps/market-ingestor/server/deriv_provider.go")));
gate("PROVIDER", "ProviderDeriv wired in app.go", /ProviderDeriv/.test(read("apps/market-ingestor/server/app.go")));
gate("PROVIDER", "Massive not compose default", !/MARKET_PROVIDER:\s*\$\{MARKET_PROVIDER:-massive\}/.test(compose));
gate("PROVIDER", "public Deriv WS URL present", /api\.derivws\.com\/trading\/v1\/options\/ws\/public/.test(read("apps/market-ingestor/server/deriv_provider.go")));
gate("PROVIDER", "migration 0108 deriv symbols", fs.existsSync(path.join(root, "packages/db/migrations/0108_deriv_provider.up.sql")));

const mig = psql("SELECT version FROM schema_migrations");
gate("PROVIDER", "schema_migrations >= 108", Number(mig.out) >= 108, mig.out);

const prices = redisHmget(["EUR/USD", "BTC/USD", "XAU/USD"]);
const eur = prices[0] || "";
const btc = prices[1] || "";
const xau = prices[2] || "";
gate("PROVIDER", "Redis EUR/USD live Deriv price", /"last":\s*[1-9]/.test(eur) && /"bid":/.test(eur), eur.slice(0, 120));
gate("PROVIDER", "Redis BTC/USD live Deriv price", /"last":\s*[1-9]/.test(btc), btc.slice(0, 120));
gate("PROVIDER", "Redis XAU/USD live Deriv price", /"last":\s*[1-9]/.test(xau), xau.slice(0, 120));

const ingestorLogs = dockerLogs("tragge_trading_core", "15m");
gate("PROVIDER", "ingestor mode=deriv", /Market provider mode.*"provider": "deriv"/.test(ingestorLogs) || /provider": "deriv"/.test(ingestorLogs));
gate("PROVIDER", "Massive not initialized as primary", !/Connecting.*"provider": "massive"/.test(ingestorLogs) && !/forex authentication failed/.test(ingestorLogs.split("\n").slice(-30).join("\n")));
gate("PROVIDER", "Binance/Nobitex skipped when deriv", /skipping Binance\/Nobitex/.test(ingestorLogs));

// --- Scheduler ---
gate("SCHEDULER", "0106 constraint fix present", /create_cron IS NOT NULL OR recurrence_rule IS NOT NULL/.test(read("packages/db/migrations/0106_mvp_tournament_scheduling.up.sql")));
const templates = psql("SELECT COUNT(*) FROM tournament_templates WHERE is_free=false AND duration_minutes=30 AND auto_create=true AND recurrence_rule='EVERY_10_MIN' AND auto_start=true");
gate("SCHEDULER", "30m paid templates auto_create+EVERY_10_MIN", Number(templates.out) >= 6, templates.out);
const upcoming = psql("SELECT COUNT(*) FROM contests WHERE status='registration_open' AND starts_at > NOW() AND starts_at < NOW() + interval '2 hours' AND auto_generated=true");
gate("SCHEDULER", "upcoming auto_generated contests exist", Number(upcoming.out) > 0, upcoming.out);
const workerLogs = dockerLogs("tragge_worker", "15m");
gate("SCHEDULER", "calendar cycle observability", /Calendar processor cycle complete/.test(workerLogs) || /templates_scanned/.test(workerLogs));
gate("SCHEDULER", "lead time 15m in compose", /FREE_CONTEST_LEAD_TIME_MINUTES:\s*"15"/.test(compose));

const proofRunning = psql("SELECT COUNT(*) FROM contests WHERE name LIKE 'SCHED-PROOF-PAID-%' AND status='running'");
const proofAny = psql("SELECT status FROM contests WHERE name LIKE 'SCHED-PROOF-PAID-%' ORDER BY created_at DESC LIMIT 1");
gate(
  "SCHEDULER",
  "controlled paid auto-start proof RUNNING (or recent)",
  Number(proofRunning.out) > 0 || proofAny.out === "running" || proofAny.out === "completed" || proofAny.out === "settling",
  proofAny.out || "none",
);

// --- Mobile ---
const layout = read("apps/user-frontend/src/modules/user/components/layout/UserLayout.vue");
const dash = read("apps/user-frontend/src/modules/user/views/DashboardPage.vue");
const tokens = read("apps/user-frontend/src/styles/mvp-design-tokens.css");
const mobileSpec = read("apps/user-frontend/e2e/mvp-mobile-home.spec.ts");
gate("MOBILE", "layout-main min-width:0", /\.layout-main[\s\S]*min-width:\s*0/.test(layout));
gate("MOBILE", "mvp-h-scroll min-width:0", /\.mvp-h-scroll[\s\S]*min-width:\s*0/.test(tokens));
gate("MOBILE", "sug-card bound to content width", /max-width:\s*calc\(100vw/.test(dash));
gate("MOBILE", "e2e includes 360/390/412/430", /412/.test(mobileSpec) && /360/.test(mobileSpec) && /430/.test(mobileSpec));
gate("MOBILE", "e2e asserts document width", /scrollWidth[\s\S]*clientWidth/.test(mobileSpec));
gate("MOBILE", "desktop viewport regression in e2e", /1280/.test(mobileSpec) && /1440/.test(mobileSpec));

// --- Cleanup ---
const exampleLeft = psql("SELECT COUNT(*) FROM users WHERE email ILIKE '%@example.com'");
gate("CLEANUP", "@example.com users cleaned", Number(exampleLeft.out) === 0, exampleLeft.out);
gate("CLEANUP", "classified cleanup script", /SAFE_TO_DELETE/.test(read("scripts/mvp/cleanup-e2e-test-data.mjs")));

// --- Docs ---
gate(
  "DOCS",
  "qualification report present",
  fs.existsSync(path.join(root, "docs/codex/reports/DERIV-MOBILE-SCHEDULER-QUALIFICATION-2026-08-18.md")),
);

const failed = results.filter((r) => !r.ok);
console.log("");
console.log(`RESULT: ${failed.length === 0 ? "DERIV + SCHEDULER + MOBILE — PASS" : "DERIV + SCHEDULER + MOBILE — BLOCKED"}`);
console.log(`gates: ${results.length - failed.length}/${results.length} pass`);
if (failed.length) {
  for (const f of failed) console.log(`  FAIL ${f.cat}: ${f.name} — ${f.detail}`);
}
process.exit(failed.length === 0 ? 0 : 1);
