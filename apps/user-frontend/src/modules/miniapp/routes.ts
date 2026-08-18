import type { RouteRecordRaw } from 'vue-router';

/**
 * Mini App routes reuse the canonical User shell + views (single design).
 * Path prefix `/miniapp/*` is kept for BotFather / Telegram deep links;
 * components are the same DashboardPage / ContestsPage / … as `/user/*`.
 */
export const miniappRoutes: RouteRecordRaw[] = [
  // Telegram auth failure — no requiresAuth (must be reachable without JWT).
  {
    path: '/miniapp/auth-error',
    name: 'telegram-auth-error',
    component: () => import('./views/TelegramAuthErrorPage.vue'),
    meta: { miniapp: true },
  },
  {
    path: '/miniapp',
    component: () => import('@/modules/user/components/layout/UserLayout.vue'),
    meta: { requiresAuth: true, miniapp: true },
    children: [
      { path: '', redirect: '/miniapp/home' },
      {
        path: 'home',
        name: 'miniapp-home',
        component: () => import('@/modules/user/views/DashboardPage.vue'),
      },
      {
        path: 'competitions',
        name: 'miniapp-competitions',
        component: () => import('@/modules/user/views/ContestsPage.vue'),
      },
      {
        path: 'competitions/:contestId',
        name: 'miniapp-competition-detail',
        component: () => import('@/modules/user/views/ContestDetailsPage.vue'),
      },
      {
        path: 'wallet',
        name: 'miniapp-wallet',
        component: () => import('@/modules/user/views/WalletPage.vue'),
      },
      {
        path: 'deposit',
        name: 'miniapp-deposit',
        // Deposit UX lives under wallet for the unified panel.
        redirect: '/miniapp/wallet',
      },
      {
        path: 'withdraw',
        name: 'miniapp-withdraw',
        redirect: '/miniapp/wallet',
      },
      {
        path: 'leaderboard',
        name: 'miniapp-leaderboard',
        component: () => import('@/modules/user/views/LeaderboardPage.vue'),
      },
      {
        path: 'categories',
        name: 'miniapp-categories',
        component: () => import('@/modules/user/views/ContestsPage.vue'),
      },
      {
        path: 'profile',
        name: 'miniapp-profile',
        component: () => import('@/modules/user/views/ProfilePage.vue'),
      },
      {
        path: 'notifications',
        name: 'miniapp-notifications',
        component: () => import('@/modules/user/views/NotificationsPage.vue'),
      },
      {
        path: 'settings',
        name: 'miniapp-settings',
        component: () => import('@/modules/user/views/SettingsPage.vue'),
      },
      {
        path: 'tickets',
        name: 'miniapp-tickets',
        component: () => import('@/modules/user/views/TicketsPage.vue'),
      },
      {
        path: 'tickets/new',
        name: 'miniapp-ticket-new',
        component: () => import('@/modules/user/views/NewTicketPage.vue'),
      },
      {
        path: 'tickets/:ticketId',
        name: 'miniapp-ticket-chat',
        component: () => import('@/modules/user/views/TicketChatPage.vue'),
      },
    ],
  },
];
