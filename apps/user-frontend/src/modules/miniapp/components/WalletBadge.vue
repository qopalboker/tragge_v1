<script setup lang="ts">
defineProps<{ balanceLabel: string }>();
defineEmits<{ click: [] }>();
</script>

<template>
  <button type="button" class="wallet-badge" @click="$emit('click')">
    <span class="ma-ltr-num amount">{{ balanceLabel }}</span>
    <span class="plus" aria-hidden="true">+</span>
  </button>
</template>

<style scoped>
.wallet-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 7px 10px 7px 12px;
  border-radius: var(--ma-radius-pill);
  border: 1px solid rgba(16, 217, 138, 0.35);
  background: linear-gradient(135deg, rgba(16, 217, 138, 0.18), rgba(10, 20, 40, 0.6));
  color: var(--ma-text);
  font-family: inherit;
  cursor: pointer;
  box-shadow: 0 0 16px rgba(16, 217, 138, 0.12);
}
.amount {
  font-size: 13px;
  font-weight: 700;
}
.plus {
  width: 18px;
  height: 18px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: var(--ma-primary);
  color: #03140c;
  font-size: 14px;
  font-weight: 800;
  line-height: 1;
}
</style>
