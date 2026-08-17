#!/usr/bin/env node
/**
 * MVP Frontend mobile reconstruction gate.
 * No cloud / payment / K8s requirements.
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const fe = path.join(root, "apps/user-frontend");
const evidenceDir = path.join(root, "docs/codex/reports/evidence/frontend");
fs.mkdirSync(evidenceDir, { recursive: true });

const results = [];
function gate(cat, name, ok, detail = "") {
  results.push({ cat, name, ok, detail });
  console.log(`${ok ? "PASS" : "FAIL"}  [${cat}] ${name}${detail ? " — " + detail : ""}`);
}

function exists(rel) {
  return fs.existsSync(path.join(root, rel));
}
function read(rel) {
  const p = path.join(root, rel);
  return fs.existsSync(p) ? fs.readFileSync(p, "utf8") : "";
}
function run(cmd, args, cwd = fe) {
  return spawnSync(cmd, args, {
    cwd,
    encoding: "utf8",
    shell: process.platform === "win32",
    timeout: 300000,
    env: process.env,
  });
}

console.log("MVP FRONTEND GATE");
console.log("=================");

// Structure
gate("ROUTES", "user dashboard page", exists("apps/user-frontend/src/modules/user/views/DashboardPage.vue"));
gate("ROUTES", "trade route", /trade\/:contestId/.test(read("apps/user-frontend/src/modules/trade/routes.ts")));
gate("ROUTES", "wallet page", exists("apps/user-frontend/src/modules/user/views/WalletPage.vue"));
gate("ROUTES", "tickets page", exists("apps/user-frontend/src/modules/user/views/TicketsPage.vue"));

gate("USER HOME", "mobile header", exists("apps/user-frontend/src/modules/user/components/dashboard/MobileHomeHeader.vue"));
gate("USER HOME", "featured contest", exists("apps/user-frontend/src/modules/user/components/dashboard/FeaturedContestCard.vue"));
gate("USER HOME", "challenge rail", exists("apps/user-frontend/src/modules/user/components/dashboard/ChallengeRail.vue"));
gate("USER HOME", "support card below challenges", exists("apps/user-frontend/src/modules/user/components/dashboard/SupportTicketCard.vue"));
gate("USER HOME", "bottom nav", exists("apps/user-frontend/src/modules/user/components/layout/BottomNav.vue"));

const dash = read("apps/user-frontend/src/modules/user/views/DashboardPage.vue");
gate("USER HOME", "dashboard uses MobileHomeHeader", /MobileHomeHeader/.test(dash));
gate("USER HOME", "dashboard uses FeaturedContestCard", /FeaturedContestCard/.test(dash));
gate("USER HOME", "dashboard uses ChallengeRail", /ChallengeRail/.test(dash));
gate("USER HOME", "dashboard uses SupportTicketCard", /SupportTicketCard/.test(dash));
gate("USER HOME", "horizontal scroll class", /mvp-h-scroll/.test(dash) || /mvp-h-scroll/.test(read("apps/user-frontend/src/modules/user/components/dashboard/ChallengeRail.vue")));

gate("WALLET", "wallet store balance API", /walletApi|\/api\/user\/wallet/.test(read("apps/user-frontend/src/modules/user/stores_wallet.ts")));
gate("CONTEST", "contests API fetch", /\/api\/user\/contests/.test(dash));
gate("CHALLENGE", "challenge uses real total_contests", /totalContests|total_contests/.test(dash + read("apps/user-frontend/src/modules/user/components/dashboard/ChallengeRail.vue")));
gate("SUPPORT", "tickets API", /ticketsApi/.test(read("apps/user-frontend/src/modules/user/components/dashboard/SupportTicketCard.vue")));
gate("TRADING", "trading page", exists("apps/user-frontend/src/modules/trade/views/TradingPage.vue"));
gate("RTL", "dashboard dir=rtl", /dir=\"rtl\"/.test(dash));
gate("RTL", "design tokens", exists("apps/user-frontend/src/styles/mvp-design-tokens.css"));
gate("RTL", "tokens imported in main", /mvp-design-tokens/.test(read("apps/user-frontend/src/main.ts")));
gate("RESPONSIVE", "safe-area bottom nav", /safe-area-inset-bottom/.test(read("apps/user-frontend/src/modules/user/components/layout/BottomNav.vue")));
gate("RESPONSIVE", "mobile content padding for nav", /mvp-bottom-nav-h|bottom-nav-height/.test(read("apps/user-frontend/src/modules/user/components/layout/UserLayout.vue")));

// Build / typecheck
const npm = process.platform === "win32" ? "npm.cmd" : "npm";
let r = run(npm, ["run", "typecheck"]);
gate("TYPECHECK", "vue-tsc", r.status === 0, `exit=${r.status}`);
r = run(npm, ["run", "build"]);
gate("BUILD", "vite production build", r.status === 0, `exit=${r.status}`);

// Reference image present
gate(
  "E2E",
  "reference image archived",
  exists("docs/codex/reports/evidence/frontend/reference-mobile-dashboard.png")
);

const failed = results.filter((x) => !x.ok).length;
const decision = failed === 0 ? "FRONTEND — PASS" : "FRONTEND — BLOCKED";
console.log("=================");
console.log(decision);
console.log(`failed=${failed}`);

fs.writeFileSync(
  path.join(evidenceDir, "frontend-gate-latest.json"),
  JSON.stringify({ ts: new Date().toISOString(), decision, failed, results }, null, 2)
);
fs.writeFileSync(
  path.join(evidenceDir, "frontend-gate-latest.txt"),
  results.map((r) => `${r.ok ? "PASS" : "FAIL"}  [${r.cat}] ${r.name}${r.detail ? " — " + r.detail : ""}`).join("\n") +
    `\n\n${decision}\n`
);
process.exit(failed === 0 ? 0 : 1);
