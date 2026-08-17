#!/usr/bin/env node
/**
 * Phase 5-Lite local Docker Compose qualification gate.
 * Does NOT claim Kubernetes readiness or production GO.
 *
 * Exit 0 = LOCAL STAGING — QUALIFIED
 * Exit 1 = LOCAL STAGING — BLOCKED
 */

import { spawnSync } from "node:child_process";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const dockerBin =
  process.env.DOCKER_BIN ||
  (process.platform === "win32"
    ? "C:\\Users\\parsa\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe"
    : "docker");
const composeDir = path.join(root, "infra/docker");
const composeFiles = [
  "-f",
  "docker-compose.yml",
  "-f",
  "docker-compose.lite.yml",
  "-f",
  "docker-compose.override.yml",
];

function portOpen(port) {
  return new Promise((resolve) => {
    const s = net.connect({ port, host: "127.0.0.1" });
    const t = setTimeout(() => {
      s.destroy();
      resolve(false);
    }, 800);
    s.on("connect", () => {
      clearTimeout(t);
      s.end();
      resolve(true);
    });
    s.on("error", () => {
      clearTimeout(t);
      resolve(false);
    });
  });
}

function run(cmd, args, opts = {}) {
  return spawnSync(cmd, args, {
    encoding: "utf8",
    shell: false,
    cwd: opts.cwd || root,
    env: { ...process.env, ...(opts.env || {}), Path: process.env.Path || process.env.PATH },
  });
}

function docker(args) {
  return run(dockerBin, args, { cwd: composeDir });
}

let failed = 0;
function gate(name, ok, detail = "") {
  console.log(`${ok ? "PASS" : "FAIL"}  ${name}${detail ? " — " + detail : ""}`);
  if (!ok) failed++;
}

console.log("PHASE 5-LITE COMPOSE GATE");
console.log("=========================");

const dv = run(dockerBin, ["--version"]);
gate("docker available", dv.status === 0, (dv.stdout || "").trim());

const ports = {
  postgres: await portOpen(5432),
  redis: await portOpen(6379),
  kafka: await portOpen(9092),
  trade_bff: await portOpen(8085),
  admin_bff: await portOpen(8083),
};
gate("postgres :5432", ports.postgres);
gate("redis :6379", ports.redis);
gate("redpanda kafka :9092", ports.kafka);
gate("trade-bff :8085", ports.trade_bff);
gate("api/admin :8083", ports.admin_bff);

const ps = docker(["compose", ...composeFiles, "--profile", "app", "ps", "--format", "json"]);
let healthy = { trading_core: false, worker: false, api_server: false };
if (ps.status === 0 && ps.stdout) {
  const lines = ps.stdout
    .trim()
    .split("\n")
    .filter(Boolean)
    .map((l) => {
      try {
        return JSON.parse(l);
      } catch {
        return null;
      }
    })
    .filter(Boolean);
  for (const row of lines) {
    const name = row.Name || row.Service || "";
    const st = row.Status || row.State || "";
    if (name.includes("trading_core") && /healthy|Up/i.test(st)) healthy.trading_core = true;
    if (name.includes("worker") && /healthy|Up/i.test(st)) healthy.worker = true;
    if (name.includes("api_server") && /healthy|Up/i.test(st)) healthy.api_server = true;
  }
}
gate("trading-core container healthy", healthy.trading_core);
gate("worker container healthy", healthy.worker);
gate("api-server container healthy", healthy.api_server);

// WAL named volume exists
const vols = docker(["volume", "ls", "--format", "{{.Name}}"]);
gate(
  "trading_core_wal named volume",
  (vols.stdout || "").includes("trading_core_wal")
);

// WAL file survives (proof file)
const walProof = docker([
  "exec",
  "tragge_trading_core",
  "sh",
  "-c",
  "test -f /var/lib/tragge/wal/phase5lite.proof && cat /var/lib/tragge/wal/phase5lite.proof",
]);
gate(
  "WAL volume content after recreate",
  walProof.status === 0 && (walProof.stdout || "").includes("wal-persist-proof"),
  (walProof.stdout || walProof.stderr || "").trim().slice(0, 80)
);

// Engine readyz inside container
const ready = docker([
  "exec",
  "tragge_trading_core",
  "wget",
  "-qO-",
  "http://127.0.0.1:8085/readyz",
]);
gate(
  "trading-engine readyz (in-container)",
  ready.status === 0 && (ready.stdout || "").includes("ready"),
  (ready.stdout || "").slice(0, 120)
);

// Migrations / financial / trading regressions against Compose Postgres
const passFile = path.join(composeDir, "secrets/postgres_admin_password.txt");
let pass = "";
if (fs.existsSync(passFile)) pass = fs.readFileSync(passFile, "utf8").trim();
const dsn = `postgres://tragge_admin:${pass}@127.0.0.1:5432/app?sslmode=disable`;
const testEnv = { TRAGGE_E2E_DATABASE_URL: dsn };

const fin = run(
  "go",
  ["test", "./packages/wallet/", "-count=1", "-timeout", "120s", "-run", "Phase11|TestPhase3_Backup"],
  { env: testEnv }
);
gate("Phase 1 financial E2E (Compose PG)", fin.status === 0);

const tr = run(
  "go",
  [
    "test",
    "./apps/trading-engine/server/",
    "-count=1",
    "-timeout",
    "180s",
    "-run",
    "TestPhase2_E2E_TradingToSettlement|TestPhase2_E2E_RestartWALRecovery|TestPhase3_WALPVC",
  ],
  { env: testEnv }
);
gate("Phase 2 trading E2E + WAL (Compose PG)", tr.status === 0);

// Compose-mode preflight
const pf = run("node", [path.join(root, "scripts/phase4/preflight.mjs")], {
  env: { STAGING_PLATFORM: "compose" },
});
const pfOut = (pf.stdout || "") + (pf.stderr || "");
gate(
  "compose preflight live_compose_qualification_possible",
  pfOut.includes("live_compose_qualification_possible=true"),
  pfOut.includes("live_compose_qualification_possible=true") ? "true" : "false"
);
// Must NOT claim k8s live
gate(
  "does not claim Kubernetes live readiness",
  !pfOut.includes("live_qualification_possible=true") ||
    pfOut.includes("live_qualification_possible=false")
);

const evidenceDir = path.join(root, "docs/codex/reports/evidence/phase5lite");
fs.mkdirSync(evidenceDir, { recursive: true });
const summary = {
  ts: new Date().toISOString(),
  failed,
  decision: failed === 0 ? "LOCAL STAGING — QUALIFIED" : "LOCAL STAGING — BLOCKED",
};
fs.writeFileSync(
  path.join(evidenceDir, "compose-gate-latest.json"),
  JSON.stringify(summary, null, 2)
);

console.log("=========================");
console.log(summary.decision);
process.exit(failed === 0 ? 0 : 1);
