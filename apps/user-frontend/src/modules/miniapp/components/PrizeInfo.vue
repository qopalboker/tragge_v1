<script setup lang="ts">
defineProps<{
  prizePoolLabel: string;
  firstPrizeLabel?: string;
  compact?: boolean;
}>();
</script>

<template>
  <div class="prize-info" :class="{ compact }">
    <div class="block">
      <span class="label">جایزه کل</span>
      <span class="ma-ltr-num value gold">{{ prizePoolLabel }}</span>
    </div>
    <div v-if="firstPrizeLabel" class="block">
      <span class="label">جایزه نفر اول</span>
      <span class="ma-ltr-num value">{{ firstPrizeLabel }}</span>
    </div>
  </div>
</template>

<style scoped>
.prize-info {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}
.prize-info.compact {
  gap: 8px;
}
.block {
  display: flex;
  flex-direction: column;
  gap: 3px;
}
.label {
  font-size: 11px;
  color: var(--ma-text-secondary);
  font-weight: 600;
}
.value {
  font-size: 16px;
  font-weight: 800;
  color: var(--ma-text);
}
.value.gold {
  color: var(--ma-gold);
}
.compact .value {
  font-size: 14px;
}
</style>
