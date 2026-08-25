/**
 * DOC-001 — CLAUDE.md must not claim paid-production readiness.
 * Fails on the pre-fix wording; passes after NO-GO correction.
 */
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");
const claudePath = path.join(root, "CLAUDE.md");
const auditPath = path.join(root, "docs/architecture/current-state-audit.md");
const readmePath = path.join(root, "README.md");

test("CLAUDE.md exists and is non-empty", () => {
  assert.ok(fs.existsSync(claudePath), "CLAUDE.md missing");
  const text = fs.readFileSync(claudePath, "utf8");
  assert.ok(text.length > 500, "CLAUDE.md unexpectedly short");
});

test("CLAUDE.md states paid-production NO-GO", () => {
  const text = fs.readFileSync(claudePath, "utf8");
  assert.match(text, /NO-GO/i, "CLAUDE.md must state NO-GO for paid production");
  assert.match(
    text,
    /current-state-audit\.md/,
    "CLAUDE.md must link the authoritative audit",
  );
});

test("CLAUDE.md does not claim Production-ready platform", () => {
  const text = fs.readFileSync(claudePath, "utf8");
  assert.doesNotMatch(
    text,
    /\*\*Status\*\*:\s*Production-ready platform/i,
    "CLAUDE.md must not claim Production-ready platform status",
  );
});

test("CLAUDE.md warns that PASS/FIXED reports need re-verification", () => {
  const text = fs.readFileSync(claudePath, "utf8");
  assert.match(
    text,
    /PASS\/FIXED|PASS\/FIXED labels|independently/i,
    "CLAUDE.md must warn that PASS/FIXED labels require independent re-verification",
  );
});

test("README.md and audit agree on NO-GO", () => {
  const readme = fs.readFileSync(readmePath, "utf8").replace(/\r\n/g, "\n");
  const audit = fs.readFileSync(auditPath, "utf8").replace(/\r\n/g, "\n");
  assert.match(readme, /NO-GO/);
  // Audit header is: **Paid-production decision:** **NO-GO**
  assert.match(
    audit,
    /Paid-production decision:[\s\*]*NO-GO/,
  );
});
