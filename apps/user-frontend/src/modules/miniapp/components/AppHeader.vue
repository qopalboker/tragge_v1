<script setup lang="ts">
import WalletBadge from './WalletBadge.vue';

defineProps<{
  balanceLabel: string;
  supportPath?: string;
  notificationsPath?: string;
  unread?: number;
}>();
defineEmits<{ wallet: []; support: []; notifications: [] }>();
</script>

<template>
  <header class="ma-app-header">
    <div class="start">
      <button type="button" class="icon-btn" aria-label="پشتیبانی" @click="$emit('support')">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
          <path d="M4 12a8 8 0 0 1 16 0v4a2 2 0 0 1-2 2h-1v-5h3" />
          <path d="M4 13h3v5H6a2 2 0 0 1-2-2v-3z" />
        </svg>
        <span>پشتیبانی</span>
      </button>
      <button type="button" class="icon-btn" aria-label="اعلان‌ها" @click="$emit('notifications')">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
          <path d="M15 17h5l-1.4-1.4A2 2 0 0 1 18 14.2V11a6 6 0 1 0-12 0v3.2c0 .5-.2 1-.6 1.4L4 17h5" />
          <path d="M9.5 17a2.5 2.5 0 0 0 5 0" />
        </svg>
        <span v-if="unread && unread > 0" class="badge">{{ unread > 9 ? '9+' : unread }}</span>
      </button>
    </div>
    <WalletBadge :balance-label="balanceLabel" @click="$emit('wallet')" />
  </header>
</template>

<style scoped>
.ma-app-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  min-height: var(--ma-header-height);
  padding: 8px 0;
}
.start {
  display: flex;
  align-items: center;
  gap: 6px;
}
.icon-btn {
  position: relative;
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 7px 10px;
  border-radius: var(--ma-radius-pill);
  border: 1px solid var(--ma-border);
  background: rgba(255, 255, 255, 0.03);
  color: var(--ma-text-secondary);
  font-family: inherit;
  font-size: 11px;
  font-weight: 600;
  cursor: pointer;
}
.badge {
  position: absolute;
  top: -3px;
  left: -3px;
  min-width: 16px;
  height: 16px;
  padding: 0 4px;
  border-radius: 8px;
  background: var(--ma-danger);
  color: white;
  font-size: 10px;
  font-weight: 700;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}
</style>
