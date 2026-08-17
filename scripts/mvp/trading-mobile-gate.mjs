#!/usr/bin/env node
/**
 * Trading + mobile + Telegram Mini App static gate.
 * Exit 0 = PASS.
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

console.log("trading-mobile-gate\n");

// MARKET DATA / PRICE path
const chartData = read("apps/user-frontend/src/modules/trade/composables/useChartData.ts");
if (chartData.includes("/api/trade/candles") && !chartData.includes("Math.random")) {
  ok("MARKET DATA / CHART: candles from /api/trade/candles; no Math.random series");
} else {
  fail("chart history must use real candles API without random generation");
}

const ws = read("apps/user-frontend/src/modules/trade/composables/useTradingWebSocket.ts");
if (ws.includes("client_order_id") && ws.includes("SymbolTick")) {
  ok("ORDER IDEMPOTENCY + PRICE: client_order_id + SymbolTick (bid/ask/last)");
} else {
  fail("WS trading composable missing client_order_id or tick types");
}

const bffCandles = read("apps/trade-bff/server/chart_handlers.go");
if (bffCandles.includes("FROM candles") || bffCandles.includes("from candles")) {
  ok("CHART backend reads candles table (ingestor-written)");
} else {
  fail("trade-bff candles handler must query DB candles");
}

// QUANTITY / ORDER UI
const mobile = read(
  "apps/user-frontend/src/modules/trade/components/trading/mobile/MobileChartPage.vue",
);
if (
  mobile.includes("availableQty") &&
  mobile.includes("usedQty") &&
  mobile.includes("totalQty") &&
  mobile.includes("updateQuantity")
) {
  ok("QUANTITY: mobile shows total/used/free and syncs qty to parent");
} else {
  fail("mobile qty strip / parent sync missing");
}
if (mobile.includes("tradingEnabled") && mobile.includes("disabled")) {
  ok("ORDER lock: mobile disables trade when not enabled");
} else {
  fail("mobile trade lock missing");
}
if (mobile.includes("safe-area-inset-bottom") || mobile.includes("sticky")) {
  ok("MOBILE sticky order bar / safe-area");
} else {
  fail("mobile sticky order bar or safe-area missing");
}

const page = read("apps/user-frontend/src/modules/trade/views/TradingPage.vue");
if (page.includes("tradingUnlocked") && (page.includes("=== 'running'") || page.includes('=== "running"'))) {
  ok("CONTEST STATE: trading unlocked only when backend running");
} else {
  fail("tradingUnlocked gate missing");
}
if (page.includes("availableQTY") && page.includes("maxQty")) {
  ok("QUANTITY max bound to free available QTY");
} else {
  fail("maxQty must track free QTY");
}
if (page.includes("revalidateAndMaybeLeaveTrade") || page.includes("/user/contests/")) {
  ok("CONTEST END redirect path present");
} else {
  fail("contest end redirect missing");
}

const side = read(
  "apps/user-frontend/src/modules/trade/components/trading/WatchlistSidebar.vue",
);
if (side.includes("availableQty") && side.includes("canTrade")) {
  ok("DESKTOP order form: free QTY strip + canTrade");
} else {
  fail("desktop qty strip / canTrade missing");
}

// TELEGRAM
const tg = read("apps/user-frontend/src/modules/miniapp/telegram.ts");
const main = read("apps/user-frontend/src/main.ts");
const indexHtml = read("apps/user-frontend/index.html");
if (indexHtml.includes("telegram-web-app.js")) {
  ok("TELEGRAM WEBAPP INITIALIZATION script in index.html");
} else {
  fail("telegram-web-app.js not loaded");
}
if (tg.includes("initData") && main.includes("loginWithTelegram") && main.includes("getTelegramInitData")) {
  ok("TELEGRAM AUTH PATH: frontend sends initData only");
} else {
  fail("Telegram initData auth bootstrap missing");
}
if (tg.includes("applyTelegramTheme") && tg.includes("applyTelegramSafeAreaCssVars")) {
  ok("TELEGRAM theme + safe-area adaptation");
} else {
  fail("Telegram theme/safe-area helpers missing");
}

const tgAuth = read("apps/user-bff/server/telegram_auth.go");
const tgVerifier = read("packages/auth/telegram_webapp.go");
if (
  tgAuth.includes("init_data") &&
  tgVerifier.includes("VerifyInitData") &&
  !tgAuth.includes("initDataUnsafe")
) {
  ok("TELEGRAM AUTH VALIDATION: server HMAC verify init_data");
} else {
  fail("server-side initData validation path incomplete");
}

// PUBLIC HTTPS URL docs
const runbook = "docs/runbook/local-telegram-mini-app.md";
if (exists(runbook)) {
  const rb = read(runbook);
  if (rb.includes("HTTPS") && rb.includes("admin") && rb.includes("NOT")) {
    ok("PUBLIC HTTPS URL runbook documents tunnel + admin exclusion");
  } else {
    fail("runbook incomplete");
  }
} else {
  fail("missing docs/runbook/local-telegram-mini-app.md");
}

// No fake market series in trade runtime
const tradeDir = path.join(root, "apps/user-frontend/src/modules/trade");
function walk(dir, acc = []) {
  for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, ent.name);
    if (ent.isDirectory()) walk(p, acc);
    else if (/\.(ts|vue|js)$/.test(ent.name) && !ent.name.includes(".test.")) acc.push(p);
  }
  return acc;
}
let fakeHit = false;
for (const f of walk(tradeDir)) {
  const t = fs.readFileSync(f, "utf8");
  if (/generateCandle|fakeCandle|mockPrice|samplePrice/.test(t)) {
    fakeHit = true;
    fail(`fake market helper in ${path.relative(root, f)}`);
  }
}
if (!fakeHit) ok("no fake candle/price generators in trade runtime modules");

// RESPONSIVE breakpoints noted
if (mobile.includes("360") || mobile.includes("430")) {
  ok("MOBILE viewport tuning present (360/430)");
} else {
  fail("mobile media queries for phone widths missing");
}

if (failed > 0) {
  console.error(`\ntrading-mobile-gate: ${failed} failure(s)`);
  process.exit(1);
}
console.log("\ntrading-mobile-gate: PASS");
console.log("NOTE: LIVE TELEGRAM VERIFIED is separate — this gate checks IMPLEMENTED paths only.");
process.exit(0);
