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
