/**
 * RC integration auth setup — one real login, shared storage state.
 * Requires E2E_INTEGRATION=1 and live user BFF + Vite.
 */
import { mkdir } from 'node:fs/promises';
import { dirname } from 'node:path';
import { test as setup, expect } from '@playwright/test';

const USER_EMAIL = process.env.RC_USER_EMAIL || 'user@tragge.com';
const USER_PASSWORD = process.env.RC_USER_PASSWORD || 'user123456';
export const RC_USER_STATE = 'apps/user-frontend/e2e/.auth/rc-user.json';

setup('rc user authenticate (real backend)', async ({ page }) => {
  setup.skip(!process.env.E2E_INTEGRATION, 'integration only');
  setup.setTimeout(180_000);

  await page.goto('/user/login', { waitUntil: 'domcontentloaded', timeout: 60_000 });
  await expect(page.locator('.auth-form:not(.signup) input[type="email"]')).toBeVisible({ timeout: 30000 });

  for (let attempt = 0; attempt < 6; attempt++) {
    await page.locator('.auth-form:not(.signup) input[type="email"]').fill(USER_EMAIL);
    await page.locator('.auth-form:not(.signup) input[type="password"]').fill(USER_PASSWORD);
    await page.locator('.auth-form:not(.signup) button[type="submit"]').click();
    try {
      await page.waitForURL(/\/user\/(dashboard|$)/, { timeout: 25_000 });
      break;
    } catch {
      const txt = (await page.locator('.auth-error').textContent().catch(() => '')) || '';
      // Rate limit: wait longer between attempts
      await page.waitForTimeout(txt.match(/unavailable|rate|too many/i) ? 20000 : 4000);
      if (attempt === 5) throw new Error(`RC setup login failed: ${txt || 'timeout'}`);
    }
  }

  await mkdir(dirname(RC_USER_STATE), { recursive: true });
  await page.context().storageState({ path: RC_USER_STATE });
});
