<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import LoadingState from '../components/LoadingState.vue';
import ErrorState from '../components/ErrorState.vue';
import EmptyState from '../components/EmptyState.vue';
import DepositModal from '@/modules/user/components/wallet/DepositModal.vue';
import WithdrawModal from '@/modules/user/components/wallet/WithdrawModal.vue';
import { useWalletStore } from '@/stores/wallet';
import { formatUsdFromCents } from '../utils/format';

const router = useRouter();
const wallet = useWalletStore();
const loading = ref(true);
const error = ref<string | null>(null);

const history = computed(() => wallet.transactions.slice(0, 30));

async function load() {
  loading.value = true;
  error.value = null;
  try {
    await wallet.fetchWallet();
    await wallet.fetchHistory({ limit: 30 });
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'خطا در دریافت کیف پول';
  } finally {
    loading.value = false;
  }
}

onMounted(load);

function statusFa(status?: string | null): string {
  switch ((status || '').toLowerCase()) {
    case 'pending':
    case 'pending_review':
    case 'processing':
      return 'در انتظار بررسی';
    case 'succeeded':
    case 'paid':
    case 'completed':
      return 'پرداخت‌شده';
    case 'rejected':
    case 'failed':
      return 'رد شده';
    default:
      return status || '—';
  }
}
</script>

<template>
  <div class="wallet-page">
    <header class="head">
      <button type="button" class="back" @click="router.back()">‹</button>
      <h1>کیف پول</h1>
      <span />
    </header>

    <LoadingState v-if="loading" />
    <ErrorState v-else-if="error" :message="error" @retry="load" />
    <template v-else>
      <section class="balance ma-glass">
        <span class="label">موجودی قابل استفاده</span>
        <span class="ma-ltr-num amount">{{ wallet.formattedBalance }}</span>
        <div class="actions">
          <button type="button" class="ma-btn ma-btn-primary" @click="router.push('/miniapp/deposit')">
            واریز
          </button>
          <button type="button" class="ma-btn ma-btn-ghost" @click="router.push('/miniapp/withdraw')">
            برداشت
          </button>
        </div>
        <p class="hint">حداقل واریز: <span class="ma-ltr-num">$4.00</span></p>
      </section>

      <section>
        <h2>تاریخچه</h2>
        <EmptyState
          v-if="!history.length"
          title="تراکنشی نیست"
          description="پس از واریز یا برداشت، تاریخچه اینجا نمایش داده می‌شود."
        />
        <ul v-else class="tx-list">
          <li v-for="tx in history" :key="tx.id" class="tx ma-glass">
            <div class="tx-main">
              <span class="type">{{ tx.type }}</span>
              <span
                class="ma-ltr-num amt"
                :class="{ pos: (tx.amount_cents ?? 0) > 0, neg: (tx.amount_cents ?? 0) < 0 }"
              >
                {{ formatUsdFromCents(tx.amount_cents) }}
              </span>
            </div>
            <div class="tx-sub">
              <span>{{ statusFa(tx.status) }}</span>
              <span v-if="tx.admin_comment" class="note">یادداشت: {{ tx.admin_comment }}</span>
            </div>
          </li>
        </ul>
      </section>
    </template>

    <DepositModal
      :show="wallet.showDepositModal"
      @update:show="(v) => (wallet.showDepositModal = v)"
    />
    <WithdrawModal
      :show="wallet.showWithdrawModal"
      @update:show="(v) => (wallet.showWithdrawModal = v)"
    />
  </div>
</template>

<style scoped>
.wallet-page {
  display: flex;
  flex-direction: column;
  gap: 16px;
}
.head {
  display: grid;
  grid-template-columns: 40px 1fr 40px;
  align-items: center;
}
.head h1 {
  margin: 0;
  text-align: center;
  font-size: 18px;
  font-weight: 800;
}
.back {
  border: none;
  background: transparent;
  color: var(--ma-text-secondary);
  font-size: 22px;
  cursor: pointer;
}
.balance {
  border-radius: var(--ma-radius-lg);
  padding: 18px 16px;
  text-align: center;
  border-color: rgba(16, 217, 138, 0.22);
}
.label {
  display: block;
  font-size: 12px;
  color: var(--ma-text-secondary);
  margin-bottom: 6px;
}
.amount {
  display: block;
  font-size: 30px;
  font-weight: 800;
  color: var(--ma-primary);
  margin-bottom: 14px;
}
.actions {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
.actions .ma-btn {
  min-height: 44px;
  font-size: 13px;
}
.hint {
  margin: 12px 0 0;
  font-size: 11px;
  color: var(--ma-text-muted);
}
h2 {
  margin: 0 0 10px;
  font-size: 14px;
  font-weight: 800;
}
.tx-list {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 8px;
}
.tx {
  border-radius: var(--ma-radius-sm);
  padding: 12px;
}
.tx-main {
  display: flex;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 4px;
}
.type {
  font-size: 12px;
  font-weight: 700;
  color: var(--ma-text);
}
.amt {
  font-size: 13px;
  font-weight: 800;
}
.amt.pos { color: var(--ma-primary); }
.amt.neg { color: var(--ma-danger); }
.tx-sub {
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 11px;
  color: var(--ma-text-muted);
}
.note {
  color: var(--ma-warning);
}
</style>
