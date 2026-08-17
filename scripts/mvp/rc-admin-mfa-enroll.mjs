#!/usr/bin/env node
/**
 * Local-only helper: complete Super Admin MFA enrollment/login for browser RC.
 * Writes secret to var/rc-admin-mfa.json (gitignored under var/).
 * Does NOT weaken production MFA.
 */
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(__dirname, "../..");
const secretPath = path.join(root, "var/rc-admin-mfa.json");

const ADMIN = process.env.RC_ADMIN_EMAIL || "admin@tragge.com";
const PASS = process.env.RC_ADMIN_PASSWORD || "159032000";
const ORIGIN = process.env.RC_ADMIN_ORIGIN || "http://localhost:5174";
const BASE = process.env.RC_ADMIN_API || "http://127.0.0.1:8083";

function base32Decode(s) {
  const alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567";
  let bits = "";
  const cleaned = s.toUpperCase().replace(/=+$/, "").replace(/[^A-Z2-7]/g, "");
  for (const c of cleaned) {
    const val = alphabet.indexOf(c);
    if (val < 0) continue;
    bits += val.toString(2).padStart(5, "0");
  }
  const bytes = [];
  for (let i = 0; i + 8 <= bits.length; i += 8) bytes.push(parseInt(bits.slice(i, i + 8), 2));
  return Buffer.from(bytes);
}

export function generateTotp(secret, now = Date.now()) {
  const key = base32Decode(secret);
  let counter = Math.floor(now / 1000 / 30);
  const buf = Buffer.alloc(8);
  for (let i = 7; i >= 0; i--) {
    buf[i] = counter & 0xff;
    counter = Math.floor(counter / 256);
  }
  const hmac = crypto.createHmac("sha1", key).update(buf).digest();
  const offset = hmac[hmac.length - 1] & 0xf;
  const code =
    ((hmac[offset] & 0x7f) << 24) |
    ((hmac[offset + 1] & 0xff) << 16) |
    ((hmac[offset + 2] & 0xff) << 8) |
    (hmac[offset + 3] & 0xff);
  return String(code % 1000000).padStart(6, "0");
}

async function post(url, body) {
  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Requested-With": "XMLHttpRequest",
      Origin: ORIGIN,
    },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    json = { raw: text };
  }
  return { status: res.status, json };
}

export async function adminLoginWithMfa() {
  const login = await post(`${BASE}/api/admin/auth/login`, { email: ADMIN, password: PASS });
  if (login.status !== 202 || !login.json.challenge) {
    // Already full login?
    if (login.status === 200 && login.json.access_token) {
      return login.json;
    }
    throw new Error(`admin login failed: ${login.status} ${JSON.stringify(login.json)}`);
  }
  const challenge = login.json.challenge;

  if (login.json.enrollment_required) {
    const start = await post(`${BASE}/api/admin/auth/mfa/enrollment/start`, { challenge });
    if (!start.json.secret) throw new Error(`enroll start failed: ${JSON.stringify(start.json)}`);
    const secret = start.json.secret;
    const code = generateTotp(secret);
    const verify = await post(`${BASE}/api/admin/auth/mfa/enrollment/verify`, {
      challenge: start.json.challenge || challenge,
      code,
    });
    if (verify.status !== 200 || !verify.json.access_token) {
      throw new Error(`enroll verify failed: ${verify.status} ${JSON.stringify(verify.json)}`);
    }
    fs.mkdirSync(path.dirname(secretPath), { recursive: true });
    fs.writeFileSync(
      secretPath,
      JSON.stringify({ email: ADMIN, secret, enrolled_at: new Date().toISOString() }, null, 2)
    );
    return verify.json;
  }

  if (!fs.existsSync(secretPath)) {
    throw new Error("MFA enrolled but var/rc-admin-mfa.json missing — reset credentials and re-run enroll");
  }
  const { secret } = JSON.parse(fs.readFileSync(secretPath, "utf8"));
  const code = generateTotp(secret);
  const verify = await post(`${BASE}/api/admin/auth/mfa/verify`, { challenge, code });
  if (verify.status !== 200 || !verify.json.access_token) {
    throw new Error(`mfa verify failed: ${verify.status} ${JSON.stringify(verify.json)}`);
  }
  return verify.json;
}

const isMain = process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url);
if (isMain) {
  adminLoginWithMfa()
    .then((r) => {
      console.log("MFA_OK token_len=" + (r.access_token || "").length);
      process.exit(0);
    })
    .catch((e) => {
      console.error(e.message || e);
      process.exit(1);
    });
}
