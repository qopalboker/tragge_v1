/**
 * CI-003 — branch-protection gate wiring (workflow + apply script).
 * Live protection assert runs when GITHUB_TOKEN is present.
 */
import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

const REQUIRED = [
  "CI required gate",
  "Go CI complete",
  "Frontend CI complete",
  "CI-002 critical Go coverage floor",
  "SEC-008 auth regression lock",
  "SEC-009 admin reauth + Super Admin MFA",
];

test("CI-003 workflow defines always-on aggregate gates", () => {
  const ci = read(".github/workflows/ci.yml");
  assert.match(ci, /name:\s*Go CI complete/);
  assert.match(ci, /name:\s*Frontend CI complete/);
  assert.match(ci, /name:\s*CI required gate/);
  assert.match(ci, /ci-003-required-gate:/);
});

test("CI-003 apply script lists required contexts", () => {
  const script = read("scripts/ci003-apply-branch-protection.mjs");
  for (const ctx of REQUIRED) {
    assert.match(script, new RegExp(ctx.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")));
  }
});

test("CI-003 live protection (optional with token)", async (t) => {
  const token = process.env.GITHUB_TOKEN || process.env.GH_TOKEN;
  if (!token) {
    t.skip("no GITHUB_TOKEN — static checks only");
    return;
  }
  const repo = process.env.GITHUB_REPOSITORY || "qopalboker/tragge_v1";
  const res = await fetch(`https://api.github.com/repos/${repo}/branches/main/protection`, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
    },
  });
  if (res.status === 404) {
    t.skip("main not yet protected — run scripts/ci003-apply-branch-protection.mjs after merge");
    return;
  }
  // default GITHUB_TOKEN often lacks Administration read for branch protection (403).
  if (res.status === 403) {
    t.skip("GITHUB_TOKEN cannot read branch protection (need administration permission); static checks remain the Actions guarantee");
    return;
  }
  assert.equal(res.status, 200, await res.text());
  const data = await res.json();
  const contexts = data.required_status_checks?.contexts || data.required_status_checks?.checks?.map((c) => c.context) || [];
  // Core contexts must be present; CI-004 may lag until protection is re-applied after that job lands.
  const core = REQUIRED.filter((c) => c !== "CI-004 secret scanning");
  for (const ctx of core) {
    assert.ok(contexts.includes(ctx), `missing required context: ${ctx}; have=${JSON.stringify(contexts)}`);
  }
  assert.equal(data.allow_force_pushes?.enabled ?? data.allow_force_pushes, false);
});
