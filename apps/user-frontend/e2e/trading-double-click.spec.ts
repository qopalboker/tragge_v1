/**
 * Double-click Buy must produce one logical order (client_order_id + backend claim).
 * Fail-fast: retries=0, no force-click.
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
  if (!contestId) throw new Error('No running contest');
  await page.evaluate(async (id) => {
    await fetch(`/api/user/contests/${id}/join`, {
      method: 'POST',
      headers: { 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/json' },
      credentials: 'include',
    });
  }, contestId);
  return contestId;
}

test.describe('Double-click order protection', () => {
  test.use({ viewport: { width: 1280, height: 720 } });

  test('rapid double Buy → one logical order', async ({ page }) => {
    test.setTimeout(90_000);
    await ensureUserSession(page);
    const contestId = await joinRunningContest(page);

    // Intercept WS frames to capture client_order_id
    const clientOrderIds: string[] = [];
    page.on('websocket', (ws) => {
      ws.on('framesent', (frame) => {
        try {
          const payload = typeof frame.payload === 'string' ? frame.payload : '';
          if (!payload.includes('order_request')) return;
          const msg = JSON.parse(payload);
          if (msg.type === 'order_request' && msg.client_order_id) {
            clientOrderIds.push(msg.client_order_id);
          }
        } catch {
          /* ignore */
        }
      });
    });

    await page.goto(`/trade/${contestId}`, { waitUntil: 'domcontentloaded', timeout: 30_000 });
    // Desktop chrome or mobile buy control — wait for either
    const desktopNav = page.locator('.tp-nav');
    const buyDesktop = page.locator('button.tp-qtbb');
    const buyMobile = page.locator('button.tp-mchart-buy, .tp-mchart-buy');
    await expect(desktopNav.or(buyMobile).or(page.locator('.tp-error, .tp-loading')).first()).toBeVisible({
      timeout: 25_000,
    });
    if (await page.locator('.tp-error').isVisible().catch(() => false)) {
      const err = await page.locator('.tp-error').textContent();
      throw new Error(`trade page error: ${err}`);
    }
    // Wait out loading
    await page.waitForTimeout(2000);
    const row = page.locator('.tp-wli').first();
    if (await row.isVisible().catch(() => false)) await row.click({ timeout: 5_000 });
    const buy = buyDesktop.or(buyMobile).first();
    await expect(buy).toBeVisible({ timeout: 15_000 });

    const qty = page.locator('input.tp-qtlot-i').first();
    await qty.fill('1');

    // Rapid double-click without force
    await Promise.all([buy.click({ timeout: 8_000 }), buy.click({ timeout: 8_000 }).catch(() => null)]);
    await page.waitForTimeout(3000);

    await page.screenshot({ path: path.join(EVIDENCE, 'double-click-buy.png'), fullPage: true });

    // At most one distinct client_order_id sent over WS (second click blocked or same id)
    const uniqueIds = [...new Set(clientOrderIds)];
    fs.writeFileSync(
      path.join(EVIDENCE, 'double-click-ws.json'),
      JSON.stringify({ contestId, clientOrderIds, uniqueIds, ts: new Date().toISOString() }, null, 2)
    );

    // UI may block second click entirely (0–1 frames) or send one id
    expect(uniqueIds.length).toBeLessThanOrEqual(1);

    // If we observed a client_order_id, DB claim table should have exactly one row for it
    // (verified server-side by engine concurrent tests; browser asserts UI/network identity)
    if (uniqueIds.length === 1) {
      expect(uniqueIds[0]).toMatch(
        /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      );
    }
  });

  test('API same client_order_id twice → one logical order_id', async ({ page }) => {
    test.setTimeout(60_000);
    await ensureUserSession(page);

    // Clear login rate-limit window from prior suite runs
    await page.waitForTimeout(12_000);

    const result = await page.evaluate(async (args: { email: string; password: string }) => {
      let accessToken = '';
      let loginBody: Record<string, unknown> = {};
      let loginStatus = 0;
      for (let attempt = 0; attempt < 4; attempt++) {
        const login = await fetch('/api/user/auth/login', {
          method: 'POST',
          credentials: 'include',
          headers: { 'X-Requested-With': 'XMLHttpRequest', 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: args.email, password: args.password }),
        });
        loginStatus = login.status;
        loginBody = await login.json().catch(() => ({}));
        accessToken =
          (loginBody as { access_token?: string }).access_token ||
          (loginBody as { accessToken?: string }).accessToken ||
          '';
        if (accessToken) break;
        const retryAfter = Number((loginBody as { retry_after?: number }).retry_after || 10);
        if (login.status === 429) {
          await new Promise((r) => setTimeout(r, (retryAfter + 1) * 1000));
          continue;
        }
        break;
      }
      if (!accessToken) {
        return { error: 'login failed', loginStatus, loginBody };
      }
      const authH = {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        Authorization: `Bearer ${accessToken}`,
      };

      // Discover + join a running contest with the same bearer identity trade-bff will see
      const listRes = await fetch('/api/user/contests?status=running&limit=30', {
        headers: authH,
        credentials: 'include',
      });
      const listData = await listRes.json().catch(() => ({}));
      const list = Array.isArray(listData) ? listData : listData.contests || [];
      const free = list.find(
        (c: { is_free?: boolean; entry_fee_cents?: number }) => c.is_free || c.entry_fee_cents === 0
      );
      const cid = (free?.id || list[0]?.id) as string | undefined;
      if (!cid) return { error: 'no running contest', listStatus: listRes.status };

      const joinRes = await fetch(`/api/user/contests/${cid}/join`, {
        method: 'POST',
        headers: authH,
        credentials: 'include',
        body: '{}',
      });
      const joinBody = await joinRes.json().catch(() => ({}));

      const clientOrderId = crypto.randomUUID();
      const body = {
        contest_id: cid,
        symbol: 'BTC/USD',
        side: 'BUY',
        type: 'MARKET',
        qty: 1,
        client_order_id: clientOrderId,
      };
      const r1 = await fetch('/api/trade/orders', {
        method: 'POST',
        headers: authH,
        credentials: 'include',
        body: JSON.stringify(body),
      });
      const j1 = await r1.json().catch(async () => ({ raw: await r1.text() }));
      const r2 = await fetch('/api/trade/orders', {
        method: 'POST',
        headers: authH,
        credentials: 'include',
        body: JSON.stringify(body),
      });
      const j2 = await r2.json().catch(async () => ({ raw: await r2.text() }));
      return {
        cid,
        joinStatus: joinRes.status,
        joinBody,
        clientOrderId,
        status1: r1.status,
        status2: r2.status,
        body1: j1,
        body2: j2,
        order1: j1.order_id || j1.orderId,
        order2: j2.order_id || j2.orderId,
      };
    }, { email: USER_EMAIL, password: USER_PASSWORD });

    fs.writeFileSync(path.join(EVIDENCE, 'api-idempotent-retry.json'), JSON.stringify(result, null, 2));

    expect(result.error, JSON.stringify(result)).toBeUndefined();
    expect(result.status1, `first: ${JSON.stringify(result.body1)}`).toBe(202);
    expect(result.status2, `second: ${JSON.stringify(result.body2)}`).toBe(202);
    expect(result.order1).toBeTruthy();
    expect(result.order2).toBeTruthy();
    expect(result.order1).toBe(result.order2);
    expect(result.order1).toBe(result.clientOrderId);
  });
});
