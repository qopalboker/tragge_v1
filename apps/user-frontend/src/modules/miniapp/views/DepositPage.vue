<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue';
import { useRouter } from 'vue-router';
import LoadingState from '../components/LoadingState.vue';
import ErrorState from '../components/ErrorState.vue';
import { walletApi, type CryptoDepositProvider } from '@/modules/user/api/index';
import { useWalletStore } from '@/stores/wallet';
import { formatUsdFromCents } from '../utils/format';
import { hapticSuccess } from '../telegram';

const router = useRouter();
const wallet = useWalletStore();

const MIN_USD = 4;
const PRESETS = [4, 10, 20, 50, 100];

const loading = ref(true);
const error = ref<string | null>(null);
const providers = ref<CryptoDepositProvider[]>([]);
const minCents = ref(400);
const amount = ref<number | null>(4);
const providerId = ref('');
const creating = ref(false);
const createError = ref<string | null>(null);

const paymentIntentId = ref<string | null>(null);
const paymentURL = ref<string | null>(null);
const paymentStatus = ref<string | null>(null);
const payAddress = ref<string | null>(null);
const payAmount = ref<number | null>(null);
const payCurrency = ref<string | null>(null);
let pollTimer: ReturnType<typeof setInterval> | null = null;

const amountValid = computed(
  () => amount.value !== null && amount.value >= MIN_USD && amount.value * 100 >= minCents.value,
);

const statusLabel = computed(() => {
  switch ((paymentStatus.value || '').toLowerCase()) {
    case 'pending':
      return 'ایجاد شد — در انتظار پرداخت';
    case 'processing':
      return 'در حال تأیید شبکه';
    case 'succeeded':
      return 'پرداخت موفق — موجودی به‌روز شد';
    case 'expired':
      return 'منقضی شده';
    case 'failed':
      return 'ناموفق / مغایرت';
    case 'refunded':
      return 'بازگشت وجه';
    default:
      return paymentStatus.value || '—';
  }
});

async function loadProviders() {
  loading.value = true;
  error.value = null;
  try {
    const res = await walletApi.listCryptoDepositProviders();
    providers.value = (res.providers || []).filter((p) => p.available);
    minCents.value = res.min_deposit_cents || 400;
    if (providers.value.length) {
      providerId.value = providers.value[0].id;
    }
    await wallet.fetchWallet().catch(() => undefined);
  } catch (e: unknown) {
    error.value = e instanceof Error ? e.message : 'خطا در دریافت درگاه‌ها';
  } finally {
    loading.value = false;
  }
}

async function createPayment() {
  if (!amountValid.value || !providerId.value || !amount.value) return;
  creating.value = true;
  createError.value = null;
  try {
    const cents = Math.round(amount.value * 100);
    const result = await wallet.createCryptoDeposit(cents, 'usdttrc20', providerId.value);
    if (!result) {
      createError.value = wallet.error || 'ایجاد پرداخت ناموفق بود';
      return;
    }
    paymentIntentId.value = result.payment_intent_id;
    paymentURL.value = result.payment_url || null;
    payAddress.value = result.pay_address || null;
    payAmount.value = result.pay_amount ?? null;
    payCurrency.value = result.pay_currency || null;
    paymentStatus.value = result.status || 'pending';
    startPolling();
    if (paymentURL.value) {
      window.open(paymentURL.value, '_blank');
    }
  } catch (e: unknown) {
    createError.value = e instanceof Error ? e.message : 'ایجاد پرداخت ناموفق بود';
  } finally {
    creating.value = false;
  }
}

function startPolling() {
  stopPolling();
  if (!paymentIntentId.value) return;
  pollTimer = setInterval(async () => {
    if (!paymentIntentId.value) return;
    try {
      const st = await walletApi.getCryptoDepositStatus(paymentIntentId.value);
      paymentStatus.value = st.status;
      if (st.status === 'succeeded') {
        hapticSuccess();
        await wallet.fetchWallet();
        stopPolling();
      }
      if (st.status === 'failed' || st.status === 'expired' || st.status === 'refunded') {
        stopPolling();
      }
    } catch {
      // keep polling; transient errors are expected
    }
  }, 4000);
}

function stopPolling() {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
}

onMounted(loadProviders);
onUnmounted(stopPolling);
</script>

<template>
  <div class="deposit-page">
    <header class="head">
      <button type="button" class="back" @click="router.push('/miniapp/wallet')">‹</button>
      <h1>واریز</h1>
      <span />
    </header>

    <LoadingState v-if="loading" />
    <ErrorState v-else-if="error" :message="error" @retry="loadProviders" />

    <template v-else>
      <section class="card ma-glass">
        <p class="label">موجودی فعلی</p>
        <p class="ma-ltr-num bal">{{ wallet.formattedBalance }}</p>
        <p class="hint">حداقل واریز: <span class="ma-ltr-num">{{ formatUsdFromCents(minCents) }}</span></p>
      </section>

      <section v-if="!paymentIntentId" class="card ma-glass">
        <p class="label">مبلغ (USD)</p>
        <div class="presets">
          <button
            v-for="p in PRESETS"
            :key="p"
            type="button"
            class="preset"
            :class="{ active: amount === p }"
            @click="amount = p"
          >
            ${{ p }}
          </button>
        </div>
        <input
          v-model.number="amount"
          type="number"
          min="4"
          step="1"
          class="amount-input ma-ltr-num"
          placeholder="4"
        />
        <p v-if="amount !== null && !amountValid" class="err">حداقل واریز $4 است.</p>

        <p class="label mt">درگاه پرداخت</p>
        <div v-if="!providers.length" class="err">هیچ درگاه کریپتویی پیکربندی نشده است.</div>
        <div v-else class="providers">
          <label v-for="p in providers" :key="p.id" class="provider">
            <input v-model="providerId" type="radio" :value="p.id" />
            <span>{{ p.name }}</span>
            <span v-if="p.type === 'fiat'" class="badge">Fiat</span>
            <span v-if="p.sandbox" class="badge sandbox">TEST</span>
          </label>
        </div>
        <p v-if="providers.some((p) => p.sandbox)" class="hint">
          حالت آزمایشی: پرداخت‌های sandbox واقعی نیستند.
        </p>

        <p v-if="createError" class="err">{{ createError }}</p>
        <button
          type="button"
          class="ma-btn ma-btn-primary submit"
          :disabled="!amountValid || !providerId || creating"
          @click="createPayment"
        >
          {{ creating ? 'در حال ایجاد…' : 'ایجاد فاکتور پرداخت' }}
        </button>
      </section>

      <section v-else class="card ma-glass status-card">
        <p class="label">وضعیت پرداخت</p>
        <p class="status">{{ statusLabel }}</p>
        <p class="meta ma-ltr-num">ID: {{ paymentIntentId }}</p>
        <p v-if="payCurrency" class="meta">
          مبلغ کریپتو:
          <span class="ma-ltr-num">{{ payAmount }} {{ payCurrency }}</span>
        </p>
        <p v-if="payAddress" class="meta break">
          آدرس:
          <span class="ma-ltr-num">{{ payAddress }}</span>
        </p>
        <a v-if="paymentURL" class="link" :href="paymentURL" target="_blank" rel="noopener">
          باز کردن صفحه پرداخت
        </a>
        <p class="note">
          موفقیت فقط پس از تأیید سرور و webhook معتبر ثبت می‌شود. بازگشت از درگاه به‌تنهایی کافی نیست.
        </p>
        <button
          v-if="paymentStatus === 'succeeded'"
          type="button"
          class="ma-btn ma-btn-primary submit"
          @click="router.push('/miniapp/wallet')"
        >
          بازگشت به کیف پول
        </button>
        <button
          v-else
          type="button"
          class="ma-btn ma-btn-ghost submit"
          @click="paymentIntentId = null; stopPolling()"
        >
          پرداخت جدید
        </button>
      </section>
    </template>
  </div>
</template>

<style scoped>
.deposit-page {
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
.meta { margin-top: 6px; }
.break { word-break: break-all; }
.presets {
  display: flex;
  gap: 8px;
  margin-bottom: 10px;
}
.preset {
  flex: 1;
  min-height: 40px;
  border-radius: 12px;
  border: 1px solid var(--ma-border);
  background: rgba(255,255,255,0.03);
  color: var(--ma-text);
  font-family: inherit;
  font-weight: 700;
  cursor: pointer;
}
.preset.active {
  border-color: rgba(16, 217, 138, 0.45);
  color: var(--ma-primary);
}
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
.providers {
  display: flex;
  flex-direction: column;
  gap: 8px;
  margin-bottom: 12px;
}
.provider {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 12px;
  border-radius: 12px;
  border: 1px solid var(--ma-border);
  font-size: 13px;
  font-weight: 700;
}
.badge {
  margin-inline-start: auto;
  font-size: 10px;
  font-weight: 800;
  padding: 2px 6px;
  border-radius: 6px;
  background: rgba(255,255,255,0.08);
  color: var(--ma-text-muted);
}
.badge.sandbox {
  background: rgba(255, 180, 0, 0.15);
  color: #f5b942;
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
.status {
  margin: 0 0 8px;
  font-size: 16px;
  font-weight: 800;
  color: var(--ma-text);
}
.link {
  display: inline-block;
  margin: 10px 0;
  color: var(--ma-cyan);
  font-weight: 700;
  font-size: 13px;
}
.note { margin-top: 10px; }
</style>
