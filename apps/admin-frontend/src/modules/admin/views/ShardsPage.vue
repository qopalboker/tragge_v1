<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import { t } from '@/i18n';
import { useToast } from '@/composables/useToast';
import ShardCard from '@/components/shards/ShardCard.vue';
import ShardStatsChart from '@/components/shards/ShardStatsChart.vue';
import {
  getShards,
  getShardStats,
  drainShard,
  activateShard,
  type Shard,
  type ShardStats,
} from '@/api/shards';

const toast = useToast();

const shards = ref<Shard[]>([]);
const shardStats = ref<ShardStats[]>([]);
const loading = ref(true);
const error = ref<string | null>(null);
const actionLoading = ref<number | null>(null);
const statusFilter = ref<string>('');

const filteredShards = computed(() => {
  if (!statusFilter.value) return shards.value;
  return shards.value.filter(s => s.status === statusFilter.value);
});

const statuses = ['active', 'draining', 'inactive'];

async function fetchShards(): Promise<void> {
  loading.value = true;
  error.value = null;
  try {
    const [shardsData, statsData] = await Promise.all([
      getShards(),
      getShardStats(),
    ]);
    shards.value = shardsData;
    shardStats.value = statsData;
  } catch {
    toast.error(t('shards.loadError'));
    error.value = t('common.error');
    // Never invent operational metrics — empty real state only.
    shards.value = [];
    shardStats.value = [];
  } finally {
    loading.value = false;
  }
}

async function startDrain(shardId: number): Promise<void> {
  if (!confirm(t('shards.confirmDrain'))) return;

  actionLoading.value = shardId;
  try {
    await drainShard(shardId);
    // Update local state
    const shard = shards.value.find(s => s.id === shardId);
    if (shard) {
      shard.status = 'draining';
    }
    toast.success(t('shards.drainSuccess'));
  } catch {
    toast.error(t('shards.drainError'));
  } finally {
    actionLoading.value = null;
  }
}

async function activate(shardId: number): Promise<void> {
  if (!confirm(t('shards.confirmActivate'))) return;

  actionLoading.value = shardId;
  try {
    await activateShard(shardId);
    // Update local state
    const shard = shards.value.find(s => s.id === shardId);
    if (shard) {
      shard.status = 'active';
    }
    toast.success(t('shards.activateSuccess'));
  } catch {
    toast.error(t('shards.activateError'));
  } finally {
    actionLoading.value = null;
  }
}

onMounted(fetchShards);
</script>

<template>
  <div class="shards-page">
    <div class="page-header">
      <h1 class="page-title">{{ t('shards.title') }}</h1>
      <button class="btn btn-ghost" @click="fetchShards" :disabled="loading">
        {{ t('shards.refresh') }}
      </button>
    </div>

    <div class="filters">
      <select v-model="statusFilter" class="input status-select">
        <option value="">{{ t('common.all') }}</option>
        <option v-for="status in statuses" :key="status" :value="status">
          {{ t(`shards.status.${status}`) }}
        </option>
      </select>
    </div>

    <div v-if="loading" class="loading">
      {{ t('common.loading') }}
    </div>

    <div v-else-if="error" class="error-message">
      {{ error }}
    </div>

    <template v-else>
      <div v-if="filteredShards.length === 0" class="no-results">
        {{ t('shards.noResults') }}
      </div>

      <div v-else class="shards-grid">
        <ShardCard
          v-for="shard in filteredShards"
          :key="shard.id"
          :shard="shard"
          @drain="startDrain"
          @activate="activate"
        />
      </div>

      <ShardStatsChart :stats="shardStats" class="stats-chart" />
    </template>
  </div>
</template>

<style scoped>
.shards-page {
  max-width: 1280px;
  margin: 0 auto;
}

.page-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: var(--spacing-lg);
}

.page-title {
  font-size: var(--font-size-2xl);
  font-weight: 700;
  color: var(--color-text-primary);
}

.filters {
  display: flex;
  gap: var(--spacing-md);
  margin-bottom: var(--spacing-lg);
}

.status-select {
  max-width: 200px;
}

.loading {
  text-align: center;
  padding: var(--spacing-2xl);
  color: var(--color-text-secondary);
}

.error-message {
  background-color: #FEE2E2;
  color: #DC2626;
  padding: var(--spacing-md);
  border-radius: var(--radius-md);
  margin-bottom: var(--spacing-lg);
}

.no-results {
  text-align: center;
  padding: var(--spacing-2xl);
  color: var(--color-text-secondary);
  background-color: var(--color-bg-secondary);
  border-radius: var(--radius-lg);
}

.shards-grid {
  display: grid;
  grid-template-columns: repeat(1, 1fr);
  gap: var(--spacing-lg);
}

@media (min-width: 640px) {
  .shards-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (min-width: 1024px) {
  .shards-grid {
    grid-template-columns: repeat(4, 1fr);
  }
}

.stats-chart {
  margin-top: var(--spacing-xl);
}
</style>
