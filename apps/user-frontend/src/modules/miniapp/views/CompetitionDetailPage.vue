<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { api } from '@/api';
import CompetitionStatusBadge from '../components/CompetitionStatusBadge.vue';
import Countdown from '../components/Countdown.vue';
import PrizeInfo from '../components/PrizeInfo.vue';
import EntryButton from '../components/EntryButton.vue';
import LoadingState from '../components/LoadingState.vue';
import ErrorState from '../components/ErrorState.vue';
import { formatUsdFromCents, formatCount, formatDateTime, shortId } from '../utils/format';
import { durationLabel, marketLabel, resolveDisplayQty } from '../utils/qty';
import { resolveCompetitionStatus } from '../utils/status';
import { bindTelegramBackButton, hapticSuccess } from '../telegram';
import { useWalletStore } from '@/stores/wallet';
import { useContestsStore } from '@/stores/contests';

const route = useRoute();
const router = useRouter();
const wallet = useWalletStore();
const contestsStore = useContestsStore();

const loading = ref(true);
const joining = ref(false);
const error = ref<string | null>(null);
const joinError = ref<string | null>(null);
const showConfirm = ref(false);

interface Detail {
  id: string;
  name: string;
  description?: string;
  status: string;
  starts_at: string;
  ends_at: string;
  entry_fee_cents: number;
  qty_total: number;
  duration_type?: string;
  duration_minutes?: number;
  market_type?: string;
  asset_class?: string;
  participant_count?: number;
  estimated_prize_pool_cents?: number;
  prize_pool_cents?: number;
  is_free?: boolean;
  user_joined?: boolean;
}

interface PrizePreview {
  prize_pool_cents?: number;
  ranks?: { rank: number; amount_cents: number }[];
  first_prize_cents?: number;
}

const contest = ref<Detail | null>(null);
const prizePreview = ref<PrizePreview | null>(null);

const contestId = computed(() => String(route.params.contestId || ''));

const participants = computed(() => contest.value?.participant_count ?? 0);
const prizePoolCents = computed(
  () =>
    prizePreview.value?.prize_pool_cents ??
    contest.value?.prize_pool_cents ??
    contest.value?.estimated_prize_pool_cents ??
    0,
);
const firstPrizeCents = computed(() => {
  if (prizePreview.value?.first_prize_cents != null) return prizePreview.value.first_prize_cents;
  const ranks = prizePreview.value?.ranks;
  if (ranks?.length) {
    const first = ranks.find((r) => r.rank === 1) || ranks[0];
    return first?.amount_cents ?? 0;
  }
  return Math.floor(prizePoolCents.value * 0.4);
});
const uiStatus = computed(() =>
  resolveCompetitionStatus(contest.value?.status, contest.value?.starts_at, participants.value),
);
const entryLabel = computed(() => {
  if (!contest.value) return formatUsdFromCents(0);
  if (contest.value.is_free || contest.value.entry_fee_cents === 0) return 'رایگان';
  return formatUsdFromCents(contest.value.entry_fee_cents);
});
const qty = computed(() =>
  resolveDisplayQty(contest.value?.duration_type, contest.value?.qty_total),
);
const countdownTarget = computed(() =>
  uiStatus.value === 'live' ? contest.value?.ends_at : contest.value?.starts_at,
);
const remainingAfterJoin = computed(() => {
  const bal = wallet.balanceCents ?? 0;
  const fee = contest.value?.entry_fee_cents ?? 0;
  return formatUsdFromCents(Math.max(0, bal - fee));
});

async function load() {
  loading.value = true;
  error.value = null;
  try {
    const [detailRes, prizeRes] = await Promise.all([
      api.get<Detail>(`/api/user/contests/${contestId.value}`),
      api.get<PrizePreview>(`/api/user/contests/${contestId.value}/prize-preview`).catch(() => null),
      wallet.fetchWallet().catch(() => undefined),
    ]);
    contest.value = detailRes.data;
    prizePreview.value = prizeRes?.data ?? null;
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'خطا در دریافت جزئیات مسابقه';
  } finally {
    loading.value = false;
  }
}

async function confirmJoin() {
  if (!contest.value) return;
  joining.value = true;
  joinError.value = null;
  try {
    await contestsStore.joinContest(contest.value.id);
    hapticSuccess();
    showConfirm.value = false;
    await load();
    if (contest.value.status === 'running' || contest.value.user_joined) {
      router.push(`/trade/${contest.value.id}`);
    }
  } catch (e: unknown) {
    joinError.value = e instanceof Error ? e.message : 'ورود ناموفق بود';
  } finally {
    joining.value = false;
  }
}

let unbindBack: (() => void) | undefined;
onMounted(() => {
  load();
  unbindBack = bindTelegramBackButton(() => router.back());
});
onUnmounted(() => unbindBack?.());
</script>

<template>
  <div class="detail">
    <header class="top">
      <button type="button" class="back" @click="router.back()">‹ بازگشت</button>
      <span v-if="contest" class="id ma-ltr-num">#{{ shortId(contest.id) }}</span>
    </header>

    <LoadingState v-if="loading" />
    <ErrorState v-else-if="error" :message="error" @retry="load" />
    <template v-else-if="contest">
      <div class="identity ma-glass">
        <div class="row">
          <span class="market">{{ marketLabel(contest.market_type || contest.asset_class) }}</span>
          <CompetitionStatusBadge :status="uiStatus" />
        </div>
        <h1>{{ contest.name }}</h1>
        <p class="sub">
          <span class="ma-ltr-num">{{ durationLabel(contest.duration_type, contest.duration_minutes) }}</span>
          ·
          <span class="ma-ltr-num">QTY {{ qty }}</span>
        </p>
      </div>

      <section class="timer ma-glass">
        <span class="timer-label">{{ uiStatus === 'live' ? 'زمان باقی‌مانده تا پایان' : 'شروع تا' }}</span>
        <Countdown :target-iso="countdownTarget" large />
        <div class="times">
          <div>
            <span class="t-label">شروع</span>
            <span class="t-value">{{ formatDateTime(contest.starts_at) }}</span>
          </div>
          <div>
            <span class="t-label">پایان</span>
            <span class="t-value">{{ formatDateTime(contest.ends_at) }}</span>
          </div>
        </div>
      </section>

      <section class="prize-block ma-glass">
        <PrizeInfo
          :prize-pool-label="formatUsdFromCents(prizePoolCents)"
          :first-prize-label="formatUsdFromCents(firstPrizeCents)"
        />
        <div class="extra">
          <div>
            <span class="e-label">مدت</span>
            <span class="ma-ltr-num e-value">{{ durationLabel(contest.duration_type, contest.duration_minutes) }}</span>
          </div>
          <div>
            <span class="e-label">شرکت‌کنندگان</span>
            <span class="ma-ltr-num e-value">{{ formatCount(participants) }}</span>
          </div>
          <div>
            <span class="e-label">Quantity</span>
            <span class="ma-ltr-num e-value">{{ qty }}</span>
          </div>
        </div>
      </section>

      <EntryButton
        v-if="!contest.user_joined && uiStatus !== 'finished'"
        :amount-label="entryLabel"
        :loading="joining"
        @click="showConfirm = true"
      />
      <button
        v-else-if="contest.user_joined"
        type="button"
        class="ma-btn ma-btn-primary trade-btn"
        @click="router.push(`/trade/${contest.id}`)"
      >
        ورود به صفحه معاملات
      </button>
    </template>

    <div v-if="showConfirm && contest" class="sheet-backdrop" @click.self="showConfirm = false">
      <div class="sheet ma-glass">
        <h3>تأیید ورود</h3>
        <ul>
          <li><span>هزینه ورود</span><span class="ma-ltr-num">{{ entryLabel }}</span></li>
          <li><span>موجودی کیف پول</span><span class="ma-ltr-num">{{ wallet.formattedBalance }}</span></li>
          <li><span>مانده پس از ورود</span><span class="ma-ltr-num">{{ remainingAfterJoin }}</span></li>
          <li><span>جایزه کل</span><span class="ma-ltr-num">{{ formatUsdFromCents(prizePoolCents) }}</span></li>
          <li><span>Quantity</span><span class="ma-ltr-num">{{ qty }}</span></li>
        </ul>
        <p v-if="joinError" class="err">{{ joinError }}</p>
        <div class="sheet-actions">
          <button type="button" class="ma-btn ma-btn-ghost" @click="showConfirm = false">انصراف</button>
          <button type="button" class="ma-btn ma-btn-primary" :disabled="joining" @click="confirmJoin">
            {{ joining ? '…' : 'تأیید ورود' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.detail {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
.top {
  display: flex;
  align-items: center;
  justify-content: space-between;
}
.back {
  border: none;
  background: transparent;
  color: var(--ma-text-secondary);
  font-family: inherit;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  padding: 6px 0;
}
.id {
  font-size: 11px;
  color: var(--ma-text-muted);
  font-weight: 700;
}
.identity,
.timer,
.prize-block {
  border-radius: var(--ma-radius-md);
  padding: 14px;
}
.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
}
.market {
  font-size: 12px;
  font-weight: 700;
  color: var(--ma-cyan);
}
.identity h1 {
  margin: 0 0 6px;
  font-size: 20px;
  font-weight: 800;
  line-height: 1.35;
}
.sub {
  margin: 0;
  font-size: 12px;
  color: var(--ma-text-secondary);
}
.timer {
  text-align: center;
}
.timer-label {
  display: block;
  font-size: 12px;
  color: var(--ma-text-secondary);
  margin-bottom: 8px;
  font-weight: 600;
}
.times {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
  margin-top: 14px;
  text-align: start;
}
.t-label,
.e-label {
  display: block;
  font-size: 11px;
  color: var(--ma-text-muted);
  margin-bottom: 3px;
}
.t-value,
.e-value {
  font-size: 12px;
  font-weight: 700;
  color: var(--ma-text);
}
.extra {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  margin-top: 14px;
  padding-top: 12px;
  border-top: 1px solid var(--ma-border);
}
.trade-btn {
  min-height: 48px;
  width: 100%;
  font-size: 14px;
}
.sheet-backdrop {
  position: fixed;
  inset: 0;
  z-index: 50;
  background: rgba(0, 0, 0, 0.55);
  display: flex;
  align-items: flex-end;
  justify-content: center;
  padding: 14px;
  padding-bottom: calc(14px + var(--ma-safe-bottom));
}
.sheet {
  width: min(480px, 100%);
  border-radius: var(--ma-radius-lg) var(--ma-radius-lg) 18px 18px;
  padding: 18px 16px 16px;
}
.sheet h3 {
  margin: 0 0 12px;
  font-size: 16px;
  font-weight: 800;
}
.sheet ul {
  list-style: none;
  margin: 0 0 12px;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.sheet li {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  font-size: 13px;
  color: var(--ma-text-secondary);
}
.sheet li .ma-ltr-num {
  color: var(--ma-text);
  font-weight: 700;
}
.sheet-actions {
  display: grid;
  grid-template-columns: 1fr 1.2fr;
  gap: 8px;
}
.sheet-actions .ma-btn {
  min-height: 44px;
  font-size: 13px;
}
.err {
  color: var(--ma-danger);
  font-size: 12px;
  margin: 0 0 10px;
}
</style>
