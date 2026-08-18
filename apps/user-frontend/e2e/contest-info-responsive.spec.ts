import { test, expect } from '@playwright/test';
import { mockApiResponse } from '../../../e2e/fixtures';

/**
 * Contest Info — runtime resilience + responsive shell.
 * Uses mocked APIs so the suite stays deterministic without a live BFF.
 */

const CONTEST_ID = 'c-info-1';

function detailPayload(overrides: Record<string, unknown> = {}) {
  return {
    id: CONTEST_ID,
    name: 'مسابقه تست فارکس',
    description: 'توضیحات مسابقه',
    status: 'registration_open',
    market_type: 'forex',
    duration_type: 'rush_30min',
    start_time: new Date(Date.now() + 10 * 60_000).toISOString(),
    end_time: new Date(Date.now() + 40 * 60_000).toISOString(),
    starts_at: new Date(Date.now() + 10 * 60_000).toISOString(),
    ends_at: new Date(Date.now() + 40 * 60_000).toISOString(),
    entry_fee_cents: 1000,
    is_free: false,
    qty_total: 100000,
    available_qty: 100000,
    min_participants: 2,
    current_participants: 1,
    participant_count: 1,
    prize_pool_cents: 0,
    estimated_prize_pool_cents: 0,
    first_place_prize_cents: 0,
    user_joined: false,
    symbols: ['EUR/USD', 'GBP/USD'],
    server_time: new Date().toISOString(),
    ...overrides,
  };
}

async function seedApis(page: import('@playwright/test').Page, detail = detailPayload()) {
  await mockApiResponse(page, '**/api/user/wallet**', {
    balance_cents: 50000,
    currency: 'USD',
    status: 'active',
  });
  await mockApiResponse(page, '**/api/user/me/tickets/unread-count**', { count: 0 });
  await mockApiResponse(page, '**/api/user/notifications/unread-count**', { count: 0 });
  await mockApiResponse(page, `**/api/user/contests/${CONTEST_ID}/participants**`, {
    participants: [],
  });
  await mockApiResponse(page, `**/api/user/contests/${CONTEST_ID}**`, detail);
  await mockApiResponse(page, '**/api/user/contests**', [detail]);
  await mockApiResponse(page, '**/api/user/me/history**', { contests: [] });
}

const VIEWPORTS = [
  { name: '360', width: 360, height: 800 },
  { name: '390', width: 390, height: 844 },
  { name: '412', width: 412, height: 915 },
  { name: '430', width: 430, height: 932 },
];

test.describe('Contest Info responsive + runtime', () => {
  for (const vp of VIEWPORTS) {
    test(`renders without crash @ ${vp.name}`, async ({ page }) => {
      const pageErrors: string[] = [];
      page.on('pageerror', (err) => pageErrors.push(String(err)));

      await page.setViewportSize({ width: vp.width, height: vp.height });
      await seedApis(page);
      await page.goto(`/user/contests/${CONTEST_ID}`);

      await expect(page.locator('.contest-details-page')).toBeVisible({ timeout: 15000 });
      await expect(page.locator('.tournament-details-card')).toBeVisible();
      await expect(page.locator('.countdown-block, .details-list')).toBeVisible();

      const overflow = await page.evaluate(() => {
        const de = document.documentElement;
        return { scrollWidth: de.scrollWidth, clientWidth: de.clientWidth };
      });
      expect(overflow.scrollWidth).toBeLessThanOrEqual(overflow.clientWidth + 2);
      expect(pageErrors.filter((e) => /toLocaleString/i.test(e))).toEqual([]);
    });
  }

  test('missing qty_total does not crash (transitional payload)', async ({ page }) => {
    const pageErrors: string[] = [];
    page.on('pageerror', (err) => pageErrors.push(String(err)));

    await page.setViewportSize({ width: 390, height: 844 });
    const partial = detailPayload();
    delete (partial as { qty_total?: number }).qty_total;
    delete (partial as { available_qty?: number }).available_qty;
    await seedApis(page, partial);
    await page.goto(`/user/contests/${CONTEST_ID}`);

    await expect(page.locator('.tournament-details-card')).toBeVisible({ timeout: 15000 });
    await expect(page.locator('.contest-details-page')).toBeVisible();
    expect(pageErrors.filter((e) => /toLocaleString/i.test(e))).toEqual([]);
  });

  test('background refresh does not full-reload the document', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await seedApis(page);
    await page.goto(`/user/contests/${CONTEST_ID}`);
    await expect(page.locator('.tournament-details-card')).toBeVisible({ timeout: 15000 });

    const before = await page.evaluate(() => performance.navigation?.type ?? 0);
    await page.waitForTimeout(1200);
    const href = page.url();
    expect(href).toContain(`/user/contests/${CONTEST_ID}`);
    const after = await page.evaluate(() => performance.navigation?.type ?? 0);
    expect(after).toBe(before);
  });
});
