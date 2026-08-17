/**
 * Telegram Mini App environment helpers.
 * WebApp script is loaded from index.html; all access is defensive.
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

export function getTelegramWebApp(): TelegramWebApp | null {
  try {
    return (window as Window & { Telegram?: { WebApp?: TelegramWebApp } }).Telegram?.WebApp ?? null;
  } catch {
    return null;
  }
}

export function isTelegramMiniApp(): boolean {
  const wa = getTelegramWebApp();
  if (!wa) return false;
  return Boolean(wa.initData && wa.initData.length > 0);
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
  // CSS env() already works for safe-area-inset-*; set content insets when WebApp provides them.
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

export function getTelegramInitData(): string {
  return getTelegramWebApp()?.initData?.trim() ?? '';
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
