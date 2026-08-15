<script setup lang="ts">
import { computed } from 'vue';
import { statusLabelFa, type CompetitionUiStatus } from '../utils/status';

const props = defineProps<{ status: CompetitionUiStatus }>();
const label = computed(() => statusLabelFa(props.status));
const cls = computed(() => `ma-chip ma-chip-${props.status}`);
</script>

<template>
  <span :class="cls">{{ label }}</span>
</template>
