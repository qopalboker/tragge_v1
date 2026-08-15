<script setup lang="ts">
defineProps<{ title: string; description?: string }>();
</script>

<template>
  <div class="ma-empty ma-glass">
    <div class="ma-empty-icon">◇</div>
    <h3>{{ title }}</h3>
    <p v-if="description">{{ description }}</p>
    <slot />
  </div>
</template>

<style scoped>
.ma-empty {
  border-radius: var(--ma-radius-md);
  padding: 28px 18px;
  text-align: center;
}
.ma-empty-icon {
  font-size: 22px;
  color: var(--ma-primary);
  margin-bottom: 8px;
  opacity: 0.85;
}
h3 {
  margin: 0 0 6px;
  font-size: 15px;
  font-weight: 700;
  color: var(--ma-text);
}
p {
  margin: 0;
  font-size: 12px;
  color: var(--ma-text-secondary);
  line-height: 1.6;
}
</style>
