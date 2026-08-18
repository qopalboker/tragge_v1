import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const src = resolve(dirname(fileURLToPath(import.meta.url)), '../..');

function read(rel: string): string {
  return readFileSync(resolve(src, rel), 'utf8');
}

describe('canonical User UI contracts', () => {
  it('UserLayout exposes canonical shell markers', () => {
    const layout = read('modules/user/components/layout/UserLayout.vue');
    expect(layout).toContain('data-canonical-shell="user"');
    expect(layout).toContain('data-design="mvp"');
    expect(layout).not.toContain('MiniAppLayout');
    expect(layout).not.toMatch(/--ma-/);
  });

  it('MVP tokens remap shared indigo primary onto emerald', () => {
    const tokens = read('styles/mvp-design-tokens.css');
    expect(tokens).toContain('--mvp-emerald');
    expect(tokens).toContain('--color-primary: var(--mvp-emerald)');
    expect(tokens).toContain('--theme-accent: var(--mvp-emerald)');
    expect(tokens).not.toMatch(/--color-primary:\s*#6366F1/i);
  });

  it('user theme wrapper forces MVP emerald accent on dark palette', () => {
    const theme = read('stores/theme.ts');
    expect(theme).toContain("accent = '#00d4a0'");
    expect(theme).toContain('Tragge MVP');
    expect(theme).not.toMatch(/accent\s*=\s*'#6c5ce7'/);
  });

  it('protected secondary routes mount under UserLayout', () => {
    const routes = read('modules/user/routes.ts');
    expect(routes).toContain("component: () => import('./components/layout/UserLayout.vue')");
    for (const path of [
      'notifications',
      'settings',
      'profile',
      'wallet',
      'tickets',
      'tickets/new',
      'tickets/:ticketId',
      'contests',
      'contests/:contestId',
      'dashboard',
    ]) {
      expect(routes).toContain(`path: '${path}'`);
    }
  });

  it('miniapp routes reuse UserLayout + user views', () => {
    const routes = read('modules/miniapp/routes.ts');
    expect(routes).toContain('UserLayout.vue');
    expect(routes).toContain('DashboardPage.vue');
    expect(routes).toContain('ContestsPage.vue');
    expect(routes).toContain('WalletPage.vue');
    expect(routes).toContain('ProfilePage.vue');
    expect(routes).toContain('NotificationsPage.vue');
    expect(routes).toContain('SettingsPage.vue');
    expect(routes).toContain('TicketsPage.vue');
    expect(routes).not.toContain('MiniAppLayout');
  });

  it('userShellPaths helper keeps mini and web prefixes distinct', () => {
    const helper = read('utils/userShellPaths.ts');
    expect(helper).toContain('/miniapp');
    expect(helper).toContain('/user');
    expect(helper).toContain('notifications');
    expect(helper).toContain('tickets');
    expect(helper).toContain('settings');
  });

  it('legacy Mini App shell artifacts are absent', () => {
    expect(existsSync(resolve(src, 'modules/miniapp/components/MiniAppLayout.vue'))).toBe(false);
    expect(existsSync(resolve(src, 'modules/miniapp/styles/tokens.css'))).toBe(false);
    expect(existsSync(resolve(src, 'modules/miniapp/views/HomePage.vue'))).toBe(false);
  });

  it('secondary pages do not hardcode indigo accent fallbacks', () => {
    const files = [
      'modules/user/views/TicketsPage.vue',
      'modules/user/views/TicketChatPage.vue',
      'modules/user/views/NewTicketPage.vue',
      'modules/user/views/NotificationsPage.vue',
      'modules/user/views/SettingsPage.vue',
      'modules/user/views/ProfilePage.vue',
      'modules/user/views/WalletPage.vue',
    ];
    for (const file of files) {
      const srcText = read(file);
      expect(srcText, file).not.toMatch(/#6366[Ff]1/);
      expect(srcText, file).not.toMatch(/rgba\(99,\s*102,\s*241/);
    }
  });
});
