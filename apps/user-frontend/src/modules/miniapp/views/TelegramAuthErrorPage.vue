<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useAuthStore } from '@/stores/auth';
import { setLocale } from '@/i18n';
import {
  prepareTelegramViewport,
  isTelegramWebAppBridgePresent,
  getTelegramDiagnostics,
} from '../telegram';

const auth = useAuthStore();
const retrying = ref(false);
const retryFeedback = ref<string | null>(null);

onMounted(() => {
  if (isTelegramWebAppBridgePresent() || auth.isTelegramSession) {
    setLocale('fa');
    document.documentElement.setAttribute('dir', 'rtl');
    document.documentElement.lang = 'fa';
    prepareTelegramViewport();
  }
  // Refresh safe diagnostics without secrets.
  Object.assign(auth.telegramDiagnostics, getTelegramDiagnostics());
});

const message = computed(() => {
  const code = auth.bootstrapError || auth.telegramDiagnostics?.lastError || '';
  switch (code) {
    case 'telegram_initdata_missing':
      return 'نشست تلگرام (initData) در دسترس نیست. اپ را از منوی ربات داخل تلگرام باز کنید.';
    case 'telegram_bridge_absent':
      return 'پل تلگرام WebApp پیدا نشد. لینک را فقط داخل تلگرام باز کنید.';
    case 'telegram_auth_unavailable':
      return 'احراز هویت تلگرام روی سرور پیکربندی نشده (TELEGRAM_BOT_TOKEN).';
    case 'telegram_auth_invalid':
      return 'امضای initData رد شد. توکن ربات سرور باید با ربات BotFather یکی باشد.';
    case 'telegram_auth_expired':
      return 'initData منقضی شده. مینی‌اپ را دوباره از تلگرام باز کنید.';
    case 'telegram_auth_replay':
      return 'این initData قبلاً استفاده شده. مینی‌اپ را دوباره باز کنید.';
    default:
      if (code) return code;
      return 'ورود از طریق تلگرام انجام نشد.';
  }
});

const diag = computed(() => auth.telegramDiagnostics);

async function retry() {
  if (retrying.value || auth.loading) return;
  retrying.value = true;
  retryFeedback.value = null;
  try {
    const ok = await auth.retryTelegramAuth();
    if (ok && auth.isAuthenticated) {
      const { default: router } = await import('@/router');
      await router.replace('/miniapp/home');
      return;
    }
    retryFeedback.value =
      auth.bootstrapError ||
      auth.telegramDiagnostics?.lastError ||
      'تلاش مجدد ناموفق بود.';
  } finally {
    retrying.value = false;
  }
}
</script>

<template>
  <div class="tg-error" dir="rtl">
    <div class="card">
      <div class="mark" aria-hidden="true">T</div>
      <h1>ورود تلگرام</h1>
      <p class="msg">{{ message }}</p>
      <p v-if="retryFeedback" class="msg secondary">{{ retryFeedback }}</p>
      <p class="hint">
        حساب فقط با
        <strong>initData امضاشده</strong>
        ساخته یا بازیابی می‌شود — نه با فرم رمز عبور.
      </p>
      <dl class="diag" aria-label="diagnostics">
        <div>
          <dt>telegramScriptLoaded</dt>
          <dd>{{ diag?.telegramScriptLoaded ? 'yes' : 'no' }}</dd>
        </div>
        <div>
          <dt>telegramObjectPresent</dt>
          <dd>{{ diag?.telegramObjectPresent ? 'yes' : 'no' }}</dd>
        </div>
        <div>
          <dt>webAppObjectPresent</dt>
          <dd>{{ diag?.webAppObjectPresent ? 'yes' : 'no' }}</dd>
        </div>
        <div>
          <dt>webAppVersion</dt>
          <dd>{{ diag?.webAppVersion || '—' }}</dd>
        </div>
        <div>
          <dt>platform</dt>
          <dd>{{ diag?.platform || '—' }}</dd>
        </div>
        <div>
          <dt>isExpanded</dt>
          <dd>{{ diag?.isExpanded == null ? '—' : diag.isExpanded ? 'yes' : 'no' }}</dd>
        </div>
        <div>
          <dt>initDataPresent</dt>
          <dd>{{ diag?.initDataPresent ? `yes (${diag?.initDataLength})` : 'no' }}</dd>
        </div>
        <div>
          <dt>auth HTTP</dt>
          <dd>{{ diag?.authRequestStatus ?? '—' }}</dd>
        </div>
        <div>
          <dt>code</dt>
          <dd>{{ diag?.authResponseCode || diag?.lastError || '—' }}</dd>
        </div>
        <div>
          <dt>phase</dt>
          <dd>{{ auth.bootstrapPhase }}</dd>
        </div>
        <div>
          <dt>retries</dt>
          <dd>{{ diag?.retryCount ?? 0 }}</dd>
        </div>
      </dl>
      <button type="button" class="retry" :disabled="retrying || auth.loading" @click="retry">
        {{ retrying || auth.loading ? '…' : 'تلاش مجدد' }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.tg-error {
  min-height: 100dvh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px 16px;
  background: var(--mvp-bg-deep, #050b18);
  color: var(--mvp-text, #e8eefc);
}
.card {
  width: 100%;
  max-width: 400px;
  border-radius: 20px;
  padding: 28px 22px;
  background: rgba(12, 22, 42, 0.92);
  border: 1px solid rgba(120, 160, 220, 0.16);
  text-align: center;
}
.mark {
  width: 52px;
  height: 52px;
  margin: 0 auto 16px;
  border-radius: 14px;
  display: grid;
  place-items: center;
  font-weight: 800;
  font-size: 22px;
  background: linear-gradient(145deg, #1ee8a5, #0a6b4a);
  color: #04120c;
}
h1 {
  margin: 0 0 10px;
  font-size: 1.25rem;
}
.msg {
  margin: 0 0 12px;
  color: #f0b4b4;
  font-size: 0.95rem;
  line-height: 1.5;
}
.msg.secondary {
  color: #f5c542;
  font-size: 0.85rem;
}
.hint {
  margin: 0 0 16px;
  font-size: 0.82rem;
  color: rgba(200, 214, 240, 0.72);
  line-height: 1.55;
}
.diag {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px 12px;
  margin: 0 0 18px;
  padding: 12px;
  border-radius: 12px;
  background: rgba(0, 0, 0, 0.25);
  text-align: start;
  font-size: 0.72rem;
}
.diag div {
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.diag dt {
  color: rgba(180, 200, 230, 0.55);
  margin: 0;
}
.diag dd {
  margin: 0;
  color: #cfe0ff;
  font-family: ui-monospace, monospace;
  word-break: break-all;
}
.retry {
  border: none;
  border-radius: 12px;
  padding: 12px 20px;
  font-weight: 700;
  cursor: pointer;
  background: #1ee8a5;
  color: #04120c;
}
.retry:disabled {
  opacity: 0.55;
  cursor: not-allowed;
}
</style>
