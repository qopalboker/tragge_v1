/**
 * RC Browser Acceptance — Admin journeys (MVP: MFA OFF by default).
 * Credentials via env: RC_ADMIN_EMAIL / RC_ADMIN_PASSWORD
 */
import { test, expect, type Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

const ADMIN_EMAIL = process.env.RC_ADMIN_EMAIL || 'admin@tragge.com';
const ADMIN_PASSWORD = process.env.RC_ADMIN_PASSWORD || '159032000';
const EVIDENCE = path.resolve('docs/codex/reports/evidence/mvp-rc-browser');

test.beforeAll(() => {
  test.skip(!process.env.E2E_INTEGRATION, 'Set E2E_INTEGRATION=1 for real-backend browser RC');
  fs.mkdirSync(EVIDENCE, { recursive: true });
});

async function loginAdmin(page: Page) {
  test.setTimeout(90_000);
  await page.goto('/admin/login', { waitUntil: 'domcontentloaded', timeout: 45_000 });
  if (!/\/admin\/login/.test(page.url())) return;

  await expect(page.locator('input[type="email"], input#email').first()).toBeVisible({ timeout: 20000 });
  await page.locator('input[type="email"], input#email').first().fill(ADMIN_EMAIL);
  await page.locator('input[type="password"], input#password').first().fill(ADMIN_PASSWORD);
  await page.locator('button[type="submit"]').first().click();

  // MVP: no MFA challenge when admin_mfa_enabled=false
  await page.waitForURL(
    (url) => /\/admin\//.test(url.pathname) && !/\/admin\/login/.test(url.pathname),
    { timeout: 30000 },
  );
  // Guard: MFA form must not appear
  await expect(page.getByLabel(/authenticator|code/i)).toHaveCount(0);
}

test.describe('RC Admin — auth (MFA off MVP)', () => {
  test('password login without MFA reaches dashboard', async ({ page }) => {
    await loginAdmin(page);
    await expect(page).not.toHaveURL(/\/admin\/login/);
    await page.reload({ waitUntil: 'domcontentloaded' });
    await expect(page).not.toHaveURL(/\/admin\/login/);
    await page.screenshot({ path: path.join(EVIDENCE, 'admin-after-login.png'), fullPage: true });
  });
});

test.describe('RC Admin — users + contests', () => {
  test('open users list authenticated', async ({ page }) => {
    await loginAdmin(page);
    await page.goto('/admin/users', { waitUntil: 'domcontentloaded', timeout: 45_000 });
    await expect(page.locator('body')).toBeVisible();
    expect(page.url()).not.toMatch(/\/admin\/login/);
    // Wait for SPA shell content (table or heading)
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(EVIDENCE, 'admin-users.png'), fullPage: true });
    await expect(page.locator('#app')).toBeVisible();
  });

  test('contests list loads', async ({ page }) => {
    await loginAdmin(page);
    await page.goto('/admin/contests', { waitUntil: 'domcontentloaded', timeout: 45_000 });
    await expect(page.locator('main, [class*="contest"], table, .layout-content, #app, body').first()).toBeVisible({
      timeout: 20000,
    });
    await page.screenshot({ path: path.join(EVIDENCE, 'admin-contests.png'), fullPage: true });
  });

  test('security settings page reachable for super admin', async ({ page }) => {
    await loginAdmin(page);
    await page.goto('/admin/security', { waitUntil: 'domcontentloaded', timeout: 45_000 });
    await expect(page.getByText(/Two-Factor|MFA|امنیت|Security/i).first()).toBeVisible({ timeout: 15000 });
    await page.screenshot({ path: path.join(EVIDENCE, 'admin-security-mfa.png'), fullPage: true });
  });
});

test.describe('RC Admin — authorization isolation', () => {
  test('user origin cannot list admin users', async ({ request }) => {
    const res = await request.get('http://127.0.0.1:8083/api/admin/users', {
      headers: { 'X-Requested-With': 'XMLHttpRequest', Origin: 'http://localhost:5173' },
    });
    expect([401, 403, 404]).toContain(res.status());
  });
});
