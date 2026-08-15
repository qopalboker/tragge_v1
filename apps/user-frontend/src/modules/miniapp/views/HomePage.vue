<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import AppHeader from '../components/AppHeader.vue';
import SectionHeader from '../components/SectionHeader.vue';
import FeaturedCompetitionCard from '../components/FeaturedCompetitionCard.vue';
import CompetitionCard, { type MiniCompetition } from '../components/CompetitionCard.vue';
import StatCard from '../components/StatCard.vue';
import LoadingState from '../components/LoadingState.vue';
import ErrorState from '../components/ErrorState.vue';
import EmptyState from '../components/EmptyState.vue';
import { useWalletStore } from '@/stores/wallet';
import { useAuthStore } from '@/stores/auth';
import { useContestsStore } from '@/stores/contests';
import { userStatsApi } from '@/api';
import { formatUsd, formatCount } from '../utils/format';
import { notificationsApi } from '@/modules/user/api/notifications';

const router = useRouter();
const wallet = useWalletStore();
const auth = useAuthStore();
const contestsStore = useContestsStore();

const loading = ref(true);
const error = ref<string | null>(null);
const unread = ref(0);
const stats = ref<{ total_contests: number; total_wins: number; total_pnl: number } | null>(null);

const balanceLabel = computed(() => wallet.formattedBalance || formatUsd(0));
const displayName = computed(
  () => auth.user?.display_name || auth.user?.username || 'تریدر',
);

const featured = computed<MiniCompetition | null>(() => {
  const list = contestsStore.contests;
  if (!list.length) return null;
  const open = list.find((c) => c.status === 'registration_open' || c.status === 'running');
  return (open || list[0]) as MiniCompetition;
});

const suggested = computed<MiniCompetition[]>(() => {
  const featId = featured.value?.id;
  return contestsStore.contests
    .filter((c) => c.id !== featId)
    .slice(0, 8) as MiniCompetition[];
});

async function load() {
  loading.value = true;
  error.value = null;
  try {
    await Promise.all([
      wallet.fetchWallet().catch(() => undefined),
      contestsStore.fetchContests().catch((e: Error) => {
        throw e;
      }),
      userStatsApi.getMyStats().then((s) => {
        stats.value = {
          total_contests: s.total_contests,
          total_wins: s.total_wins,
          total_pnl: s.total_pnl,
        };
      }).catch(() => {
        stats.value = null;
      }),
      notificationsApi.getUnreadCount().then((r) => {
        unread.value = r.count ?? 0;
      }).catch(() => undefined),
    ]);
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'خطا در بارگذاری خانه';
  } finally {
    loading.value = false;
  }
}

onMounted(load);

function openContest(id: string) {
  router.push(`/miniapp/competitions/${id}`);
}
</script>

<template>
  <div class="home">
    <AppHeader
      :balance-label="balanceLabel"
      :unread="unread"
      @wallet="router.push('/miniapp/wallet')"
      @support="router.push('/user/tickets')"
      @notifications="router.push('/user/notifications')"
    />

    <section class="hero">
      <div class="hero-mark" aria-hidden="true">T</div>
      <div class="hero-copy">
        <h1>به ترالنت خوش آمدی{{ displayName ? '، ' + displayName : '' }}</h1>
        <p>برای شروع، یک مسابقه انتخاب کن و مهارت‌هات رو به چالش بکش.</p>
      </div>
    </section>

    <LoadingState v-if="loading" />
    <ErrorState v-else-if="error" :message="error" @retry="load" />
    <template v-else>
      <section class="balance-grid">
        <StatCard
          class="span-2"
          label="ارزش کل دارایی"
          :value="balanceLabel"
          :hint="stats ? `بردها: ${formatCount(stats.total_wins)}` : 'موجودی کیف پول'"
          accent="green"
        />
        <StatCard
          label="جوایز"
          :value="stats ? formatCount(stats.total_wins) : '—'"
          hint="تعداد برد"
          accent="gold"
          :ltr="true"
        />
        <StatCard
          label="مسابقات"
          :value="stats ? formatCount(stats.total_contests) : '—'"
          hint="شرکت‌کرده"
          accent="cyan"
          :ltr="true"
        />
      </section>

      <section class="featured-wrap">
        <SectionHeader title="مسابقه ویژه" />
        <FeaturedCompetitionCard
          v-if="featured"
          :contest="featured"
          @open="openContest"
          @join="openContest"
        />
        <EmptyState
          v-else
          title="مسابقه‌ای فعال نیست"
          description="به‌زودی مسابقات جدید اضافه می‌شود."
        />
      </section>

      <section class="suggested">
        <SectionHeader
          title="مسابقات پیشنهادی"
          action-label="همه"
          @action="router.push('/miniapp/competitions')"
        />
        <div v-if="suggested.length" class="rail">
          <CompetitionCard
            v-for="c in suggested"
            :key="c.id"
            :contest="c"
            @select="openContest"
          />
        </div>
        <EmptyState
          v-else
          title="موردی نیست"
          description="فعلاً مسابقه پیشنهادی دیگری وجود ندارد."
        />
      </section>
    </template>
  </div>
</template>

<style scoped>
.home {
  display: flex;
  flex-direction: column;
  gap: 18px;
}
.hero {
  display: flex;
  gap: 12px;
  align-items: center;
  padding: 4px 2px 2px;
}
.hero-mark {
  width: 48px;
  height: 48px;
  border-radius: 16px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 900;
  font-size: 22px;
  color: #03140c;
  background: linear-gradient(145deg, #1cf0a4, #0aa86a);
  box-shadow: 0 0 24px rgba(16, 217, 138, 0.35);
  flex-shrink: 0;
}
.hero-copy h1 {
  margin: 0 0 4px;
  font-size: 16px;
  font-weight: 800;
  line-height: 1.4;
}
.hero-copy p {
  margin: 0;
  font-size: 12px;
  color: var(--ma-text-secondary);
  line-height: 1.65;
}
.balance-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}
.span-2 {
  grid-column: 1 / -1;
}
.rail {
  display: flex;
  gap: 10px;
  overflow-x: auto;
  padding-bottom: 4px;
  scroll-snap-type: x mandatory;
  -webkit-overflow-scrolling: touch;
}
.rail > * {
  scroll-snap-align: start;
}
.rail::-webkit-scrollbar {
  display: none;
}
</style>
