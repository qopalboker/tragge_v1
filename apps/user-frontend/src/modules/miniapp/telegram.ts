/**
 * Telegram Mini App environment helpers.
 * WebApp script is loaded from index.html; all access is defensive.
 *
 * Identity must come only from signed initData (verified server-side).
 * Never use initDataUnsafe for authentication.
 */

export interface TelegramWebAppUser {
  id: number;
  first_name?: string;
  last_name?: string;
  username?: string;
  language_code?: string;
  photo_url?: string;
}

export interface TelegramWebApp {
  initData: string;
  initDataUnsafe?: { user?: TelegramWebAppUser; start_param?: string };
  ready: () => void;
  expand: () => void;
  close: () => void;
  BackButton?: {
    show: () => void;
    hide: () => void;
    onClick: (cb: () => void) => void;
    offClick: (cb: () => void) => void;
  };
  HapticFeedback?: {
    impactOccurred: (style: 'light' | 'medium' | 'heavy' | 'rigid' | 'soft') => void;
    notificationOccurred: (type: 'error' | 'success' | 'warning') => void;
  };
  themeParams?: Record<string, string>;
  colorScheme?: 'light' | 'dark';
  viewportHeight?: number;
  viewportStableHeight?: number;
  isExpanded?: boolean;
}

export type TelegramBridgePhase =
  | 'bridge_absent'
  | 'bridge_present_waiting_initdata'
  | 'init_data_available'
  | 'init_data_unavailable';

export function getTelegramWebApp(): TelegramWebApp | null {
  try {
    return (window as Window & { Telegram?: { WebApp?: TelegramWebApp } }).Telegram?.WebApp ?? null;
  } catch {
    return null;
  }
}

/** True when the Telegram WebApp bridge object exists (may still have empty initData). */
export function isTelegramWebAppBridgePresent(): boolean {
  return getTelegramWebApp() != null;
}

/**
 * True when we have signed initData ready for server exchange.
 * Prefer this over bridge-only checks for "can authenticate now".
 */
export function isTelegramMiniApp(): boolean {
  const data = getTelegramInitData();
  return data.length > 0;
}

/** User-Agent / bridge hint that we are likely inside Telegram (not a terminal auth decision). */
export function isLikelyTelegramClient(): boolean {
  if (isTelegramWebAppBridgePresent()) return true;
  try {
    return /Telegram/i.test(navigator.userAgent || '');
  } catch {
    return false;
  }
}

export function getTelegramInitData(): string {
  return getTelegramWebApp()?.initData?.trim() ?? '';
}

function getTelegramWebAppScriptEl(): HTMLScriptElement | null {
  try {
    return document.querySelector<HTMLScriptElement>('script[src*="telegram-web-app.js"]');
  } catch {
    return null;
  }
}

/**
 * Wait until the official Telegram WebApp script has finished loading (or failed),
 * without setTimeout. Uses the script element's load/error events + rAF only.
 */
function waitForTelegramScriptReady(maxFrames = 120): Promise<'ready' | 'missing' | 'error' | 'timeout'> {
  if (isTelegramWebAppBridgePresent()) return Promise.resolve('ready');
  const el = getTelegramWebAppScriptEl();
  if (!el) return Promise.resolve('missing');

  // Classic sync scripts in <head> are usually complete before modules run.
  const loadState = el.getAttribute('data-tg-load-state');
  if (loadState === 'error') return Promise.resolve('error');
  if (loadState === 'loaded') return Promise.resolve('ready');

  return new Promise((resolve) => {
    let settled = false;
    let frames = 0;
    const done = (status: 'ready' | 'missing' | 'error' | 'timeout') => {
      if (settled) return;
      settled = true;
      el.removeEventListener('load', onLoad);
      el.removeEventListener('error', onError);
      resolve(status);
    };
    const onLoad = () => {
      el.setAttribute('data-tg-load-state', 'loaded');
      done('ready');
    };
    const onError = () => {
      el.setAttribute('data-tg-load-state', 'error');
      done('error');
    };
    el.addEventListener('load', onLoad);
    el.addEventListener('error', onError);

    const step = () => {
      if (isTelegramWebAppBridgePresent()) {
        done('ready');
        return;
      }
      const state = el.getAttribute('data-tg-load-state');
      if (state === 'error') {
        done('error');
        return;
      }
      frames += 1;
      if (frames >= maxFrames) {
        // Script tag present but neither load nor bridge — treat as timeout.
        done(isTelegramWebAppBridgePresent() ? 'ready' : 'timeout');
        return;
      }
      requestAnimationFrame(step);
    };
    requestAnimationFrame(step);
  });
}

/**
 * Wait until signed initData is non-empty, or readiness budget is exhausted.
 *
 * Sequence: script readiness → bridge present → initData non-empty.
 * Uses script load/error + requestAnimationFrame only (no setTimeout).
 */
export function waitForSignedInitData(options?: {
  maxFrames?: number;
}): Promise<{ phase: TelegramBridgePhase; initData: string }> {
  const maxFrames = options?.maxFrames ?? 120; // ~2s at 60fps — budget, not a delay hack

  return new Promise((resolve) => {
    const finish = () => {
      const initData = getTelegramInitData();
      if (initData) {
        resolve({ phase: 'init_data_available', initData });
        return;
      }
      if (!isTelegramWebAppBridgePresent()) {
        resolve({ phase: 'bridge_absent', initData: '' });
        return;
      }
      resolve({ phase: 'init_data_unavailable', initData: '' });
    };

    const immediate = getTelegramInitData();
    if (immediate) {
      resolve({ phase: 'init_data_available', initData: immediate });
      return;
    }

    void waitForTelegramScriptReady(maxFrames).then(() => {
      const afterScript = getTelegramInitData();
      if (afterScript) {
        resolve({ phase: 'init_data_available', initData: afterScript });
        return;
      }

      let frames = 0;
      const step = () => {
        const data = getTelegramInitData();
        if (data) {
          resolve({ phase: 'init_data_available', initData: data });
          return;
        }
        frames += 1;
        if (frames >= maxFrames) {
          finish();
          return;
        }
        requestAnimationFrame(step);
      };
      requestAnimationFrame(step);
    });
  });
}

export function prepareTelegramViewport(): void {
  const wa = getTelegramWebApp();
  if (!wa) return;
  try {
    wa.ready();
    wa.expand();
  } catch {
    // ignore missing methods in older clients
  }
  applyTelegramTheme();
  applyTelegramSafeAreaCssVars();
}

/**
 * Map Telegram themeParams onto CSS variables without wiping TRAGGE identity.
 * Only applies when running inside a Mini App with signed initData.
 */
export function applyTelegramTheme(): void {
  if (!isTelegramMiniApp()) return;
  const wa = getTelegramWebApp();
  const tp = wa?.themeParams;
  if (!tp) return;
  const root = document.documentElement;
  const map: Record<string, string> = {
    bg_color: '--tg-theme-bg-color',
    text_color: '--tg-theme-text-color',
    hint_color: '--tg-theme-hint-color',
    link_color: '--tg-theme-link-color',
    button_color: '--tg-theme-button-color',
    button_text_color: '--tg-theme-button-text-color',
    secondary_bg_color: '--tg-theme-secondary-bg-color',
  };
  for (const [key, cssVar] of Object.entries(map)) {
    const val = tp[key];
    if (val) root.style.setProperty(cssVar, val);
  }
  if (wa?.colorScheme === 'dark' || wa?.colorScheme === 'light') {
    root.setAttribute('data-tg-color-scheme', wa.colorScheme);
  }
}

/** Expose safe-area / content-safe-area as CSS vars for Mini App layouts. */
export function applyTelegramSafeAreaCssVars(): void {
  const root = document.documentElement;
  try {
    const wa = getTelegramWebApp() as TelegramWebApp & {
      contentSafeAreaInset?: { top?: number; bottom?: number; left?: number; right?: number };
      safeAreaInset?: { top?: number; bottom?: number; left?: number; right?: number };
    } | null;
    const c = wa?.contentSafeAreaInset;
    if (c) {
      if (c.top != null) root.style.setProperty('--tg-content-safe-top', `${c.top}px`);
      if (c.bottom != null) root.style.setProperty('--tg-content-safe-bottom', `${c.bottom}px`);
      if (c.left != null) root.style.setProperty('--tg-content-safe-left', `${c.left}px`);
      if (c.right != null) root.style.setProperty('--tg-content-safe-right', `${c.right}px`);
    }
    const s = wa?.safeAreaInset;
    if (s) {
      if (s.top != null) root.style.setProperty('--tg-safe-top', `${s.top}px`);
      if (s.bottom != null) root.style.setProperty('--tg-safe-bottom', `${s.bottom}px`);
    }
  } catch {
    // older clients
  }
}

export function hapticLight(): void {
  try {
    getTelegramWebApp()?.HapticFeedback?.impactOccurred('light');
  } catch {
    // no-op outside Telegram
  }
}

export function hapticSuccess(): void {
  try {
    getTelegramWebApp()?.HapticFeedback?.notificationOccurred('success');
  } catch {
    // no-op
  }
}

export function bindTelegramBackButton(handler: () => void): () => void {
  const back = getTelegramWebApp()?.BackButton;
  if (!back) return () => undefined;
  back.show();
  back.onClick(handler);
  return () => {
    try {
      back.offClick(handler);
      back.hide();
    } catch {
      // ignore
    }
  };
}

/** Safe diagnostics for UI/E2E — never includes initData payload or secrets. */
export function getTelegramDiagnostics(): {
  telegramScriptInDom: boolean;
  /** True when script tag is present and load did not error (or Telegram already exists). */
  telegramScriptLoaded: boolean;
  telegramObjectPresent: boolean;
  webAppObjectPresent: boolean;
  webAppVersion: string | null;
  platform: string | null;
  isExpanded: boolean | null;
  bridgePresent: boolean;
  initDataPresent: boolean;
  initDataLength: number;
  likelyTelegramClient: boolean;
} {
  const initData = getTelegramInitData();
  const wa = getTelegramWebApp() as (TelegramWebApp & { version?: string; platform?: string }) | null;
  const scriptEl = getTelegramWebAppScriptEl();
  const telegramScriptInDom = scriptEl != null;
  const loadState = scriptEl?.getAttribute('data-tg-load-state');
  let telegramObjectPresent = false;
  try {
    telegramObjectPresent = Boolean(
      (window as Window & { Telegram?: unknown }).Telegram,
    );
  } catch {
    telegramObjectPresent = false;
  }
  const telegramScriptLoaded =
    telegramObjectPresent ||
    (telegramScriptInDom && loadState !== 'error');
  return {
    telegramScriptInDom,
    telegramScriptLoaded,
    telegramObjectPresent,
    webAppObjectPresent: wa != null,
    webAppVersion: wa?.version ?? null,
    platform: wa?.platform ?? null,
    isExpanded: wa?.isExpanded ?? null,
    bridgePresent: wa != null,
    initDataPresent: initData.length > 0,
    initDataLength: initData.length,
    likelyTelegramClient: isLikelyTelegramClient(),
  };
}
