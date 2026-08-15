<script setup lang="ts">
defineProps<{ title?: string; message?: string }>();
defineEmits<{ retry: [] }>();
</script>

<template>
  <div class="ma-error ma-glass">
    <h3>{{ title || 'خطا در دریافت اطلاعات' }}</h3>
    <p>{{ message || 'لطفاً دوباره تلاش کنید.' }}</p>
    <button type="button" class="ma-btn ma-btn-primary ma-retry" @click="$emit('retry')">
      تلاش مجدد
    </button>
  </div>
</template>

<style scoped>
.ma-error {
  border-radius: var(--ma-radius-md);
  padding: 22px 16px;
  text-align: center;
  border-color: rgba(255, 92, 122, 0.25);
}
h3 {
  margin: 0 0 6px;
  font-size: 15px;
  color: var(--ma-text);
}
p {
  margin: 0 0 14px;
  font-size: 12px;
  color: var(--ma-text-secondary);
  line-height: 1.55;
}
.ma-retry {
  min-height: 40px;
  padding: 0 18px;
  font-size: 13px;
}
</style>
