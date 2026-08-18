<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { t } from '@/i18n';
import { ticketsApi, type Ticket } from '@/modules/user/api/tickets';
import { userShellPaths } from '@/utils/userShellPaths';
import { useAuthStore } from '@/stores/auth';

const route = useRoute();
const router = useRouter();
const auth = useAuthStore();
const paths = computed(() =>
  userShellPaths(route, { telegramSession: auth.isTelegramSession }),
);
const loading = ref(true);
const tickets = ref<Ticket[]>([]);
const error = ref(false);

onMounted(async () => {
  loading.value = true;
  error.value = false;
  try {
    const res = await ticketsApi.list({ limit: 3, offset: 0 });
    tickets.value = res.tickets || [];
  } catch {
    error.value = true;
    tickets.value = [];
  } finally {
    loading.value = false;
  }
});

function openList() {
  router.push(paths.value.tickets);
}
function openNew() {
  router.push(paths.value.ticketNew);
}
function openTicket(id: string) {
  router.push(paths.value.ticket(id));
}

function statusLabel(s: string) {
  const map: Record<string, string> = {
    open: t('tickets.statusOpen') || 'باز',
    pending: t('tickets.statusPending') || 'در انتظار',
    closed: t('tickets.statusClosed') || 'بسته',
    answered: t('tickets.statusAnswered') || 'پاسخ‌داده‌شده',
  };
  return map[s] || s;
}
</script>

<template>
  <section class="sup" dir="rtl" aria-label="support">
    <div class="sup-head">
      <h2 class="sup-title">{{ t('nav.support') || 'پشتیبانی' }}</h2>
      <button type="button" class="sup-all" @click="openList">
        {{ t('dashboard.seeAll') }}
      </button>
    </div>

    <div v-if="loading" class="sup-card mvp-glass skel" />
    <div v-else-if="error" class="sup-card mvp-glass">
      <p class="sup-msg">{{ t('common.error') }}</p>
      <button type="button" class="sup-cta secondary" @click="openList">{{ t('common.retry') }}</button>
    </div>
    <div v-else-if="tickets.length === 0" class="sup-card mvp-glass">
      <div class="sup-empty-icon" aria-hidden="true">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6">
          <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
        </svg>
      </div>
      <p class="sup-msg">{{ t('tickets.noTickets') || 'هنوز تیکت پشتیبانی ندارید' }}</p>
      <button type="button" class="sup-cta" @click="openNew">
        {{ t('tickets.createFirst') || 'ایجاد تیکت پشتیبانی' }}
      </button>
    </div>
    <div v-else class="sup-card mvp-glass">
      <button
        v-for="tk in tickets.slice(0, 2)"
        :key="tk.id"
        type="button"
        class="sup-row"
        @click="openTicket(tk.id)"
      >
        <div class="sup-row-main">
          <span class="sup-row-title">{{ tk.subject || ('#' + tk.id.slice(0, 8)) }}</span>
          <span class="sup-row-status">{{ statusLabel(tk.status) }}</span>
        </div>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="rtl-flip">
          <polyline points="9 18 15 12 9 6" />
        </svg>
      </button>
      <button type="button" class="sup-cta" @click="openNew">
        {{ t('tickets.create') || 'تیکت جدید' }}
      </button>
    </div>
  </section>
</template>

<style scoped>
.sup-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 12px;
}
.sup-title {
  margin: 0;
  font-size: 16px;
  font-weight: 800;
  color: var(--mvp-text);
}
.sup-all {
  border: none;
  background: none;
  color: var(--mvp-emerald);
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
}
.sup-card {
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.sup-card.skel {
  min-height: 110px;
  animation: pulse 1.4s ease-in-out infinite;
}
.sup-empty-icon {
  width: 48px;
  height: 48px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--mvp-emerald-soft);
  color: var(--mvp-emerald);
  margin: 0 auto;
}
.sup-msg {
  margin: 0;
  text-align: center;
  color: var(--mvp-text-secondary);
  font-size: 13px;
}
.sup-cta {
  margin-top: 4px;
  border: none;
  border-radius: 999px;
  padding: 11px 16px;
  background: linear-gradient(135deg, #00e6ad, #00b386);
  color: #03140f;
  font-weight: 800;
  font-size: 13px;
  cursor: pointer;
}
.sup-cta.secondary {
  background: rgba(255, 255, 255, 0.06);
  color: var(--mvp-text);
  border: 1px solid var(--mvp-border);
}
.sup-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  width: 100%;
  text-align: start;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid rgba(255, 255, 255, 0.06);
  background: rgba(255, 255, 255, 0.03);
  color: var(--mvp-text);
  cursor: pointer;
}
.sup-row-main {
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}
.sup-row-title {
  font-size: 13px;
  font-weight: 700;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.sup-row-status {
  font-size: 11px;
  color: var(--mvp-emerald);
  font-weight: 600;
}
.rtl-flip { transform: scaleX(-1); }
@keyframes pulse {
  0%, 100% { opacity: 0.55; }
  50% { opacity: 1; }
}
</style>
