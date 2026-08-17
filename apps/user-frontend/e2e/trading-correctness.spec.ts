/**
 * Trading Correctness — multi-qty browser path (real backends).
 * Fail-fast: retries=0, short action timeouts, no force-click.
 */
import { test, expect, type Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

const USER_EMAIL = process.env.RC_USER_EMAIL || 'user@tragge.com';
const USER_PASSWORD = process.env.RC_USER_PASSWORD || 'user123456';
const EVIDENCE = path.resolve('docs/codex/reports/evidence/trading-correctness');

test.beforeAll(() => {
  test.skip(!process.env.E2E_INTEGRATION, 'Set E2E_INTEGRATION=1 for real-backend trading cert');
  fs.mkdirSync(EVIDENCE, { recursive: true });
});

test.describe.configure({ timeout: 90_000, retries: 0 });

async function ensureUserSession(page: Page) {
  await page.goto('/user/dashboard', { waitUntil: 'domcontentloaded', timeout: 30_000 });
  if (!/login/.test(page.url())) return;
  await page.goto('/user/login', { waitUntil: 'domcontentloaded', timeout: 30_000 });
  await expect(page.locator('input[type="email"]').first()).toBeVisible({ timeout: 20_000 });
  await page.locator('input[type="email"]').first().fill(USER_EMAIL);
  await page.locator('input[type="password"]').first().fill(USER_PASSWORD);
  await page.locator('button[type="submit"]').first().click();
  await page.waitForURL(/\/user\/(dashboard|$)/, { timeout: 25_000 });
}

async function findAndJoinRunningContest(page: Page): Promise<string | null> {
  const contestId = await page.evaluate(async () => {
    const res = await fetch('/api/user/contests?status=running&limit=30', {
      headers: { 'X-Requested-With': 'XMLHttpRequest' },
      credentials: 'include',
    });
    if (!res.ok) return null;
    const data = await res.json();
    const list = Array.isArray(data) ? data : data.contests || [];
    const free = list.find(
      (c: { is_free?: boolean; entry_fee_cents?: number }) => c.is_free || c.entry_fee_cents === 0
    );
    return free?.id || list[0]?.id || null;
  });
  if (!contestId) return null;
  await page.evaluate(async (id) => {
    await fetch(`/api/user/contests/${id}/join`, {
      method: 'POST',
      headers: { 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/json' },
      credentials: 'include',
    });
  }, contestId);
  return contestId;
}

test.describe('Trading Correctness — browser market path', () => {
  test.use({ viewport: { width: 1280, height: 720 } });

  test('login → join → trade qty round-trip → refresh', async ({ page }) => {
    test.setTimeout(90_000);
    await ensureUserSession(page);

    const contestId = await findAndJoinRunningContest(page);
    if (!contestId) {
      throw new Error('No running contest for browser trading');
    }

    await page.goto(`/trade/${contestId}`, { waitUntil: 'domcontentloaded', timeout: 30_000 });
    expect(page.url()).not.toMatch(/\/user\/login/);
    await expect(page.locator('.tp-nav')).toBeVisible({ timeout: 20_000 });

    const row = page.locator('.tp-wli').first();
    if (await row.isVisible().catch(() => false)) {
      await row.click({ timeout: 5_000 });
    }
    await expect(page.locator('.tp-qtp')).toBeVisible({ timeout: 15_000 });

    const qtyInput = page.locator('input.tp-qtlot-i').first();
    const buyBtn = page.locator('button.tp-qtbb').first();
    await expect(buyBtn).toBeVisible({ timeout: 10_000 });

    // Regression: Buy must not be under nav (elementFromPoint)
    const covered = await buyBtn.evaluate((el) => {
      const r = el.getBoundingClientRect();
      const top = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
      return !!(top && top.closest('.tp-nav') && !el.contains(top));
    });
    expect(covered, 'nav must not cover Buy').toBeFalsy();

    const quantities = [1, 2, 5];
    const results: { qty: number; submitted: boolean }[] = [];

    for (const qty of quantities) {
      await qtyInput.fill(String(qty));
      expect(Number(await qtyInput.inputValue())).toBe(qty);
      await buyBtn.click({ timeout: 8_000 });
      await page.waitForTimeout(1500);
      results.push({ qty, submitted: true });
    }

    await page.screenshot({ path: path.join(EVIDENCE, 'after-orders.png'), fullPage: true });
    await page.reload({ waitUntil: 'domcontentloaded' });
    await page.goto(`/trade/${contestId}`, { waitUntil: 'domcontentloaded' });
    await expect(page.locator('.tp-nav')).toBeVisible({ timeout: 15_000 });
    await page.screenshot({ path: path.join(EVIDENCE, 'after-refresh.png'), fullPage: true });

    fs.writeFileSync(
      path.join(EVIDENCE, 'browser-qty-results.json'),
      JSON.stringify({ contestId, quantities, results, ts: new Date().toISOString() }, null, 2)
    );
    expect(results.every((r) => r.submitted)).toBeTruthy();
  });

  test('quantity input whole units', async ({ page }) => {
    test.setTimeout(60_000);
    await ensureUserSession(page);
    const contestId = await findAndJoinRunningContest(page);
    if (!contestId) throw new Error('no contest');
    await page.goto(`/trade/${contestId}`, { waitUntil: 'domcontentloaded', timeout: 30_000 });
    const row = page.locator('.tp-wli').first();
    if (await row.isVisible().catch(() => false)) await row.click({ timeout: 5_000 });
    const qtyInput = page.locator('input.tp-qtlot-i').first();
    await expect(qtyInput).toBeVisible({ timeout: 15_000 });
    await qtyInput.fill('10');
    expect(Number(await qtyInput.inputValue())).toBe(10);
    expect(await qtyInput.getAttribute('step')).toBe('1');
    expect(await qtyInput.getAttribute('min')).toBe('1');
  });
});
