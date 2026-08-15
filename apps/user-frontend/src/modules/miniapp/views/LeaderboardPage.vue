<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import LoadingState from '../components/LoadingState.vue';
import ErrorState from '../components/ErrorState.vue';
import EmptyState from '../components/EmptyState.vue';
import { userStatsApi, type GlobalLeaderboardEntry } from '@/api';
import { useAuthStore } from '@/stores/auth';
import { formatCount } from '../utils/format';

const auth = useAuthStore();
const loading = ref(true);
const error = ref<string | null>(null);
const entries = ref<GlobalLeaderboardEntry[]>([]);
const userRank = ref<number | undefined>();

const meId = computed(() => auth.user?.id);

async function load() {
  loading.value = true;
  error.value = null;
  try {
    const res = await userStatsApi.getGlobalLeaderboard({ limit: 50 });
    entries.value = res.entries || [];
    userRank.value = res.user_rank;
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'خطا در دریافت رتبه‌بندی';
  } finally {
    loading.value = false;
  }
}

onMounted(load);

function medal(rank: number): string {
  if (rank === 1) return '🥇';
  if (rank === 2) return '🥈';
  if (rank === 3) return '🥉';
  return String(rank);
}
</script>

<template>
  <div class="lb">
    <header>
      <h1>رتبه‌بندی</h1>
      <p v-if="userRank">رتبه شما: <span class="ma-ltr-num">{{ userRank }}</span></p>
    </header>

    <LoadingState v-if="loading" />
    <ErrorState v-else-if="error" :message="error" @retry="load" />
    <EmptyState
      v-else-if="!entries.length"
      title="رتبه‌بندی خالی است"
      description="پس از شرکت در مسابقات، جدول رتبه پر می‌شود."
    />
    <ul v-else class="list">
      <li
        v-for="e in entries"
        :key="e.user_id"
        class="row ma-glass"
        :class="{ me: e.user_id === meId, top: e.rank <= 3 }"
      >
        <span class="rank ma-ltr-num">{{ medal(e.rank) }}</span>
        <div class="who">
          <span class="name">{{ e.username || e.user_id.slice(0, 8) }}</span>
          <span class="meta ma-ltr-num">{{ formatCount(e.total_contests) }} contests · {{ e.win_rate?.toFixed?.(0) || 0 }}% WR</span>
        </div>
        <span class="ma-ltr-num score">{{ Math.round(e.tragge_point || 0) }}</span>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.lb {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
header h1 {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 800;
}
header p {
  margin: 0;
  font-size: 12px;
  color: var(--ma-text-secondary);
}
.list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.row {
  display: grid;
  grid-template-columns: 40px 1fr auto;
  gap: 10px;
  align-items: center;
  padding: 12px;
  border-radius: var(--ma-radius-sm);
}
.row.top {
  border-color: rgba(245, 197, 66, 0.25);
}
.row.me {
  border-color: rgba(16, 217, 138, 0.4);
  box-shadow: 0 0 0 1px rgba(16, 217, 138, 0.15);
}
.rank {
  font-weight: 800;
  font-size: 14px;
  text-align: center;
}
.name {
  display: block;
  font-size: 13px;
  font-weight: 700;
}
.meta {
  display: block;
  font-size: 10px;
  color: var(--ma-text-muted);
  margin-top: 2px;
}
.score {
  font-size: 14px;
  font-weight: 800;
  color: var(--ma-primary);
}
</style>
