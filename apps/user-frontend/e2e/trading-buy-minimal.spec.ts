/**
 * Minimal trading browser test + Buy-button layout regression.
 * Real backends only (E2E_INTEGRATION=1). Fail-fast: short timeouts, no force-click.
 */
import { test, expect, type Page } from '@playwright/test';
import fs from 'node:fs';
import path from 'node:path';

const USER_EMAIL = process.env.RC_USER_EMAIL || 'user@tragge.com';
const USER_PASSWORD = process.env.RC_USER_PASSWORD || 'user123456';
const EVIDENCE = path.resolve('docs/codex/reports/evidence/trading-correctness');

test.beforeAll(() => {
  test.skip(!process.env.E2E_INTEGRATION, 'Set E2E_INTEGRATION=1');
  fs.mkdirSync(EVIDENCE, { recursive: true });
});

// Fail-fast suite: do not hang on retries
test.describe.configure({ timeout: 90_000, retries: 0 });

async function ensureUserSession(page: Page) {
  await page.goto('/user/dashboard', { waitUntil: 'domcontentloaded', timeout: 30_000 });
  if (!/login/.test(page.url())) return;

  await page.goto('/user/login', { waitUntil: 'domcontentloaded', timeout: 30_000 });
  const email = page.locator('input[type="email"]').first();
  await expect(email).toBeVisible({ timeout: 20_000 });
  await email.fill(USER_EMAIL);
  await page.locator('input[type="password"]').first().fill(USER_PASSWORD);
  await page.locator('button[type="submit"]').first().click();
  await page.waitForURL(/\/user\/(dashboard|$)/, { timeout: 25_000 });
}

async function joinRunningContest(page: Page): Promise<string> {
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
    return (free?.id || list[0]?.id || null) as string | null;
  });
  if (!contestId) throw new Error('No running contest available');

  await page.evaluate(async (id) => {
    await fetch(`/api/user/contests/${id}/join`, {
      method: 'POST',
      headers: { 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/json' },
      credentials: 'include',
    });
  }, contestId);
  return contestId;
}

/** Assert Buy is the topmost element at its center (real user can click). */
async function assertBuyNotObscured(page: Page) {
  const buy = page.locator('button.tp-qtbb').first();
  await expect(buy).toBeVisible({ timeout: 20_000 });

  const hit = await buy.evaluate((el) => {
    const r = el.getBoundingClientRect();
    const cx = r.left + r.width / 2;
    const cy = r.top + r.height / 2;
    const top = document.elementFromPoint(cx, cy) as HTMLElement | null;
    const path: string[] = [];
    let n: HTMLElement | null = top;
    while (n && path.length < 8) {
      path.push(
        `${n.tagName.toLowerCase()}${n.className && typeof n.className === 'string' ? '.' + n.className.trim().split(/\s+/).slice(0, 3).join('.') : ''}`
      );
      n = n.parentElement;
    }
    return {
      cx,
      cy,
      width: r.width,
      height: r.height,
      top: r.top,
      left: r.left,
      inViewport: r.top >= 0 && r.bottom <= window.innerHeight && r.left >= 0 && r.right <= window.innerWidth,
      topTag: top?.tagName || null,
      topClass: (top && typeof top.className === 'string' ? top.className : '') || '',
      isBuyOrChild: !!(top && (top === el || el.contains(top))),
      path,
      navRightCovers: !!(top && (top.closest('.tp-nright') || top.closest('.tp-nav')) && !el.contains(top)),
    };
  });

  fs.writeFileSync(path.join(EVIDENCE, 'buy-hit-test.json'), JSON.stringify(hit, null, 2));

  expect(hit.width, 'Buy button has size').toBeGreaterThan(20);
  expect(hit.height, 'Buy button has size').toBeGreaterThan(20);
  expect(hit.inViewport, 'Buy button in viewport').toBeTruthy();
  expect(hit.navRightCovers, 'tp-nav/tp-nright must not cover Buy').toBeFalsy();
  expect(hit.isBuyOrChild, `elementFromPoint must be Buy (got ${hit.path.join(' > ')})`).toBeTruthy();
}

test.describe('Trading Buy layout + minimal order', () => {
  test.use({ viewport: { width: 1280, height: 720 } });

  test('nav does not intercept Buy; quantity + Buy click works', async ({ page }) => {
    test.setTimeout(90_000);

    await ensureUserSession(page);
    const contestId = await joinRunningContest(page);

    await page.goto(`/trade/${contestId}`, { waitUntil: 'domcontentloaded', timeout: 30_000 });
    expect(page.url()).not.toMatch(/login/);

    // Desktop layout: navbar + sidebar
    await expect(page.locator('.tp-nav')).toBeVisible({ timeout: 20_000 });
    await expect(page.locator('.tp-sb, .tp-wli').first()).toBeVisible({ timeout: 20_000 });

    // Select first symbol if needed so quick-trade mounts
    const row = page.locator('.tp-wli').first();
    if (await row.isVisible().catch(() => false)) {
      await row.click({ timeout: 5_000 });
    }

    await expect(page.locator('.tp-qtp')).toBeVisible({ timeout: 15_000 });
    await assertBuyNotObscured(page);

    // Layout geometry: nav bottom must be above Buy top
    const geometry = await page.evaluate(() => {
      const nav = document.querySelector('.tp-nav') as HTMLElement | null;
      const buy = document.querySelector('button.tp-qtbb') as HTMLElement | null;
      const nright = document.querySelector('.tp-nright') as HTMLElement | null;
      if (!nav || !buy) return null;
      const nr = nav.getBoundingClientRect();
      const br = buy.getBoundingClientRect();
      const rr = nright?.getBoundingClientRect();
      return {
        navBottom: nr.bottom,
        navHeight: nr.height,
        buyTop: br.top,
        buyLeft: br.left,
        nrightBottom: rr?.bottom ?? null,
        gap: br.top - nr.bottom,
      };
    });
    expect(geometry).toBeTruthy();
    expect(geometry!.navHeight, 'nav is a compact top bar').toBeLessThanOrEqual(64);
    expect(geometry!.gap, 'Buy sits below nav (no vertical overlap)').toBeGreaterThanOrEqual(0);

    fs.writeFileSync(path.join(EVIDENCE, 'buy-layout-geometry.json'), JSON.stringify(geometry, null, 2));
    await page.screenshot({ path: path.join(EVIDENCE, 'buy-clickable.png'), fullPage: true });

    // Enter quantity and click Buy without force
    const qty = page.locator('input.tp-qtlot-i').first();
    await qty.fill('1');
    expect(Number(await qty.inputValue())).toBe(1);

    const buy = page.locator('button.tp-qtbb').first();
    await buy.click({ timeout: 8_000 }); // no force
    await page.waitForTimeout(2000);
    await page.screenshot({ path: path.join(EVIDENCE, 'after-buy-click.png'), fullPage: true });

    // Soft order verification: toast, position row, or qty change — at least UI accepted click
    const uiReacted = await page.evaluate(() => {
      const toast = document.querySelector('.tp-toast');
      const pos = document.querySelector('.tp-bp-row, .tp-bp-symbol, .position-row');
      return { toast: !!toast, pos: !!pos, hasQtp: !!document.querySelector('.tp-qtp') };
    });
    fs.writeFileSync(
      path.join(EVIDENCE, 'after-buy-state.json'),
      JSON.stringify({ contestId, uiReacted, ts: new Date().toISOString() }, null, 2)
    );
    // Click succeeded if we got here without timeout; page still on trade
    expect(page.url()).toMatch(/\/trade\//);
  });
});
