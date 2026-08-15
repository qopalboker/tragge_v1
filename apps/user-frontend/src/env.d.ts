/// <reference types="vite/client" />
declare module '*.vue' {
  import type { DefineComponent } from 'vue'
  const component: DefineComponent
  export default component
}

interface TelegramWebApp {
  initData: string
  initDataUnsafe?: {
    user?: {
      id: number
      first_name?: string
      last_name?: string
      username?: string
    }
  }
  ready: () => void
  expand: () => void
  close: () => void
  BackButton?: {
    show: () => void
    hide: () => void
    onClick: (cb: () => void) => void
    offClick: (cb: () => void) => void
  }
  HapticFeedback?: {
    impactOccurred: (style: string) => void
    notificationOccurred: (type: string) => void
  }
}

interface Window {
  Telegram?: { WebApp?: TelegramWebApp }
}
