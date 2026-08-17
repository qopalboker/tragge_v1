#!/usr/bin/env node
/**
 * Production health gate — VM + Docker (no Kubernetes).
 * Exit 0 = PRODUCTION HEALTH — PASS
 * Exit 1 = BLOCKED
 */
import {
  docker,
  portOpen,
  writeEvidence,
  compose,
  localQualComposeArgs,
} from "./lib.mjs";

const checks = [];
function gate(name, ok, detail = "") {
  checks.push({ name, ok, detail });
  console.log(`${ok ? "PASS" : "FAIL"}  ${name}${detail ? " — " + detail : ""}`);
}

console.log("PRODUCTION HEALTH GATE (VM/Docker)");
console.log("==================================");

// Prefer in-container probes (works even if host ports differ)
const containers = [
  ["postgres", "tragge_postgres"],
  ["redis", "tragge_redis"],
  ["redpanda", "tragge_redpanda"],
  ["api-server", "tragge_api_server"],
  ["trading-core", "tragge_trading_core"],
  ["worker", "tragge_worker"],
];

const ps = docker(["ps", "--format", "{{.Names}} {{.Status}}"]);
const psOut = ps.stdout || "";

for (const [label, name] of containers) {
  const line = psOut.split("\n").find((l) => l.includes(name)) || "";
  const healthy = /healthy/i.test(line) || (/Up/i.test(line) && label === "redpanda");
  gate(`container_${label}`, /Up/i.test(line), line.trim().slice(0, 80));
  if (label !== "redpanda") {
    gate(`${label}_healthy_flag`, /healthy/i.test(line), line.includes("healthy") ? "healthy" : "not healthy");
  }
}

// Engine readyz + WAL
const ready = docker([
  "exec",
  "tragge_trading_core",
  "wget",
  "-qO-",
  "http://127.0.0.1:8085/readyz",
]);
const body = ready.stdout || "";
gate("trading_engine_readyz_reachable", ready.status === 0, body.slice(0, 120));
gate(
  "wal_recovery",
  ready.status === 0 && /wal_recovery/i.test(body) && /"wal_recovery"\s*:\s*"ok"/i.test(body),
  body.match(/"wal_recovery"\s*:\s*"[^"]+"/)?.[0] || "missing"
);
gate(
  "engine_status_ready",
  ready.status === 0 && /"status"\s*:\s*"ready"/i.test(body),
  body.match(/"status"\s*:\s*"[^"]+"/)?.[0] || "missing"
);
// Market data may be not ready offline — surface but do not auto-PASS production MD
const mdReady = /"market_data"\s*:\s*\{[^}]*"ready"\s*:\s*true/i.test(body);
gate(
  "market_data_observed",
  ready.status === 0,
  mdReady ? "market_data.ready=true" : "market_data.ready=false (must be true for live paid launch)"
);

// API health
const api = docker([
  "exec",
  "tragge_api_server",
  "wget",
  "-qO-",
  "http://127.0.0.1:8081/healthz",
]);
gate("api_user_bff_healthz", api.status === 0, (api.stdout || "").slice(0, 60));

// Worker presence (settlement process in same container)
const workerPs = docker(["ps", "--filter", "name=tragge_worker", "--format", "{{.Status}}"]);
gate("worker_up", /Up/i.test(workerPs.stdout || ""), (workerPs.stdout || "").trim());

// Optional gateway
const gwPort = await portOpen(8080);
gate("gateway_port_8080", gwPort, gwPort ? "open" : "closed (optional if LB elsewhere)");

// Postgres connectivity via container
const pg = docker([
  "exec",
  "tragge_postgres",
  "pg_isready",
  "-U",
  process.env.POSTGRES_ADMIN_USER || "tragge_admin",
  "-d",
  process.env.POSTGRES_DB || "app",
]);
gate("postgres_ready", pg.status === 0, (pg.stdout || pg.stderr || "").trim().slice(0, 80));

// Redis ping
const redis = docker([
  "exec",
  "tragge_redis",
  "sh",
  "-c",
  'redis-cli -a "$(cat /run/secrets/redis_password)" --no-auth-warning ping',
]);
gate("redis_ping", redis.status === 0 && /PONG/i.test(redis.stdout || ""), (redis.stdout || "").trim());

const failed = checks.filter((c) => !c.ok).length;
// Soft-allow gateway closed and market_data false for infra health of core stack
const hardFails = checks.filter(
  (c) =>
    !c.ok &&
    !["gateway_port_8080", "market_data_observed"].includes(c.name) &&
    // market_data_observed always ok if reachable — only hard-fail if we want MD
    true
).filter((c) => {
  if (c.name === "gateway_port_8080") return false;
  // MD observation always passes if we only observe; we already gate on reachable
  if (c.name === "market_data_observed") return false;
  return !c.ok;
});

// Recompute hard fails without gateway
const hard = checks.filter(
  (c) =>
    !c.ok &&
    c.name !== "gateway_port_8080"
);

// For health gate: require core services + WAL recovery; MD ready is launch-gate not health-gate
const coreRequired = [
  "container_postgres",
  "container_redis",
  "container_redpanda",
  "container_api-server",
  "container_trading-core",
  "container_worker",
  "trading_engine_readyz_reachable",
  "wal_recovery",
  "postgres_ready",
  "redis_ping",
];
const coreFail = coreRequired.some((n) => {
  const c = checks.find((x) => x.name === n);
  return !c || !c.ok;
});

const decision = coreFail ? "PRODUCTION HEALTH — BLOCKED" : "PRODUCTION HEALTH — PASS";
console.log("==================================");
console.log(decision);

const report = {
  ts: new Date().toISOString(),
  decision,
  checks,
  core_fail: coreFail,
  note:
    "market_data.ready=false is allowed for health-gate but BLOCKS launch-gate until real provider feeds",
};
writeEvidence("health-gate-latest.json", JSON.stringify(report, null, 2));
writeEvidence(
  "health-gate-latest.txt",
  checks.map((c) => `${c.ok ? "PASS" : "FAIL"}  ${c.name} ${c.detail}`).join("\n") +
    `\n\n${decision}\n`
);

process.exit(coreFail ? 1 : 0);
