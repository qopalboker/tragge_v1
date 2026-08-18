import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function read(rel: string): string {
  return readFileSync(resolve(root, rel), 'utf8');
}

describe('Telegram auth bootstrap ordering', () => {
  it('installs the router only after bootstrapFull completes', () => {
    const main = read('main.ts');
    const bootstrapIdx = main.indexOf('await auth.bootstrapFull()');
    const useRouterIdx = main.indexOf('app.use(router)');
    expect(bootstrapIdx).toBeGreaterThan(-1);
    expect(useRouterIdx).toBeGreaterThan(-1);
    expect(bootstrapIdx).toBeLessThan(useRouterIdx);
    // Must not run Telegram exchange after router install only.
    expect(main).not.toMatch(/app\.use\(router\)[\s\S]*bootstrapTelegramSession/);
  });

  it('router never redirects Telegram Mini App to /user/login when unauthenticated', () => {
    const router = read('router/index.ts');
    expect(router).toContain('telegram-auth-error');
    expect(router).toContain('telegram_authenticating');
    // Unauthenticated miniapp path must not be a bare login redirect.
    expect(router).toMatch(/inTelegram[\s\S]*telegram-auth-error/);
    expect(router).toContain("path: '/user/login'");
  });

  it('auth store exposes bootstrap phases used by the guard', () => {
    const auth = read('stores/auth.ts');
    expect(auth).toContain('telegram_authenticating');
    expect(auth).toContain('bootstrapFull');
    expect(auth).toContain('loginWithTelegram');
    expect(auth).toContain('retryTelegramAuth');
    expect(auth).toContain('waitForSignedInitData');
    expect(auth).toContain('init_data');
    expect(auth).not.toContain('initDataUnsafe');
  });

  it('miniapp routes reuse UserLayout + DashboardPage (single design)', () => {
    const routes = read('modules/miniapp/routes.ts');
    expect(routes).toContain('UserLayout.vue');
    expect(routes).toContain('DashboardPage.vue');
    expect(routes).not.toMatch(/miniapp\/views\/HomePage/);
    expect(routes).not.toContain('MiniAppLayout');
  });

  it('legacy MiniAppLayout and miniapp HomePage are removed from the tree', async () => {
    const fs = await import('node:fs');
    const path = await import('node:path');
    const mini = resolve(root, 'modules/miniapp');
    expect(fs.existsSync(path.join(mini, 'components', 'MiniAppLayout.vue'))).toBe(false);
    expect(fs.existsSync(path.join(mini, 'views', 'HomePage.vue'))).toBe(false);
    expect(fs.existsSync(path.join(mini, 'styles', 'tokens.css'))).toBe(false);
  });
});
