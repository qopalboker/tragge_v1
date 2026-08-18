import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import App from './App.vue'
import { i18n, initializeI18n } from './i18n'
import { useAuthStore } from '@/stores/auth'
import { useThemeStore } from '@/stores/theme'
import { installConsoleRedaction } from '@tragge/frontend-shared'
// Ensure the API client module loads so its interceptors are wired
// before any code calls the auth store (which uses `api` internally).
import '@/api/client'
import '@tragge/frontend-shared/styles/main.css'
import './styles/mvp-design-tokens.css'
import { isTelegramMiniApp } from '@/modules/miniapp/telegram'

installConsoleRedaction()
initializeI18n()

async function start() {
  const app = createApp(App)
  const pinia = createPinia()

  app.use(pinia)
  app.use(i18n)

  // Theme before first paint; must run after pinia.
  useThemeStore().initTheme()

  // CRITICAL: complete cookie + Telegram bootstrap BEFORE installing the
  // router. Vue Router resolves the initial URL when installed; if that
  // happens while Telegram auth is still pending, the global guard
  // redirects /miniapp/* → /user/login.
  const auth = useAuthStore()
  try {
    await auth.bootstrapFull()
  } catch (err) {
    console.warn('[bootstrap] full session bootstrap failed; continuing as guest', err)
  }

  // Install router only after auth phase is terminal.
  app.use(router)

  // Telegram deep entry: prefer Mini App home over bare origin / login.
  try {
    if (isTelegramMiniApp() && auth.isAuthenticated) {
      const path = window.location.pathname
      if (
        path === '/' ||
        path === '' ||
        path === '/user/login' ||
        path.startsWith('/user/dashboard')
      ) {
        await router.replace('/miniapp/home')
      }
    }
  } catch {
    /* web routes still work */
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
