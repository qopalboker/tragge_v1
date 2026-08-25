/**
 * Telegram Mini App auth + Admin System Settings wiring (static regression locks).
 */
import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => fs.readFileSync(path.join(root, rel), "utf8");

test("Telegram auth returns telegram_auth_unavailable when verifier missing", () => {
  const src = read("apps/user-bff/server/telegram_auth.go");
  assert.match(src, /telegram_auth_unavailable/);
  assert.match(src, /StatusServiceUnavailable/);
  assert.doesNotMatch(src, /skip.?signature|bypass.?hmac/i);
});

test("Compose mounts telegram_bot_token secret file path", () => {
  const compose = read("infra/docker/docker-compose.yml");
  assert.match(compose, /telegram_bot_token:\s*\n\s*file:/);
  assert.match(compose, /TELEGRAM_BOT_TOKEN_FILE:.*\/run\/secrets\/telegram_bot_token/);
  assert.match(compose, /- telegram_bot_token/);
});

test("Admin security routes expose telegram settings with sensitive reauth", () => {
  const app = read("apps/admin-bff/server/app.go");
  const handlers = read("apps/admin-bff/server/handlers_telegram_settings.go");
  assert.match(app, /\/telegram/);
  assert.match(app, /requireTelegramBotTokenSensitive/);
  assert.match(handlers, /EncryptSystemSecret/);
  assert.match(handlers, /MaskSecret/);
  assert.match(handlers, /settings\.telegram_bot_token/);
  assert.doesNotMatch(handlers, /fmt\.Sprintf\("%s".*token/);
});

test("Admin Security settings UI includes Telegram + MFA sections", () => {
  const page = read("apps/admin-frontend/src/modules/admin/views/SecuritySettingsPage.vue");
  assert.match(page, /Telegram Mini App|telegramTitle/);
  assert.match(page, /Two-Factor|mfaTitle|admin_mfa_enabled/);
  assert.match(page, /TelegramBotToken/);
  assert.match(page, /type=\"password\"/);
});

test("packages/auth system secret + mask unit tests pass", () => {
  const result = spawnSync("go", ["test", "-count=1", "-run=^TestSystemSecret|^TestParseSystemSecret", "."], {
    cwd: path.join(root, "packages/auth"),
    encoding: "utf8",
    env: { ...process.env, GOCACHE: process.env.GOCACHE || path.join(root, ".go-cache"), GOFLAGS: "-vet=off" },
  });
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  assert.equal(result.status, 0, output);
});

test("user-bff telegram auth unit tests pass", () => {
  const result = spawnSync(
    "go",
    ["test", "-count=1", "-short", "-run=^TestHandleTelegramMiniAppAuth|^TestIsPlaceholder", "."],
    {
      cwd: path.join(root, "apps/user-bff/server"),
      encoding: "utf8",
      env: { ...process.env, GOCACHE: process.env.GOCACHE || path.join(root, ".go-cache"), GOFLAGS: "-vet=off" },
    },
  );
  const output = `${result.stdout || ""}${result.stderr || ""}`;
  assert.equal(result.status, 0, output);
});
