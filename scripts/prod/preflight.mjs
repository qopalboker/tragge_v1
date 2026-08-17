#!/usr/bin/env node
/**
 * Production preflight — VM + Docker (no Kubernetes).
 * Exit 0 = preflight recorded and platform tools present.
 * Exit 2 = critical tools missing (cannot deploy).
 */
import fs from "node:fs";
import path from "node:path";
import {
  root,
  composeDir,
  dockerBin,
  docker,
  compose,
  prodComposeArgs,
  portOpen,
  writeEvidence,
  walHostPath,
  run,
} from "./lib.mjs";

const lines = [];
const ts = new Date().toISOString();
lines.push(`PROD_PREFLIGHT ${ts}`);
lines.push(`platform=vm-docker`);
lines.push(`kubernetes_required=false`);

function rec(k, v) {
  lines.push(`${k}=${v}`);
}

// Docker
const dv = run(dockerBin, ["version", "--format", "{{.Server.Version}}"]);
const dockerOk = dv.status === 0;
rec("docker", dockerOk ? `PRESENT ${ (dv.stdout || "").trim()}` : "MISSING");

// Compose files
const baseYml = path.join(composeDir, "docker-compose.yml");
const prodYml = path.join(composeDir, "docker-compose.production.yml");
rec("compose_base", fs.existsSync(baseYml) ? "PRESENT" : "MISSING");
rec("compose_production", fs.existsSync(prodYml) ? "PRESENT" : "MISSING");

// Secrets dir
const secretsDir = path.join(composeDir, "secrets");
rec("secrets_dir", fs.existsSync(secretsDir) ? "PRESENT" : "MISSING");
const requiredSecrets = [
  "postgres_admin_password.txt",
  "postgres_app_password.txt",
  "redis_password.txt",
  "jwt_secret_user.txt",
  "jwt_secret_admin.txt",
];
let secretsOk = true;
for (const s of requiredSecrets) {
  const ok = fs.existsSync(path.join(secretsDir, s));
  rec(`secret_${s}`, ok ? "PRESENT" : "MISSING");
  if (!ok) secretsOk = false;
}

// WAL host path
const wal = walHostPath();
rec("wal_host_path", wal);
let walOk = false;
try {
  fs.mkdirSync(wal, { recursive: true });
  const probe = path.join(wal, ".prod-preflight-write");
  fs.writeFileSync(probe, ts);
  walOk = fs.existsSync(probe);
  rec("wal_host_writable", walOk ? "true" : "false");
} catch (e) {
  rec("wal_host_writable", `false:${e.message}`);
}

// Compose config validate (production files)
const cfg = compose(["config", "--quiet"], prodComposeArgs, {
  env: { TRAGGE_WAL_HOST_PATH: wal, WAL_REQUIRE_PERSIST: "true" },
});
rec("compose_config_valid", cfg.status === 0 ? "true" : `false:${(cfg.stderr || "").slice(0, 120)}`);

// Optional live ports (local or prod host)
const ports = {
  postgres: 5432,
  redis: 6379,
  kafka: 9092,
  gateway: 8080,
  engine_host_map: 8093,
};
for (const [name, port] of Object.entries(ports)) {
  // eslint-disable-next-line no-await-in-loop
  const open = await portOpen(port);
  rec(`port_${port}_${name}`, open ? "open" : "closed");
}

// Container health if running
const ps = docker(["ps", "--format", "{{.Names}}\t{{.Status}}"]);
rec("docker_ps_exit", String(ps.status));
if (ps.status === 0) {
  for (const name of [
    "tragge_postgres",
    "tragge_redis",
    "tragge_redpanda",
    "tragge_api_server",
    "tragge_trading_core",
    "tragge_worker",
  ]) {
    const line = (ps.stdout || "")
      .split("\n")
      .find((l) => l.includes(name));
    rec(`container_${name}`, line ? line.trim() : "not_running");
  }
}

// Trading readiness if container up
const ready = docker([
  "exec",
  "tragge_trading_core",
  "wget",
  "-qO-",
  "http://127.0.0.1:8085/readyz",
]);
if (ready.status === 0) {
  const body = (ready.stdout || "").trim();
  rec("trading_readyz", body.slice(0, 300));
  rec("wal_recovery_ok", body.includes("wal_recovery") && /ok|success/i.test(body) ? "true" : "false");
} else {
  rec("trading_readyz", "unavailable");
}

const toolsOk = dockerOk && fs.existsSync(baseYml) && fs.existsSync(prodYml);
const criticalOk = toolsOk && secretsOk && walOk && cfg.status === 0;
rec("preflight_tools_ok", toolsOk ? "true" : "false");
rec("preflight_critical_ok", criticalOk ? "true" : "false");
rec(
  "note",
  criticalOk
    ? "tools+compose+wal path OK — still need live health, providers, backup for GO"
    : "BLOCKED — fix docker/compose/secrets/WAL path before deploy"
);

const out = lines.join("\n") + "\n";
console.log(out);
writeEvidence("preflight-latest.txt", out);
writeEvidence(`preflight-${ts.slice(0, 10)}.txt`, out);

process.exit(toolsOk ? 0 : 2);
