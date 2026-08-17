<script setup lang="ts">
import { computed, ref, onMounted, onUnmounted } from 'vue';
import { useRoute } from 'vue-router';
import { t } from '@/i18n';
import IconDashboard from '@/components/icons/IconDashboard.vue';
import IconTournaments from '@/components/icons/IconTournaments.vue';
import IconSupport from '@/components/icons/IconSupport.vue';
import IconProfile from '@/components/icons/IconProfile.vue';
import { ticketsApi } from '../../api/tickets';

const route = useRoute();

const navItems = computed(() => [
  { name: 'profile', path: '/user/profile', icon: IconProfile, label: t('nav.profile'), center: false },
  { name: 'contests', path: '/user/contests', icon: IconTournaments, label: t('contests.title').split(' ')[0], center: false },
  { name: 'home', path: '/user/dashboard', icon: IconDashboard, label: t('nav.dashboard').split(' ')[0], center: true },
  { name: 'leaderboard', path: '/user/leaderboard', icon: IconTournaments, label: t('nav.leaderboard') || 'رده‌بندی', center: false },
  { name: 'support', path: '/user/tickets', icon: IconSupport, label: t('nav.support'), center: false },
]);

function isActive(path: string): boolean {
  if (path === '/user/dashboard') return route.path === path || route.path === '/user';
  return route.path === path || route.path.startsWith(path + '/');
}

const unreadTicketCount = ref(0);
let ticketBadgeTimer: ReturnType<typeof setInterval> | null = null;

async function fetchUnreadTicketCount() {
  try {
    const res = await ticketsApi.getUnreadCount();
    unreadTicketCount.value = res.count;
  } catch {
    /* silent */
  }
}

onMounted(() => {
  fetchUnreadTicketCount();
  ticketBadgeTimer = setInterval(fetchUnreadTicketCount, 30000);
});
onUnmounted(() => {
  if (ticketBadgeTimer) clearInterval(ticketBadgeTimer);
});
</script>

<template>
  <nav class="bottom-nav" dir="rtl" aria-label="primary">
    <RouterLink
      v-for="item in navItems"
      :key="item.name"
      :to="item.path"
      :class="[
        'bottom-nav-item',
        {
          'bottom-nav-item-active': isActive(item.path),
          'bottom-nav-item-center': item.center,
        },
      ]"
    >
      <div class="bottom-nav-icon-wrapper">
        <div v-if="item.center" class="center-fab">
          <span class="center-fab-t">T</span>
        </div>
        <component v-else :is="item.icon" class="bottom-nav-icon" />
        <span
          v-if="item.name === 'support' && unreadTicketCount > 0"
          class="nav-badge"
        >{{ unreadTicketCount > 9 ? '9+' : unreadTicketCount }}</span>
      </div>
      <span v-if="!item.center" class="bottom-nav-label">{{ item.label }}</span>
    </RouterLink>
  </nav>
</template>

<style scoped>
.bottom-nav {
  display: flex;
  align-items: flex-end;
  justify-content: space-around;
  height: calc(var(--mvp-bottom-nav-h, 72px) + env(safe-area-inset-bottom, 0px));
  padding: 0 6px;
  padding-bottom: env(safe-area-inset-bottom, 0px);
  background: rgba(5, 10, 18, 0.94);
  backdrop-filter: blur(22px) saturate(1.4);
  -webkit-backdrop-filter: blur(22px) saturate(1.4);
  border-top: 1px solid rgba(0, 212, 160, 0.12);
  box-shadow: 0 -8px 32px rgba(0, 0, 0, 0.35);
}

.bottom-nav-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  flex: 1;
  min-height: 56px;
  padding: 8px 4px 10px;
  color: var(--mvp-text-muted, #5c667a);
  text-decoration: none;
  position: relative;
  border: none;
  background: transparent;
  cursor: pointer;
}

.bottom-nav-item-active {
  color: var(--mvp-emerald, #00d4a0);
}

.bottom-nav-item-center {
  transform: translateY(-14px);
}

.center-fab {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: radial-gradient(circle at 40% 30%, #14f1b8, #059669 70%);
  box-shadow:
    0 0 0 6px rgba(0, 212, 160, 0.12),
    0 10px 28px rgba(0, 212, 160, 0.4);
  border: 2px solid rgba(255, 255, 255, 0.15);
}

.center-fab-t {
  font-size: 22px;
  font-weight: 900;
  color: #03140f;
}

.bottom-nav-icon-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

.bottom-nav-icon {
  width: 22px;
  height: 22px;
}

.bottom-nav-label {
  font-size: 10px;
  font-weight: 700;
  max-width: 64px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.nav-badge {
  position: absolute;
  top: -6px;
  inset-inline-start: -4px;
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
</style>
