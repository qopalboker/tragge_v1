<script setup lang="ts">
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { hapticLight } from '../telegram';

const route = useRoute();
const router = useRouter();

const items = computed(() => [
  { key: 'home', path: '/miniapp/home', label: 'خانه', icon: 'home' },
  { key: 'competitions', path: '/miniapp/competitions', label: 'مسابقات', icon: 'cup' },
  { key: 'leaderboard', path: '/miniapp/leaderboard', label: 'رتبه‌بندی', icon: 'rank' },
  { key: 'categories', path: '/miniapp/categories', label: 'دسته‌ها', icon: 'grid' },
  { key: 'profile', path: '/miniapp/profile', label: 'پروفایل', icon: 'user' },
]);

function isActive(path: string): boolean {
  return route.path === path || route.path.startsWith(path + '/');
}

function go(path: string) {
  hapticLight();
  router.push(path);
}
</script>

<template>
  <nav class="ma-bottom-nav" aria-label="ناوبری اصلی">
    <div class="nav-shell ma-glass">
      <button
        v-for="item in items"
        :key="item.key"
        type="button"
        class="nav-item"
        :class="{ active: isActive(item.path) }"
        @click="go(item.path)"
      >
        <span class="icon" aria-hidden="true">
          <template v-if="item.icon === 'home'">⌂</template>
          <template v-else-if="item.icon === 'cup'">◆</template>
          <template v-else-if="item.icon === 'rank'">☰</template>
          <template v-else-if="item.icon === 'grid'">▦</template>
          <template v-else>●</template>
        </span>
        <span class="label">{{ item.label }}</span>
      </button>
    </div>
  </nav>
</template>

<style scoped>
.ma-bottom-nav {
  position: fixed;
  left: 0;
  right: 0;
  bottom: 0;
  z-index: 40;
  padding: 0 12px calc(10px + var(--ma-safe-bottom));
  pointer-events: none;
}
.nav-shell {
  pointer-events: auto;
  display: flex;
  align-items: stretch;
  justify-content: space-between;
  min-height: var(--ma-nav-height);
  border-radius: 22px;
  padding: 6px 4px;
  background: rgba(8, 16, 32, 0.92);
  border: 1px solid rgba(120, 160, 220, 0.14);
  box-shadow: 0 12px 36px rgba(0, 0, 0, 0.45);
}
.nav-item {
  flex: 1;
  border: none;
  background: transparent;
  color: var(--ma-text-muted);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  font-family: inherit;
  cursor: pointer;
  padding: 6px 2px;
  border-radius: 16px;
  transition: color 0.15s ease, background 0.15s ease, box-shadow 0.15s ease;
}
.nav-item.active {
  color: var(--ma-primary);
  background: rgba(16, 217, 138, 0.08);
  box-shadow: inset 0 0 0 1px rgba(16, 217, 138, 0.12);
}
.icon {
  font-size: 15px;
  line-height: 1;
}
.label {
  font-size: 10px;
  font-weight: 700;
}
</style>
