/**
 * MD-005A — Admin Forex/Crypto provider selection defaults + audit wiring.
 * Full AUTO/FORCE/PAUSE remains MD-005/MD-006 (out of scope).
 */
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("MD-005A migration defaults forex=deriv and keeps crypto=nobitex", () => {
  const mig = read("packages/db/migrations/0114_md005a_forex_provider_default_deriv.up.sql");
  assert.match(mig, /active_provider = 'deriv'/);
  assert.match(mig, /asset_class = 'forex'/);
  assert.match(mig, /asset_class = 'crypto'/);
  assert.match(mig, /active_provider = 'nobitex'/);
});

test("MD-005A admin-bff allows deriv for forex switches", () => {
  const h = read("apps/admin-bff/server/handlers_market.go");
  assert.match(h, /body\.Provider != "deriv"/);
  assert.match(h, /market\.switch_forex_provider/);
  assert.match(h, /market\.switch_crypto_provider/);
  assert.match(h, /X-Actor-User-Id/);
  assert.match(h, /asset_class": "forex"/);
  assert.match(h, /asset_class": "crypto"/);
});

test("MD-005A market-ingestor persists forex and reloads from DB", () => {
  const app = read("apps/market-ingestor/server/app.go");
  assert.match(app, /persistProviderConfig/);
  assert.match(app, /asset_class = 'forex'/);
  assert.match(app, /Loaded forex provider from DB|Forex provider already matches DB/);
  assert.match(app, /X-Actor-User-Id/);
  // Defaults remain deriv/nobitex in env bootstrap paths
  assert.match(app, /CRYPTO_PROVIDER/);
  assert.match(app, /MARKET_PROVIDER/);
});

test("MD-005A admin UI labels Deriv and prefers it in forex fallback list", () => {
  const en = read("apps/admin-frontend/src/i18n/locales/en.ts");
  const page = read("apps/admin-frontend/src/modules/admin/views/SymbolsPage.vue");
  assert.match(en, /deriv:\s*'Deriv'/);
  assert.match(en, /Default Forex\/commodity provider/);
  assert.match(page, /\['deriv',\s*'massive',\s*'twelvedata',\s*'finnhub'\]/);
  assert.match(page, /switchForexProvider/);
  assert.match(page, /switchCryptoProvider/);
});

test("MD-005A does not implement AUTO/FORCE/PAUSE lifecycle here", () => {
  const h = read("apps/admin-bff/server/handlers_market.go");
  assert.doesNotMatch(h, /FORCE_PROVIDER|PAUSE_SYMBOL|AUTO_SELECT/);
});
