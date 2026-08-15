import type { RouteRecordRaw } from 'vue-router';

export const miniappRoutes: RouteRecordRaw[] = [
  {
    path: '/miniapp',
    component: () => import('./components/MiniAppLayout.vue'),
    meta: { requiresAuth: true, miniapp: true },
    children: [
      { path: '', redirect: '/miniapp/home' },
      {
        path: 'home',
        name: 'miniapp-home',
        component: () => import('./views/HomePage.vue'),
      },
      {
        path: 'competitions',
        name: 'miniapp-competitions',
        component: () => import('./views/CompetitionsPage.vue'),
      },
      {
        path: 'competitions/:contestId',
        name: 'miniapp-competition-detail',
        component: () => import('./views/CompetitionDetailPage.vue'),
      },
      {
        path: 'wallet',
        name: 'miniapp-wallet',
        component: () => import('./views/WalletPage.vue'),
      },
      {
        path: 'deposit',
        name: 'miniapp-deposit',
        component: () => import('./views/DepositPage.vue'),
      },
      {
        path: 'withdraw',
        name: 'miniapp-withdraw',
        component: () => import('./views/WithdrawPage.vue'),
      },
      {
        path: 'leaderboard',
        name: 'miniapp-leaderboard',
        component: () => import('./views/LeaderboardPage.vue'),
      },
      {
        path: 'categories',
        name: 'miniapp-categories',
        component: () => import('./views/CategoriesPage.vue'),
      },
      {
        path: 'profile',
        name: 'miniapp-profile',
        component: () => import('./views/ProfilePage.vue'),
      },
    ],
  },
];
