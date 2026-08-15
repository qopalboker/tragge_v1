<script setup lang="ts">
defineProps<{ label?: string }>();
</script>

<template>
  <div class="ma-loading" role="status" aria-live="polite">
    <div class="ma-spinner" />
    <p>{{ label || 'در حال بارگذاری…' }}</p>
  </div>
</template>

<style scoped>
.ma-loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  padding: 40px 16px;
  color: var(--ma-text-secondary);
  font-size: 13px;
}
.ma-spinner {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  border: 2px solid rgba(16, 217, 138, 0.2);
  border-top-color: var(--ma-primary);
  animation: spin 0.8s linear infinite;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>
