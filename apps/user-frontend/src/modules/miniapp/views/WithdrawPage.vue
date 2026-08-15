<script setup lang="ts">
import { computed, onMounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import LoadingState from '../components/LoadingState.vue';
import ErrorState from '../components/ErrorState.vue';
import { walletApi, type UserWithdrawalItem } from '@/modules/user/api/index';
import { useWalletStore } from '@/stores/wallet';
import { formatUsdFromCents } from '../utils/format';
import { hapticSuccess } from '../telegram';

const router = useRouter();
const wallet = useWalletStore();

const MIN_USD = 10;
const TRC20_REGEX = /^T[1-9A-HJ-NP-Za-km-z]{33}$/;
const NETWORK = 'TRC20';
const CURRENCY = 'USDT';

type Step = 'form' | 'review' | 'done';

const loading = ref(true);
const error = ref<string | null>(null);
const step = ref<Step>('form');
const amount = ref<number | null>(null);
const address = ref('');
const addressTouched = ref(false);
const submitting = ref(false);
const submitError = ref<string | null>(null);
const lastPayoutId = ref<string | null>(null);
const lastStatus = ref<string | null>(null);
const history = ref<UserWithdrawalItem[]>([]);

const amountValid = computed(() => {
  if (amount.value === null || amount.value < MIN_USD) return false;
  const cents = Math.round(amount.value * 100);
  return cents <= wallet.balanceCents;
});

const addressValid = computed(() => TRC20_REGEX.test(address.value.trim()));

const afterBalance = computed(() => {
  if (amount.value === null) return wallet.balanceCents;
  return Math.max(0, wallet.balanceCents - Math.round(amount.value * 100));
});

function statusLabel(status: string, userFacing?: string): string {
  const key = (userFacing || status || '').toLowerCase();
  switch (key) {
    case 'pending':
    case 'pending_review':
      return 'در انتظار بررسی';
    case 'processing':
      return 'در حال پردازش (پرداخت دستی ادمین)';
    case 'succeeded':
    case 'paid':
    case 'completed':
      return 'پرداخت ثبت‌شده';
    case 'rejected':
    case 'failed':
    case 'cancelled':
      return 'رد شده';
    default:
      return status || '—';
  }
}

async function load() {
  loading.value = true;
  error.value = null;
  try {
    await wallet.fetchWallet();
    const res = await walletApi.listWithdrawals({ limit: 30 });
    history.value = res.withdrawals || [];
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'خطا در دریافت اطلاعات برداشت';
  } finally {
    loading.value = false;
  }
}

function goReview() {
  submitError.value = null;
  addressTouched.value = true;
  if (!amountValid.value || !addressValid.value) return;
  step.value = 'review';
}

async function confirmWithdraw() {
  if (!amountValid.value || !addressValid.value || amount.value === null) return;
  submitting.value = true;
  submitError.value = null;
  try {
    const cents = Math.round(amount.value * 100);
    const result = await wallet.requestWithdraw({
      amount_cents: cents,
      destination_type: 'crypto',
      crypto_details: {
        address: address.value.trim(),
        network: NETWORK,
        currency: CURRENCY,
      },
    });
    if (!result) {
      submitError.value = wallet.error || 'ثبت درخواست ناموفق بود';
      return;
    }
    lastPayoutId.value = result.payout_id;
    lastStatus.value = result.user_facing_status || result.status || 'pending';
    hapticSuccess();
    step.value = 'done';
    await load();
  } catch (e: unknown) {
    submitError.value = e instanceof Error ? e.message : 'ثبت درخواست ناموفق بود';
  } finally {
    submitting.value = false;
  }
}

function resetForm() {
  step.value = 'form';
  amount.value = null;
  address.value = '';
  addressTouched.value = false;
  lastPayoutId.value = null;
  lastStatus.value = null;
  submitError.value = null;
}

onMounted(load);
</script>

<template>
  <div class="withdraw-page">
    <header class="head">
      <button type="button" class="back" @click="router.push('/miniapp/wallet')">‹</button>
      <h1>برداشت</h1>
      <span />
    </header>

    <LoadingState v-if="loading" />
    <ErrorState v-else-if="error" :message="error" @retry="load" />

    <template v-else>
      <section class="card ma-glass">
        <p class="label">موجودی قابل برداشت</p>
        <p class="ma-ltr-num bal">{{ wallet.formattedBalance }}</p>
        <p class="hint">حداقل برداشت: <span class="ma-ltr-num">${{ MIN_USD }}</span> · شبکه: USDT TRC20</p>
        <p class="hint">پرداخت کریپتو به‌صورت دستی توسط ادمین انجام می‌شود (بدون ارسال خودکار).</p>
      </section>

      <section v-if="step === 'form'" class="card ma-glass">
        <p class="label">مبلغ (USD)</p>
        <input
          v-model.number="amount"
          type="number"
          min="10"
          step="1"
          class="amount-input ma-ltr-num"
          placeholder="10"
        />
        <p v-if="amount !== null && !amountValid" class="err">
          مبلغ نامعتبر است (حداقل $10 و حداکثر موجودی).
        </p>

        <p class="label mt">آدرس کیف پول USDT TRC20</p>
        <input
          v-model="address"
          type="text"
          class="amount-input ma-ltr-num"
          dir="ltr"
          placeholder="T..."
          autocomplete="off"
          spellcheck="false"
          @blur="addressTouched = true"
        />
        <p v-if="addressTouched && !addressValid" class="err">آدرس TRC20 نامعتبر است.</p>

        <p v-if="submitError" class="err">{{ submitError }}</p>
        <button
          type="button"
          class="ma-btn ma-btn-primary submit"
          :disabled="!amountValid || !addressValid"
          @click="goReview"
        >
          بررسی و ادامه
        </button>
      </section>

      <section v-else-if="step === 'review'" class="card ma-glass">
        <p class="label">تأیید برداشت</p>
        <div class="review-row">
          <span>مبلغ</span>
          <span class="ma-ltr-num">${{ amount }}</span>
        </div>
        <div class="review-row">
          <span>شبکه</span>
          <span class="ma-ltr-num">{{ CURRENCY }} {{ NETWORK }}</span>
        </div>
        <div class="review-row col">
          <span>مقصد</span>
          <span class="ma-ltr-num break">{{ address.trim() }}</span>
        </div>
        <div class="review-row">
          <span>موجودی پس از ثبت</span>
          <span class="ma-ltr-num">{{ formatUsdFromCents(afterBalance) }}</span>
        </div>
        <p class="note">
          پس از تأیید، مبلغ از موجودی قابل استفاده کسر و تا بررسی ادمین نگه داشته می‌شود.
          موفقیت پرداخت فقط پس از ثبت دستی تراکنش توسط ادمین نمایش داده می‌شود.
        </p>
        <p v-if="submitError" class="err">{{ submitError }}</p>
        <button
          type="button"
          class="ma-btn ma-btn-primary submit"
          :disabled="submitting"
          @click="confirmWithdraw"
        >
          {{ submitting ? 'در حال ثبت…' : 'تأیید و ثبت برداشت' }}
        </button>
        <button type="button" class="ma-btn ma-btn-ghost submit" :disabled="submitting" @click="step = 'form'">
          بازگشت
        </button>
      </section>

      <section v-else class="card ma-glass">
        <p class="label">درخواست ثبت شد</p>
        <p class="status">{{ statusLabel(lastStatus || 'pending') }}</p>
        <p class="meta ma-ltr-num">ID: {{ lastPayoutId }}</p>
        <p class="note">وضعیت از سرور به‌روز می‌شود. بازگشت از این صفحه به‌معنای پرداخت نیست.</p>
        <button type="button" class="ma-btn ma-btn-primary submit" @click="resetForm">برداشت جدید</button>
        <button type="button" class="ma-btn ma-btn-ghost submit" @click="router.push('/miniapp/wallet')">
          بازگشت به کیف پول
        </button>
      </section>

      <section class="card ma-glass">
        <p class="label">تاریخچه برداشت‌ها</p>
        <p v-if="!history.length" class="hint">برداشتی ثبت نشده است.</p>
        <ul v-else class="hist">
          <li v-for="w in history" :key="w.payout_id" class="hist-item">
            <div class="hist-main">
              <span class="ma-ltr-num">{{ formatUsdFromCents(w.amount_cents) }}</span>
              <span>{{ statusLabel(w.status, w.user_facing_status) }}</span>
            </div>
            <p class="meta">{{ w.created_at }}</p>
            <p v-if="w.wallet_address" class="meta break ma-ltr-num">{{ w.wallet_address }}</p>
            <p v-if="w.admin_note" class="note">یادداشت ادمین: {{ w.admin_note }}</p>
            <p v-if="w.transaction_id" class="meta ma-ltr-num">
              مرجع پرداخت (ثبت‌شده، نه تأیید زنجیره): {{ w.transaction_id }}
            </p>
          </li>
        </ul>
      </section>
    </template>
  </div>
</template>

<style scoped>
.withdraw-page {
  display: flex;
  flex-direction: column;
  gap: 14px;
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
.card {
  border-radius: var(--ma-radius-md);
  padding: 16px;
}
.label {
  margin: 0 0 8px;
  font-size: 12px;
  color: var(--ma-text-secondary);
  font-weight: 700;
}
.mt { margin-top: 14px; }
.bal {
  margin: 0 0 6px;
  font-size: 28px;
  font-weight: 800;
  color: var(--ma-primary);
}
.hint, .meta, .note {
  margin: 0;
  font-size: 11px;
  color: var(--ma-text-muted);
  line-height: 1.5;
}
.meta { margin-top: 4px; }
.note { margin-top: 10px; }
.break { word-break: break-all; }
.amount-input {
  width: 100%;
  min-height: 46px;
  border-radius: 12px;
  border: 1px solid var(--ma-border);
  background: rgba(0,0,0,0.25);
  color: var(--ma-text);
  padding: 0 12px;
  font-size: 16px;
  font-weight: 700;
}
.submit {
  width: 100%;
  min-height: 48px;
  margin-top: 8px;
  font-size: 14px;
}
.err {
  color: var(--ma-danger);
  font-size: 12px;
  margin: 8px 0 0;
}
.review-row {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  margin: 8px 0;
  font-size: 13px;
  font-weight: 700;
}
.review-row.col {
  flex-direction: column;
  align-items: flex-start;
}
.status {
  margin: 0 0 8px;
  font-size: 16px;
  font-weight: 800;
}
.hist {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.hist-item {
  border: 1px solid var(--ma-border);
  border-radius: 12px;
  padding: 10px 12px;
}
.hist-main {
  display: flex;
  justify-content: space-between;
  font-weight: 800;
  font-size: 13px;
}
</style>
