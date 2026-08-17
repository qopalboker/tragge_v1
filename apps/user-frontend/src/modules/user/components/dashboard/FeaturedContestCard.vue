<script setup lang="ts">
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { t } from '@/i18n';
import type { Contest } from '@/stores/contests';

const props = defineProps<{ contest: Contest | null; loading?: boolean }>();
const router = useRouter();

const prize = computed(() => {
  const cents = props.contest?.estimated_prize_pool_cents ?? 0;
  return formatMoney(cents);
});
const entry = computed(() => {
  if (props.contest?.is_free) return t('contests.free') || 'رایگان';
  return formatMoney(props.contest?.entry_fee_cents ?? 0);
});
const participants = computed(() => props.contest?.participant_count ?? 0);
const duration = computed(() => {
  const map: Record<string, string> = {
    rush_30min: '30M',
    hourly: '1H',
    four_hour: '4H',
    daily: '1D',
    weekly: '1W',
  };
  return map[props.contest?.duration_type || ''] || '—';
});

function formatMoney(cents: number) {
  const v = (cents || 0) / 100;
  return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD', maximumFractionDigits: 0 }).format(v);
}

function open() {
  if (!props.contest?.id) return;
  router.push(`/user/contests/${props.contest.id}`);
}
</script>

<template>
  <div v-if="loading" class="feat skeleton mvp-glass-strong" />
  <article v-else-if="contest" class="feat mvp-glass-strong" dir="rtl">
    <div class="feat-glow" aria-hidden="true" />
    <div class="feat-body">
      <div class="feat-copy">
        <span class="feat-badge">
          <span class="feat-badge-dot" />
          {{ t('contests.featured') || 'مسابقه ویژه' }}
        </span>
        <h2 class="feat-title">{{ contest.name }}</h2>
        <p class="feat-sub">
          {{ contest.description || t('dashboard.subtitle') }}
        </p>
        <div class="feat-meta">
          <span class="chip">{{ duration }}</span>
          <span class="chip chip-muted">{{ entry }} {{ t('contests.entryFee') || 'ورودی' }}</span>
          <span class="chip chip-prize">{{ prize }}</span>
        </div>
        <div class="feat-footer">
          <div class="feat-people">
            <span class="avatars" aria-hidden="true">
              <i /><i /><i />
            </span>
            <span class="people-count ma-ltr-num">+{{ participants }}</span>
            <span class="people-label">{{ t('dashboard.participants') || 'در حال ثبت‌نام' }}</span>
          </div>
          <button type="button" class="feat-cta" @click="open">
            {{ t('contests.viewAndJoin') || 'مشاهده و ثبت‌نام' }}
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" class="rtl-flip">
              <polyline points="15 18 9 12 15 6" />
            </svg>
          </button>
        </div>
      </div>
      <div class="feat-art" aria-hidden="true">
        <div class="gauge">
          <div class="gauge-ring" />
          <div class="gauge-needle" />
        </div>
      </div>
    </div>
  </article>
  <div v-else class="feat empty mvp-glass">
    <p>{{ t('contests.noResults') }}</p>
    <RouterLink to="/user/contests" class="feat-cta link">{{ t('dashboard.viewAll') }}</RouterLink>
  </div>
</template>

<style scoped>
.feat {
  position: relative;
  overflow: hidden;
  padding: 18px;
  min-height: 168px;
}
.feat.skeleton {
  min-height: 180px;
  animation: pulse 1.4s ease-in-out infinite;
}
.feat-glow {
  position: absolute;
  inset-inline-start: -20%;
  top: -40%;
  width: 70%;
  height: 120%;
  background: radial-gradient(circle, rgba(0, 212, 160, 0.22), transparent 65%);
  pointer-events: none;
}
.feat-body {
  position: relative;
  display: grid;
  grid-template-columns: 1fr minmax(90px, 120px);
  gap: 12px;
  align-items: stretch;
}
.feat-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  font-weight: 700;
  color: var(--mvp-emerald);
  margin-bottom: 8px;
}
.feat-badge-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--mvp-emerald);
  box-shadow: 0 0 8px var(--mvp-emerald-glow);
}
.feat-title {
  margin: 0 0 6px;
  font-size: 18px;
  font-weight: 800;
  color: var(--mvp-text);
  line-height: 1.35;
}
.feat-sub {
  margin: 0 0 12px;
  font-size: 12px;
  color: var(--mvp-text-secondary);
  line-height: 1.5;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.feat-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-bottom: 14px;
}
.chip {
  font-size: 11px;
  font-weight: 700;
  padding: 4px 10px;
  border-radius: 999px;
  background: var(--mvp-emerald-soft);
  color: var(--mvp-emerald);
  border: 1px solid rgba(0, 212, 160, 0.25);
}
.chip-muted {
  background: rgba(255, 255, 255, 0.05);
  color: var(--mvp-text-secondary);
  border-color: rgba(255, 255, 255, 0.08);
}
.chip-prize {
  background: rgba(255, 215, 0, 0.1);
  color: #ffd666;
  border-color: rgba(255, 215, 0, 0.2);
}
.feat-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  flex-wrap: wrap;
}
.feat-people {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--mvp-text-secondary);
}
.avatars {
  display: flex;
}
.avatars i {
  width: 22px;
  height: 22px;
  border-radius: 50%;
  border: 2px solid #0a1524;
  background: linear-gradient(135deg, #1e3a5f, #0d9488);
  margin-inline-end: -8px;
}
.people-count {
  font-weight: 800;
  color: var(--mvp-text);
  direction: ltr;
}
.feat-cta {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 10px 16px;
  border: none;
  border-radius: 999px;
  background: linear-gradient(135deg, #00e6ad, #00b386);
  color: #03140f;
  font-size: 13px;
  font-weight: 800;
  cursor: pointer;
  box-shadow: 0 8px 24px rgba(0, 212, 160, 0.35);
  text-decoration: none;
}
.feat-cta.link {
  margin-top: 8px;
}
.feat-art {
  display: flex;
  align-items: center;
  justify-content: center;
}
.gauge {
  position: relative;
  width: 96px;
  height: 96px;
}
.gauge-ring {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  border: 3px solid rgba(0, 212, 160, 0.25);
  box-shadow: 0 0 30px rgba(0, 212, 160, 0.25), inset 0 0 20px rgba(0, 212, 160, 0.12);
  background: radial-gradient(circle at 40% 40%, rgba(0, 212, 160, 0.15), transparent 60%);
}
.gauge-needle {
  position: absolute;
  width: 40%;
  height: 3px;
  background: linear-gradient(90deg, transparent, var(--mvp-emerald));
  top: 50%;
  left: 50%;
  transform-origin: left center;
  transform: rotate(-35deg);
  border-radius: 2px;
  box-shadow: 0 0 10px var(--mvp-emerald-glow);
}
.feat.empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 120px;
  color: var(--mvp-text-secondary);
  text-align: center;
}
.rtl-flip {
  transform: scaleX(-1);
}
@keyframes pulse {
  0%, 100% { opacity: 0.55; }
  50% { opacity: 1; }
}
@media (min-width: 768px) {
  .feat-title { font-size: 22px; }
  .gauge { width: 120px; height: 120px; }
}
</style>
