/**
 * Shared helpers for production VM/Docker scripts.
 * No Kubernetes dependency.
 */
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import net from "node:net";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const root = path.resolve(__dirname, "../..");
export const composeDir = path.join(root, "infra/docker");
export const evidenceDir = path.join(root, "docs/codex/reports/evidence/phase6nk");

export const dockerBin =
  process.env.DOCKER_BIN ||
  (process.platform === "win32"
    ? "C:\\Users\\parsa\\AppData\\Local\\Programs\\DockerDesktop\\resources\\bin\\docker.exe"
    : "docker");

/** Authoritative production compose files (no override / no lite). */
export const prodComposeArgs = [
  "-f",
  "docker-compose.yml",
  "-f",
  "docker-compose.production.yml",
];

/** Local qualification: may include lite+override for operator workstation. */
export const localQualComposeArgs = [
  "-f",
  "docker-compose.yml",
  "-f",
  "docker-compose.lite.yml",
  "-f",
  "docker-compose.override.yml",
];

export function ensureEvidenceDir() {
  fs.mkdirSync(evidenceDir, { recursive: true });
}

export function run(cmd, args, opts = {}) {
  return spawnSync(cmd, args, {
    encoding: "utf8",
    shell: false,
    cwd: opts.cwd || root,
    env: { ...process.env, ...(opts.env || {}) },
    timeout: opts.timeout || 120000,
  });
}

export function docker(args, opts = {}) {
  return run(dockerBin, args, { ...opts, cwd: opts.cwd || composeDir });
}

export function compose(args, composeArgs = prodComposeArgs, opts = {}) {
  return docker(["compose", ...composeArgs, ...args], opts);
}

export function portOpen(port, host = "127.0.0.1", timeoutMs = 800) {
  return new Promise((resolve) => {
    const s = net.connect({ port, host });
    const t = setTimeout(() => {
      s.destroy();
      resolve(false);
    }, timeoutMs);
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

export function writeEvidence(name, body) {
  ensureEvidenceDir();
  const p = path.join(evidenceDir, name);
  fs.writeFileSync(p, body.endsWith("\n") ? body : body + "\n");
  return p;
}

export function hasEvidenceToken(token) {
  if (!fs.existsSync(evidenceDir)) return false;
  // Require an affirmative line: token alone, "token PASS", or "PASS ... token"
  // Avoid matching instructional prose that merely names the token.
  const affirmative = new RegExp(
    `(^|\\n)\\s*(${token}\\s*(PASS|SUCCESS|OK|QUALIFIED)?|(PASS|SUCCESS|OK|QUALIFIED)\\b[^\\n]*${token})\\s*($|\\n)`,
    "im"
  );
  for (const f of fs.readdirSync(evidenceDir)) {
    // Do not treat gate output as evidence of itself (prevents self-PASS loops)
    if (/^launch-gate/i.test(f)) continue;
    const p = path.join(evidenceDir, f);
    if (!fs.statSync(p).isFile()) continue;
    const body = fs.readFileSync(p, "utf8");
    if (affirmative.test(body)) return true;
    // Explicit single-line token status written by drills
    if (body.split(/\r?\n/).some((line) => line.trim() === token)) return true;
  }
  return false;
}

export function readSecret(name) {
  const p = path.join(composeDir, "secrets", name);
  if (!fs.existsSync(p)) return "";
  return fs.readFileSync(p, "utf8").trim();
}

export function walHostPath() {
  return (
    process.env.TRAGGE_WAL_HOST_PATH ||
    (process.platform === "win32"
      ? path.join(root, "var", "lib", "tragge", "wal")
      : "/var/lib/tragge/wal")
  );
}
