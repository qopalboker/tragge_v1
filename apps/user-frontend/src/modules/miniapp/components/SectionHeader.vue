<script setup lang="ts">
defineProps<{ title: string; actionLabel?: string }>();
defineEmits<{ action: [] }>();
</script>

<template>
  <div class="ma-section-header">
    <h2>{{ title }}</h2>
    <button
      v-if="actionLabel"
      type="button"
      class="ma-section-action"
      @click="$emit('action')"
    >
      {{ actionLabel }}
    </button>
  </div>
</template>

<style scoped>
.ma-section-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 12px;
}
h2 {
  margin: 0;
  font-size: 15px;
  font-weight: 700;
  color: var(--ma-text);
}
.ma-section-action {
  border: none;
  background: transparent;
  color: var(--ma-primary);
  font-family: inherit;
  font-size: 12px;
  font-weight: 700;
  cursor: pointer;
  padding: 4px 0;
}
</style>
