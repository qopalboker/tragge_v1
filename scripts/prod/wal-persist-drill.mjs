#!/usr/bin/env node
/**
 * WAL host-path persistence drill (container recreate).
 * Writes proof to WAL path inside container, force-recreates trading-core,
 * verifies proof survives. Emits WAL_HOST_PERSIST_PASS evidence on success.
 *
 * Uses currently running stack compose files (local qual or production).
 */
import fs from "node:fs";
import path from "node:path";
import {
  docker,
  compose,
  localQualComposeArgs,
  prodComposeArgs,
  writeEvidence,
  walHostPath,
} from "./lib.mjs";

const useProd = process.env.USE_PROD_COMPOSE === "1";
const cargs = useProd ? prodComposeArgs : localQualComposeArgs;
const proof = `wal-host-proof-${Date.now()}`;

console.log("WAL PERSIST DRILL");
console.log("compose=", useProd ? "production" : "local-qual");

const write = docker([
  "exec",
  "tragge_trading_core",
  "sh",
  "-c",
  `echo ${proof} > /var/lib/tragge/wal/host-persist.proof && cat /var/lib/tragge/wal/host-persist.proof`,
]);
if (write.status !== 0) {
  console.error("FAIL write proof", write.stderr || write.stdout);
  writeEvidence("wal-persist-drill.txt", "FAIL write proof\n");
  process.exit(1);
}

const rec = compose(
  ["--profile", "app", "up", "-d", "--force-recreate", "trading-core"],
  cargs,
  {
    env: {
      TRAGGE_WAL_HOST_PATH: walHostPath(),
      WAL_REQUIRE_PERSIST: process.env.WAL_REQUIRE_PERSIST || "true",
    },
    timeout: 180000,
  }
);
console.log(rec.stdout || "");
if (rec.status !== 0) {
  console.error("FAIL recreate", rec.stderr);
  writeEvidence("wal-persist-drill.txt", "FAIL recreate\n");
  process.exit(1);
}

// wait
await new Promise((r) => setTimeout(r, 18000));

const read = docker([
  "exec",
  "tragge_trading_core",
  "cat",
  "/var/lib/tragge/wal/host-persist.proof",
]);
const body = (read.stdout || "").trim();
const ok = read.status === 0 && body.includes(proof);

const ready = docker([
  "exec",
  "tragge_trading_core",
  "wget",
  "-qO-",
  "http://127.0.0.1:8085/readyz",
]);
const readyBody = ready.stdout || "";
const readyOk =
  ready.status === 0 &&
  /"wal_recovery"\s*:\s*"ok"/i.test(readyBody);

const pass = ok && readyOk;
const report = [
  pass ? "WAL_HOST_PERSIST_PASS" : "WAL_HOST_PERSIST_FAIL",
  `proof_survived=${ok}`,
  `proof=${body.slice(0, 80)}`,
  `readyz_ok=${readyOk}`,
  `readyz=${readyBody.slice(0, 200)}`,
  `wal_host_path=${walHostPath()}`,
  pass ? "PASS" : "FAIL",
].join("\n");
console.log(report);
writeEvidence("wal-persist-drill.txt", report + "\n");
process.exit(pass ? 0 : 1);
