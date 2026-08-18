<script setup lang="ts">
import { computed, ref, watch } from 'vue';
import { t } from '@/i18n';
import type { MarketType } from '@/stores/contests';
import { useCountdown } from '@/composables/useCountdown';

const props = defineProps<{
  startsAt: string;
  endsAt: string;
  marketType?: MarketType;
  participantCount: number;
  maxParticipants?: number;
  minParticipants?: number;
  /** Trading allocation; may be absent on transitional payloads — display falls back to em dash. */
  qtyTotal?: number | null;
  entryFeeCents: number;
  isJoined: boolean;
  isJoining: boolean;
  canJoin: boolean;
  status: 'registration_open' | 'scheduled' | 'registration_closed' | 'running' | 'paused' | 'settling' | 'completed' | 'cancelled';
  serverTimeDeltaMs?: number;
}>();

const emit = defineEmits<{
  join: [];
  enterTrading: [];
  viewResults: [];
}>();

const minRequired = computed(() => props.minParticipants ?? 2);
const needsMorePlayers = computed(
  () =>
    (props.status === 'registration_open' || props.status === 'scheduled' || props.status === 'registration_closed') &&
    props.participantCount < minRequired.value
);
const countdownTarget = computed(() => {
  if (props.status === 'running' || props.status === 'paused') return props.endsAt;
  return props.startsAt;
});
const serverDelta = ref(props.serverTimeDeltaMs ?? 0);
watch(
  () => props.serverTimeDeltaMs,
  (v) => {
    serverDelta.value = v ?? 0;
  }
);
const { compactDisplay, timeRemaining } = useCountdown({
  targetDate: countdownTarget,
  serverTimeDelta: serverDelta,
});

function formatContestInstant(iso: string | undefined | null): string {
  if (!iso) return '—';
  const date = new Date(iso);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString([], {
    day: '2-digit',
    month: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  });
}

// Format date/time
const formattedStartTime = computed(() => formatContestInstant(props.startsAt));
const formattedEndTime = computed(() => formatContestInstant(props.endsAt));

// Calculate duration
const duration = computed(() => {
  const start = new Date(props.startsAt);
  const end = new Date(props.endsAt);
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) return '—';
  const diffMs = end.getTime() - start.getTime();
  if (diffMs <= 0) return '—';
  const hours = Math.floor(diffMs / (1000 * 60 * 60));
  const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));

  if (hours >= 24) {
    const days = Math.floor(hours / 24);
    const remainingHours = hours % 24;
    if (remainingHours > 0) {
      return `${days} ${t('contestDetails.day')} ${remainingHours} ${t('contestDetails.hour')}`;
    }
    return `${days} ${t('contestDetails.day')}`;
  }
  if (hours > 0) {
    return minutes > 0 ? `${hours} ${t('contestDetails.hour')}` : `${hours} ${t('contestDetails.hour')}`;
  }
  return `${minutes} ${t('contestDetails.minute')}`;
});

// Market type label
const marketTypeLabel = computed(() => {
  if (!props.marketType) return '-';
  return t(`filters.market.${props.marketType}`);
});

// Entry fee
const entryFee = computed(() => {
  if (props.entryFeeCents === 0) {
    return t('contests.free');
  }
  return `$${(props.entryFeeCents / 100).toFixed(2)}`;
});

// Entry fee badge style
const entryFeeIsFree = computed(() => props.entryFeeCents === 0);

// Available quantity display — qty_total is intentional contract; guard transitional nulls.
const availableQty = computed(() => {
  const qty = props.qtyTotal;
  if (typeof qty !== 'number' || !Number.isFinite(qty)) {
    return '—';
  }
  return `$${qty.toLocaleString()}`;
});

// Participant display (real users only from API)
const participantDisplay = computed(() => {
  return `${props.participantCount} / ${minRequired.value}`;
});

// Available slots
const availableSlots = computed(() => {
  if (!props.maxParticipants) return null;
  return props.maxParticipants - props.participantCount;
});

const isRunning = computed(() => props.status === 'running');
const isCompleted = computed(() => props.status === 'completed' || props.status === 'settling');
const isPreStart = computed(
  () =>
    props.status === 'registration_open' ||
    props.status === 'scheduled' ||
    props.status === 'registration_closed'
);
const countdownLabel = computed(() => {
  if (isRunning.value || props.status === 'paused') return t('countdown.endsIn') || 'Ends in';
  if (isPreStart.value) return t('countdown.startsIn') || 'Starts in';
  return '';
});
const waitLabel = computed(() => {
  if (!needsMorePlayers.value) return '';
  const need = Math.max(0, minRequired.value - props.participantCount);
  return t('contestDetails.waitingParticipants', { current: props.participantCount, min: minRequired.value, need }) ||
    `Waiting for participants (${props.participantCount}/${minRequired.value})`;
});

function handleJoin(): void {
  emit('join');
}

function handleEnterTrading(): void {
  emit('enterTrading');
}

function handleViewResults(): void {
  emit('viewResults');
}
</script>

<template>
  <div class="tournament-details-card">
    <!-- Header -->
    <div class="card-header">
      <h3 class="card-title">{{ t('contestDetails.tournamentDetails') }}</h3>
      <button class="info-button" :title="t('contestDetails.moreInfo')">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <circle cx="12" cy="12" r="10" />
          <path d="M12 16v-4M12 8h.01" />
        </svg>
      </button>
    </div>

    <!-- Live countdown + quorum (presentation only; backend is authoritative) -->
    <div v-if="isPreStart || isRunning" class="countdown-block">
      <div v-if="needsMorePlayers" class="wait-banner">{{ waitLabel }}</div>
      <div v-else-if="isPreStart && !timeRemaining.isExpired" class="ready-banner">
        {{ t('contestDetails.readyToStart') || 'Ready — waiting for start time' }}
      </div>
      <div v-if="!timeRemaining.isExpired" class="countdown-row">
        <span class="countdown-label">{{ countdownLabel }}</span>
        <span class="countdown-value ma-ltr-num">{{ compactDisplay }}</span>
      </div>
      <div v-else-if="isPreStart" class="countdown-row muted">
        {{ t('contestDetails.awaitingStart') || 'Start time reached — waiting for server…' }}
      </div>
    </div>

    <!-- Details List -->
    <div class="details-list">
      <div class="detail-row">
        <span class="detail-label">{{ t('contestDetails.start') }}</span>
        <span class="detail-value">{{ formattedStartTime }}</span>
      </div>
      <div class="detail-row">
        <span class="detail-label">{{ t('contestDetails.end') }}</span>
        <span class="detail-value">{{ formattedEndTime }}</span>
      </div>
      <div class="detail-row">
        <span class="detail-label">{{ t('contestDetails.duration') }}</span>
        <span class="detail-value">{{ duration }}</span>
      </div>
      <div class="detail-row">
        <span class="detail-label">{{ t('contestDetails.market') }}</span>
        <span class="detail-value">{{ marketTypeLabel }}</span>
      </div>
      <div class="detail-row">
        <span class="detail-label">{{ t('contestDetails.traders') }}</span>
        <span class="detail-value detail-value-link">{{ participantDisplay }}</span>
      </div>
      <div class="detail-row">
        <span class="detail-label">{{ t('contestDetails.availableQuantity') }}</span>
        <span class="detail-value">
          <svg class="qty-icon" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="2" y="4" width="20" height="16" rx="2" />
            <path d="M7 15h10M7 11h4" />
          </svg>
          {{ availableQty }}
        </span>
      </div>
      <div class="detail-row">
        <span class="detail-label">{{ t('contestDetails.entryFee') }}</span>
        <span :class="['detail-value', 'entry-fee-badge', { 'entry-fee-free': entryFeeIsFree }]">
          {{ entryFee }}
        </span>
      </div>
    </div>

    <!-- Action Button — CTAs follow backend status only -->
    <div class="card-actions">
      <template v-if="canJoin && !isJoined">
        <button
          class="btn btn-primary btn-join"
          :disabled="isJoining"
          @click="handleJoin"
        >
          <span v-if="isJoining" class="btn-loading">
            <span class="spinner"></span>
          </span>
          <span v-else>{{ t('contests.join') }}</span>
        </button>
      </template>
      <template v-else-if="isJoined && isRunning">
        <button
          class="btn btn-success btn-enter"
          @click="handleEnterTrading"
        >
          {{ t('contests.enterTrading') || 'Enter Trading' }}
        </button>
      </template>
      <template v-else-if="isJoined && (props.status === 'settling' || props.status === 'completed')">
        <button
          class="btn btn-primary btn-results"
          @click="handleViewResults"
        >
          {{ t('contestDetails.viewResults') || 'View Result' }}
        </button>
      </template>
      <template v-else-if="isJoined && isPreStart">
        <div class="joined-status">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="20 6 9 17 4 12" />
          </svg>
          <span>{{ needsMorePlayers
            ? (t('contestDetails.waitingForPlayers') || 'Waiting for players')
            : (t('contestDetails.waitingForStart') || 'Waiting for start') }}</span>
        </div>
      </template>
      <template v-else-if="isJoined">
        <div class="joined-status">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="20 6 9 17 4 12" />
          </svg>
          <span>{{ t('contests.joined') }}</span>
        </div>
      </template>
    </div>

    <!-- Available Slots Notice -->
    <div v-if="availableSlots !== null && availableSlots < 10 && canJoin" class="slots-notice">
      <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10" />
        <polyline points="12 6 12 12 16 14" />
      </svg>
      <span>{{ t('contestDetails.slotsRemaining', { count: availableSlots }) }}</span>
    </div>
  </div>
</template>

<style scoped>
.tournament-details-card {
  background: var(--color-bg-primary);
  border-radius: var(--radius-lg);
  border: 1px solid var(--color-border);
  overflow: hidden;
  width: 100%;
  max-width: 100%;
  min-width: 0;
  box-sizing: border-box;
}

.countdown-block {
  padding: 12px 16px;
  border-bottom: 1px solid var(--color-border);
  background: var(--color-bg-secondary, rgba(0, 0, 0, 0.15));
}
.wait-banner {
  font-size: 12px;
  font-weight: 600;
  color: var(--color-warning, #f59e0b);
  margin-bottom: 6px;
}
.ready-banner {
  font-size: 12px;
  font-weight: 600;
  color: var(--color-success, #10b981);
  margin-bottom: 6px;
}
.countdown-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}
.countdown-label {
  font-size: 12px;
  color: var(--color-text-secondary);
}
.countdown-value {
  font-size: 18px;
  font-weight: 800;
  font-variant-numeric: tabular-nums;
  color: var(--color-text-primary);
}
.countdown-row.muted {
  font-size: 12px;
  color: var(--color-text-secondary);
}

.card-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--spacing-md) var(--spacing-lg);
  border-bottom: 1px solid var(--color-border);
  background: var(--color-bg-secondary);
}

.card-title {
  font-size: var(--font-size-md);
  font-weight: 600;
  color: var(--color-text-primary);
  margin: 0;
}

.info-button {
  width: 28px;
  height: 28px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: var(--radius-md);
  color: var(--color-text-secondary);
  cursor: pointer;
  transition: background-color var(--transition-fast);
}

.info-button:hover {
  background: var(--color-bg-tertiary);
}

.details-list {
  padding: var(--spacing-md) var(--spacing-lg);
}

.detail-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--spacing-sm) 0;
  border-bottom: 1px solid var(--color-border-light, rgba(0,0,0,0.05));
}

.detail-row:last-child {
  border-bottom: none;
}

.detail-label {
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
}

.detail-value {
  font-size: var(--font-size-sm);
  font-weight: 500;
  color: var(--color-text-primary);
  display: flex;
  align-items: center;
  gap: var(--spacing-xs);
}

.detail-value-link {
  color: var(--color-primary);
}

.qty-icon {
  color: var(--color-text-muted);
}

.entry-fee-badge {
  padding: 2px var(--spacing-sm);
  border-radius: var(--radius-full);
  background: var(--color-bg-tertiary);
}

.entry-fee-free {
  background: #ECFDF5;
  color: #059669;
  border: 1px solid #059669;
}

.card-actions {
  padding: var(--spacing-md) var(--spacing-lg);
  border-top: 1px solid var(--color-border);
}

.btn-join {
  width: 100%;
  padding: var(--spacing-md);
  font-size: var(--font-size-md);
  font-weight: 600;
  background: linear-gradient(135deg, #06b6d4 0%, #0891b2 100%);
  border: none;
  border-radius: var(--radius-md);
  color: white;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.btn-join:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(6, 182, 212, 0.3);
}

.btn-join:disabled {
  opacity: 0.7;
  cursor: not-allowed;
}

.btn-leave {
  width: 100%;
  padding: var(--spacing-md);
  font-size: var(--font-size-md);
  font-weight: 500;
  background: var(--color-bg-secondary);
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  color: var(--color-text-secondary);
  cursor: pointer;
  transition: all var(--transition-fast);
}

.btn-leave:hover {
  background: var(--color-bg-tertiary);
  color: var(--color-danger);
  border-color: var(--color-danger);
}

.btn-enter {
  width: 100%;
  padding: var(--spacing-md);
  font-size: var(--font-size-md);
  font-weight: 600;
  background: linear-gradient(135deg, #10b981 0%, #059669 100%);
  border: none;
  border-radius: var(--radius-md);
  color: white;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.btn-enter:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
}

.btn-results {
  width: 100%;
  padding: var(--spacing-md);
  font-size: var(--font-size-md);
  font-weight: 600;
  background: linear-gradient(135deg, #8b5cf6 0%, #7c3aed 100%);
  border: none;
  border-radius: var(--radius-md);
  color: white;
  cursor: pointer;
  transition: all var(--transition-fast);
}

.btn-results:hover {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);
}

.joined-status {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-xs);
  padding: var(--spacing-md);
  background: #ECFDF5;
  color: #059669;
  border-radius: var(--radius-md);
  font-weight: 500;
}

.slots-notice {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-xs);
  padding: var(--spacing-sm) var(--spacing-lg);
  background: #FEF3C7;
  color: #D97706;
  font-size: var(--font-size-sm);
  font-weight: 500;
}

.btn-loading {
  display: flex;
  align-items: center;
  justify-content: center;
}

.spinner {
  width: 18px;
  height: 18px;
  border: 2px solid currentColor;
  border-top-color: transparent;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

/* RTL Support */
[dir="rtl"] .detail-row {
  flex-direction: row-reverse;
}

[dir="rtl"] .card-header {
  flex-direction: row-reverse;
}

/* Mobile */
@media (max-width: 767px) {
  .card-header {
    padding: var(--spacing-sm) var(--spacing-md);
  }

  .details-list {
    padding: var(--spacing-sm) var(--spacing-md);
  }

  .card-actions {
    padding: var(--spacing-sm) var(--spacing-md);
  }

  .detail-label,
  .detail-value {
    font-size: var(--font-size-xs);
  }
}
</style>
