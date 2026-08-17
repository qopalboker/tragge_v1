import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import App from './App.vue'
import { i18n, initializeI18n, setLocale } from './i18n'
import { useAuthStore } from '@/stores/auth'
import { useThemeStore } from '@/stores/theme'
import { installConsoleRedaction } from '@tragge/frontend-shared'
// Ensure the API client module loads so its interceptors are wired
// before any code calls the auth store (which uses `api` internally).
import '@/api/client'
import '@tragge/frontend-shared/styles/main.css'
import './styles/mvp-design-tokens.css'
import {
  getTelegramInitData,
  isTelegramMiniApp,
  prepareTelegramViewport,
} from '@/modules/miniapp/telegram'

installConsoleRedaction()
initializeI18n()

async function bootstrapTelegramSession(auth: ReturnType<typeof useAuthStore>): Promise<void> {
  // Telegram is an enhancement: failures must never blank the normal web dashboard.
  try {
    if (!isTelegramMiniApp()) return
    setLocale('fa')
    document.documentElement.setAttribute('dir', 'rtl')
    document.documentElement.lang = 'fa'
    prepareTelegramViewport()

    // Prefer existing User session; only exchange initData when unauthenticated.
    if (auth.isAuthenticated) return
    const initData = getTelegramInitData()
    if (!initData) return
    await auth.loginWithTelegram(initData)
  } catch (err) {
    console.warn('[bootstrap] Telegram session skipped', err)
  }
}

async function start() {
  const app = createApp(App)
  const pinia = createPinia()

  app.use(pinia)
  app.use(router)
  app.use(i18n)

  // Apply the persisted theme to <html> on first paint and wire cross-tab
  // sync. Must run after pinia is installed.
  useThemeStore().initTheme()

  // Restore session from the httpOnly refresh cookie before the first
  // router guard runs. Without this, a hard refresh on a protected
  // page evaluates `isAuthenticated` against an empty Pinia store and
  // bounces the user to /user/login even when their cookie is still
  // valid.
  const auth = useAuthStore()
  try {
    await auth.bootstrap()
  } catch (err) {
    console.warn('[bootstrap] auth bootstrap failed; continuing as guest', err)
  }
  await bootstrapTelegramSession(auth)

  // Telegram Mini App deep entry: land on mobile shell when opened in TG.
  try {
    if (isTelegramMiniApp() && auth.isAuthenticated) {
      const path = window.location.pathname
      if (path === '/' || path === '' || path.startsWith('/user/dashboard')) {
        await router.replace('/miniapp/home')
      }
    }
  } catch {
    /* ignore TG routing errors — web routes still work */
  }

  await router.isReady()
  app.mount('#app')
}

start().catch((err) => {
  console.error('[bootstrap] fatal', err)
  // Last-resort mount so a bootstrap failure is not a blank page
  try {
    const app = createApp(App)
    app.use(createPinia())
    app.use(router)
    app.use(i18n)
    app.mount('#app')
  } catch {
    /* already logged */
  }
})
