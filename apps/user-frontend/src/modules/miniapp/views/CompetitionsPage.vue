<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import CompetitionCard, { type MiniCompetition } from '../components/CompetitionCard.vue';
import LoadingState from '../components/LoadingState.vue';
import ErrorState from '../components/ErrorState.vue';
import EmptyState from '../components/EmptyState.vue';
import { useContestsStore, type MarketType, type DurationType } from '@/stores/contests';

const router = useRouter();
const route = useRoute();
const store = useContestsStore();
const loading = ref(true);
const error = ref<string | null>(null);
const market = ref<MarketType | ''>((route.query.market as MarketType) || '');
const duration = ref<DurationType | ''>('');

const list = computed(() => store.contests as MiniCompetition[]);

async function load() {
  loading.value = true;
  error.value = null;
  try {
    await store.fetchContests({
      market_type: market.value || undefined,
      duration_type: duration.value || undefined,
    });
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'خطا در دریافت مسابقات';
  } finally {
    loading.value = false;
  }
}

onMounted(load);
</script>

<template>
  <div class="page">
    <header class="head">
      <h1>مسابقات</h1>
      <p>بهترین تورنمنت‌ها برای مهارت و جایزه</p>
    </header>

    <div class="filters">
      <select v-model="market" @change="load">
        <option value="">همه بازارها</option>
        <option value="forex">Forex</option>
        <option value="crypto">Crypto</option>
        <option value="mixed">Mixed</option>
      </select>
      <select v-model="duration" @change="load">
        <option value="">همه زمان‌ها</option>
        <option value="rush_30min">30M</option>
        <option value="hourly">1H</option>
        <option value="four_hour">4H</option>
        <option value="daily">1D</option>
        <option value="weekly">1W</option>
      </select>
    </div>

    <LoadingState v-if="loading" />
    <ErrorState v-else-if="error" :message="error" @retry="load" />
    <EmptyState
      v-else-if="!list.length"
      title="مسابقه‌ای یافت نشد"
      description="فیلترها را تغییر دهید یا بعداً سر بزنید."
    />
    <div v-else class="grid">
      <CompetitionCard
        v-for="c in list"
        :key="c.id"
        class="full"
        :contest="c"
        @select="(id) => router.push(`/miniapp/competitions/${id}`)"
      />
    </div>
  </div>
</template>

<style scoped>
.page {
  display: flex;
  flex-direction: column;
  gap: 14px;
}
.head h1 {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 800;
}
.head p {
  margin: 0;
  font-size: 12px;
  color: var(--ma-text-secondary);
}
.filters {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
select {
  appearance: none;
  background: var(--ma-surface-solid);
  border: 1px solid var(--ma-border);
  color: var(--ma-text);
  border-radius: var(--ma-radius-sm);
  padding: 10px 12px;
  font-family: inherit;
  font-size: 12px;
  font-weight: 600;
}
.grid {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.grid :deep(.comp-card) {
  width: 100%;
  min-width: 0;
}
</style>
