<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { t } from '@/i18n';
import { useWalletStore } from '@/modules/user/stores_wallet';
import { ticketsApi } from '@/modules/user/api/tickets';
import { notificationsApi } from '@/modules/user/api/notifications';
import { userShellPaths } from '@/utils/userShellPaths';
import { useAuthStore } from '@/stores/auth';

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const walletStore = useWalletStore();
const paths = computed(() =>
  userShellPaths(route, { telegramSession: auth.isTelegramSession }),
);

const unreadTickets = ref(0);
const unreadNotifs = ref(0);
let timer: ReturnType<typeof setInterval> | null = null;

const balanceLabel = computed(() => walletStore.formattedBalance);
const loadingWallet = computed(() => walletStore.loading && !walletStore.wallet);

async function refreshBadges() {
  try {
    const [tRes, nRes] = await Promise.all([
      ticketsApi.getUnreadCount().catch(() => ({ count: 0 })),
      notificationsApi.getUnreadCount().catch(() => ({ count: 0 })),
    ]);
    unreadTickets.value = tRes.count ?? 0;
    unreadNotifs.value = nRes.count ?? 0;
  } catch {
    /* silent */
  }
}

onMounted(async () => {
  if (!walletStore.wallet) {
    walletStore.fetchWallet().catch(() => undefined);
  }
  await refreshBadges();
  timer = setInterval(refreshBadges, 30000);
});
onUnmounted(() => {
  if (timer) clearInterval(timer);
});

function goWallet() {
  router.push(paths.value.wallet);
}
function goSupport() {
  router.push(paths.value.tickets);
}
function goNotifications() {
  router.push(paths.value.notifications);
}
</script>

<template>
  <header class="mh-header" dir="rtl">
    <div class="mh-utils">
      <button type="button" class="mh-icon-btn" :aria-label="t('nav.support')" @click="goSupport">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
        </svg>
        <span class="mh-icon-caption">{{ t('nav.support') }}</span>
        <span v-if="unreadTickets > 0" class="mh-dot" />
      </button>
      <button type="button" class="mh-icon-btn" :aria-label="t('nav.notifications')" @click="goNotifications">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
          <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
          <path d="M13.73 21a2 2 0 0 1-3.46 0" />
        </svg>
        <span class="mh-icon-caption">{{ t('nav.notifications') || 'اعلان‌ها' }}</span>
        <span v-if="unreadNotifs > 0" class="mh-badge">{{ unreadNotifs > 9 ? '9+' : unreadNotifs }}</span>
      </button>
    </div>

    <button type="button" class="mh-wallet" @click="goWallet">
      <span class="mh-wallet-icon" aria-hidden="true">
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <rect x="2" y="6" width="20" height="14" rx="2" />
          <path d="M2 10h20" />
        </svg>
      </span>
      <span v-if="loadingWallet" class="mh-wallet-skel" />
      <span v-else class="mh-wallet-bal ma-ltr-num">{{ balanceLabel }}</span>
      <span class="mh-wallet-add" aria-hidden="true">+</span>
    </button>
  </header>
</template>

<style scoped>
.mh-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  padding: 4px 0 8px;
}
.mh-utils {
  display: flex;
  gap: 10px;
}
.mh-icon-btn {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  min-width: 52px;
  padding: 8px 10px;
  border-radius: 14px;
  border: 1px solid var(--mvp-border);
  background: rgba(12, 22, 38, 0.75);
  color: var(--mvp-text-secondary);
  cursor: pointer;
}
.mh-icon-caption {
  font-size: 10px;
  font-weight: 600;
  color: var(--mvp-text-secondary);
}
.mh-dot {
  position: absolute;
  top: 6px;
  inset-inline-start: 10px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--mvp-emerald);
  box-shadow: 0 0 8px var(--mvp-emerald-glow);
}
.mh-badge {
  position: absolute;
  top: 2px;
  inset-inline-start: 6px;
  min-width: 16px;
  height: 16px;
  padding: 0 4px;
  border-radius: 8px;
  background: #ef4444;
  color: #fff;
  font-size: 10px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
}
.mh-wallet {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px 8px 8px;
  border-radius: 999px;
  border: 1px solid var(--mvp-border-strong);
  background: linear-gradient(135deg, rgba(0, 212, 160, 0.12), rgba(8, 16, 28, 0.9));
  color: var(--mvp-text);
  cursor: pointer;
  box-shadow: 0 0 20px rgba(0, 212, 160, 0.12);
}
.mh-wallet-icon {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--mvp-emerald-soft);
  color: var(--mvp-emerald);
}
.mh-wallet-bal {
  font-size: 14px;
  font-weight: 800;
  letter-spacing: 0.02em;
  direction: ltr;
}
.mh-wallet-add {
  width: 26px;
  height: 26px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--mvp-emerald);
  color: #04120e;
  font-size: 18px;
  font-weight: 700;
  line-height: 1;
}
.mh-wallet-skel {
  width: 56px;
  height: 14px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.08);
  animation: pulse 1.4s ease-in-out infinite;
}
@keyframes pulse {
  0%, 100% { opacity: 0.5; }
  50% { opacity: 1; }
}
</style>
