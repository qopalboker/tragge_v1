import type { RouteLocationNormalizedLoaded } from 'vue-router';
import { isTelegramMiniApp } from '@/modules/miniapp/telegram';

/** True when the current surface should stay under `/miniapp/*` paths. */
export function isMiniShellRoute(
  route: Pick<RouteLocationNormalizedLoaded, 'matched' | 'path'>,
  opts?: { telegramSession?: boolean },
): boolean {
  return (
    route.matched.some((r) => r.meta.miniapp) ||
    route.path.startsWith('/miniapp') ||
    Boolean(opts?.telegramSession) ||
    isTelegramMiniApp()
  );
}

/** Prefix-aware User panel paths (same views, single design). */
export function userShellPaths(
  route: Pick<RouteLocationNormalizedLoaded, 'matched' | 'path'>,
  opts?: { telegramSession?: boolean },
) {
  const mini = isMiniShellRoute(route, opts);
  const root = mini ? '/miniapp' : '/user';
  return {
    mini,
    home: mini ? `${root}/home` : `${root}/dashboard`,
    contests: mini ? `${root}/competitions` : `${root}/contests`,
    wallet: `${root}/wallet`,
    profile: `${root}/profile`,
    notifications: `${root}/notifications`,
    settings: `${root}/settings`,
    tickets: `${root}/tickets`,
    ticketNew: `${root}/tickets/new`,
    ticket: (id: string) => `${root}/tickets/${id}`,
    contest: (id: string) =>
      mini ? `${root}/competitions/${id}` : `${root}/contests/${id}`,
  };
}
