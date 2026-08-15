<script setup lang="ts">
import { computed } from 'vue';
import CompetitionStatusBadge from './CompetitionStatusBadge.vue';
import Countdown from './Countdown.vue';
import EntryButton from './EntryButton.vue';
import type { MiniCompetition } from './CompetitionCard.vue';
import { formatUsdFromCents, formatCount } from '../utils/format';
import { durationLabel, marketLabel, resolveDisplayQty } from '../utils/qty';
import { resolveCompetitionStatus } from '../utils/status';

const props = defineProps<{ contest: MiniCompetition }>();
defineEmits<{ open: [id: string]; join: [id: string] }>();

const participants = computed(
  () => props.contest.participant_count ?? props.contest.current_participants ?? 0,
);
const prizeCents = computed(
  () => props.contest.prize_pool_cents ?? props.contest.estimated_prize_pool_cents ?? 0,
);
const uiStatus = computed(() =>
  resolveCompetitionStatus(props.contest.status, props.contest.starts_at, participants.value),
);
const entryLabel = computed(() => {
  if (props.contest.is_free || (props.contest.entry_fee_cents ?? 0) === 0) return 'رایگان';
  return formatUsdFromCents(props.contest.entry_fee_cents);
});
const countdownTarget = computed(() =>
  uiStatus.value === 'live' ? props.contest.ends_at : props.contest.starts_at,
);
</script>

<template>
  <article class="featured ma-glass">
    <div class="glow" aria-hidden="true" />
    <div class="top-row">
      <CompetitionStatusBadge :status="uiStatus" />
      <span class="duration ma-ltr-num">{{ durationLabel(contest.duration_type, contest.duration_minutes) }}</span>
    </div>
    <h2 class="title">{{ contest.name }}</h2>
    <p class="subtitle">
      {{ marketLabel(contest.market_type || contest.asset_class) }}
      ·
      <span class="ma-ltr-num">QTY {{ resolveDisplayQty(contest.duration_type, contest.qty_total) }}</span>
    </p>

    <div class="stats">
      <div class="stat">
        <span class="label">Prize</span>
        <span class="ma-ltr-num value gold">{{ formatUsdFromCents(prizeCents) }}</span>
      </div>
      <div class="stat">
        <span class="label">Entry</span>
        <span class="ma-ltr-num value">{{ entryLabel }}</span>
      </div>
      <div class="stat">
        <span class="label">Players</span>
        <span class="ma-ltr-num value">{{ formatCount(participants) }}</span>
      </div>
    </div>

    <div class="timer-row">
      <span class="timer-label">{{ uiStatus === 'live' ? 'پایان' : 'شروع' }}</span>
      <Countdown :target-iso="countdownTarget" large />
    </div>

    <EntryButton
      :amount-label="entryLabel"
      label="مشاهده و ثبت‌نام"
      @click="$emit('open', contest.id)"
    />
  </article>
</template>

<style scoped>
.featured {
  position: relative;
  overflow: hidden;
  border-radius: var(--ma-radius-lg);
  padding: 16px;
  border-color: rgba(16, 217, 138, 0.22);
}
.glow {
  position: absolute;
  inset: auto -20% -40% auto;
  width: 180px;
  height: 180px;
  background: radial-gradient(circle, rgba(16, 217, 138, 0.22), transparent 70%);
  pointer-events: none;
}
.top-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
}
.duration {
  font-size: 12px;
  font-weight: 800;
  color: var(--ma-primary);
  background: rgba(16, 217, 138, 0.12);
  border: 1px solid rgba(16, 217, 138, 0.25);
  padding: 4px 10px;
  border-radius: var(--ma-radius-pill);
}
.title {
  margin: 0 0 4px;
  font-size: 18px;
  font-weight: 800;
  line-height: 1.35;
  position: relative;
}
.subtitle {
  margin: 0 0 14px;
  font-size: 12px;
  color: var(--ma-text-secondary);
  position: relative;
}
.stats {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  margin-bottom: 14px;
  position: relative;
}
.stat {
  background: rgba(0, 0, 0, 0.22);
  border: 1px solid var(--ma-border);
  border-radius: var(--ma-radius-sm);
  padding: 10px 8px;
  text-align: center;
}
.label {
  display: block;
  font-size: 10px;
  color: var(--ma-text-muted);
  margin-bottom: 4px;
  font-weight: 600;
}
.value {
  font-size: 13px;
  font-weight: 800;
}
.value.gold {
  color: var(--ma-gold);
}
.timer-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
  position: relative;
}
.timer-label {
  font-size: 12px;
  color: var(--ma-text-secondary);
  font-weight: 600;
}
</style>
