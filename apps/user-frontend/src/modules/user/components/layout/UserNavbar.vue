<script setup lang="ts">
/**
 * Canonical UserNavbar — single component for mobile + desktop.
 * Hosts Wallet / Notifications / Support shortcuts (not page content).
 */
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
const showBrand = computed(() => !route.path.includes('/dashboard') && !route.path.includes('/home'));

async function refreshBadges() {
  try {
    const [tRes, nRes] = await Promise.all([
      ticketsApi.getUnreadCount().catch(() => ({ count: 0 })),
      notificationsApi.getUnreadCount().catch(() => ({ count: 0 })),
    ]);
    unreadTickets.value = tRes.count ?? 0;
    unreadNotifs.value = nRes.count ?? 0;
  } catch {
    /* silent — badges are non-critical */
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

function goHome() {
  router.push(paths.value.home);
}
function goWallet() {
  router.push(paths.value.wallet);
}
function goSupport() {
  router.push(paths.value.tickets);
}
function goNotifications() {
  router.push(paths.value.notifications);
}
function goProfile() {
  router.push(paths.value.profile);
}
</script>

<template>
  <header class="user-navbar" dir="rtl" data-canonical="user-navbar" aria-label="user-navbar">
    <div class="un-start">
      <button
        v-if="showBrand"
        type="button"
        class="un-brand"
        :aria-label="t('nav.dashboard')"
        @click="goHome"
      >
        <span class="un-brand-mark">T</span>
        <span class="un-brand-text">{{ t('app.name') }}</span>
      </button>

      <div class="un-actions">
        <button type="button" class="un-icon-btn" :aria-label="t('nav.support')" @click="goSupport">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
          </svg>
          <span class="un-icon-caption">{{ t('nav.support') }}</span>
          <span v-if="unreadTickets > 0" class="un-dot" />
        </button>
        <button
          type="button"
          class="un-icon-btn"
          :aria-label="t('nav.notifications') || 'اعلان‌ها'"
          @click="goNotifications"
        >
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
            <path d="M13.73 21a2 2 0 0 1-3.46 0" />
          </svg>
          <span class="un-icon-caption">{{ t('nav.notifications') || 'اعلان‌ها' }}</span>
          <span v-if="unreadNotifs > 0" class="un-badge">{{ unreadNotifs > 9 ? '9+' : unreadNotifs }}</span>
        </button>
      </div>
    </div>

    <div class="un-end">
      <button type="button" class="un-wallet" @click="goWallet">
        <span class="un-wallet-icon" aria-hidden="true">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="2" y="6" width="20" height="14" rx="2" />
            <path d="M2 10h20" />
          </svg>
        </span>
        <span v-if="loadingWallet" class="un-wallet-skel" />
        <span v-else class="un-wallet-bal ma-ltr-num">{{ balanceLabel }}</span>
        <span class="un-wallet-add" aria-hidden="true">+</span>
      </button>
      <button
        type="button"
        class="un-profile"
        :aria-label="t('nav.profile')"
        @click="goProfile"
      >
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
          <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
          <circle cx="12" cy="7" r="4" />
        </svg>
      </button>
    </div>
  </header>
</template>

<style scoped>
.user-navbar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  width: 100%;
  max-width: 100%;
  min-width: 0;
  box-sizing: border-box;
  padding: 6px 0 10px;
}
.un-start,
.un-end,
.un-actions {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}
.un-brand {
  display: none;
  align-items: center;
  gap: 8px;
  padding: 6px 8px;
  border: none;
  background: transparent;
  color: var(--mvp-text);
  cursor: pointer;
}
.un-brand-mark {
  width: 28px;
  height: 28px;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 900;
  color: #fff;
  background: linear-gradient(135deg, var(--mvp-emerald), #0ea5e9);
}
.un-brand-text {
  font-size: 14px;
  font-weight: 800;
}
.un-icon-btn {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  min-width: 48px;
  max-width: 64px;
  padding: 8px 8px;
  border-radius: 14px;
  border: 1px solid var(--mvp-border);
  background: rgba(12, 22, 38, 0.75);
  color: var(--mvp-text-secondary);
  cursor: pointer;
  box-sizing: border-box;
}
.un-icon-caption {
  font-size: 10px;
  font-weight: 600;
  color: var(--mvp-text-secondary);
  max-width: 100%;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.un-dot {
  position: absolute;
  top: 6px;
  inset-inline-start: 10px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--mvp-emerald);
  box-shadow: 0 0 8px var(--mvp-emerald-glow);
}
.un-badge {
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
.un-wallet {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
  max-width: min(220px, 52vw);
  padding: 8px 10px 8px 8px;
  border-radius: 999px;
  border: 1px solid var(--mvp-border-strong);
  background: linear-gradient(135deg, rgba(0, 212, 160, 0.12), rgba(8, 16, 28, 0.9));
  color: var(--mvp-text);
  cursor: pointer;
  box-shadow: 0 0 20px rgba(0, 212, 160, 0.12);
  box-sizing: border-box;
}
.un-wallet-icon {
  flex-shrink: 0;
  width: 28px;
  height: 28px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--mvp-emerald-soft);
  color: var(--mvp-emerald);
}
.un-wallet-bal {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 14px;
  font-weight: 800;
  letter-spacing: 0.02em;
  direction: ltr;
}
.un-wallet-add {
  flex-shrink: 0;
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
.un-wallet-skel {
  width: 56px;
  height: 14px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.08);
  animation: pulse 1.4s ease-in-out infinite;
}
.un-profile {
  display: none;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 12px;
  border: 1px solid var(--mvp-border);
  background: rgba(12, 22, 38, 0.75);
  color: var(--mvp-text-secondary);
  cursor: pointer;
}
@keyframes pulse {
  0%, 100% { opacity: 0.5; }
  50% { opacity: 1; }
}

@media (min-width: 768px) {
  .un-brand {
    display: inline-flex;
  }
  .un-profile {
    display: inline-flex;
  }
  .un-icon-btn {
    flex-direction: row;
    min-width: auto;
    max-width: none;
    padding: 8px 12px;
    gap: 8px;
  }
  .un-icon-caption {
    font-size: 12px;
  }
  .un-wallet {
    max-width: 280px;
  }
}

@media (max-width: 359px) {
  .un-icon-caption {
    display: none;
  }
  .un-icon-btn {
    min-width: 40px;
    padding: 8px;
  }
}
</style>
