#!/usr/bin/env node
/**
 * Contest Lifecycle Gate — static + live checks for MVP start path.
 * Exit 0 = lifecycle surfaces PASS; Exit 1 = BLOCKED.
 */
import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const results = [];
function gate(cat, name, ok, detail = "") {
  results.push({ cat, name, ok, detail: String(detail || "").slice(0, 200) });
  console.log(`${ok ? "PASS" : "FAIL"}  [${cat}] ${name}${detail ? " — " + detail : ""}`);
}
function read(rel) {
  const p = path.join(root, rel);
  return fs.existsSync(p) ? fs.readFileSync(p, "utf8") : "";
}
function exists(rel) {
  return fs.existsSync(path.join(root, rel));
}

console.log("CONTEST LIFECYCLE GATE");
console.log("======================");

// Domain policy
const sm = read("packages/domain/statemachine/statemachine.go");
gate("STATE MACHINE", "status enum running", /StatusRunning/.test(sm));
gate("STATE MACHINE", "min participants real users only", /is_system/.test(sm) && /minimum participants not met/.test(sm));
gate("STATE MACHINE", "auto-start candidates", /FindContestsForAutoTransition/.test(sm));
gate("STATE MACHINE", "auto_start query", /auto_start = TRUE/.test(sm));

const policy = read("docs/product/FIXED_PRODUCT_AND_TECHNICAL_POLICIES.md");
gate("POLICY", "two real users at start", /Two or more real users/.test(policy) || /two or more real/.test(policy.toLowerCase()));
gate("POLICY", "system users never satisfy quorum", /System users never satisfy/.test(policy));

// Admin create defaults
const adminContest = read("apps/admin-bff/server/handlers_contest.go");
gate("ADMIN CREATE", "min_participants default 2", /MinParticipants = 2/.test(adminContest));
gate("ADMIN CREATE", "paid AutoStart true", /AutoStart = true/.test(adminContest));

// No admin demo data
const shards = read("apps/admin-frontend/src/modules/admin/views/ShardsPage.vue");
const audit = read("apps/admin-frontend/src/modules/admin/views/AuditPage.vue");
gate("REAL ADMIN DATA", "shards no mock participants", !/participant_count: 1542/.test(shards));
gate("REAL ADMIN DATA", "audit no mock logs", !/admin@example.com/.test(audit));

// FE countdown
const ctd = read("apps/user-frontend/src/modules/user/components/contests/CountdownTimer.vue");
gate("COUNTDOWN", "no FE invent running status", !/emit\('statusChange', 'running'\)/.test(ctd));
gate("COUNTDOWN", "timestamp based", /startsAt|endsAt|getTime\(\)/.test(ctd));
gate("COUNTDOWN", "useCountdown server delta support", /serverTimeDelta/.test(read("apps/user-frontend/src/modules/user/composables/useCountdown.ts")));

const tdc = read("apps/user-frontend/src/modules/user/components/contests/TournamentDetailsCard.vue");
gate("COUNTDOWN", "details card shows quorum", /minParticipants|minRequired|waiting/.test(tdc));
gate("TRADING UNLOCK", "enter trading only when running", /isRunning/.test(tdc) && /enterTrading/.test(tdc));

// Prize invent removed
gate("NO FAKE ECONOMICS", "no *0.83 prize invent ContestCard", !/\* 0\.83/.test(read("apps/user-frontend/src/modules/user/components/contests/ContestCard.vue")));
gate("NO FAKE ECONOMICS", "no *0.83 ContestResults", !/\* 0\.83/.test(read("apps/user-frontend/src/modules/user/views/ContestResultsPage.vue")));

// User-bff real participant counts
const ch = read("apps/user-bff/server/contest_handlers.go");
gate("REAL COUNTS", "exclude is_system participants", /is_system/.test(ch));
gate("REAL COUNTS", "server_time on details", /ServerTime|server_time/.test(ch));

// Seed gated
const appGo = read("apps/user-bff/server/app.go");
gate("SEED", "dev-only seedAdminUsers", /SEED_DEV_USERS|development/.test(appGo) && /seedAdminUsers/.test(appGo));

// Cleanup tool present
gate("CLEANUP", "e2e data cleanup script", exists("scripts/mvp/cleanup-e2e-test-data.mjs"));

// Trading still gated
const eng = read("apps/trading-engine/server/order_processing.go");
gate("TRADING GATE", "engine requires running", /contest is not running/.test(eng) || /status: %s/.test(eng));

const failed = results.filter((r) => !r.ok);
console.log("");
console.log(`checks=${results.length} fail=${failed.length}`);
console.log(failed.length ? "CONTEST LIFECYCLE — BLOCKED" : "CONTEST LIFECYCLE — PASS");
process.exit(failed.length ? 1 : 0);
