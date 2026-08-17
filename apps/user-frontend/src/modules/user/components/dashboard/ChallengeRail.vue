<script setup lang="ts">
import { computed } from 'vue';
import { t } from '@/i18n';

const props = defineProps<{
  totalContests: number;
  loading?: boolean;
}>();

/**
 * Progression track from authoritative participation count (stats.total_contests).
 * Milestone labels are UX progress markers only — not ledger prize credits.
 */
const milestones = [1, 3, 5, 7];

const current = computed(() => Math.max(0, props.totalContests || 0));
const goal = 7;
const progress = computed(() => Math.min(current.value, goal));
const ratio = computed(() => Math.min(1, progress.value / goal));

function stateAt(m: number): 'done' | 'current' | 'locked' {
  if (current.value >= m) return 'done';
  const prev = milestones[milestones.indexOf(m) - 1] ?? 0;
  if (current.value >= prev && current.value < m) return 'current';
  return 'locked';
}
</script>

<template>
  <section class="ch" dir="rtl" aria-label="challenges">
    <div class="ch-head">
      <div>
        <h2 class="ch-title">{{ t('dashboard.ultimateChallenge') || 'چالش اولتیمیت' }}</h2>
        <p class="ch-sub">
          {{ t('dashboard.ultimateChallengeSubProgress') || t('dashboard.ultimateChallengeSub') || 'پیشرفت شرکت در مسابقات (۷ مرحله)' }}
        </p>
      </div>
    </div>

    <div v-if="loading" class="ch-skel mvp-glass" />
    <div v-else class="ch-card mvp-glass">
      <div class="ch-ring-wrap">
        <div class="ch-ring" :style="{ '--p': ratio }">
          <div class="ch-ring-inner">
            <span class="ch-ring-num ma-ltr-num">{{ progress }}/{{ goal }}</span>
            <span class="ch-ring-label">{{ t('dashboard.contestsShort') || 'مسابقه' }}</span>
          </div>
        </div>
      </div>

      <div class="mvp-h-scroll ch-rail" role="list">
        <div
          v-for="(m, i) in milestones"
          :key="m"
          class="ch-node"
          :class="stateAt(m)"
          role="listitem"
        >
          <div class="ch-node-dot">
            <svg v-if="stateAt(m) === 'done'" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
              <polyline points="20 6 9 17 4 12" />
            </svg>
            <span v-else class="ma-ltr-num">{{ m }}</span>
          </div>
          <div class="ch-node-reward">
            <span class="ch-node-cap">{{ t('dashboard.milestone') || 'مرحله' }}</span>
            <span class="ma-ltr-num">{{ m }}</span>
          </div>
          <div v-if="i < milestones.length - 1" class="ch-node-line" />
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.ch-head {
  margin-bottom: 12px;
}
.ch-title {
  margin: 0;
  font-size: 16px;
  font-weight: 800;
  color: var(--mvp-text);
}
.ch-sub {
  margin: 4px 0 0;
  font-size: 12px;
  color: var(--mvp-text-secondary);
}
.ch-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 14px;
  min-height: 112px;
}
.ch-skel {
  height: 112px;
  animation: pulse 1.4s ease-in-out infinite;
}
.ch-ring-wrap {
  flex-shrink: 0;
}
.ch-ring {
  --p: 0;
  width: 78px;
  height: 78px;
  border-radius: 50%;
  background: conic-gradient(var(--mvp-emerald) calc(var(--p) * 360deg), rgba(255, 255, 255, 0.08) 0);
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 0 20px rgba(0, 212, 160, 0.2);
}
.ch-ring-inner {
  width: 62px;
  height: 62px;
  border-radius: 50%;
  background: #0a1524;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
}
.ch-ring-num {
  font-size: 15px;
  font-weight: 900;
  color: var(--mvp-text);
  direction: ltr;
}
.ch-ring-label {
  font-size: 9px;
  color: var(--mvp-text-secondary);
}
.ch-rail {
  flex: 1;
  min-width: 0;
  margin-inline: 0 !important;
  padding-inline: 4px !important;
  align-items: center;
}
.ch-node {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  width: 72px;
  padding-inline-end: 18px;
}
.ch-node-dot {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 12px;
  font-weight: 800;
  border: 2px solid rgba(255, 255, 255, 0.12);
  background: rgba(255, 255, 255, 0.04);
  color: var(--mvp-text-secondary);
  z-index: 1;
}
.ch-node.done .ch-node-dot {
  background: var(--mvp-emerald);
  border-color: var(--mvp-emerald);
  color: #03140f;
  box-shadow: 0 0 12px var(--mvp-emerald-glow);
}
.ch-node.current .ch-node-dot {
  border-color: var(--mvp-emerald);
  color: var(--mvp-emerald);
  box-shadow: 0 0 12px rgba(0, 212, 160, 0.3);
}
.ch-node.locked .ch-node-dot {
  opacity: 0.55;
}
.ch-node-reward {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 11px;
  font-weight: 700;
  color: var(--mvp-text-secondary);
}
.ch-node-cap {
  font-size: 10px;
  font-weight: 600;
  color: var(--mvp-text-muted, #5c667a);
}
.ch-node.done .ch-node-reward {
  color: var(--mvp-emerald);
}
.ch-node-line {
  position: absolute;
  top: 17px;
  inset-inline-end: 0;
  width: 22px;
  height: 2px;
  background: rgba(255, 255, 255, 0.1);
}
.ch-node.done .ch-node-line {
  background: rgba(0, 212, 160, 0.45);
}
@keyframes pulse {
  0%, 100% { opacity: 0.55; }
  50% { opacity: 1; }
}
</style>
