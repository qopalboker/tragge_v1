#!/usr/bin/env node
/**
 * Creates one durable settled contest on Compose Postgres for reconciliation evidence.
 * Does not clean up (operator may inspect rows).
 */
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import crypto from "node:crypto";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const dockerBin =
  process.env.DOCKER_BIN ||
  (process.platform === "win32"
    ? "C:\\Users\\parsa\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe"
    : "docker");
const passFile = path.join(root, "infra/docker/secrets/postgres_admin_password.txt");
const pass = fs.readFileSync(passFile, "utf8").trim();
const evidenceDir = path.join(root, "docs/codex/reports/evidence/phase4.1lite");
fs.mkdirSync(evidenceDir, { recursive: true });

const uuid = () => crypto.randomUUID();
const contestId = uuid();
const users = [uuid(), uuid(), uuid()];
const entry = 10000;
const bps = 2000;
const gross = entry * users.length;
const fee = Math.floor((gross * bps) / 10000);
const net = gross - fee;
const payouts = [
  Math.floor(net * 0.5),
  Math.floor(net * 0.3),
  net - Math.floor(net * 0.5) - Math.floor(net * 0.3),
];
const settlementId = uuid();

const lines = ["BEGIN;"];
for (let i = 0; i < users.length; i++) {
  const uid = users[i];
  const email = `p41lite-${i}-${uid.slice(0, 8)}@example.com`;
  lines.push(
    `INSERT INTO users (id, email, password_hash, email_verified, terms_accepted_at) VALUES ('${uid}', '${email}', 'x', TRUE, NOW()) ON CONFLICT (id) DO NOTHING;`
  );
  lines.push(
    `INSERT INTO wallets (user_id, balance_cents, status) VALUES ('${uid}', 50000, 'active') ON CONFLICT (user_id) DO UPDATE SET balance_cents = 50000, status='active';`
  );
}
lines.push(`
INSERT INTO contests (
  id, name, starts_at, ends_at, status, entry_fee_cents, platform_fee_bps,
  qty_total, commission_rate, is_free, current_participants,
  prize_pool_net_cents, commission_amount,
  economics_locked_at, locked_entry_fee_cents, locked_platform_fee_bps, late_join_enabled
) VALUES (
  '${contestId}', 'phase41lite-durable', NOW() - interval '1 hour', NOW() + interval '1 hour',
  'completed', ${entry}, ${bps},
  10, 20.0, FALSE, ${users.length},
  ${net}, ${fee},
  NOW(), ${entry}, ${bps}, TRUE
);`);
for (let i = 0; i < users.length; i++) {
  const uid = users[i];
  const score = 3000 - i * 500;
  lines.push(
    `INSERT INTO contest_participants (contest_id, user_id, qty_total, qty_available, total_score) VALUES ('${contestId}', '${uid}', 10, 10, ${score});`
  );
  lines.push(
    `INSERT INTO wallet_ledger (id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, idempotency_key, description, created_at)
     VALUES ('${uuid()}', '${uid}', 'contest_entry', -${entry}, ${50000 - entry}, 'contest', '${contestId}', 'contest_entry:${contestId}:${uid}', 'phase41lite entry ${contestId}', NOW());`
  );
  lines.push(
    `UPDATE wallets SET balance_cents = balance_cents - ${entry} WHERE user_id='${uid}';`
  );
}
lines.push(`
INSERT INTO contest_settlements (
  id, contest_id, status, started_at, completed_at,
  total_participants, total_winners,
  prize_pool_gross_cents, prize_pool_net_cents,
  total_distributed_cents, platform_fee_cents
) VALUES (
  '${settlementId}', '${contestId}', 'completed', NOW(), NOW(),
  ${users.length}, ${users.length},
  ${gross}, ${net}, ${net}, ${fee}
) ON CONFLICT (contest_id) DO NOTHING;
`);
for (let i = 0; i < users.length; i++) {
  const uid = users[i];
  const rank = i + 1;
  const amt = payouts[i];
  const pct = ((amt / net) * 100).toFixed(6);
  const score = 3000 - i * 500;
  const balAfter = 50000 - entry + amt;
  lines.push(
    `INSERT INTO prize_distributions (id, settlement_id, contest_id, user_id, rank, final_score, prize_amount_cents, prize_percentage, status, credited_at)
     VALUES ('${uuid()}', '${settlementId}', '${contestId}', '${uid}', ${rank}, ${score}, ${amt}, ${pct}, 'credited', NOW());`
  );
  lines.push(
    `INSERT INTO wallet_ledger (id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, idempotency_key, description, created_at)
     VALUES ('${uuid()}', '${uid}', 'prize_credit', ${amt}, ${balAfter}, 'contest', '${contestId}', 'finalization:${contestId}:${uid}:${rank}', 'phase41lite prize ${contestId}', NOW());`
  );
  lines.push(`UPDATE wallets SET balance_cents = balance_cents + ${amt} WHERE user_id='${uid}';`);
}
lines.push("COMMIT;");

const sqlFile = path.join(evidenceDir, "durable-contest.sql");
fs.writeFileSync(sqlFile, lines.join("\n"));

const rCopy = spawnSync(dockerBin, ["cp", sqlFile, "tragge_postgres:/tmp/durable-contest.sql"], {
  encoding: "utf8",
});
if (rCopy.status !== 0) {
  console.error(rCopy.stderr || rCopy.stdout);
  process.exit(1);
}
const rSql = spawnSync(
  dockerBin,
  [
    "exec",
    "-e",
    `PGPASSWORD=${pass}`,
    "tragge_postgres",
    "psql",
    "-U",
    "tragge_admin",
    "-d",
    "app",
    "-v",
    "ON_ERROR_STOP=1",
    "-f",
    "/tmp/durable-contest.sql",
  ],
  { encoding: "utf8" }
);
if (rSql.status !== 0) {
  console.error("SQL failed", rSql.stderr || rSql.stdout);
  process.exit(1);
}

const dsn = `postgres://tragge_admin:${encodeURIComponent(pass)}@127.0.0.1:5432/app?sslmode=disable`;
const recon = spawnSync("node", [path.join(root, "scripts/contest-reconcile.mjs"), contestId], {
  encoding: "utf8",
  env: { ...process.env, DATABASE_URL: dsn },
  cwd: root,
});
const reconOut = (recon.stdout || "") + (recon.stderr || "");
const reconOk = recon.status === 0;
const meta = {
  contest_id: contestId,
  users,
  entry_fee_cents: entry,
  platform_fee_bps: bps,
  gross,
  fee,
  net,
  payouts,
  payout_sum: payouts.reduce((a, b) => a + b, 0),
  settlement_id: settlementId,
  reconcile_exit: recon.status,
  reconcile_ok: reconOk,
  reconcile_output: reconOut.slice(0, 4000),
  ts: new Date().toISOString(),
};
fs.writeFileSync(path.join(evidenceDir, "durable-contest-evidence.json"), JSON.stringify(meta, null, 2));
console.log(JSON.stringify(meta, null, 2));
console.log(reconOk ? "RECONCILE PASS" : "RECONCILE FAIL");
process.exit(reconOk ? 0 : 1);
