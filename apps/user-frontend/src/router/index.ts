import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import { userRoutes } from '@/modules/user/routes'
import { tradeRoutes } from '@/modules/trade/routes'
import { miniappRoutes } from '@/modules/miniapp/routes'

// user-frontend routes — user + trade + Telegram Mini App.
// Admin routes live in apps/admin-frontend (separate origin).
const routes: RouteRecordRaw[] = [
  // Bare origin (http://localhost:5173/) has no page — send users to login.
  { path: '/', redirect: '/user/login' },
  ...miniappRoutes,
  ...userRoutes,
  ...tradeRoutes,
  {
    path: '/:pathMatch(.*)*',
    name: 'not-found',
    component: () => import('@/modules/user/views/NotFoundPage.vue'),
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Global auth guard. No admin branch — browser guests hit /user/login.
// Telegram Mini App / miniapp meta must NEVER land on the password form
// (see docs/codex/reports/USER-UI-UNIFICATION-TELEGRAM-AUTH-2026-08-17.md).
router.beforeEach(async (to) => {
  const requiresAuth = to.matched.some(r => r.meta.requiresAuth)
  const isAuthPage = to.matched.some(r => r.meta.isAuthPage)
  const roleRecord = to.matched.find(r => r.meta.requiresRole)
  const requiresRole = roleRecord?.meta.requiresRole
  const isMiniappRoute = to.matched.some(r => r.meta.miniapp)

  // Only load the store when we actually need it (lazy import keeps the
  // landing-page chunk small). `bootstrap()` is deduped against the
  // call main.ts makes before mount, so in-app navigations are cheap.
  if (requiresAuth || requiresRole || isAuthPage) {
    const { useAuthStore } = await import('@/stores/auth')
    const auth = useAuthStore()
    if (!auth.ready) {
      await auth.bootstrap()
    }

    const { isTelegramMiniApp } = await import('@/modules/miniapp/telegram')
    const inTelegram = isTelegramMiniApp() || isMiniappRoute

    // Telegram / miniapp: never redirect to password login. While
    // telegram_authenticating or after definitive failure, send users to
    // the Mini App auth-error page (retry without leaving Telegram).
    if (
      inTelegram &&
      (auth.bootstrapPhase === 'telegram_authenticating' ||
        isAuthPage ||
        (requiresAuth && !auth.isAuthenticated))
    ) {
      if (auth.isAuthenticated) {
        return '/miniapp/home'
      }
      if (to.name === 'telegram-auth-error') {
        return true
      }
      return { name: 'telegram-auth-error' }
    }

    if (requiresAuth && !auth.isAuthenticated) {
      return { path: '/user/login', query: { redirect: to.fullPath } }
    }

    if (requiresRole && typeof requiresRole === 'string') {
      if (!auth.hasRole(requiresRole)) {
        return '/'
      }
    }

    // Redirect authenticated users away from auth pages (login,
    // register, forgot-password).
    if (isAuthPage && auth.isAuthenticated) {
      return isTelegramMiniApp() ? '/miniapp/home' : '/user/dashboard'
    }
  }
})

export default router
