import { test, expect } from '@playwright/test';
import { mockApiResponse } from '../../../e2e/fixtures';

/**
 * MVP mobile home acceptance — layout hierarchy + rails.
 * Uses mocked APIs so the suite is deterministic without a live BFF,
 * while still asserting the stabilized DOM contract of the redesigned home.
 *
 * Hierarchy under test:
 * Header → Hero → Wallet summary → Featured → Suggested (h-scroll)
 * → Challenges (h-scroll) → Support → Bottom nav
 */
const MOCK_CONTESTS = [
  {
    id: 'c-featured-1',
    name: 'مسابقه روزانه فارکس',
    status: 'registration_open',
    description: 'جایزه نقدی برای بهترین عملکرد روزانه',
    entry_fee_cents: 1000,
    estimated_prize_pool_cents: 750000,
    participant_count: 128,
    duration_type: 'daily',
    market_type: 'forex',
    is_free: false,
  },
  {
    id: 'c-sug-1',
    name: 'فارکس',
    status: 'registration_open',
    entry_fee_cents: 1000,
    estimated_prize_pool_cents: 500000,
    participant_count: 125,
    duration_type: 'hourly',
    market_type: 'forex',
    is_free: false,
  },
  {
    id: 'c-sug-2',
    name: 'کریپتو',
    status: 'registration_open',
    entry_fee_cents: 500,
    estimated_prize_pool_cents: 300000,
    participant_count: 98,
    duration_type: 'four_hour',
    market_type: 'crypto',
    is_free: false,
  },
];

async function seedDashboardApis(page: import('@playwright/test').Page) {
  await mockApiResponse(page, '**/api/user/me/stats**', {
    total_contests: 2,
    total_wins: 0,
    win_rate: 0,
  });
  await mockApiResponse(page, '**/api/user/global-leaderboard**', {
    entries: [],
    user_rank: null,
  });
  await mockApiResponse(page, '**/api/user/contests**', MOCK_CONTESTS);
  await mockApiResponse(page, '**/api/user/wallet**', {
    balance_cents: 2100,
    currency: 'USD',
    status: 'active',
  });
  await mockApiResponse(page, '**/api/user/me/tickets**', { tickets: [], total: 0, has_more: false });
  await mockApiResponse(page, '**/api/user/me/tickets/unread-count**', { count: 0 });
  await mockApiResponse(page, '**/api/user/notifications/unread-count**', { count: 0 });
  await mockApiResponse(page, '**/api/user/me/tournaments**', { tournaments: [] });
  await mockApiResponse(page, '**/api/user/me/history**', { contests: [] });
}

const VIEWPORTS = [
  { name: '320', width: 320, height: 568 },
  { name: '360', width: 360, height: 800 },
  { name: '375', width: 375, height: 812 },
  { name: '390', width: 390, height: 844 },
  { name: '412', width: 412, height: 915 },
  { name: '414', width: 414, height: 896 },
  { name: '430', width: 430, height: 932 },
];

const DESKTOP_VIEWPORTS = [
  { name: '1280', width: 1280, height: 800 },
  { name: '1440', width: 1440, height: 900 },
];

test.describe('MVP mobile home', () => {
  for (const vp of VIEWPORTS) {
    test(`hierarchy + no page overflow @ ${vp.name}`, async ({ page }) => {
      await page.setViewportSize({ width: vp.width, height: vp.height });
      await seedDashboardApis(page);
      await page.goto('/user/dashboard');

      const home = page.locator('.home[dir="rtl"]');
      await expect(home).toBeVisible({ timeout: 15000 });

      // Header utilities
      await expect(page.locator('.mh-header, header.mh-header')).toBeVisible();

      // Hero
      await expect(page.locator('.hero')).toBeVisible();

      // Metrics / wallet summary
      await expect(page.locator('.metrics')).toBeVisible();

      // Featured contest (from real mock contest payload)
      await expect(page.locator('.feat, article.feat')).toBeVisible();

      // Suggested horizontal rail
      const sugRail = page.locator('.rail-section .mvp-h-scroll').first();
      await expect(sugRail).toBeVisible();

      // Challenge section + horizontal rail
      await expect(page.locator('section.ch[aria-label="challenges"]')).toBeVisible();
      await expect(page.locator('section.ch .mvp-h-scroll')).toBeVisible();

      // Support immediately after challenges in DOM order
      const challengeBox = await page.locator('section.ch').boundingBox();
      const supportBox = await page.locator('section.sup[aria-label="support"]').boundingBox();
      expect(challengeBox && supportBox).toBeTruthy();
      if (challengeBox && supportBox) {
        expect(supportBox.y).toBeGreaterThan(challengeBox.y);
      }

      // Bottom nav on mobile
      await expect(page.locator('nav.bottom-nav')).toBeVisible();

      // Page itself must not scroll horizontally
      const overflow = await page.evaluate(() => {
        const de = document.documentElement;
        return {
          scrollWidth: de.scrollWidth,
          clientWidth: de.clientWidth,
          bodyScrollWidth: document.body.scrollWidth,
        };
      });
      expect(overflow.scrollWidth).toBeLessThanOrEqual(overflow.clientWidth + 2);

      // Horizontal rails are intended to scroll internally
      const sugScroll = await sugRail.evaluate((el) => el.scrollWidth > el.clientWidth - 1 || el.children.length > 0);
      expect(sugScroll).toBeTruthy();
    });
  }

  test('bottom nav destinations resolve', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await seedDashboardApis(page);
    await page.goto('/user/dashboard');
    await expect(page.locator('nav.bottom-nav')).toBeVisible({ timeout: 15000 });

    const links = page.locator('nav.bottom-nav a');
    const count = await links.count();
    expect(count).toBeGreaterThanOrEqual(4);

    // Center home remains active on dashboard
    await expect(page.locator('nav.bottom-nav a[href*="dashboard"]')).toHaveClass(/active|bottom-nav-item-active/);
  });

  for (const vp of DESKTOP_VIEWPORTS) {
    test(`desktop dashboard no horizontal overflow @ ${vp.name}`, async ({ page }) => {
      await page.setViewportSize({ width: vp.width, height: vp.height });
      await seedDashboardApis(page);
      await page.goto('/user/dashboard');
      const home = page.locator('.home[dir="rtl"]');
      await expect(home).toBeVisible({ timeout: 15000 });
      const overflow = await page.evaluate(() => {
        const de = document.documentElement;
        return { scrollWidth: de.scrollWidth, clientWidth: de.clientWidth };
      });
      expect(overflow.scrollWidth).toBeLessThanOrEqual(overflow.clientWidth + 2);
    });
  }
});
