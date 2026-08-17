#!/usr/bin/env node
/**
 * Static gate: tournament scheduling / lifecycle product rules.
 * Exit 0 = PASS, non-zero = FAIL.
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
let failed = 0;

function ok(msg) {
  console.log(`  PASS  ${msg}`);
}
function fail(msg) {
  console.error(`  FAIL  ${msg}`);
  failed++;
}
function read(rel) {
  return fs.readFileSync(path.join(root, rel), "utf8");
}
function exists(rel) {
  return fs.existsSync(path.join(root, rel));
}

console.log("contest-scheduling-gate");

// --- Recurrence / 30m slots ---
const cal = read("apps/contest-scheduler/internal/scheduler/calendar.go");
if (cal.includes("EVERY_10_MIN") && cal.includes("slotHorizon")) {
  ok("calendar supports EVERY_10_MIN + slot horizon materialization");
} else {
  fail("calendar missing EVERY_10_MIN / slotHorizon");
}
if (cal.includes(`return "four_hour"`) || cal.includes('return "four_hour"')) {
  ok("duration type four_hour (not 4hour) for 4h contests");
} else {
  fail("getDurationTypeFromMinutes must return four_hour");
}
if (!cal.includes("15-minute") && !cal.includes("rush_15")) {
  ok("no 15-minute tournament duration introduced");
} else {
  fail("15-minute duration must not be added this phase");
}

// --- Quorum ---
const sm = read("packages/domain/statemachine/statemachine.go");
const sched = read("apps/contest-scheduler/internal/scheduler/scheduler.go");
if (sm.includes("is_system") && sm.includes("minimum participants not met")) {
  ok("state machine enforces real-user quorum (excludes is_system)");
} else {
  fail("state machine quorum check missing");
}
if (sched.includes("IsFree") && sched.includes("minRequired") && sched.includes("Auto-cancelled")) {
  ok("scheduler auto-cancels below-quorum free/paid starts");
} else {
  fail("scheduler free/paid quorum cancel path missing");
}

// --- Free T-bot ---
if (cal.includes("is_system") && cal.includes("TBotUserID")) {
  ok("calendar free path registers T-bot as system participant");
} else {
  fail("T-bot auto-join missing on free calendar creates");
}
const freeGen = read("apps/free-contest-generator/server/app.go");
if (freeGen.includes("is_system") || freeGen.includes("TBotUserID")) {
  ok("free-contest-generator retains T-bot integration");
} else {
  fail("free generator T-bot missing");
}

// --- Migration ---
if (exists("packages/db/migrations/0106_mvp_tournament_scheduling.up.sql")) {
  const mig = read("packages/db/migrations/0106_mvp_tournament_scheduling.up.sql");
  if (mig.includes("EVERY_10_MIN") && mig.includes("auto_create = TRUE")) {
    ok("0106 enables 30m EVERY_10_MIN auto_create templates");
  } else {
    fail("0106 migration incomplete");
  }
} else {
  fail("missing 0106_mvp_tournament_scheduling migration");
}

// --- User list API contract ---
const list = read("apps/user-bff/server/contest_handlers.go");
if (list.includes("prize_pool_net_cents") && list.includes("CONTEST_LIST_UPCOMING")) {
  ok("user list has prize + upcoming window config");
} else {
  fail("user list prize/window missing");
}
if (list.includes("is_system") && list.includes("FALSE")) {
  ok("participant_count excludes system users");
} else {
  fail("participant_count must exclude is_system");
}

// --- FE: No prize / Join without price / Tehran ---
const card = read("apps/user-frontend/src/modules/user/components/contests/ContestCard.vue");
if (card.includes("noPrize") || card.includes("No prize")) {
  ok("contest card shows No prize when pool is 0");
} else {
  fail("contest card missing No prize copy");
}
if (card.includes("Asia/Tehran")) {
  ok("contest card formats times in Asia/Tehran");
} else {
  fail("Tehran timezone formatting missing on card");
}
if (card.includes("Entry fee") || card.includes("entryFee")) {
  ok("entry fee shown separately from Join CTA");
} else {
  fail("entry fee row missing");
}
// Join button should not interpolate $
if (!/join.*\$\{\{/.test(card) && !/Join\s*\$/.test(card)) {
  ok("Join CTA does not embed price");
} else {
  fail("Join CTA must not contain price");
}

// --- Details SPA nav ---
const details = read("apps/user-frontend/src/modules/user/views/ContestDetailsPage.vue");
if (details.includes("contest.value = null") && details.includes("watch(contestId")) {
  ok("contest details clears state on route param change");
} else {
  fail("contest details SPA stale-state fix missing");
}

// --- Trade end redirect ---
const trade = read("apps/user-frontend/src/modules/trade/views/TradingPage.vue");
if (trade.includes("revalidateAndMaybeLeaveTrade") || trade.includes("/user/contests/")) {
  ok("trading page redirects to contest info after end");
} else {
  fail("trading end redirect missing");
}

// --- Countdown does not invent running ---
const cd = read("apps/user-frontend/src/modules/user/components/contests/CountdownTimer.vue");
if (cd.includes("refresh") && !cd.includes("status = 'running'")) {
  ok("countdown emits refresh; does not invent running");
} else {
  fail("countdown invents status or lacks refresh");
}

if (failed > 0) {
  console.error(`\ncontest-scheduling-gate: ${failed} failure(s)`);
  process.exit(1);
}
console.log("\ncontest-scheduling-gate: PASS");
process.exit(0);
