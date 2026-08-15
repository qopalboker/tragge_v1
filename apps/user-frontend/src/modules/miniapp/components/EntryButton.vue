<script setup lang="ts">
defineProps<{
  label?: string;
  amountLabel: string;
  disabled?: boolean;
  loading?: boolean;
}>();
defineEmits<{ click: [] }>();
</script>

<template>
  <button
    type="button"
    class="ma-btn ma-entry-btn"
    :disabled="disabled || loading"
    @click="$emit('click')"
  >
    <span class="label">{{ loading ? 'در حال پردازش…' : (label || 'ورود به مسابقه') }}</span>
    <span class="ma-ltr-num amount">{{ amountLabel }}</span>
  </button>
</template>

<style scoped>
.ma-entry-btn {
  width: 100%;
  min-height: 54px;
  padding: 10px 18px;
  border-radius: var(--ma-radius-md);
  background: linear-gradient(135deg, #18f0a0 0%, #0bb86f 55%, #089a5d 100%);
  color: #02140b;
  box-shadow: 0 10px 28px rgba(16, 217, 138, 0.28);
  display: flex;
  flex-direction: column;
  gap: 2px;
}
.label {
  font-size: 14px;
  font-weight: 800;
}
.amount {
  font-size: 16px;
  font-weight: 800;
  opacity: 0.92;
}
</style>
