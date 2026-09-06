import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";

import {
  repositoryRoot,
  validateMarkdownFiles,
} from "./production-baseline.mjs";

const glossaryPath =
  "docs/product/canonical-domain-glossary-and-version-catalog.md";
const policyPath = "docs/product/FIXED_PRODUCT_AND_TECHNICAL_POLICIES.md";
const roadmapPath = "docs/codex/PRODUCTION_ROADMAP_AND_CODEX_TASKS.md";
const adrPath = "docs/adr/0001-target-runtime-architecture.md";
const contractsReadmePath = "packages/contracts/README.md";

const expectedTerms = [
  "Platform Modular Monolith",
  "Platform API runtime",
  "Platform Realtime runtime",
  "Platform Worker runtime",
  "Trading Engine",
  "Market Data Service",
  "Contest",
  "Contest Template",
  "Scheduler Template Version",
  "Custom Contest",
  "Upcoming",
  "Registration Open",
  "Running",
  "Join Cutoff",
  "Late Entry",
  "Real Participant",
  "Free Practice Contest",
  "System Participant",
  "Participant Capacity",
  "Quantity (unqualified)",
  "Trading QTY",
  "Base Entry Fee",
  "Late-Entry Surcharge",
  "Platform Fee",
  "Prize Pool",
  "Effective Participant Count",
  "Effective Prize Pool",
  "Effective Planned Winners",
  "Gross Prize",
  "Economics Lock",
  "Filled Trade",
  "Planned Winners",
  "Eligible Users",
  "Actual Winners",
  "Rank Band",
  "Reward Weight",
  "T-Score",
  "Official Ranking",
  "Rank 0",
  "Unawarded Prize",
  "Commission Rate",
  "Wallet",
  "Available Balance",
  "Reserved Balance",
  "Double-Entry Ledger",
  "Settlement",
  "Settlement Review",
  "Leaderboard Projection",
  "Reconciliation",
  "Provider",
  "Asset Group",
  "Symbol",
  "Price Quality",
  "Source Epoch",
  "Stale Price",
  "Paused Symbol",
  "Degraded Feed",
  "Outbox",
  "Inbox",
  "Idempotency Key",
  "Immutable Snapshot",
  "Replay",
  "Support Admin",
  "Super Admin",
  "Super Admin Wallet",
  "Contest Fee Wallet",
  "Sensitive-Action Password Reauthentication",
  "Reauthentication Grant",
  "Super Admin MFA",
  "KYC",
  "Deposit",
  "Withdrawal",
  "Second Chance",
];

const expectedCatalogItems = [
  "Fixed product-policy document",
  "Production roadmap",
  "Target architecture ADR",
  "Contest policy ruleset",
  "Contest funds and participant lifecycle",
  "Scheduler Template Version",
  "Symbol registry",
  "Scoring / T-Score rules",
  "Prize distribution",
  "Money and rate representation",
  "Canonical money minor units",
  "Canonical price/rate/PnL/score",
  "Contest economics snapshot",
  "Legacy shared event schemas",
  "Market Data event contract",
  "Trading Engine command/event contracts",
  "Settlement result snapshot",
  "Outbox/inbox event envelope",
  "Payment-provider retirement decision",
  "User/Admin authentication isolation",
  "Sensitive-action reauthentication contract",
  "Super Admin MFA contract",
  "REST API contracts",
  "WebSocket contracts",
  "Database schema/migration baseline",
];

function read(relativePath) {
  return fs.readFileSync(path.join(repositoryRoot, relativePath), "utf8");
}

function glossaryRows(markdown) {
  return new Map(
    [...markdown.matchAll(/^\| \*\*([^*]+)\*\* \| (.+) \|$/gm)].map(
      (match) => [match[1], match[2]],
    ),
  );
}

function versionRows(markdown) {
  const match = markdown.match(
    /## Version catalog\r?\n[\s\S]+?\r?\n\| Versioned item [\s\S]+?\r?\n\r?\n## Repository terminology remediation register/,
  );
  assert.ok(match, "version catalog table is missing");
  const lines = match[0].split(/\r?\n/);
  const rows = new Map();
  for (const line of lines) {
    if (!line.startsWith("| ") || line.startsWith("| Versioned item")) {
      continue;
    }
    if (/^\|[-|]+\|$/.test(line.replaceAll(" ", ""))) {
      continue;
    }
    const cells = line
      .slice(1, -1)
      .split("|")
      .map((cell) => cell.trim());
    if (cells.length === 4) {
      rows.set(cells[0], {
        identifier: cells[1],
        status: cells[2],
        owner: cells[3],
      });
    }
  }
  return rows;
}

function walkTextFiles(relativeDirectory) {
  const root = path.join(repositoryRoot, relativeDirectory);
  const files = [];
  function walk(directory) {
    for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
      const absolute = path.join(directory, entry.name);
      if (entry.isDirectory()) {
        walk(absolute);
      } else if (entry.isFile()) {
        files.push(absolute);
      }
    }
  }
  walk(root);
  return files;
}

test("canonical glossary defines every required term exactly once", () => {
  const rows = glossaryRows(read(glossaryPath));
  assert.equal(rows.size, expectedTerms.length);
  assert.deepEqual([...rows.keys()].sort(), [...expectedTerms].sort());
  for (const [term, definition] of rows) {
    assert.ok(definition.length >= 40, `${term} definition is too weak`);
  }
});

test("collision rules preserve policy meanings", () => {
  const glossary = read(glossaryPath);
  const rows = glossaryRows(glossary);

  assert.match(rows.get("Participant Capacity"), /does not exist/);
  assert.match(rows.get("Quantity (unqualified)"), /prohibited/);
  assert.match(rows.get("Quantity (unqualified)"), /Trading QTY/);
  assert.match(rows.get("Trading QTY"), /never means participant count/);
  assert.match(rows.get("Reward Weight"), /is not T-Score/);
  assert.match(rows.get("T-Score"), /must not name Reward Weight/);
  assert.match(rows.get("Platform Fee"), /platform_fee_bps = 2000/);
  assert.match(rows.get("Commission Rate"), /Deprecated/);
  assert.match(rows.get("Gross Prize"), /deprecated ambiguous label/);
  assert.match(rows.get("Leaderboard Projection"), /does not own Settlement/);
  assert.match(rows.get("System Participant"), /not a real user/);
  assert.match(rows.get("System Participant"), /never prize/);
  assert.match(rows.get("Support Admin"), /support and KYC/);
  assert.match(rows.get("Super Admin"), /alone may execute approved destructive financial operations/);
  assert.match(rows.get("Sensitive-Action Password Reauthentication"), /SEC-004/);
  assert.match(rows.get("Sensitive-Action Password Reauthentication"), /distinct from login MFA/);
  assert.match(rows.get("Reauthentication Grant"), /short-lived, single-use/);
  assert.match(rows.get("Super Admin MFA"), /implemented `SEC-007`/);
  assert.match(rows.get("Super Admin MFA"), /super_admin_totp_v1/);

  assert.match(rows.get("Base Entry Fee"), /20%.*80%/);
  assert.match(rows.get("Late-Entry Surcharge"), /10%/);
  assert.match(rows.get("Prize Pool"), /ledger-backed financial allocation/);
  assert.match(rows.get("Prize Pool"), /custody returns to Super Admin Wallet/);
  assert.match(rows.get("Actual Winners"), /effective planned rank schedule/);
  assert.match(rows.get("Actual Winners"), /do not renormalize/);
  assert.match(rows.get("Rank 0"), /qualifying Filled Trade/);
  assert.match(rows.get("Contest Fee Wallet"), /Super-Admin-only/);
  assert.ok(glossary.includes("`tralent_v1`"));
});

test("Second Chance is only documented as removed and has no active code", () => {
  const glossaryLines = read(glossaryPath)
    .split(/\r?\n/)
    .filter((line) => /Second Chance/i.test(line));
  assert.ok(glossaryLines.length >= 3);
  for (const line of glossaryLines) {
    assert.match(
      line,
      /removed|must not|prohibited|Keep removed|prohibitions|release-blocking regression/i,
    );
  }

  for (const file of [
    ...walkTextFiles("apps"),
    ...walkTextFiles("packages"),
  ]) {
    const contents = fs.readFileSync(file, "utf8");
    assert.doesNotMatch(
      contents,
      /second[_ -]chance/i,
      `active Second Chance reference: ${path.relative(repositoryRoot, file)}`,
    );
  }
});

test("version catalog distinguishes current, planned, and legacy versions", () => {
  const rows = versionRows(read(glossaryPath));
  assert.deepEqual([...rows.keys()].sort(), [...expectedCatalogItems].sort());

  assert.equal(rows.get("Fixed product-policy document").identifier, "`2026-09-06.1`");
  assert.match(rows.get("Fixed product-policy document").status, /in review; pending human approval/);
  assert.equal(rows.get("Production roadmap").identifier, "`2026-09-06.1`");
  assert.equal(rows.get("Target architecture ADR").identifier, "`ADR-0001`");
  assert.equal(rows.get("Prize distribution").identifier, "`tralent_v1`");
  assert.match(rows.get("Contest funds and participant lifecycle").status, /in review; pending human approval/);
  assert.equal(rows.get("Market Data event contract").identifier, "`v2`");
  assert.equal(rows.get("Payment-provider retirement decision").identifier, "`PAYMENT4-RETIREMENT-2026-08-01`");
  assert.match(rows.get("Payment-provider retirement decision").status, /current product decision/);
  assert.match(rows.get("Legacy shared event schemas").status, /legacy/);
  assert.match(rows.get("User/Admin authentication isolation").status, /current implementation/);
  assert.match(rows.get("User/Admin authentication isolation").identifier, /No public contract version assigned/);
  assert.match(rows.get("Sensitive-action reauthentication contract").identifier, /Not assigned/);
  assert.match(rows.get("Sensitive-action reauthentication contract").status, /current local implementation/);
  assert.equal(rows.get("Super Admin MFA contract").identifier, "`super_admin_totp_v1`");
  assert.match(rows.get("Super Admin MFA contract").status, /current implementation/);

  for (const item of [
    "Scheduler Template Version",
    "Symbol registry",
    "Scoring / T-Score rules",
    "Money and rate representation",
    "Contest economics snapshot",
    "Trading Engine command/event contracts",
    "Settlement result snapshot",
    "Outbox/inbox event envelope",
    "REST API contracts",
    "WebSocket contracts",
    "Database schema/migration baseline",
  ]) {
    assert.match(rows.get(item).identifier, /Not assigned|not assigned/);
    assert.match(rows.get(item).status, /planned/);
  }
});

test("every referenced roadmap task and repository path resolves", () => {
  const glossary = read(glossaryPath);
  const roadmap = read(roadmapPath);
  const taskIds = new Set(
    glossary.match(
      /\b(?:FND|ARCH|DATA|CON|PRIZE|ENG|MD|FE|SCH|SEC|PAY|OPS|REL)-\d{3}\b/g,
    ) ?? [],
  );
  assert.ok(taskIds.size >= 20);
  for (const taskId of taskIds) {
    assert.match(roadmap, new RegExp(`^### ${taskId} `, "m"), taskId);
  }

  const links = validateMarkdownFiles(
    [glossaryPath, contractsReadmePath],
    repositoryRoot,
  );
  assert.deepEqual(links.missing, []);
  assert.ok(links.checkedLinks >= 30);
});

test("architecture names and runtime modes agree with Accepted ADR-0001", () => {
  const glossary = read(glossaryPath);
  const adr = read(adrPath);
  for (const name of [
    "Platform Modular Monolith",
    "Trading Engine",
    "Market Data Service",
  ]) {
    assert.match(glossary, new RegExp(name, "i"));
    assert.match(adr, new RegExp(name, "i"));
  }
  for (const mode of ["api", "realtime", "worker"]) {
    const expression = new RegExp(`platform --mode=${mode}`);
    assert.match(glossary, expression);
    assert.match(adr, expression);
  }
});

test("financial terminology and contract README do not bless legacy floats", () => {
  const glossary = read(glossaryPath);
  const policy = read(policyPath);
  const contractsReadme = read(contractsReadmePath);

  for (const required of [
    "platform_fee_bps = 2000",
    "commission_rate",
    "integer minor units",
    "integer basis points",
    "fixed-point",
    "tralent_v1",
  ]) {
    assert.ok(policy.includes(required), `policy missing ${required}`);
    assert.ok(glossary.includes(required), `glossary missing ${required}`);
  }

  assert.ok(contractsReadme.includes("Legacy compatibility status"));
  assert.ok(contractsReadme.includes("Legacy v1 prices"));
  assert.ok(contractsReadme.includes("Trading QTY"));
  assert.doesNotMatch(contractsReadme, /\*\*Prices\*\* are always float64/);
});

test("POLICY-001 preserves custody and effective-economics invariants", () => {
  const policy = read(policyPath);
  const catalog = versionRows(read(glossaryPath));
  for (const required of [
    "user entitlement debit = total successful contest entry charge",
    "contest join Super Admin Wallet debit = Contest Prize Pool credit + Contest Fee Wallet credit",
    "effective settlement economics",
    "= immutable cutoff snapshot + authorized append-only adjustments",
    "settlement effective Prize Pool = winner liabilities/payouts + unawarded residual",
    "Contest Prize Pool custodial balance = 0",
    "In review — POLICY-001 pending human approval/merge",
  ]) {
    assert.ok(policy.includes(required), `POLICY-001 missing ${required}`);
  }
  assert.match(catalog.get("Fixed product-policy document").status, /in review; pending human approval/);
  assert.match(catalog.get("Contest funds and participant lifecycle").status, /in review; pending human approval/);
});

test("FND-003 Markdown has clean baseline style", () => {
  for (const file of [glossaryPath, contractsReadmePath]) {
    const markdown = read(file);
    assert.doesNotMatch(markdown, /\t/);
    for (const [index, line] of markdown.split(/\r?\n/).entries()) {
      assert.doesNotMatch(
        line,
        /[ \t]+$/,
        `${file}:${index + 1} has trailing whitespace`,
      );
    }
  }
});
