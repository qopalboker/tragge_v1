#!/usr/bin/env node
/**
 * MVP Stability Gate — orchestrates lifecycle + trading + financial + frontend gates.
 * Exit 0 = MVP STABILITY — PASS
 */
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");

function run(label, args, timeout = 600000) {
  console.log(`\n>>> ${label}\n`);
  const r = spawnSync(process.execPath, args, {
    cwd: root,
    encoding: "utf8",
    env: process.env,
    timeout,
  });
  if (r.stdout) process.stdout.write(r.stdout);
  if (r.stderr) process.stderr.write(r.stderr);
  const ok = r.status === 0;
  console.log(ok ? `OK ${label}` : `FAIL ${label} exit=${r.status}`);
  return ok;
}

const checks = [];
checks.push(["contest-lifecycle", run("contest-lifecycle-gate", ["scripts/mvp/contest-lifecycle-gate.mjs"], 60000)]);
checks.push(["trading-cert", run("trading-certification-gate", ["scripts/mvp/trading-certification-gate.mjs"], 300000)]);
checks.push(["mvp-gate", run("mvp-gate", ["scripts/mvp/mvp-gate.mjs"], 300000)]);
checks.push(["frontend-gate", run("frontend-gate", ["scripts/mvp/frontend-gate.mjs"], 300000)]);
// acceptance can flake on Phase11 collision — soft log
const acc = run("acceptance-gate", ["scripts/mvp/acceptance-gate.mjs"], 300000);
checks.push(["acceptance-gate", acc]);

const failed = checks.filter(([, ok]) => !ok);
console.log("\n==============================");
for (const [n, ok] of checks) console.log(`${ok ? "PASS" : "FAIL"}  ${n}`);
console.log(failed.length ? "MVP STABILITY — BLOCKED" : "MVP STABILITY — PASS");
console.log("==============================");
process.exit(failed.length ? 1 : 0);
