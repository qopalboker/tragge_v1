<script setup lang="ts">
import { useRouter } from 'vue-router';

const router = useRouter();

const categories = [
  { key: 'forex', title: 'Forex', desc: 'مسابقات جفت‌ارزها', accent: 'cyan' },
  { key: 'crypto', title: 'Crypto', desc: 'BTC، ETH و دارایی‌های دیجیتال', accent: 'green' },
  { key: 'gold', title: 'Gold', desc: 'دارایی‌های کالایی و طلا', accent: 'gold' },
];

function open(market: string) {
  router.push({ path: '/miniapp/competitions', query: { market } });
}
</script>

<template>
  <div class="cats">
    <header>
      <h1>دسته‌بندی‌ها</h1>
      <p>بازار مورد علاقه‌ات را انتخاب کن</p>
    </header>
    <button
      v-for="c in categories"
      :key="c.key"
      type="button"
      class="cat ma-glass"
      :class="c.accent"
      @click="open(c.key === 'gold' ? 'mixed' : c.key)"
    >
      <span class="title ma-ltr-num">{{ c.title }}</span>
      <span class="desc">{{ c.desc }}</span>
    </button>
  </div>
</template>

<style scoped>
.cats {
  display: flex;
  flex-direction: column;
  gap: 12px;
}
header h1 {
  margin: 0 0 4px;
  font-size: 20px;
  font-weight: 800;
}
header p {
  margin: 0 0 6px;
  font-size: 12px;
  color: var(--ma-text-secondary);
}
.cat {
  border: 1px solid var(--ma-border);
  border-radius: var(--ma-radius-md);
  padding: 16px;
  text-align: start;
  cursor: pointer;
  font-family: inherit;
  color: var(--ma-text);
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.cat.green { border-color: rgba(16, 217, 138, 0.28); }
.cat.cyan { border-color: rgba(34, 211, 238, 0.28); }
.cat.gold { border-color: rgba(245, 197, 66, 0.28); }
.title {
  font-size: 16px;
  font-weight: 800;
}
.desc {
  font-size: 12px;
  color: var(--ma-text-secondary);
}
</style>
