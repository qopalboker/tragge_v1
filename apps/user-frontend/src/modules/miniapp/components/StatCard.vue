<script setup lang="ts">
defineProps<{
  label: string;
  value: string;
  hint?: string;
  accent?: 'green' | 'gold' | 'cyan' | 'default';
  ltr?: boolean;
}>();
</script>

<template>
  <div class="ma-stat ma-glass" :class="accent || 'default'">
    <span class="label">{{ label }}</span>
    <span class="value" :class="{ 'ma-ltr-num': ltr !== false }">{{ value }}</span>
    <span v-if="hint" class="hint" :class="{ 'ma-ltr-num': ltr !== false }">{{ hint }}</span>
  </div>
</template>

<style scoped>
.ma-stat {
  border-radius: var(--ma-radius-md);
  padding: 12px 14px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  min-width: 0;
}
.label {
  font-size: 11px;
  color: var(--ma-text-secondary);
  font-weight: 600;
}
.value {
  font-size: 18px;
  font-weight: 700;
  color: var(--ma-text);
  line-height: 1.2;
}
.hint {
  font-size: 11px;
  color: var(--ma-text-muted);
}
.green .value { color: var(--ma-primary); }
.gold .value { color: var(--ma-gold); }
.cyan .value { color: var(--ma-cyan); }
</style>
