import { readFileSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const root = resolve(dirname(fileURLToPath(import.meta.url)));

function read(name: string): string {
  return readFileSync(resolve(root, name), 'utf8');
}

describe('Telegram initData readiness (source contracts)', () => {
  it('exports waitForSignedInitData and does not use setTimeout', () => {
    const src = read('telegram.ts');
    expect(src).toContain('waitForSignedInitData');
    expect(src).toContain('waitForTelegramScriptReady');
    expect(src).toContain('requestAnimationFrame');
    expect(src).not.toMatch(/setTimeout\s*\(/);
    expect(src).toContain('init_data_available');
    expect(src).toContain('bridge_absent');
    expect(src).toContain('getTelegramDiagnostics');
  });

  it('diagnostics omit raw initData payload and expose safe bridge fields', () => {
    const src = read('telegram.ts');
    expect(src).toContain('initDataLength');
    expect(src).toContain('initDataPresent');
    expect(src).toContain('telegramScriptLoaded');
    expect(src).toContain('telegramObjectPresent');
    expect(src).toContain('webAppObjectPresent');
    // Must not return initData string from diagnostics helper body.
    const diagFn = src.slice(src.indexOf('export function getTelegramDiagnostics'));
    expect(diagFn).not.toMatch(/return\s*\{[^}]*initData\s*:/);
  });

  it('error page Retry calls retryTelegramAuth (not silent no-op)', () => {
    const page = read('views/TelegramAuthErrorPage.vue');
    expect(page).toContain('retryTelegramAuth');
    expect(page).toContain('retrying');
    expect(page).not.toMatch(/if\s*\(\s*!isTelegramMiniApp\(\)\s*\)\s*return\s*;/);
  });
});
