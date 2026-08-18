import { test, expect } from '@playwright/test';
import { mockApiResponse } from '../../../e2e/fixtures';

async function seedShellApis(page: import('@playwright/test').Page) {
  await mockApiResponse(page, '**/api/user/wallet**', {
    balance_cents: 2100,
    currency: 'USD',
    status: 'active',
  });
  await mockApiResponse(page, '**/api/user/me/stats**', {
    total_contests: 2,
    total_wins: 0,
    win_rate: 0,
  });
  await mockApiResponse(page, '**/api/user/global-leaderboard**', {
    entries: [],
    user_rank: null,
  });
  await mockApiResponse(page, '**/api/user/contests**', []);
  await mockApiResponse(page, '**/api/user/me/tickets**', { tickets: [], total: 0, has_more: false });
  await mockApiResponse(page, '**/api/user/me/tickets/unread-count**', { count: 2 });
  await mockApiResponse(page, '**/api/user/notifications/unread-count**', { count: 3 });
  await mockApiResponse(page, '**/api/user/me/tournaments**', { tournaments: [] });
  await mockApiResponse(page, '**/api/user/me/history**', { contests: [] });
  await mockApiResponse(page, '**/api/user/notifications**', { notifications: [], total: 0 });
}

test.describe('Canonical UserNavbar', () => {
  test('mobile: fits viewport and navigates wallet/notifications/support', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await seedShellApis(page);
    await page.goto('/user/dashboard');

    const nav = page.locator('header.user-navbar');
    await expect(nav).toBeVisible({ timeout: 15000 });

    const overflow = await page.evaluate(() => {
      const de = document.documentElement;
      return { scrollWidth: de.scrollWidth, clientWidth: de.clientWidth };
    });
    expect(overflow.scrollWidth).toBeLessThanOrEqual(overflow.clientWidth + 2);

    await nav.locator('.un-wallet').click();
    await expect(page).toHaveURL(/\/user\/wallet/);

    await page.goto('/user/dashboard');
    await expect(nav).toBeVisible();
    await nav.getByLabel(/اعلان|notification/i).click();
    await expect(page).toHaveURL(/\/user\/notifications/);

    await page.goto('/user/dashboard');
    await expect(nav).toBeVisible();
    await nav.getByLabel(/پشتیبانی|support/i).click();
    await expect(page).toHaveURL(/\/user\/tickets/);
  });

  test('desktop: same navbar actions remain usable', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await seedShellApis(page);
    await page.goto('/user/dashboard');

    const nav = page.locator('header.user-navbar');
    await expect(nav).toBeVisible({ timeout: 15000 });
    await expect(nav.locator('.un-wallet')).toBeVisible();
    await expect(nav.getByLabel(/اعلان|notification/i)).toBeVisible();
    await expect(nav.getByLabel(/پشتیبانی|support/i)).toBeVisible();

    const overflow = await page.evaluate(() => {
      const de = document.documentElement;
      return { scrollWidth: de.scrollWidth, clientWidth: de.clientWidth };
    });
    expect(overflow.scrollWidth).toBeLessThanOrEqual(overflow.clientWidth + 2);
  });
});
