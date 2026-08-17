<template>
  <div class="tp-mchart">
    <!-- Symbol selector -->
    <div class="tp-mchart-sym" @click="showSymbolPicker = true">
      <SymbolFlag :symbol="selectedSymbol.symbol" :base="selectedSymbol.base" :quote="selectedSymbol.quote" />
      <div class="tp-mchart-sym-info">
        <span class="tp-mchart-sym-name">{{ selectedSymbol.symbol }}</span>
        <span class="tp-mchart-sym-price" :class="selectedSymbol.price > 0 ? (selectedSymbol.change >= 0 ? 'up' : 'down') : ''">
          {{ selectedSymbol.price > 0 ? formatPrice(selectedSymbol.price, selectedSymbol.decimals) : '—' }}
          <span class="tp-mchart-sym-chg">
            {{ selectedSymbol.change >= 0 ? '+' : '' }}{{ selectedSymbol.change.toFixed(2) }}%
          </span>
        </span>
      </div>
      <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="6 9 12 15 18 9"/>
      </svg>
    </div>

    <!-- Authoritative QTY strip (allocation / used / free) -->
    <div class="tp-mchart-qtybar" aria-label="QTY">
      <span class="tp-mchart-qitem">
        <em>{{ t('trading.totalQty') || 'کل' }}</em>
        <strong class="ma-ltr-num">{{ totalQty }}</strong>
      </span>
      <span class="tp-mchart-qitem">
        <em>{{ t('trading.usedQty') || 'مصرف‌شده' }}</em>
        <strong class="ma-ltr-num">{{ usedQty }}</strong>
      </span>
      <span class="tp-mchart-qitem free">
        <em>{{ t('trading.availableQty') || 'آزاد' }}</em>
        <strong class="ma-ltr-num">{{ availableQty }}</strong>
      </span>
    </div>

    <div v-if="!tradingEnabled && lockedReason" class="tp-mchart-lock">
      {{ lockedReason }}
    </div>

    <!-- Chart area using MarketChart -->
    <div class="tp-mchart-area">
      <MarketChart
        :symbol="selectedSymbol.symbol"
        :ticks="ticks"
        :show-position-lines="true"
        :contest-id="contestId"
      />
    </div>

    <!-- Sticky quick trade bar (safe-area aware) -->
    <div class="tp-mchart-trade" :class="{ locked: !tradingEnabled || submitting }">
      <button
        class="tp-mchart-sell"
        type="button"
        :disabled="!canTrade"
        @click="emit('trade', 'sell')"
      >
        <span class="tp-mchart-trade-l">{{ t('order.sell') }}</span>
        <span class="tp-mchart-trade-p">{{ formatPrice(selectedSymbol.bid, selectedSymbol.decimals) }}</span>
      </button>

      <div class="tp-mchart-qty">
        <button class="tp-mchart-qty-btn" type="button" :disabled="!canTrade" @click="adjustQty(-1)">−</button>
        <input
          :value="quantity"
          type="number"
          class="tp-mchart-qty-inp"
          min="1"
          :max="maxQty"
          step="1"
          :disabled="!canTrade"
          @input="onQtyInput"
        />
        <button class="tp-mchart-qty-btn" type="button" :disabled="!canTrade" @click="adjustQty(1)">+</button>
      </div>

      <button
        class="tp-mchart-buy"
        type="button"
        :disabled="!canTrade"
        @click="emit('trade', 'buy')"
      >
        <span class="tp-mchart-trade-l">{{ t('order.buy') }}</span>
        <span class="tp-mchart-trade-p">{{ formatPrice(selectedSymbol.ask, selectedSymbol.decimals) }}</span>
      </button>
    </div>

    <!-- Symbol picker modal -->
    <Teleport to="body">
      <div v-if="showSymbolPicker" class="tp-mpicker-overlay" @click="showSymbolPicker = false">
        <div class="tp-mpicker" @click.stop>
          <div class="tp-mpicker-hdr">
            <h3>{{ t('mobile.selectSymbol') }}</h3>
            <button class="tp-mpicker-close" type="button" @click="showSymbolPicker = false">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <path d="M18 6L6 18M6 6l12 12"/>
              </svg>
            </button>
          </div>

          <div class="tp-mpicker-search">
            <input
              v-model="searchQuery"
              type="text"
              :placeholder="t('watchlist.searchPlaceholder')"
            />
          </div>

          <div class="tp-mpicker-list scrollbar-thin">
            <div
              v-for="item in filteredSymbols"
              :key="item.symbol"
              class="tp-mpicker-item"
              :class="{ selected: item.symbol === selectedSymbol.symbol }"
              @click="selectSymbol(item)"
            >
              <SymbolFlag :symbol="item.symbol" :base="item.base" :quote="item.quote" />
              <div class="tp-mpicker-item-info">
                <span class="tp-mpicker-item-sym">{{ item.symbol }}</span>
                <span class="tp-mpicker-item-price">
                  {{ item.price > 0 ? formatPrice(item.price, item.decimals) : '—' }}
                </span>
              </div>
              <span class="tp-mpicker-item-chg" :class="item.change >= 0 ? 'up' : 'down'">
                {{ item.change >= 0 ? '+' : '' }}{{ item.change.toFixed(2) }}%
              </span>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { t } from '@/i18n'
import { ref, computed } from 'vue'
import SymbolFlag from '../SymbolFlag.vue'
import MarketChart from '@/components/MarketChart.vue'
import type { WatchlistItem } from '../WatchlistSidebar.vue'
import type { TickData } from '@/composables/useChartData'

const props = defineProps<{
  symbols: WatchlistItem[]
  selectedSymbol: WatchlistItem
  ticks: TickData[]
  quantity: number
  maxQty: number
  availableQty: number
  usedQty: number
  totalQty: number
  contestId: string
  submitting?: boolean
  tradingEnabled?: boolean
  lockedReason?: string
}>()

const emit = defineEmits<{
  (e: 'selectSymbol', symbol: string): void
  (e: 'trade', side: 'buy' | 'sell'): void
  (e: 'updateQuantity', qty: number): void
}>()

const showSymbolPicker = ref(false)
const searchQuery = ref('')

const canTrade = computed(
  () => (props.tradingEnabled !== false) && !props.submitting && props.maxQty > 0,
)

const filteredSymbols = computed(() => {
  if (!searchQuery.value) return props.symbols
  const query = searchQuery.value.toUpperCase()
  return props.symbols.filter(s => s.symbol.includes(query))
})

function formatPrice(price: number, decimals: number): string {
  if (!price || price <= 0) return '—'
  return price.toFixed(decimals)
}

function selectSymbol(item: WatchlistItem) {
  emit('selectSymbol', item.symbol)
  showSymbolPicker.value = false
}

function adjustQty(delta: number) {
  const next = Math.max(1, Math.min(props.maxQty, Math.floor(props.quantity) + delta))
  emit('updateQuantity', next)
}

function onQtyInput(ev: Event) {
  const raw = Number((ev.target as HTMLInputElement).value)
  const next = Math.max(1, Math.min(props.maxQty, Math.floor(raw || 1)))
  emit('updateQuantity', next)
}
</script>

<style scoped>
.tp-mchart {
  display: flex;
  flex-direction: column;
  height: 100%;
  min-height: 0;
  background: var(--tp-bg, #0f172a);
}

.tp-mchart-sym {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  border-bottom: 1px solid var(--tp-bd, #334155);
  cursor: pointer;
  flex: 0 0 auto;
}

.tp-mchart-sym-info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.tp-mchart-sym-name {
  font-weight: 700;
  font-size: 14px;
}

.tp-mchart-sym-price {
  font-size: 13px;
  font-variant-numeric: tabular-nums;
  direction: ltr;
}

.tp-mchart-sym-price.up { color: #22c55e; }
.tp-mchart-sym-price.down { color: #ef4444; }
.tp-mchart-sym-chg { font-size: 11px; opacity: 0.85; margin-inline-start: 4px; }

.tp-mchart-qtybar {
  display: flex;
  gap: 8px;
  padding: 8px 12px;
  border-bottom: 1px solid var(--tp-bd, #334155);
  flex: 0 0 auto;
}

.tp-mchart-qitem {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 6px 8px;
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.06);
}

.tp-mchart-qitem em {
  font-style: normal;
  font-size: 10px;
  color: var(--tp-t1, #94a3b8);
}

.tp-mchart-qitem strong {
  font-size: 13px;
  font-weight: 700;
}

.tp-mchart-qitem.free {
  border-color: rgba(34, 197, 94, 0.35);
  background: rgba(34, 197, 94, 0.08);
}

.tp-mchart-lock {
  margin: 0 12px 8px;
  padding: 8px 10px;
  border-radius: 10px;
  background: rgba(234, 179, 8, 0.12);
  border: 1px solid rgba(234, 179, 8, 0.35);
  color: #fbbf24;
  font-size: 12px;
  text-align: center;
  flex: 0 0 auto;
}

.tp-mchart-area {
  flex: 1 1 auto;
  min-height: 180px;
  direction: ltr;
  position: relative;
}

/* Sticky order bar — above bottom nav, respects Telegram/iOS safe area */
.tp-mchart-trade {
  flex: 0 0 auto;
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: 8px;
  align-items: stretch;
  padding: 10px 12px calc(10px + env(safe-area-inset-bottom, 0px));
  border-top: 1px solid var(--tp-bd, #334155);
  background: color-mix(in srgb, var(--tp-bg-nav, #1e293b) 92%, transparent);
  backdrop-filter: blur(8px);
  position: sticky;
  bottom: 0;
  z-index: 5;
}

.tp-mchart-trade.locked {
  opacity: 0.72;
}

.tp-mchart-sell,
.tp-mchart-buy {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  min-height: 48px;
  border: none;
  border-radius: 12px;
  color: #fff;
  font-weight: 700;
  cursor: pointer;
}

.tp-mchart-sell { background: #dc2626; }
.tp-mchart-buy { background: #16a34a; }
.tp-mchart-sell:disabled,
.tp-mchart-buy:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.tp-mchart-trade-l { font-size: 12px; text-transform: uppercase; letter-spacing: 0.04em; }
.tp-mchart-trade-p { font-size: 13px; font-variant-numeric: tabular-nums; direction: ltr; }

.tp-mchart-qty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 4px;
  min-width: 88px;
}

.tp-mchart-qty-inp {
  width: 64px;
  text-align: center;
  border-radius: 8px;
  border: 1px solid var(--tp-bd, #334155);
  background: var(--tp-bg-inp, #1e293b);
  color: var(--tp-tw, #f1f5f9);
  padding: 6px 4px;
  font-weight: 700;
}

.tp-mchart-qty-btn {
  width: 28px;
  height: 28px;
  border-radius: 8px;
  border: 1px solid var(--tp-bd, #334155);
  background: var(--tp-bg-card, #1e293b);
  color: var(--tp-tw, #f1f5f9);
  font-size: 16px;
  line-height: 1;
  cursor: pointer;
}

.tp-mchart-qty {
  display: grid;
  grid-template-columns: 28px 1fr 28px;
  grid-template-rows: auto;
  align-items: center;
  gap: 4px;
}

.tp-mchart-qty-inp { width: 100%; grid-column: 2; grid-row: 1; }
.tp-mchart-qty-btn:first-child { grid-column: 1; }
.tp-mchart-qty-btn:last-child { grid-column: 3; }

/* Symbol picker */
.tp-mpicker-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.55);
  z-index: 80;
  display: flex;
  align-items: flex-end;
}

.tp-mpicker {
  width: 100%;
  max-height: 72vh;
  background: var(--tp-bg-card, #1e293b);
  border-radius: 16px 16px 0 0;
  padding-bottom: env(safe-area-inset-bottom, 0px);
  display: flex;
  flex-direction: column;
}

.tp-mpicker-hdr {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 14px 16px;
  border-bottom: 1px solid var(--tp-bd, #334155);
}

.tp-mpicker-search { padding: 10px 16px; }
.tp-mpicker-search input {
  width: 100%;
  padding: 10px 12px;
  border-radius: 10px;
  border: 1px solid var(--tp-bd, #334155);
  background: var(--tp-bg-inp, #0f172a);
  color: var(--tp-tw, #f1f5f9);
}

.tp-mpicker-list {
  overflow: auto;
  padding: 0 8px 12px;
}

.tp-mpicker-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 12px 10px;
  border-radius: 10px;
  cursor: pointer;
}

.tp-mpicker-item.selected { background: rgba(34, 197, 94, 0.12); }
.tp-mpicker-item-info { flex: 1; display: flex; flex-direction: column; }
.tp-mpicker-item-price { direction: ltr; font-variant-numeric: tabular-nums; font-size: 12px; opacity: 0.85; }
.tp-mpicker-item-chg.up { color: #22c55e; }
.tp-mpicker-item-chg.down { color: #ef4444; }

@media (max-width: 430px) {
  .tp-mchart-area { min-height: 160px; }
}

@media (max-width: 360px) {
  .tp-mchart-trade-p { font-size: 11px; }
  .tp-mchart-qty { min-width: 72px; }
}
</style>
