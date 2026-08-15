<script setup lang="ts">
import CompetitionStatusBadge from './CompetitionStatusBadge.vue';
import Countdown from './Countdown.vue';
import { formatUsdFromCents, formatCount } from '../utils/format';
import { durationLabel, marketLabel, resolveDisplayQty } from '../utils/qty';
import { resolveCompetitionStatus } from '../utils/status';
import { computed } from 'vue';

export interface MiniCompetition {
  id: string;
  name: string;
  status?: string;
  starts_at?: string;
  ends_at?: string;
  entry_fee_cents?: number;
  qty_total?: number;
  duration_type?: string;
  duration_minutes?: number;
  market_type?: string;
  asset_class?: string;
  participant_count?: number;
  current_participants?: number;
  estimated_prize_pool_cents?: number;
  prize_pool_cents?: number;
  is_free?: boolean;
}

const props = defineProps<{ contest: MiniCompetition }>();
defineEmits<{ select: [id: string] }>();

const participants = computed(
  () => props.contest.participant_count ?? props.contest.current_participants ?? 0,
);
const prizeCents = computed(
  () => props.contest.prize_pool_cents ?? props.contest.estimated_prize_pool_cents ?? 0,
);
const uiStatus = computed(() =>
  resolveCompetitionStatus(props.contest.status, props.contest.starts_at, participants.value),
);
const market = computed(() =>
  marketLabel(props.contest.market_type || props.contest.asset_class),
);
const duration = computed(() =>
  durationLabel(props.contest.duration_type, props.contest.duration_minutes),
);
const qty = computed(() =>
  resolveDisplayQty(props.contest.duration_type, props.contest.qty_total),
);
const countdownTarget = computed(() => {
  if (uiStatus.value === 'live') return props.contest.ends_at;
  return props.contest.starts_at;
});
const entryLabel = computed(() => {
  if (props.contest.is_free || (props.contest.entry_fee_cents ?? 0) === 0) return 'رایگان';
  return formatUsdFromCents(props.contest.entry_fee_cents);
});
</script>

<template>
  <article class="comp-card ma-glass" @click="$emit('select', contest.id)">
    <div class="top">
      <CompetitionStatusBadge :status="uiStatus" />
      <span class="duration ma-ltr-num">{{ duration }}</span>
    </div>
    <h3 class="title">{{ contest.name }}</h3>
    <div class="meta">
      <span class="market">{{ market }}</span>
      <span class="dot">·</span>
      <span class="qty ma-ltr-num">QTY {{ qty }}</span>
    </div>
    <div class="metrics">
      <div>
        <span class="m-label">جایزه</span>
        <span class="ma-ltr-num m-value gold">{{ formatUsdFromCents(prizeCents) }}</span>
      </div>
      <div>
        <span class="m-label">ورود</span>
        <span class="ma-ltr-num m-value">{{ entryLabel }}</span>
      </div>
      <div>
        <span class="m-label">بازیکنان</span>
        <span class="ma-ltr-num m-value">{{ formatCount(participants) }}</span>
      </div>
    </div>
    <div class="footer">
      <Countdown :target-iso="countdownTarget" />
      <button type="button" class="details-btn" @click.stop="$emit('select', contest.id)">
        جزئیات
      </button>
    </div>
  </article>
</template>

<style scoped>
.comp-card {
  border-radius: var(--ma-radius-md);
  padding: 14px;
  width: 240px;
  min-width: 240px;
  display: flex;
  flex-direction: column;
  gap: 8px;
  cursor: pointer;
  flex-shrink: 0;
}
.top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.duration {
  font-size: 12px;
  font-weight: 800;
  color: var(--ma-cyan);
  background: var(--ma-cyan-dim);
  padding: 3px 8px;
  border-radius: var(--ma-radius-pill);
}
.title {
  margin: 0;
  font-size: 14px;
  font-weight: 800;
  line-height: 1.35;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
  min-height: 2.6em;
}
.meta {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--ma-text-secondary);
}
.metrics {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 6px;
  padding: 8px 0 2px;
  border-top: 1px solid var(--ma-border);
}
.m-label {
  display: block;
  font-size: 10px;
  color: var(--ma-text-muted);
  margin-bottom: 2px;
}
.m-value {
  font-size: 12px;
  font-weight: 800;
  color: var(--ma-text);
}
.m-value.gold {
  color: var(--ma-gold);
}
.footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-top: 2px;
}
.details-btn {
  border: 1px solid rgba(16, 217, 138, 0.35);
  background: rgba(16, 217, 138, 0.1);
  color: var(--ma-primary);
  border-radius: var(--ma-radius-pill);
  padding: 6px 12px;
  font-family: inherit;
  font-size: 11px;
  font-weight: 700;
  cursor: pointer;
}
</style>
