<script setup lang="ts">
/**
 * Mobile-first RTL home dashboard — visual system aligned to product reference.
 * Uses real wallet / contests / stats / tickets APIs only.
 */
import { ref, computed, onMounted } from 'vue';
import { t } from '@/i18n';
import { type Contest } from '@/stores/contests';
import { userStatsApi, type UserStats, type GlobalLeaderboardEntry, api } from '@/api';
import { useAuthStore } from '@/stores/auth';
import { useWalletStore } from '@/modules/user/stores_wallet';
import FeaturedContestCard from '@/modules/user/components/dashboard/FeaturedContestCard.vue';
import ChallengeRail from '@/modules/user/components/dashboard/ChallengeRail.vue';
import SupportTicketCard from '@/modules/user/components/dashboard/SupportTicketCard.vue';
import ActiveContestsPanel from '@/components/dashboard/ActiveContestsPanel.vue';
import LeaderboardPreview from '@/components/dashboard/LeaderboardPreview.vue';

const authStore = useAuthStore();
const walletStore = useWalletStore();

const stats = ref<UserStats | null>(null);
const globalRank = ref<number | null>(null);
const totalPlayers = ref(0);
const leaderboard = ref<{ rank: number; username: string; score: number }[]>([]);
const contests = ref<Contest[]>([]);
const loading = ref(true);
const error = ref(false);

const upcomingContests = computed(() =>
  contests.value.filter((c) => c.status === 'registration_open' || c.status === 'scheduled'),
);

const featuredContest = computed(() => {
  const open = upcomingContests.value;
  if (!open.length) return contests.value.find((c) => c.status === 'running') || null;
  return [...open].sort(
    (a, b) => (b.estimated_prize_pool_cents || 0) - (a.estimated_prize_pool_cents || 0),
  )[0];
});

const suggestedContests = computed(() => {
  const featId = featuredContest.value?.id;
  return upcomingContests.value.filter((c) => c.id !== featId).slice(0, 12);
});

const userName = computed(() => {
  const user = authStore.user;
  if (user?.username) return user.username;
  if (user?.email) return user.email.split('@')[0];
  return 'Trader';
});

const winRate = computed(() => stats.value?.win_rate || 0);
const totalContests = computed(() => stats.value?.total_contests || 0);
const totalWins = computed(() => stats.value?.total_wins || 0);
const balanceLabel = computed(() => walletStore.formattedBalance);

function marketLabel(c: Contest): string {
  const m = c.market_type;
  if (m === 'forex') return 'فارکس';
  if (m === 'crypto') return 'کریپتو';
  if (m === 'stocks') return 'سهام';
  if (m === 'mixed') return 'ترکیبی';
  return t('contests.title') || 'مسابقه';
}

function durationLabel(c: Contest): string {
  const map: Record<string, string> = {
    rush_30min: '30M',
    hourly: '1H',
    four_hour: '4H',
    daily: '1D',
    weekly: '1W',
  };
  return map[c.duration_type || ''] || '—';
}

function money(cents?: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format((cents || 0) / 100);
}

async function loadDashboardData() {
  loading.value = true;
  error.value = false;

  const [statsData, leaderboardData] = await Promise.all([
    userStatsApi.getMyStats().catch(() => null),
    userStatsApi.getGlobalLeaderboard({ limit: 5 }).catch(() => null),
  ]);

  if (statsData) stats.value = statsData;
  if (leaderboardData) {
    leaderboard.value = leaderboardData.entries.map((entry: GlobalLeaderboardEntry) => ({
      rank: entry.rank,
      username: entry.username || `Trader${entry.rank}`,
      score: Math.round(entry.tragge_point),
    }));
    globalRank.value = leaderboardData.user_rank || null;
    if (leaderboardData.entries.length > 0) {
      totalPlayers.value = Math.max(leaderboardData.entries.length, globalRank.value || 0);
    }
  }
  error.value = !statsData && !leaderboardData;

  try {
    // BFF returns a JSON array of contests (not { contests: [...] }).
    const contestsResponse = await api.get<Contest[] | { contests: Contest[] }>('/api/user/contests', {
      params: { status: 'running,scheduled,registration_open', limit: 16 },
    });
    const raw = contestsResponse.data;
    const list = Array.isArray(raw) ? raw : (raw?.contests ?? []);
    contests.value = list.filter((c) => c.status !== 'cancelled');
  } catch {
    contests.value = [];
  }

  walletStore.fetchWallet().catch(() => undefined);
  loading.value = false;
}

onMounted(() => {
  loadDashboardData();
});
</script>

<template>
  <div class="home" dir="rtl">
    <!-- Hero — Wallet/Notifications/Support shortcuts live in canonical UserNavbar -->
    <section class="hero mvp-glass-strong">
      <div class="hero-copy">
        <h1 class="hero-title">
          {{ t('dashboard.welcomeHero') || 'به ترگنت خوش آمدی' }}
          <span class="wave" aria-hidden="true">👋</span>
        </h1>
        <p class="hero-sub">
          {{ t('dashboard.heroSub') || 'برای شروع، یک مسابقه انتخاب کن و مهارت‌هات رو به چالش بکش.' }}
        </p>
        <p class="hero-user">{{ userName }}</p>
      </div>
      <div class="hero-brand" aria-hidden="true">
        <div class="hero-orb">
          <div class="hero-cube">T</div>
          <div class="hero-rings" />
        </div>
      </div>
    </section>

    <div v-if="error && !loading" class="error-banner mvp-glass">
      <p>{{ t('dashboard.loadError') }}</p>
      <button type="button" class="retry-btn" @click="loadDashboardData">{{ t('common.retry') }}</button>
    </div>

    <!-- Summary metrics -->
    <section class="metrics" aria-label="summary">
      <div class="metric-main mvp-glass">
        <div class="metric-main-top">
          <span class="metric-label">{{ t('dashboard.totalAssets') || 'ارزش کل دارایی' }}</span>
        </div>
        <div class="metric-balance ma-ltr-num">{{ balanceLabel }}</div>
        <div class="metric-spark" aria-hidden="true" />
      </div>
      <div class="metric-side">
        <RouterLink to="/user/my-contests" class="metric-mini mvp-glass">
          <span class="metric-mini-icon trophy">🏆</span>
          <div>
            <div class="metric-mini-val ma-ltr-num">{{ totalWins }}</div>
            <div class="metric-mini-lab">{{ t('dashboard.prizesEarned') || 'جایزه کسب‌شده' }}</div>
          </div>
        </RouterLink>
        <RouterLink to="/user/my-tournaments" class="metric-mini mvp-glass">
          <span class="metric-mini-icon shield">◎</span>
          <div>
            <div class="metric-mini-val ma-ltr-num">{{ totalContests }}</div>
            <div class="metric-mini-lab">{{ t('dashboard.totalContests') }}</div>
          </div>
        </RouterLink>
      </div>
    </section>

    <ActiveContestsPanel />

    <!-- Featured -->
    <FeaturedContestCard :contest="featuredContest" :loading="loading" />

    <!-- Suggested horizontal rail -->
    <section class="rail-section" aria-label="suggested-contests">
      <div class="section-head">
        <h2 class="section-title">{{ t('dashboard.suggestedContests') || 'مسابقات پیشنهادی' }}</h2>
        <RouterLink to="/user/contests" class="see-all">
          {{ t('dashboard.seeAll') }}
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="rtl-flip">
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </RouterLink>
      </div>

      <div v-if="loading" class="mvp-h-scroll">
        <div v-for="i in 3" :key="i" class="sug-card skel mvp-glass" />
      </div>
      <div v-else-if="suggestedContests.length === 0" class="empty mvp-glass">
        <p>{{ t('contests.noResults') }}</p>
        <RouterLink to="/user/contests" class="see-all">{{ t('dashboard.viewAll') }}</RouterLink>
      </div>
      <div v-else class="mvp-h-scroll" role="list">
        <RouterLink
          v-for="c in suggestedContests"
          :key="c.id"
          :to="`/user/contests/${c.id}`"
          class="sug-card mvp-glass"
          role="listitem"
        >
          <div class="sug-top">
            <span class="sug-dur">{{ durationLabel(c) }}</span>
            <span class="sug-market">{{ marketLabel(c) }}</span>
          </div>
          <h3 class="sug-name">{{ c.name }}</h3>
          <div class="sug-row">
            <div>
              <div class="sug-amt ma-ltr-num prize">{{ money(c.estimated_prize_pool_cents) }}</div>
              <div class="sug-cap">{{ t('contests.prizePool') || 'جایزه کل' }}</div>
            </div>
            <div class="sug-entry">
              <div class="sug-amt ma-ltr-num">{{ c.is_free ? (t('contests.free') || 'رایگان') : money(c.entry_fee_cents) }}</div>
              <div class="sug-cap">{{ t('contests.entryFee') || 'ورودی' }}</div>
            </div>
          </div>
          <div class="sug-foot">
            <span class="sug-people ma-ltr-num">{{ c.participant_count || 0 }} {{ t('dashboard.participants') }}</span>
            <span class="sug-cta">{{ t('contests.details') || 'جزئیات' }}</span>
          </div>
        </RouterLink>
      </div>
    </section>

    <!-- Challenges horizontal -->
    <ChallengeRail :total-contests="totalContests" :loading="loading" />

    <!-- Support immediately below challenges -->
    <SupportTicketCard />

    <!-- Desktop-only extras -->
    <div class="desktop-extra">
      <div class="mvp-glass desk-card">
        <h3 class="desk-title">{{ t('dashboard.globalRanking') }}</h3>
        <div v-if="loading" class="skel-block" />
        <div v-else-if="leaderboard.length === 0" class="empty-sm">{{ t('leaderboard.noEntries') }}</div>
        <LeaderboardPreview v-else :entries="leaderboard" :user-rank="globalRank || 0" />
      </div>
      <div class="mvp-glass desk-card">
        <h3 class="desk-title">{{ t('dashboard.winRate') }}</h3>
        <p class="desk-big ma-ltr-num">{{ winRate }}%</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.home {
  display: flex;
  flex-direction: column;
  gap: var(--mvp-section-gap, 20px);
  padding: 8px var(--mvp-page-pad, 16px) calc(var(--mvp-bottom-nav-h, 72px) + var(--mvp-safe-bottom, 0px) + 20px);
  width: 100%;
  max-width: min(720px, 100%);
  margin: 0 auto;
  overflow-x: clip;
  min-width: 0;
  min-height: 100%;
  box-sizing: border-box;
}

.rail-section {
  min-width: 0;
  max-width: 100%;
}

/* Hero */
.hero {
  display: grid;
  grid-template-columns: 1.2fr 0.8fr;
  gap: 8px;
  padding: 18px 16px;
  position: relative;
  overflow: hidden;
  min-height: 140px;
}
.hero-title {
  margin: 0 0 8px;
  font-size: 20px;
  font-weight: 900;
  color: var(--mvp-text);
  line-height: 1.4;
}
.hero-sub {
  margin: 0;
  font-size: 12px;
  color: var(--mvp-text-secondary);
  line-height: 1.6;
  max-width: 28ch;
}
.hero-user {
  margin: 10px 0 0;
  font-size: 11px;
  color: var(--mvp-emerald);
  font-weight: 700;
}
.hero-brand {
  display: flex;
  align-items: center;
  justify-content: center;
}
.hero-orb {
  position: relative;
  width: 100px;
  height: 100px;
}
.hero-cube {
  position: absolute;
  inset: 22px;
  border-radius: 18px;
  background: linear-gradient(145deg, #0f766e, #042f2e);
  border: 1px solid rgba(0, 212, 160, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 28px;
  font-weight: 900;
  color: #5eead4;
  box-shadow: 0 0 30px rgba(0, 212, 160, 0.35);
  z-index: 1;
}
.hero-rings {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  border: 2px solid rgba(0, 212, 160, 0.25);
  box-shadow: 0 0 40px rgba(0, 212, 160, 0.2), inset 0 0 30px rgba(0, 212, 160, 0.08);
}
.hero-rings::after {
  content: '';
  position: absolute;
  inset: 12px;
  border-radius: 50%;
  border: 1px dashed rgba(0, 212, 160, 0.35);
}

/* Metrics */
.metrics {
  display: grid;
  grid-template-columns: 1.25fr 1fr;
  gap: 10px;
}
.metric-main {
  padding: 14px;
  min-height: 110px;
  position: relative;
  overflow: hidden;
}
.metric-label {
  font-size: 11px;
  color: var(--mvp-text-secondary);
  font-weight: 600;
}
.metric-balance {
  margin-top: 8px;
  font-size: 26px;
  font-weight: 900;
  color: var(--mvp-text);
  direction: ltr;
}
.metric-spark {
  position: absolute;
  inset-inline-end: 8px;
  bottom: 10px;
  width: 46%;
  height: 36px;
  background: linear-gradient(90deg, transparent, rgba(0, 212, 160, 0.15));
  mask-image: radial-gradient(ellipse at bottom, #000 20%, transparent 70%);
  border-radius: 8px;
}
.metric-side {
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.metric-mini {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px;
  text-decoration: none;
  color: inherit;
  min-height: 50px;
}
.metric-mini-icon {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--mvp-emerald-soft);
  font-size: 14px;
}
.metric-mini-val {
  font-size: 16px;
  font-weight: 900;
  color: var(--mvp-text);
  direction: ltr;
}
.metric-mini-lab {
  font-size: 10px;
  color: var(--mvp-text-secondary);
  font-weight: 600;
}

/* Suggested rail cards */
.section-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}
.section-title {
  margin: 0;
  font-size: 16px;
  font-weight: 800;
  color: var(--mvp-text);
}
.see-all {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: var(--mvp-emerald);
  font-size: 12px;
  font-weight: 700;
  text-decoration: none;
}
.rtl-flip { transform: scaleX(-1); }
.sug-card {
  /* Bound to parent content box, not raw viewport — avoids padding-driven overflow. */
  flex: 0 0 auto;
  width: min(240px, 100%);
  max-width: calc(100vw - 2 * var(--mvp-page-pad, 16px) - 8px);
  padding: 14px;
  text-decoration: none;
  color: inherit;
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-height: 168px;
  box-sizing: border-box;
}
.sug-card.skel {
  min-height: 160px;
  animation: pulse 1.4s ease-in-out infinite;
}
.sug-top {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
.sug-dur {
  font-size: 11px;
  font-weight: 800;
  color: var(--mvp-emerald);
  background: var(--mvp-emerald-soft);
  padding: 3px 8px;
  border-radius: 8px;
}
.sug-market {
  font-size: 12px;
  font-weight: 700;
  color: var(--mvp-text-secondary);
}
.sug-name {
  margin: 0;
  font-size: 15px;
  font-weight: 800;
  color: var(--mvp-text);
  line-height: 1.35;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
.sug-row {
  display: flex;
  justify-content: space-between;
  gap: 8px;
}
.sug-amt {
  font-size: 15px;
  font-weight: 900;
  direction: ltr;
}
.sug-amt.prize { color: #ffd666; }
.sug-cap {
  font-size: 10px;
  color: var(--mvp-text-muted);
  margin-top: 2px;
}
.sug-foot {
  margin-top: auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}
.sug-people {
  font-size: 11px;
  color: var(--mvp-text-secondary);
}
.sug-cta {
  font-size: 12px;
  font-weight: 800;
  color: #03140f;
  background: var(--mvp-emerald);
  padding: 6px 12px;
  border-radius: 999px;
}
.empty {
  padding: 20px;
  text-align: center;
  color: var(--mvp-text-secondary);
  display: flex;
  flex-direction: column;
  gap: 8px;
  align-items: center;
}
.error-banner {
  padding: 14px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  color: var(--mvp-text-secondary);
}
.retry-btn {
  border: 1px solid var(--mvp-border);
  background: rgba(255, 255, 255, 0.06);
  color: var(--mvp-text);
  border-radius: 10px;
  padding: 8px 12px;
  cursor: pointer;
}

.desktop-extra {
  display: none;
}

@media (min-width: 768px) {
  .home {
    max-width: 960px;
    padding-bottom: 40px;
  }
  .hero {
    min-height: 180px;
    padding: 28px 24px;
  }
  .hero-title { font-size: 28px; }
  .hero-orb { width: 140px; height: 140px; }
  .desktop-extra {
    display: grid;
    grid-template-columns: 1.4fr 1fr;
    gap: 14px;
  }
  .desk-card { padding: 16px; }
  .desk-title {
    margin: 0 0 12px;
    font-size: 14px;
    color: var(--mvp-text-secondary);
  }
  .desk-big {
    margin: 0;
    font-size: 32px;
    font-weight: 900;
    color: var(--mvp-emerald);
  }
  .skel-block {
    height: 120px;
    border-radius: 12px;
    background: rgba(255, 255, 255, 0.04);
  }
  .empty-sm {
    color: var(--mvp-text-secondary);
    font-size: 13px;
  }
}

@keyframes pulse {
  0%, 100% { opacity: 0.55; }
  50% { opacity: 1; }
}
</style>
