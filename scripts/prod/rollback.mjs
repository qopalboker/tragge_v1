#!/usr/bin/env node
/**
 * Production rollback — VM + Docker (no Kubernetes).
 *
 * Supports:
 *   - image tag rollback via IMAGE_TAG / previous compose project
 *   - compose down + up previous known-good
 *
 * Database: forward-fix only. Never auto-downgrade migrations.
 *
 * Env:
 *   ROLLBACK_IMAGE_TAG — previous image tag (if using pre-built images)
 *   TRAGGE_WAL_HOST_PATH — must remain the same volume (do not wipe WAL)
 *   CONFIRM=yes — required
 */
import path from "node:path";
import {
  root,
  compose,
  prodComposeArgs,
  walHostPath,
  writeEvidence,
  run,
} from "./lib.mjs";

if (process.env.CONFIRM !== "yes") {
  console.error("Set CONFIRM=yes to execute rollback");
  console.error("WAL path is preserved; migrations are NOT rolled back.");
  process.exit(2);
}

const wal = walHostPath();
const tag = process.env.ROLLBACK_IMAGE_TAG || "";
const lines = [];
lines.push(`PROD_ROLLBACK ${new Date().toISOString()}`);
lines.push(`wal_host_path=${wal}`);
lines.push(`rollback_image_tag=${tag || "(compose rebuild from git ref — set GIT_REF)"}`);
lines.push(`db_migration_rollback=NEVER_AUTO`);
lines.push(`strategy=forward_fix_app_only`);

console.log("PROD ROLLBACK");
console.log("=============");
console.log("Preserving WAL at", wal);
console.log("Database migrations will NOT be downgraded.");

// Stop app services only (keep postgres/redis/redpanda unless FULL=1)
const services = (process.env.ROLLBACK_SERVICES || "api-server,trading-core,worker,gateway")
  .split(",")
  .map((s) => s.trim())
  .filter(Boolean);

const stop = compose(["stop", ...services], prodComposeArgs, {
  env: { TRAGGE_WAL_HOST_PATH: wal },
});
lines.push(`stop_exit=${stop.status}`);
console.log(stop.stdout || stop.stderr || "");

if (process.env.GIT_REF) {
  const co = run("git", ["checkout", process.env.GIT_REF, "--", "apps", "packages", "infra/docker"], {
    timeout: 60000,
  });
  lines.push(`git_checkout_exit=${co.status}`);
}

const profileFlags = ["--profile", "app"];
if (process.env.WITH_FRONTEND === "1") {
  profileFlags.push("--profile", "frontend");
}
const up = compose(
  [...profileFlags, "up", "-d", "--build", ...services],
  prodComposeArgs,
  { env: { TRAGGE_WAL_HOST_PATH: wal, IMAGE_TAG: tag }, timeout: 600000 }
);
lines.push(`up_exit=${up.status}`);
console.log(up.stdout || "");
if (up.stderr) console.error(up.stderr);

await new Promise((r) => setTimeout(r, 20000));
const hg = run("node", [path.join(root, "scripts/prod/health-gate.mjs")], {
  env: { TRAGGE_WAL_HOST_PATH: wal },
});
lines.push(`health_gate_exit=${hg.status}`);
console.log(hg.stdout || "");

const ok = up.status === 0 && hg.status === 0;
lines.push(ok ? "ROLLBACK PASS" : "ROLLBACK FAIL");
writeEvidence("rollback-latest.txt", lines.join("\n") + "\n");
process.exit(ok ? 0 : 1);
