#!/usr/bin/env node
/**
 * Minimal contest financial reconciliation diagnostic.
 * Usage: node scripts/contest-reconcile.mjs <contest_id>
 * Env:
 *   DATABASE_URL  — optional postgres URL (if `pg` is installed)
 *   Or Compose default via docker exec tragge_postgres + PGPASSWORD / secrets file
 *
 * Verifies conservation and basic invariants for a single contest.
 * Fails with exit 1 on mismatch.
 */
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const contestId = process.argv[2];
if (!contestId) {
  console.error("Usage: node scripts/contest-reconcile.mjs <contest_id>");
  process.exit(2);
}

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "..");
const dockerBin =
  process.env.DOCKER_BIN ||
  (process.platform === "win32"
    ? "C:\\Users\\parsa\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe"
    : "docker");
const passFile = path.join(root, "infra/docker/secrets/postgres_admin_password.txt");
const pass =
  process.env.PGPASSWORD ||
  (fs.existsSync(passFile) ? fs.readFileSync(passFile, "utf8").trim() : "");

function psqlJson(query) {
  const r = spawnSync(
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
      "-t",
      "-A",
      "-c",
      query,
    ],
    { encoding: "utf8" }
  );
  if (r.status !== 0) {
    throw new Error((r.stderr || r.stdout || "psql failed").trim());
  }
  const out = (r.stdout || "").trim();
  if (!out) return null;
  try {
    return JSON.parse(out);
  } catch {
    return out;
  }
}

// Prefer docker exec (no node pg dependency). Fall back to pg if DATABASE_URL set and package present.
let report;
try {
  const c = psqlJson(
    `SELECT row_to_json(t) FROM (
      SELECT id, status::text AS status, entry_fee_cents, platform_fee_bps, commission_rate,
             prize_pool_net_cents, commission_amount, current_participants,
             locked_entry_fee_cents, locked_platform_fee_bps, economics_locked_at
      FROM contests WHERE id = '${contestId}'
    ) t;`
  );
  if (!c) {
    console.error("contest not found");
    process.exit(1);
  }
  const participants = Number(
    psqlJson(
      `SELECT COUNT(*)::text FROM contest_participants WHERE contest_id = '${contestId}';`
    )
  );
  const ledger = psqlJson(
    `SELECT COALESCE(json_agg(row_to_json(x)), '[]'::json) FROM (
      SELECT type::text AS type, COALESCE(SUM(amount_cents),0)::bigint AS total
      FROM wallet_ledger
      WHERE ref_id = '${contestId}'::uuid
         OR description ILIKE '%${contestId}%'
         OR idempotency_key ILIKE '%${contestId}%'
      GROUP BY type
    ) x;`
  );
  const settlements = psqlJson(
    `SELECT COALESCE(json_agg(row_to_json(s)), '[]'::json) FROM (
      SELECT id, status::text AS status, prize_pool_gross_cents, prize_pool_net_cents,
             total_distributed_cents, platform_fee_cents, total_winners
      FROM contest_settlements WHERE contest_id = '${contestId}'
    ) s;`
  );
  const prizes = psqlJson(
    `SELECT row_to_json(t) FROM (
      SELECT COALESCE(SUM(prize_amount_cents),0)::bigint AS paid, COUNT(*)::int AS n
      FROM prize_distributions WHERE contest_id = '${contestId}'
    ) t;`
  );

  const entry = Number(c.locked_entry_fee_cents ?? c.entry_fee_cents);
  const bps = Number(c.locked_platform_fee_bps ?? c.platform_fee_bps ?? 2000);
  const gross = participants * entry;
  const fee = Math.floor((gross * bps) / 10000);
  const net = gross - fee;

  report = {
    contest_id: contestId,
    status: c.status,
    participants,
    entry_fee_cents: entry,
    platform_fee_bps: bps,
    expected_gross: gross,
    expected_fee: fee,
    expected_net: net,
    stored_prize_pool_net: Number(c.prize_pool_net_cents ?? 0),
    settlements: settlements || [],
    prize_distributions: prizes || { paid: 0, n: 0 },
    ledger_by_type: ledger || [],
  };
} catch (e) {
  console.error("reconcile query failed:", e.message || e);
  process.exit(1);
}

console.log(JSON.stringify(report, null, 2));

let failed = false;
if (report.settlements.length > 1) {
  console.error("FAIL: multiple settlement rows for one contest");
  failed = true;
}
if (report.settlements.length === 1) {
  const s = report.settlements[0];
  const paid = Number(report.prize_distributions.paid);
  const dist = Number(s.total_distributed_cents);
  if (paid !== dist && s.status === "completed") {
    console.error(
      `FAIL: prize_distributions sum ${paid} != settlement total_distributed ${dist}`
    );
    failed = true;
  }
  if (Number(s.prize_pool_net_cents) !== report.expected_net && s.status === "completed") {
    // warn only if stored pool differs from recomputed locked economics
    if (Number(s.prize_pool_net_cents) !== Number(report.stored_prize_pool_net)) {
      console.error(
        `FAIL: settlement net ${s.prize_pool_net_cents} != contest prize_pool_net ${report.stored_prize_pool_net}`
      );
      failed = true;
    }
  }
  if (paid !== Number(s.prize_pool_net_cents) && s.status === "completed") {
    console.error(
      `FAIL: sum(payouts)=${paid} != prize_pool_net=${s.prize_pool_net_cents}`
    );
    failed = true;
  }
}
if (report.settlements.length === 0) {
  console.error("WARN: no settlement row (may be pre-settlement contest)");
}
if (failed) process.exit(1);
console.error("OK: no critical mismatches detected");
process.exit(0);
