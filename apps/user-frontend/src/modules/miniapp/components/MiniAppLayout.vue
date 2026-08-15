<script setup lang="ts">
import { onMounted } from 'vue';
import BottomNavigation from './BottomNavigation.vue';
import { prepareTelegramViewport } from '../telegram';
import { setLocale } from '@/i18n';
import '../styles/tokens.css';

const isStaging =
  import.meta.env.VITE_APP_ENV === 'staging' ||
  import.meta.env.MODE === 'staging' ||
  import.meta.env.VITE_STAGING === 'true';

onMounted(() => {
  setLocale('fa');
  document.documentElement.setAttribute('dir', 'rtl');
  document.documentElement.lang = 'fa';
  prepareTelegramViewport();
});
</script>

<template>
  <div class="miniapp-root">
    <div v-if="isStaging" class="staging-banner" role="status">STAGING / TEST</div>
    <div class="ma-page">
      <RouterView />
    </div>
    <BottomNavigation />
  </div>
</template>

<style scoped>
.staging-banner {
  position: sticky;
  top: 0;
  z-index: 50;
  text-align: center;
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.08em;
  padding: 4px 8px;
  background: rgba(245, 185, 66, 0.18);
  color: #f5b942;
  border-bottom: 1px solid rgba(245, 185, 66, 0.25);
}
.ma-page {
  width: 100%;
  max-width: 480px;
  margin: 0 auto;
  min-height: 100dvh;
  padding:
    calc(10px + var(--ma-safe-top))
    14px
    calc(var(--ma-nav-height) + 28px + var(--ma-safe-bottom));
}
</style>
