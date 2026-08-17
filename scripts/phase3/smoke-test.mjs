#!/usr/bin/env node
/**
 * Phase 3 production smoke test (deployment functional gate)
 *
 * Checks HTTP health/readiness of critical endpoints when URLs are provided,
 * and always runs offline Phase 1/2 regression packages as a minimum gate.
 *
 * Env (optional HTTP):
 *   SMOKE_ENGINE_URL=http://127.0.0.1:8085
 *   SMOKE_TRADE_BFF_URL=http://127.0.0.1:8082
 *   SMOKE_USER_BFF_URL=http://127.0.0.1:8081
 *   SMOKE_WORKER_SETTLEMENT_URL=http://127.0.0.1:8087
 */

import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
let failed = 0;

function log(msg) {
  console.log(`[smoke] ${msg}`);
}

async function httpCheck(name, base, pathSuffix) {
  if (!base) {
    log(`SKIP ${name} (URL not set)`);
    return;
  }
  const url = base.replace(/\/$/, "") + pathSuffix;
  try {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), 5000);
    const res = await fetch(url, { signal: ctrl.signal });
    clearTimeout(t);
    if (res.ok) {
      log(`PASS ${name} ${pathSuffix} → ${res.status}`);
    } else {
      log(`FAIL ${name} ${pathSuffix} → ${res.status}`);
      failed++;
    }
  } catch (e) {
    log(`FAIL ${name} ${pathSuffix}: ${e.message}`);
    failed++;
  }
}

function goTest(pkg, run) {
  const args = ["test", pkg, "-count=1", "-timeout", "120s"];
  if (run) args.push("-run", run);
  log(`go ${args.join(" ")}`);
  // shell:false so Windows does not treat | in -run as a pipe
  const r = spawnSync("go", args, {
    cwd: root,
    encoding: "utf8",
    shell: false,
  });
  if (r.status !== 0) {
    process.stdout.write(r.stdout || "");
    process.stderr.write(r.stderr || "");
    log(`FAIL ${pkg}`);
    failed++;
  } else {
    log(`PASS ${pkg}${run ? " " + run : ""}`);
  }
}

log("Phase 3 smoke starting");

// Offline correctness gates (always)
goTest("./apps/trading-engine/server/", "TestPhase3_WALPVCRescheduleSimulation|TestPhase2_E2E|TestWAL_");
goTest("./packages/wallet/", "Phase11|Locked|Idempotent");
goTest("./packages/scoring/economics/", "");
goTest("./apps/settlement-service/server/", "");

// HTTP when deployed
await httpCheck("trading-engine", process.env.SMOKE_ENGINE_URL, "/healthz");
await httpCheck("trading-engine", process.env.SMOKE_ENGINE_URL, "/readyz");
await httpCheck("trade-bff", process.env.SMOKE_TRADE_BFF_URL, "/healthz");
await httpCheck("user-bff", process.env.SMOKE_USER_BFF_URL, "/healthz");
await httpCheck("settlement", process.env.SMOKE_WORKER_SETTLEMENT_URL, "/healthz");

if (failed > 0) {
  log(`SMOKE FAILED (${failed} checks)`);
  process.exit(1);
}
log("SMOKE PASS");
process.exit(0);
