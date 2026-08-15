<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref, watch } from 'vue';

const props = defineProps<{
  targetIso?: string | null;
  large?: boolean;
  endedLabel?: string;
}>();

const now = ref(Date.now());
let timer: ReturnType<typeof setInterval> | null = null;

const remainingMs = computed(() => {
  if (!props.targetIso) return 0;
  return Math.max(0, new Date(props.targetIso).getTime() - now.value);
});

const parts = computed(() => {
  const total = Math.floor(remainingMs.value / 1000);
  const h = Math.floor(total / 3600);
  const m = Math.floor((total % 3600) / 60);
  const s = total % 60;
  return {
    h: String(h).padStart(2, '0'),
    m: String(m).padStart(2, '0'),
    s: String(s).padStart(2, '0'),
    ended: remainingMs.value <= 0,
  };
});

onMounted(() => {
  timer = setInterval(() => {
    now.value = Date.now();
  }, 1000);
});
onUnmounted(() => {
  if (timer) clearInterval(timer);
});
watch(
  () => props.targetIso,
  () => {
    now.value = Date.now();
  },
);
</script>

<template>
  <div class="ma-countdown" :class="{ large }">
    <template v-if="parts.ended">
      <span class="ended">{{ endedLabel || '۰۰:۰۰:۰۰' }}</span>
    </template>
    <template v-else>
      <span class="ma-ltr-num unit">{{ parts.h }}</span>
      <span class="sep">:</span>
      <span class="ma-ltr-num unit">{{ parts.m }}</span>
      <span class="sep">:</span>
      <span class="ma-ltr-num unit">{{ parts.s }}</span>
    </template>
  </div>
</template>

<style scoped>
.ma-countdown {
  display: inline-flex;
  align-items: baseline;
  gap: 2px;
  font-weight: 700;
  color: var(--ma-text);
  letter-spacing: 0.04em;
}
.ma-countdown.large .unit {
  font-size: 28px;
  min-width: 1.35em;
  text-align: center;
}
.unit {
  font-size: 14px;
}
.sep {
  color: var(--ma-primary);
  opacity: 0.7;
  font-size: 0.9em;
}
.ended {
  color: var(--ma-text-muted);
  font-size: 14px;
}
.large .ended {
  font-size: 22px;
}
</style>
