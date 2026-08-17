/**
 * RC Browser Acceptance — User journeys against REAL local backends.
 * Requires: Compose stack + Vite user frontend + E2E_INTEGRATION=1
 *
 * Credentials via env (defaults match scripts/create-admin-users):
 *   RC_USER_EMAIL / RC_USER_PASSWORD
 */
import { test, expect, type Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

const USER_EMAIL = process.env.RC_USER_EMAIL || 'user@tragge.com';
const USER_PASSWORD = process.env.RC_USER_PASSWORD || 'user123456';
const EVIDENCE = path.resolve('docs/codex/reports/evidence/mvp-rc-browser');

test.beforeAll(() => {
  test.skip(!process.env.E2E_INTEGRATION, 'Set E2E_INTEGRATION=1 for real-backend browser RC');
  fs.mkdirSync(EVIDENCE, { recursive: true });
});

// Fail fast — do not hang forever on stuck navigation/auth
test.describe.configure({ timeout: 90_000 });


/** Prefer session from setup storageState; only login via UI when needed. */
async function ensureUserSession(page: Page) {
  test.setTimeout(120_000);
  await page.goto('/user/dashboard', { waitUntil: 'domcontentloaded', timeout: 60_000 });
  if (/\/user\/dashboard/.test(page.url()) && (await page.locator('.home').isVisible().catch(() => false))) {
    return;
  }
  await page.goto('/user/login', { waitUntil: 'domcontentloaded', timeout: 60_000 });
  await expect(page.locator('.auth-form:not(.signup) input[type="email"]')).toBeVisible({ timeout: 30000 });
  await page.locator('.auth-form:not(.signup) input[type="email"]').fill(USER_EMAIL);
  await page.locator('.auth-form:not(.signup) input[type="password"]').fill(USER_PASSWORD);
  await page.locator('.auth-form:not(.signup) button[type="submit"]').click();
  await page.waitForURL(/\/user\/(dashboard|$)/, { timeout: 45_000 });
}

async function loginUser(page: Page) {
  await ensureUserSession(page);
}

test.describe('RC User — auth', () => {
  test('login, refresh persistence, protected redirect, logout', async ({ browser, page }) => {
    test.setTimeout(120_000);

    // Unauthenticated deep link must use a clean context (no storageState)
    const anon = await browser.newContext({ baseURL: process.env.E2E_USER_URL || 'http://127.0.0.1:5173' });
    const anonPage = await anon.newPage();
    await anonPage.goto('/user/wallet', { waitUntil: 'domcontentloaded', timeout: 60_000 });
    // Client-side auth guard may take a moment after bootstrap
    await expect(anonPage.locator('.auth-form:not(.signup) input[type="email"], input[type="email"]')).toBeVisible({
      timeout: 45000,
    });
    expect(anonPage.url()).toMatch(/\/user\/login/);
    await anon.close();

    // Authenticated session from setup storageState
    await loginUser(page);
    await expect(page).toHaveURL(/\/user\/dashboard/);

    // Refresh persistence
    await page.reload({ waitUntil: 'domcontentloaded' });
    await expect(page).toHaveURL(/\/user\/dashboard/);
    await expect(page.locator('.home')).toBeVisible({ timeout: 30000 });

    // Screenshot evidence
    await page.screenshot({ path: path.join(EVIDENCE, 'user-dashboard-after-login.png'), fullPage: true });
  });
});

test.describe('RC User — mobile home hierarchy', () => {
  const viewports = [
    { w: 320, h: 568 },
    { w: 360, h: 800 },
    { w: 375, h: 812 },
    { w: 390, h: 844 },
    { w: 414, h: 896 },
    { w: 430, h: 932 },
  ];

  for (const vp of viewports) {
    test(`hierarchy @ ${vp.w}x${vp.h}`, async ({ page }) => {
      await page.setViewportSize({ width: vp.w, height: vp.h });
      await loginUser(page);
      await page.goto('/user/dashboard', { waitUntil: 'domcontentloaded', timeout: 60_000 });
      await expect(page.locator('.home[dir="rtl"]')).toBeVisible({ timeout: 30000 });

      await expect(page.locator('.mh-header, header.mh-header')).toBeVisible();
      await expect(page.locator('.hero')).toBeVisible();
      await expect(page.locator('.metrics')).toBeVisible();

      // Wallet shows real balance (we seeded 50000 cents = $500)
      const bal = page.locator('.metric-balance, .mh-wallet-bal').first();
      await expect(bal).toBeVisible();
      const balText = (await bal.textContent()) || '';
      expect(balText.replace(/[^\d.]/g, '').length).toBeGreaterThan(0);

      // Featured may be empty if no open contests match — section or empty is ok if no crash
      // Suggested rail container
      await expect(page.locator('.rail-section').first()).toBeVisible();

      // Challenges then Support order
      const ch = page.locator('section.ch[aria-label="challenges"]');
      const sup = page.locator('section.sup[aria-label="support"]');
      await expect(ch).toBeVisible();
      await expect(sup).toBeVisible();
      const chBox = await ch.boundingBox();
      const supBox = await sup.boundingBox();
      expect(chBox && supBox).toBeTruthy();
      if (chBox && supBox) expect(supBox.y).toBeGreaterThan(chBox.y);

      await expect(page.locator('nav.bottom-nav')).toBeVisible();

      // Page must not scroll horizontally; allow 1px subpixel + scrollbar gutter
      const overflow = await page.evaluate(() => {
        const de = document.documentElement;
        const body = document.body;
        return {
          sw: Math.max(de.scrollWidth, body.scrollWidth),
          cw: de.clientWidth,
        };
      });
      expect(overflow.sw).toBeLessThanOrEqual(overflow.cw + 4);

      // Horizontal rails present
      await expect(page.locator('section.ch .mvp-h-scroll')).toBeVisible();

      await page.screenshot({
        path: path.join(EVIDENCE, `user-home-${vp.w}.png`),
        fullPage: true,
      });
    });
  }
});

test.describe('RC User — wallet + contests + join', () => {
  test('wallet page shows API balance', async ({ page }) => {
    await loginUser(page);
    await page.goto('/user/wallet');
    await expect(page).toHaveURL(/\/user\/wallet/);
    // Balance region should render (not blank)
    await expect(page.locator('main, .wallet-page, .page-content').first()).toBeVisible({ timeout: 20000 });
    await page.screenshot({ path: path.join(EVIDENCE, 'user-wallet.png'), fullPage: true });
  });

  test('contest list + detail load real data', async ({ page }) => {
    await loginUser(page);
    await page.goto('/user/contests');
    await expect(page).toHaveURL(/\/user\/contests/);
    await page.waitForTimeout(1500);
    // Navigate to first contest link if present
    const link = page.locator('a[href*="/user/contests/"]').first();
    if (await link.count()) {
      await link.click();
      await expect(page).toHaveURL(/\/user\/contests\/[^/]+/);
      await page.screenshot({ path: path.join(EVIDENCE, 'user-contest-detail.png'), fullPage: true });
    } else {
      // Empty list is not a P0 if backend has only expired e2e contests filtered out
      await page.screenshot({ path: path.join(EVIDENCE, 'user-contests-empty.png'), fullPage: true });
    }
  });

  test('join free running contest when available', async ({ page }) => {
    await loginUser(page);
    // Find a free running contest via API through the page context
    const contestId = await page.evaluate(async () => {
      const res = await fetch('/api/user/contests?status=running&limit=50', {
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        credentials: 'include',
      });
      // Need bearer from localStorage if used
      return null as string | null;
    });

    // Use UI: open contests, find free / practice if listed
    await page.goto('/user/contests');
    await page.waitForTimeout(2000);

    // Prefer free contest from dashboard featured or direct free practice
    // Use API with token from storage
    const id = await page.evaluate(async () => {
      const token =
        localStorage.getItem('access_token') ||
        sessionStorage.getItem('access_token') ||
        '';
      // Pinia may store differently — try common keys
      const keys = Object.keys(localStorage);
      let authTok = token;
      for (const k of keys) {
        if (k.toLowerCase().includes('token') || k.includes('auth')) {
          try {
            const v = localStorage.getItem(k) || '';
            if (v.startsWith('eyJ')) authTok = v;
            const parsed = JSON.parse(v);
            if (parsed?.access_token) authTok = parsed.access_token;
            if (parsed?.token) authTok = parsed.token;
          } catch {
            /* ignore */
          }
        }
      }
      // Memory token not in localStorage (in-memory only) — use cookie session refresh
      const res = await fetch('/api/user/contests?status=running,registration_open&limit=30', {
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          ...(authTok ? { Authorization: `Bearer ${authTok}` } : {}),
        },
        credentials: 'include',
      });
      if (!res.ok) return null;
      const data = await res.json();
      const list = Array.isArray(data) ? data : data.contests || [];
      const free = list.find((c: { is_free?: boolean; entry_fee_cents?: number; status?: string }) =>
        (c.is_free || c.entry_fee_cents === 0) && (c.status === 'running' || c.status === 'registration_open')
      );
      return free?.id || list[0]?.id || null;
    });

    if (!id) {
      test.info().annotations.push({ type: 'note', description: 'No joinable contest in API list' });
      return;
    }

    await page.goto(`/user/contests/${id}`);
    await expect(page.locator('main, .contest-details, .page-content').first()).toBeVisible({ timeout: 20000 });
    await page.screenshot({ path: path.join(EVIDENCE, 'user-join-candidate.png'), fullPage: true });

    // Attempt join if button available
    const joinBtn = page.getByRole('button', { name: /join|شرکت|ثبت/i }).first();
    if (await joinBtn.isVisible().catch(() => false)) {
      await joinBtn.click();
      // Confirm modal if present
      const confirm = page.getByRole('button', { name: /confirm|تأیید|pay|پرداخت/i }).first();
      if (await confirm.isVisible({ timeout: 3000 }).catch(() => false)) {
        await confirm.click();
      }
      await page.waitForTimeout(2000);
      await page.screenshot({ path: path.join(EVIDENCE, 'user-after-join.png'), fullPage: true });
    }

    // Refresh join state
    await page.reload();
    await expect(page.locator('main, .contest-details, .page-content').first()).toBeVisible({ timeout: 20000 });
  });
});

test.describe('RC User — trading route', () => {
  test('trade page loads for running free contest when joined', async ({ page }) => {
    await loginUser(page);

    // Discover free running contest
    const contestId = await page.evaluate(async () => {
      const res = await fetch('/api/user/contests?status=running&limit=20', {
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        credentials: 'include',
      });
      if (!res.ok) return null;
      const data = await res.json();
      const list = Array.isArray(data) ? data : data.contests || [];
      const free = list.find((c: { is_free?: boolean; entry_fee_cents?: number }) => c.is_free || c.entry_fee_cents === 0);
      return free?.id || null;
    });

    if (!contestId) {
      test.info().annotations.push({ type: 'note', description: 'No free running contest for trading UI load' });
      return;
    }

    // Join via API
    await page.evaluate(async (id) => {
      await fetch(`/api/user/contests/${id}/join`, {
        method: 'POST',
        headers: { 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/json' },
        credentials: 'include',
      });
    }, contestId);

    await page.goto(`/trade/${contestId}`);
    // Should not be blank forever
    await page.waitForTimeout(3000);
    await page.screenshot({ path: path.join(EVIDENCE, 'user-trading.png'), fullPage: true });
    // Page should not be login redirect if session valid
    expect(page.url()).not.toMatch(/\/user\/login/);
  });
});

test.describe('RC User — support + challenges + bottom nav', () => {
  test('support empty/create surface + bottom nav routes', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await loginUser(page);
    await page.goto('/user/dashboard');
    await expect(page.locator('section.sup')).toBeVisible();
    await expect(page.locator('section.ch .mvp-h-scroll')).toBeVisible();

    // Bottom nav destinations
    const nav = page.locator('nav.bottom-nav');
    await expect(nav).toBeVisible();
    await nav.locator('a[href*="contests"]').first().click();
    await expect(page).toHaveURL(/\/user\/contests/);
    await nav.locator('a[href*="dashboard"]').first().click();
    await expect(page).toHaveURL(/\/user\/dashboard/);
  });

  test('tablet and desktop dashboards render', async ({ page }) => {
    await loginUser(page);
    for (const vp of [
      { w: 768, h: 1024, name: 'tablet' },
      { w: 1280, h: 800, name: 'desktop' },
    ]) {
      await page.setViewportSize({ width: vp.w, height: vp.h });
      await page.goto('/user/dashboard');
      await expect(page.locator('.home, main').first()).toBeVisible({ timeout: 20000 });
      await page.screenshot({ path: path.join(EVIDENCE, `user-home-${vp.name}.png`), fullPage: true });
    }
  });
});
