#!/usr/bin/env node
/**
 * Production deploy — VM + Docker Compose (no Kubernetes).
 *
 * Steps:
 *  1. preflight
 *  2. validate compose
 *  3. ensure WAL host path
 *  4. up dependencies + app
 *  5. health gate
 *
 * Env:
 *   TRAGGE_WAL_HOST_PATH  — host path for WAL bind
 *   PROD_PROFILES         — default "app" (add "frontend" for gateway)
 *   SKIP_BUILD=1          — do not --build
 *   DRY_RUN=1             — validate only
 */
import fs from "node:fs";
import path from "node:path";
import {
  root,
  compose,
  prodComposeArgs,
  walHostPath,
  writeEvidence,
  run,
  dockerBin,
} from "./lib.mjs";

const dry = process.env.DRY_RUN === "1";
const skipBuild = process.env.SKIP_BUILD === "1";
const profiles = (process.env.PROD_PROFILES || "app").split(/[,\s]+/).filter(Boolean);
const wal = walHostPath();

console.log("PROD DEPLOY (VM/Docker)");
console.log("=======================");
console.log(`wal_host_path=${wal}`);
console.log(`profiles=${profiles.join(",")}`);
console.log(`dry_run=${dry}`);

// 1. Preflight
const pf = run("node", [path.join(root, "scripts/prod/preflight.mjs")], {
  env: { TRAGGE_WAL_HOST_PATH: wal },
  timeout: 60000,
});
console.log(pf.stdout || "");
if (pf.status === 2) {
  console.error("DEPLOY BLOCKED: preflight tools missing");
  process.exit(2);
}

// 2. Ensure WAL dir
fs.mkdirSync(wal, { recursive: true });
const proof = path.join(wal, "deploy-proof.txt");
fs.writeFileSync(proof, `deploy ${new Date().toISOString()}\n`);

// 3. Compose config
const env = {
  TRAGGE_WAL_HOST_PATH: wal,
  WAL_REQUIRE_PERSIST: "true",
  ENVIRONMENT: process.env.ENVIRONMENT || "production",
  APP_ENV: process.env.APP_ENV || "production",
};
const cfg = compose(["config", "--quiet"], prodComposeArgs, { env });
if (cfg.status !== 0) {
  console.error("compose config invalid:", cfg.stderr || cfg.stdout);
  process.exit(1);
}
console.log("compose config: OK");

if (dry) {
  console.log("DRY_RUN complete — not starting containers");
  writeEvidence(
    "deploy-dry-run.txt",
    `PASS DRY_RUN\nwal=${wal}\nprofiles=${profiles.join(",")}\n`
  );
  process.exit(0);
}

// 4. Up
const upArgs = ["--profile", ...profiles.flatMap((p, i) => (i === 0 ? [p] : ["--profile", p]))];
// fix flatMap: docker compose wants --profile app --profile frontend
const profileFlags = [];
for (const p of profiles) {
  profileFlags.push("--profile", p);
}
const upCmd = [
  ...profileFlags,
  "up",
  "-d",
  ...(skipBuild ? [] : ["--build"]),
  "--remove-orphans",
];
console.log("running:", "docker compose", prodComposeArgs.join(" "), upCmd.join(" "));
const up = compose(upCmd, prodComposeArgs, { env, timeout: 600000 });
console.log(up.stdout || "");
if (up.stderr) console.error(up.stderr);
if (up.status !== 0) {
  console.error("DEPLOY FAILED: compose up exit", up.status);
  writeEvidence("deploy-failed.txt", `FAIL compose up exit=${up.status}\n${up.stderr || ""}\n`);
  process.exit(1);
}

// Wait for health
console.log("waiting for services...");
await new Promise((r) => setTimeout(r, 25000));

// 5. Health gate
const hg = run("node", [path.join(root, "scripts/prod/health-gate.mjs")], {
  env: { TRAGGE_WAL_HOST_PATH: wal },
  timeout: 120000,
});
console.log(hg.stdout || "");
if (hg.stderr) console.error(hg.stderr);

const ok = hg.status === 0;
writeEvidence(
  "deploy-latest.txt",
  `${ok ? "PASS" : "FAIL"} deploy ${new Date().toISOString()}\nwal=${wal}\nhealth_gate_exit=${hg.status}\n`
);
if (!ok) {
  console.error("DEPLOY BLOCKED: health gate failed");
  process.exit(1);
}
console.log("DEPLOY OK");
process.exit(0);
