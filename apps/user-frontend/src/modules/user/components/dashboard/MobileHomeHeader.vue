<script setup lang="ts">
/**
 * LEGACY alias — Wallet/Notifications/Support shortcuts moved to canonical UserNavbar.
 * Kept as a thin re-export so older imports do not break during migration.
 */
import UserNavbar from '@/modules/user/components/layout/UserNavbar.vue';
</script>

<template>
  <UserNavbar />
</template>
