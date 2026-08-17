<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { t } from '@/i18n';
import { useAuthStore } from '@/stores/auth';
import { useToast } from '@/composables/useToast';
import { getAdminMFAPolicy, setAdminMFAPolicy, type AdminMFAPolicy } from '@/api/security';
import { SensitiveAdminAction, withPasswordReauthentication } from '@/api/reauthentication';

const auth = useAuthStore();
const toast = useToast();

const loading = ref(true);
const saving = ref(false);
const policy = ref<AdminMFAPolicy | null>(null);
const error = ref<string | null>(null);

const canToggle = computed(() => policy.value?.can_toggle === true && auth.isSuperAdmin);

async function load() {
  loading.value = true;
  error.value = null;
  try {
    policy.value = await getAdminMFAPolicy();
  } catch {
    error.value = t('securitySettings.loadError') || 'Failed to load security settings';
  } finally {
    loading.value = false;
  }
}

async function toggleMFA() {
  if (!policy.value || !canToggle.value || saving.value) return;
  const next = !policy.value.admin_mfa_enabled;
  if (next && policy.value.requires_enrollment_to_enable) {
    toast.error(
      t('securitySettings.enrollmentRequired') ||
        'Complete authenticator enrollment before enabling MFA policy.',
    );
    return;
  }
  const password = window.prompt(t('securitySettings.reauthPrompt') || 'Confirm your admin password:') || '';
  if (!password) return;

  saving.value = true;
  try {
    policy.value = await withPasswordReauthentication(
      {
        password,
        action: SensitiveAdminAction.AdminMFAPolicy,
        resourceId: 'admin_mfa_policy',
      },
      (grant) => setAdminMFAPolicy(next, grant),
    );
    toast.success(
      next
        ? t('securitySettings.enabled') || 'Two-factor authentication is now required for Super Admin login.'
        : t('securitySettings.disabled') || 'Two-factor authentication is disabled for Super Admin login (MVP default).',
    );
  } catch (e: unknown) {
    const msg =
      (e as { response?: { data?: { message?: string; error?: string } } })?.response?.data?.message ||
      (e as { response?: { data?: { error?: string } } })?.response?.data?.error ||
      t('securitySettings.saveError') ||
      'Could not update MFA policy';
    toast.error(String(msg));
  } finally {
    saving.value = false;
  }
}

onMounted(load);
</script>

<template>
  <div class="security-page" dir="auto">
    <header class="page-header">
      <h1>{{ t('securitySettings.title') || 'Security' }}</h1>
      <p class="sub">
        {{ t('securitySettings.subtitle') || 'Admin panel security policy for the current MVP environment.' }}
      </p>
    </header>

    <div v-if="loading" class="card">{{ t('common.loading') || 'Loading…' }}</div>
    <div v-else-if="error" class="card error">
      <p>{{ error }}</p>
      <button type="button" class="btn" @click="load">{{ t('common.retry') || 'Retry' }}</button>
    </div>
    <section v-else class="card">
      <div class="row">
        <div class="copy">
          <h2>{{ t('securitySettings.mfaTitle') || 'Two-Factor Authentication (Admin)' }}</h2>
          <p>
            {{
              t('securitySettings.mfaDesc') ||
              'When enabled, Super Admin login requires password + authenticator code. MVP default is disabled so operators can sign in with password only. MFA implementation remains available.'
            }}
          </p>
          <p class="status">
            <span class="label">{{ t('securitySettings.current') || 'Current state' }}:</span>
            <strong :class="policy?.admin_mfa_enabled ? 'on' : 'off'">
              {{
                policy?.admin_mfa_enabled
                  ? t('securitySettings.stateOn') || 'Enabled (required on login)'
                  : t('securitySettings.stateOff') || 'Disabled (MVP default)'
              }}
            </strong>
          </p>
          <p v-if="policy?.requires_enrollment_to_enable && !policy?.admin_mfa_enabled" class="hint">
            {{
              t('securitySettings.enrollHint') ||
              'You must enroll an authenticator for this Super Admin account before enabling the global MFA policy.'
            }}
          </p>
        </div>
        <button
          type="button"
          class="btn primary"
          :disabled="!canToggle || saving"
          @click="toggleMFA"
        >
          {{
            saving
              ? t('common.loading') || '…'
              : policy?.admin_mfa_enabled
                ? t('securitySettings.disable') || 'Disable MFA'
                : t('securitySettings.enable') || 'Enable MFA'
          }}
        </button>
      </div>
    </section>
  </div>
</template>

<style scoped>
.security-page {
  padding: 24px;
  max-width: 880px;
}
.page-header h1 {
  margin: 0 0 8px;
  font-size: 1.5rem;
}
.sub {
  margin: 0 0 20px;
  color: var(--color-text-secondary, #8b95a8);
  font-size: 0.95rem;
}
.card {
  background: var(--color-surface, #121a28);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 12px;
  padding: 20px;
}
.card.error {
  border-color: rgba(239, 68, 68, 0.4);
}
.row {
  display: flex;
  gap: 20px;
  align-items: flex-start;
  justify-content: space-between;
  flex-wrap: wrap;
}
.copy {
  flex: 1;
  min-width: 240px;
}
.copy h2 {
  margin: 0 0 8px;
  font-size: 1.1rem;
}
.copy p {
  margin: 0 0 10px;
  line-height: 1.5;
  color: var(--color-text-secondary, #a0aabe);
  font-size: 0.92rem;
}
.status .label {
  margin-inline-end: 8px;
}
.status .on {
  color: #34d399;
}
.status .off {
  color: #fbbf24;
}
.hint {
  color: #fbbf24 !important;
}
.btn {
  border: 1px solid rgba(255, 255, 255, 0.15);
  background: transparent;
  color: inherit;
  border-radius: 8px;
  padding: 10px 16px;
  cursor: pointer;
  font-weight: 600;
}
.btn.primary {
  background: var(--color-primary, #3b82f6);
  border-color: transparent;
  color: #fff;
}
.btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
