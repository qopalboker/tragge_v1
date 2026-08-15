<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import StatCard from '../components/StatCard.vue';
import LoadingState from '../components/LoadingState.vue';
import ErrorState from '../components/ErrorState.vue';
import { useAuthStore } from '@/stores/auth';
import { useWalletStore } from '@/stores/wallet';
import { userStatsApi } from '@/api';
import { formatCount } from '../utils/format';
import { getTelegramWebApp } from '../telegram';

const router = useRouter();
const auth = useAuthStore();
const wallet = useWalletStore();
const loading = ref(true);
const error = ref<string | null>(null);
const stats = ref<{ total_contests: number; total_wins: number } | null>(null);

const tgUser = computed(() => getTelegramWebApp()?.initDataUnsafe?.user);
const displayName = computed(
  () =>
    auth.user?.display_name ||
    auth.user?.username ||
    tgUser.value?.username ||
    tgUser.value?.first_name ||
    'کاربر ترالنت',
);
const telegramHandle = computed(() => {
  const u = tgUser.value?.username || auth.user?.username;
  return u ? `@${u.replace(/^@/, '')}` : '—';
});
const tradingId = computed(() => auth.user?.id?.slice(0, 8)?.toUpperCase() || '—');

async function load() {
  loading.value = true;
  error.value = null;
  try {
    await Promise.all([
      auth.fetchUser?.(true).catch(() => undefined),
      wallet.fetchWallet().catch(() => undefined),
      userStatsApi.getMyStats().then((s) => {
        stats.value = { total_contests: s.total_contests, total_wins: s.total_wins };
      }).catch(() => {
        stats.value = null;
      }),
    ]);
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'خطا در دریافت پروفایل';
  } finally {
    loading.value = false;
  }
}

onMounted(load);
</script>

<template>
  <div class="profile">
    <header class="hero ma-glass">
      <div class="avatar">{{ displayName.slice(0, 1) }}</div>
      <h1>{{ displayName }}</h1>
      <p class="handle ma-ltr-num">{{ telegramHandle }}</p>
      <p class="tid">شناسه معاملاتی: <span class="ma-ltr-num">{{ tradingId }}</span></p>
    </header>

    <LoadingState v-if="loading" />
    <ErrorState v-else-if="error" :message="error" @retry="load" />
    <template v-else>
      <div class="grid">
        <StatCard label="موجودی" :value="wallet.formattedBalance" accent="green" />
        <StatCard
          label="مسابقات"
          :value="stats ? formatCount(stats.total_contests) : '—'"
          accent="cyan"
        />
        <StatCard
          label="جوایز"
          :value="stats ? formatCount(stats.total_wins) : '—'"
          accent="gold"
        />
      </div>
      <div class="links">
        <button type="button" class="ma-btn ma-btn-ghost row" @click="router.push('/miniapp/wallet')">
          کیف پول
        </button>
        <button type="button" class="ma-btn ma-btn-ghost row" @click="router.push('/user/settings')">
          تنظیمات
        </button>
        <button type="button" class="ma-btn ma-btn-ghost row" @click="router.push('/user/tickets')">
          پشتیبانی
        </button>
      </div>
    </template>
  </div>
</template>

<style scoped>
.profile {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.hero {
  border-radius: var(--ma-radius-lg);
  padding: 20px 16px;
  text-align: center;
}
.avatar {
  width: 56px;
  height: 56px;
  margin: 0 auto 10px;
  border-radius: 18px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 900;
  font-size: 22px;
  color: #03140c;
  background: linear-gradient(145deg, #1cf0a4, #0aa86a);
}
h1 {
  margin: 0 0 4px;
  font-size: 18px;
  font-weight: 800;
}
.handle {
  margin: 0 0 4px;
  color: var(--ma-cyan);
  font-size: 13px;
  font-weight: 700;
}
.tid {
  margin: 0;
  font-size: 11px;
  color: var(--ma-text-muted);
}
.grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: 8px;
}
.links {
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.row {
  min-height: 46px;
  width: 100%;
  font-size: 13px;
  justify-content: flex-start;
  padding: 0 14px;
}
</style>
