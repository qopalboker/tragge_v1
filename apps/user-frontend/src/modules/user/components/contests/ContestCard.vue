<script setup lang="ts">
import { computed, ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { t } from '@/i18n';
import { useContestsStore, type Contest, type DurationType, type MarketType } from '@/stores/contests';
import { useWalletStore } from '@/stores/wallet';
import { useToast } from '@/composables/useToast';
import CountdownTimer from './CountdownTimer.vue';

const props = defineProps<{
  contest: Contest;
  compact?: boolean;
}>();

const emit = defineEmits<{
  joined: [contestId: string];
  joinClick: [contest: Contest];
  refresh: [contestId: string];
}>();

const router = useRouter();
const contestsStore = useContestsStore();
const walletStore = useWalletStore();
const toast = useToast();
const showDetails = ref(false);
const showDepositModal = ref(false);

// Ensure wallet is loaded for balance checks on paid contests
onMounted(() => {
  if (props.contest.entry_fee_cents > 0 && !walletStore.wallet) {
    walletStore.fetchWallet();
  }
});

const entryFee = computed(() => {
  if (props.contest.entry_fee_cents === 0) {
    return t('contests.free');
  }
  return `$${(props.contest.entry_fee_cents / 100).toFixed(2)}`;
});

const isFreeEntry = computed(() => props.contest.entry_fee_cents === 0);

/** Product display timezone: Asia/Tehran (authoritative UI TZ; not browser local). */
const TEHRAN_TZ = 'Asia/Tehran';

function formatTehran(iso: string, opts: Intl.DateTimeFormatOptions): string {
  try {
    return new Date(iso).toLocaleString('en-GB', { timeZone: TEHRAN_TZ, ...opts });
  } catch {
    return new Date(iso).toLocaleString([], opts);
  }
}

const formattedStartTime = computed(() =>
  formatTehran(props.contest.starts_at, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }),
);

const formattedEndTime = computed(() =>
  formatTehran(props.contest.ends_at, {
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }),
);

const duration = computed(() => {
  const start = new Date(props.contest.starts_at);
  const end = new Date(props.contest.ends_at);
  const diffMs = end.getTime() - start.getTime();
  const hours = Math.floor(diffMs / (1000 * 60 * 60));
  const minutes = Math.floor((diffMs % (1000 * 60 * 60)) / (1000 * 60));

  if (hours >= 24) {
    const days = Math.floor(hours / 24);
    return `${days}d`;
  }
  if (hours > 0) {
    return minutes > 0 ? `${hours}h ${minutes}m` : `${hours}h`;
  }
  return `${minutes}m`;
});

// Duration type badge
const durationTypeIcons: Record<DurationType, string> = {
  rush_30min: '\u26A1',
  hourly: '\u23F1\uFE0F',
  four_hour: '\uD83D\uDD53',
  daily: '\uD83D\uDCC5',
  weekly: '\uD83D\uDCC6',
};

// Market type icons
const marketTypeIcons: Record<MarketType, string> = {
  crypto: '\u20BF',
  forex: '\uD83D\uDCB1',
  stocks: '\uD83D\uDCC8',
  mixed: '\uD83C\uDFAF',
};

const durationTypeLabel = computed(() => {
  if (!props.contest.duration_type) return null;
  return t(`filters.duration.${props.contest.duration_type}`);
});

const durationTypeIcon = computed(() => {
  if (!props.contest.duration_type) return null;
  return durationTypeIcons[props.contest.duration_type] || '';
});

const marketTypeLabel = computed(() => {
  if (!props.contest.market_type) return null;
  return t(`filters.market.${props.contest.market_type}`);
});

const marketTypeIcon = computed(() => {
  if (!props.contest.market_type) return null;
  return marketTypeIcons[props.contest.market_type] || '';
});

// Participant count
const participantCount = computed(() => props.contest.participant_count ?? 0);
// LIFECYCLE-002: product capacity removed — show count only (no max/slots).
const participantDisplay = computed(() => participantCount.value.toString());

// Authoritative prize pool only — never invent economics client-side.
const estimatedPrizePool = computed(
  () =>
    props.contest.estimated_prize_pool_cents ??
    (props.contest as { prize_pool_cents?: number }).prize_pool_cents ??
    0,
);

const formattedPrizePool = computed(() => {
  // Free and pre-quorum paid: product copy is "No prize".
  if (estimatedPrizePool.value <= 0) {
    return t('contests.noPrize') || 'No prize';
  }
  const amount = estimatedPrizePool.value / 100;
  if (amount >= 1000) {
    return `$${(amount / 1000).toFixed(1)}K`;
  }
  return `$${amount.toFixed(0)}`;
});

const firstPlacePrize = computed(
  () => (props.contest as { first_place_prize_cents?: number }).first_place_prize_cents ?? 0,
);

const formattedFirstPrize = computed(() => {
  if (firstPlacePrize.value <= 0) {
    return t('contests.noPrize') || 'No prize';
  }
  return `$${(firstPlacePrize.value / 100).toFixed(0)}`;
});

const hasAnyPrize = computed(
  () => estimatedPrizePool.value > 0 || firstPlacePrize.value > 0,
);

const symbolsList = computed(() => {
  const symbols = props.contest.symbols;
  if (!Array.isArray(symbols) || symbols.length === 0) return '';
  return (
    symbols
      .filter((s) => s.enabled)
      .map((s) => s.symbol)
      .slice(0, 3)
      .join(', ') + (symbols.length > 3 ? '...' : '')
  );
});

/** QTY is trading allocation, not money. Guard transitional nulls. */
const qtyDisplay = computed(() => {
  const qty = props.contest.qty_total;
  if (qty == null || typeof qty !== 'number' || !Number.isFinite(qty)) {
    return '—';
  }
  return `${qty.toLocaleString()} QTY`;
});

const contestIdLabel = computed(() => {
  const id = props.contest.id;
  if (!id) return '';
  return `ID ${id}`;
});

const canJoin = computed(() => {
  return props.contest.status === 'registration_open' && !contestsStore.isJoined(props.contest.id);
});

const isJoining = computed(() => contestsStore.isJoining(props.contest.id));
const isJoined = computed(() => contestsStore.isJoined(props.contest.id));

// Balance check for paid contests
const hasSufficientBalance = computed(() => {
  if (props.contest.entry_fee_cents === 0) return true;
  return walletStore.balanceCents >= props.contest.entry_fee_cents;
});

const amountNeeded = computed(() => {
  if (hasSufficientBalance.value) return 0;
  return props.contest.entry_fee_cents - walletStore.balanceCents;
});

const formattedAmountNeeded = computed(() => {
  return `$${(amountNeeded.value / 100).toFixed(2)}`;
});

function toggleDetails(): void {
  showDetails.value = !showDetails.value;
}

function closeDepositModal(): void {
  showDepositModal.value = false;
}

function goToDeposit(): void {
  showDepositModal.value = false;
  walletStore.openDepositModal();
}

function handleJoinClick(): void {
  // Check balance for paid contests
  if (props.contest.entry_fee_cents > 0 && !hasSufficientBalance.value) {
    showDepositModal.value = true;
    return;
  }

  // Emit joinClick for parent to show confirmation modal
  emit('joinClick', props.contest);
}

async function handleJoin(): Promise<void> {
  try {
    await contestsStore.joinContest(props.contest.id);
    toast.success(t('contests.joinSuccess'));
    emit('joined', props.contest.id);
  } catch (err) {
    const message = err instanceof Error ? err.message : t('common.error');
    // Check if error is insufficient balance from backend
    if (message.toLowerCase().includes('insufficient') || message.toLowerCase().includes('balance')) {
      showDepositModal.value = true;
    } else {
      toast.error(message);
    }
  }
}

// Expose handleJoin for parent to call after confirmation
defineExpose({ handleJoin });
</script>

<template>
  <div :class="['contest-card', 'card', { 'contest-card-compact': compact, 'is-open': showDetails }]">
    <div class="cc-main">
      <!-- TYPE -->
      <div class="cc-cell cc-type">
        <span class="cc-label">{{ t('tournament.colType') || 'Type' }}</span>
        <div class="cc-type-badges">
          <span v-if="durationTypeLabel" class="duration-type-badge">
            <span class="duration-icon">{{ durationTypeIcon }}</span>
            <span class="duration-label">{{ durationTypeLabel }}</span>
          </span>
          <span v-if="marketTypeLabel" class="market-type-badge">
            <span class="market-icon">{{ marketTypeIcon }}</span>
            <span class="market-label">{{ marketTypeLabel }}</span>
          </span>
          <span v-if="!durationTypeLabel && !marketTypeLabel" class="cc-muted">{{ duration }}</span>
        </div>
      </div>

      <!-- TOURNAMENT (name + id) -->
      <div class="cc-cell cc-tournament">
        <span class="cc-label">{{ t('contests.name') || 'Tournament' }}</span>
        <span class="contest-name" :title="contest.name">{{ contest.name }}</span>
        <span v-if="contestIdLabel" class="contest-id" :title="contest.id">{{ contestIdLabel }}</span>
      </div>

      <!-- START & END -->
      <div class="cc-cell cc-schedule">
        <span class="cc-label">{{ t('contest.starts') || 'Start' }} &amp; {{ t('contest.ends') || 'End' }}</span>
        <span class="cc-schedule-line ma-ltr-num">{{ formattedStartTime }}</span>
        <span class="cc-schedule-line ma-ltr-num">{{ formattedEndTime }}</span>
        <span class="cc-schedule-dur">{{ duration }}</span>
      </div>

      <!-- TRADERS -->
      <div class="cc-cell cc-traders">
        <span class="cc-label">{{ t('freePractice.traders') || t('contests.participants') || 'Traders' }}</span>
        <span class="cc-traders-value ma-ltr-num">{{ participantDisplay }}</span>
      </div>

      <!-- FIRST & TOTAL PRIZE (authoritative only) -->
      <div class="cc-cell cc-prize">
        <span class="cc-label">{{ t('contests.firstPrize') || '1st' }} &amp; {{ t('contests.prizePool') }}</span>
        <template v-if="hasAnyPrize">
          <span class="cc-prize-first ma-ltr-num">{{ formattedFirstPrize }}</span>
          <span class="cc-prize-total ma-ltr-num">{{ formattedPrizePool }}</span>
        </template>
        <span v-else class="cc-prize-none">{{ formattedPrizePool }}</span>
      </div>

      <!-- ENTRY FEE (own column — never on the Join button) -->
      <div class="cc-cell cc-fee">
        <span class="cc-label">{{ t('contests.entryFee') || 'Entry fee' }}</span>
        <span :class="['cc-fee-value', 'ma-ltr-num', { 'cc-fee-free': isFreeEntry }]">{{ entryFee }}</span>
      </div>

      <!-- STARTING IN (countdown) -->
      <div class="cc-cell cc-countdown">
        <span class="cc-label">{{ t('countdown.startsIn') || t('contests.time.startsIn') || 'Starting in' }}</span>
        <CountdownTimer
          :starts-at="contest.starts_at"
          :ends-at="contest.ends_at"
          :status="contest.status"
          :compact="true"
          @status-change="emit('refresh', contest.id)"
        />
      </div>

      <!-- JOIN — text is only Join / Enter Trading / Joined -->
      <div class="cc-cell cc-join">
        <div class="card-actions">
          <button
            v-if="!compact"
            class="btn btn-secondary btn-sm cc-details-btn"
            type="button"
            @click="toggleDetails"
          >
            {{ showDetails ? t('common.hide') || 'Hide' : t('contests.details') }}
          </button>
          <button
            v-if="canJoin"
            class="btn btn-primary join-btn"
            type="button"
            :disabled="isJoining"
            @click="handleJoinClick"
          >
            <span v-if="isJoining" class="btn-loading">
              <span class="spinner"></span>
            </span>
            <span v-else>{{ t('contests.join') || 'Join' }}</span>
          </button>
          <span v-else-if="contest.status === 'cancelled'" class="joined-badge joined-badge-muted">
            {{ t('contests.cancelled') || 'Contest Cancelled' }}
          </span>
          <button
            v-else-if="contest.status === 'running' && isJoined"
            class="btn btn-primary join-btn"
            type="button"
            @click="router.push(`/trade/${contest.id}`)"
          >
            {{ t('contests.enterTrading') || 'Enter Trading' }}
          </button>
          <span v-else-if="isJoined" class="joined-badge">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="20 6 9 17 4 12" />
            </svg>
            {{ t('contests.joined') }}
          </span>
          <span
            v-else-if="contest.status === 'registration_closed' || contest.status === 'scheduled'"
            class="joined-badge joined-badge-muted"
          >
            {{ t('countdown.startingNow') || 'Starting...' }}
          </span>
        </div>
      </div>
    </div>

    <p v-if="contest.description && !compact && showDetails" class="contest-description">
      {{ contest.description }}
    </p>

    <!-- LIFECYCLE-002: no capacity / slots progress (policy §5.2). -->
    <div v-if="showDetails" class="participants-progress">
      <span class="progress-label">{{ participantDisplay }} {{ t('contests.participants') }}</span>
    </div>

    <!-- Stats Grid (collapsed by default) -->
    <div v-if="showDetails" class="stats-grid">
      <div class="stat">
        <span class="stat-label">{{ t('contest.starts') || 'Start' }}</span>
        <span class="stat-value ma-ltr-num">{{ formattedStartTime }}</span>
      </div>
      <div class="stat">
        <span class="stat-label">{{ t('contest.ends') || 'End' }}</span>
        <span class="stat-value ma-ltr-num">{{ formattedEndTime }}</span>
      </div>
      <div class="stat">
        <span class="stat-label">{{ t('contest.symbols') || 'Symbols' }}</span>
        <span class="stat-value">{{ symbolsList || '-' }}</span>
      </div>
      <div class="stat">
        <span class="stat-label">{{ t('contest.tradingCapital') || 'QTY' }}</span>
        <span class="stat-value ma-ltr-num">{{ qtyDisplay }}</span>
      </div>
    </div>

    <!-- Expandable Details -->
    <div v-if="showDetails" class="details-section">
      <div class="details-content">
        <h4>{{ t('contest.availableSymbols') || 'Symbols' }}</h4>
        <div class="symbols-list">
          <span
            v-for="symbol in contest.symbols || []"
            :key="symbol.symbol"
            :class="['symbol-tag', { 'symbol-disabled': !symbol.enabled }]"
          >
            {{ symbol.symbol }}
          </span>
        </div>

        <template v-if="contest.rules">
          <h4>{{ t('contest.rules') || 'Rules' }}</h4>
          <p class="rules-text">{{ JSON.stringify(contest.rules, null, 2) }}</p>
        </template>
      </div>
    </div>

    <!-- Insufficient Balance Modal -->
    <Teleport to="body">
      <div v-if="showDepositModal" class="modal-overlay" @click.self="closeDepositModal">
        <div class="modal-content">
          <div class="modal-header">
            <h3 class="modal-title">{{ t('contests.depositRequired') }}</h3>
            <button class="modal-close" type="button" @click="closeDepositModal">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <line x1="18" y1="6" x2="6" y2="18" />
                <line x1="6" y1="6" x2="18" y2="18" />
              </svg>
            </button>
          </div>
          <div class="modal-body">
            <div class="deposit-icon">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M21 12V7H5a2 2 0 0 1 0-4h14v4" />
                <path d="M3 5v14a2 2 0 0 0 2 2h16v-5" />
                <path d="M18 12a2 2 0 0 0 0 4h4v-4h-4z" />
              </svg>
            </div>
            <p class="deposit-message">
              {{ t('contests.depositRequiredDesc').replace('{amount}', formattedAmountNeeded) }}
            </p>
          </div>
          <div class="modal-footer">
            <button class="btn btn-secondary" type="button" @click="closeDepositModal">
              {{ t('common.cancel') }}
            </button>
            <button class="btn btn-primary" type="button" @click="goToDeposit">
              {{ t('contests.depositNow') }}
            </button>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<style scoped>
.contest-card {
  display: flex;
  flex-direction: column;
  gap: 10px;
  width: 100%;
  max-width: 100%;
  min-width: 0;
  box-sizing: border-box;
  padding: 12px;
  overflow-x: hidden;
  background: var(--mvp-bg-card, var(--color-surface));
  border: 1px solid var(--mvp-border, var(--color-border));
  border-radius: var(--mvp-radius-sm, 12px);
  color: var(--mvp-text, var(--color-text-primary));
}

.contest-card-compact {
  padding: 10px;
}

.cc-main {
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-width: 0;
  width: 100%;
  box-sizing: border-box;
}

.cc-cell {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
  box-sizing: border-box;
}

.cc-label {
  font-size: 10px;
  font-weight: 600;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--mvp-text-muted, var(--color-text-muted));
}

.cc-type-badges {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 4px;
  min-width: 0;
}

.duration-type-badge,
.market-type-badge {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  max-width: 100%;
  padding: 3px 7px;
  font-size: 11px;
  font-weight: 600;
  line-height: 1.2;
  border-radius: 8px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.duration-type-badge {
  background-color: var(--color-bg-tertiary, var(--mvp-bg-mid));
  color: var(--mvp-text-secondary, var(--color-text-secondary));
}

.market-type-badge {
  background-color: var(--mvp-emerald-soft, var(--color-primary-light));
  color: var(--mvp-emerald, var(--color-primary));
}

.duration-icon,
.market-icon {
  font-size: 12px;
  line-height: 1;
  flex-shrink: 0;
}

.duration-label,
.market-label {
  line-height: 1.2;
  overflow: hidden;
  text-overflow: ellipsis;
}

.contest-name {
  font-size: 14px;
  font-weight: 700;
  color: var(--mvp-text, var(--color-text-primary));
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.contest-id {
  font-size: 11px;
  font-weight: 500;
  color: var(--mvp-text-muted, var(--color-text-muted));
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-variant-numeric: tabular-nums;
}

.cc-schedule-line {
  font-size: 12px;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  color: var(--mvp-text, var(--color-text-primary));
}

.cc-schedule-dur {
  font-size: 11px;
  color: var(--mvp-text-muted, var(--color-text-muted));
}

.cc-traders-value {
  font-size: 14px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
  color: var(--mvp-text, var(--color-text-primary));
}

.cc-prize-first {
  font-size: 13px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
  color: var(--mvp-emerald, var(--color-primary));
}

.cc-prize-total {
  font-size: 11px;
  font-weight: 500;
  font-variant-numeric: tabular-nums;
  color: var(--mvp-text-secondary, var(--color-text-secondary));
}

.cc-prize-none,
.cc-muted {
  font-size: 13px;
  font-weight: 500;
  color: var(--mvp-text-muted, var(--color-text-muted));
}

.cc-fee-value {
  font-size: 13px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
  color: var(--mvp-text, var(--color-text-primary));
}

.cc-fee-free {
  color: var(--mvp-emerald, var(--color-primary));
}

.cc-countdown :deep(.countdown-timer) {
  min-width: 0;
  max-width: 100%;
}

.contest-description {
  font-size: 13px;
  color: var(--mvp-text-secondary, var(--color-text-secondary));
  line-height: 1.5;
  margin: 0;
  min-width: 0;
}

.participants-progress {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}

.progress-bar {
  height: 6px;
  background-color: var(--mvp-bg-mid, var(--color-bg-tertiary));
  border-radius: 999px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--mvp-emerald, var(--color-primary)), var(--mvp-emerald-dim, #00b386));
  border-radius: 999px;
  transition: width 0.3s ease;
}

.progress-fill.progress-full {
  background: linear-gradient(90deg, var(--color-warning, #f59e0b), var(--color-danger, #ef4444));
}

.progress-label {
  font-size: 11px;
  color: var(--mvp-text-muted, var(--color-text-muted));
  text-align: end;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 6px;
  min-width: 0;
}

.stat {
  display: flex;
  justify-content: space-between;
  gap: 8px;
  min-width: 0;
  padding: 6px 8px;
  background-color: var(--mvp-bg-mid, var(--color-bg-secondary));
  border-radius: 8px;
}

.stat-label {
  font-size: 11px;
  color: var(--mvp-text-secondary, var(--color-text-secondary));
  flex-shrink: 0;
}

.stat-value {
  font-size: 11px;
  font-weight: 600;
  color: var(--mvp-text, var(--color-text-primary));
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  min-width: 0;
}

.details-section {
  padding: 10px;
  background-color: var(--mvp-bg-mid, var(--color-bg-secondary));
  border-radius: 10px;
  font-size: 13px;
  min-width: 0;
  box-sizing: border-box;
}

.details-content h4 {
  font-size: 12px;
  font-weight: 700;
  margin: 0 0 6px;
  color: var(--mvp-text, var(--color-text-primary));
}

.details-content p {
  color: var(--mvp-text-secondary, var(--color-text-secondary));
  margin: 0 0 8px;
}

.details-content p:last-child {
  margin-bottom: 0;
}

.symbols-list {
  display: flex;
  flex-wrap: wrap;
  gap: 4px;
  margin-bottom: 8px;
}

.symbol-tag {
  padding: 3px 7px;
  background-color: var(--mvp-bg-deep, var(--color-bg-primary));
  border-radius: 6px;
  font-size: 11px;
  font-weight: 600;
}

.symbol-disabled {
  opacity: 0.5;
  text-decoration: line-through;
}

.rules-text {
  font-family: var(--mvp-font-num, monospace);
  font-size: 11px;
  white-space: pre-wrap;
  word-break: break-word;
  background-color: var(--mvp-bg-deep, var(--color-bg-primary));
  padding: 8px;
  border-radius: 8px;
}

.card-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
  min-width: 0;
}

.card-actions .btn-sm {
  flex: 0 0 auto;
  padding: 6px 10px;
  font-size: 11px;
}

.join-btn {
  flex: 1 1 auto;
  min-width: 0;
  padding: 8px 14px;
  background: linear-gradient(135deg, var(--mvp-emerald, var(--color-primary)), var(--mvp-emerald-dim, #00b386));
  color: #04120e;
  font-weight: 700;
  border: none;
  border-radius: 10px;
  white-space: nowrap;
}

.join-btn:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 4px 12px var(--mvp-emerald-glow, rgba(0, 212, 160, 0.3));
}

.joined-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 6px 10px;
  background-color: var(--mvp-emerald-soft, #ECFDF5);
  color: var(--mvp-emerald, #059669);
  border-radius: 8px;
  font-size: 12px;
  font-weight: 600;
  white-space: nowrap;
}

.joined-badge-muted {
  background-color: var(--mvp-bg-mid, var(--color-bg-tertiary));
  color: var(--mvp-text-secondary, var(--color-text-secondary));
}

.btn-loading {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
}

.spinner {
  width: 14px;
  height: 14px;
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

.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 16px;
}

.modal-content {
  background: var(--mvp-bg-card-solid, var(--color-bg-primary));
  border-radius: var(--mvp-radius-md, 16px);
  max-width: 400px;
  width: 100%;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.15);
  animation: modalSlideIn 0.2s ease-out;
}

@keyframes modalSlideIn {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px;
  border-bottom: 1px solid var(--mvp-border, var(--color-border));
}

.modal-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--mvp-text, var(--color-text-primary));
  margin: 0;
}

.modal-close {
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: transparent;
  border: none;
  border-radius: 8px;
  color: var(--mvp-text-secondary, var(--color-text-secondary));
  cursor: pointer;
}

.modal-close:hover {
  background: var(--mvp-bg-mid, var(--color-bg-secondary));
}

.modal-close svg {
  width: 20px;
  height: 20px;
}

.modal-body {
  padding: 24px;
  text-align: center;
}

.deposit-icon {
  width: 64px;
  height: 64px;
  background: var(--mvp-emerald-soft, var(--color-primary-light));
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  margin: 0 auto 16px;
}

.deposit-icon svg {
  width: 32px;
  height: 32px;
  color: var(--mvp-emerald, var(--color-primary));
}

.deposit-message {
  font-size: 14px;
  color: var(--mvp-text-secondary, var(--color-text-secondary));
  line-height: 1.5;
  margin: 0;
}

.modal-footer {
  display: flex;
  gap: 8px;
  padding: 16px;
  border-top: 1px solid var(--mvp-border, var(--color-border));
}

.modal-footer .btn {
  flex: 1;
}

/* Desktop: horizontal competition row. Compact carousel cards stay stacked. */
@media (min-width: 900px) {
  .contest-card:not(.contest-card-compact) {
    grid-column: 1 / -1;
    padding: 10px 12px;
    gap: 8px;
  }

  .contest-card:not(.contest-card-compact) .cc-main {
    display: grid;
    grid-template-columns:
      minmax(72px, 0.85fr)
      minmax(0, 1.5fr)
      minmax(0, 1.15fr)
      minmax(52px, 0.7fr)
      minmax(0, 1fr)
      minmax(64px, 0.8fr)
      minmax(92px, 1.05fr)
      auto;
    align-items: center;
    gap: 0;
  }

  .contest-card:not(.contest-card-compact) .cc-cell {
    padding: 0 10px;
    border-inline-start: 1px solid var(--mvp-border, var(--color-border));
    justify-content: center;
  }

  .contest-card:not(.contest-card-compact) .cc-cell:first-child {
    border-inline-start: none;
    padding-inline-start: 0;
  }

  .contest-card:not(.contest-card-compact) .cc-join {
    padding-inline-end: 0;
    align-items: stretch;
  }

  .contest-card:not(.contest-card-compact) .cc-type-badges {
    flex-direction: column;
    align-items: flex-start;
    flex-wrap: nowrap;
  }

  .contest-card:not(.contest-card-compact) .card-actions {
    flex-wrap: nowrap;
    justify-content: flex-end;
  }

  .contest-card:not(.contest-card-compact) .join-btn {
    flex: 0 0 auto;
    min-width: 88px;
    padding: 7px 14px;
    font-size: 12px;
  }

  .contest-card:not(.contest-card-compact) .cc-details-btn {
    padding: 6px 8px;
  }

  .contest-card:not(.contest-card-compact) .cc-label {
    /* Column IA is implied by order; labels stay on stacked mobile cards. */
    position: absolute;
    width: 1px;
    height: 1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
  }

  .contest-card:not(.contest-card-compact) .cc-cell {
    position: relative;
  }
}

@media (max-width: 899px) {
  .contest-card {
    /* Stacked card — never a shrunk table row */
    display: flex;
    flex-direction: column;
  }

  .cc-main {
    display: flex;
    flex-direction: column;
  }

  .cc-cell {
    border-inline-start: none;
    padding-block: 2px;
  }

  .contest-name {
    white-space: normal;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
  }

  .cc-schedule-line,
  .cc-prize-first,
  .cc-prize-total,
  .cc-fee-value {
    white-space: normal;
  }

  .join-btn {
    flex: 1 1 120px;
  }
}
</style>
