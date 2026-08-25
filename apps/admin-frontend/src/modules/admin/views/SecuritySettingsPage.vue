<script setup lang="ts">
import { ref, onMounted, computed } from 'vue';
import { t } from '@/i18n';
import { useAuthStore } from '@/stores/auth';
import { useToast } from '@/composables/useToast';
import {
  getAdminMFAPolicy,
  setAdminMFAPolicy,
  getTelegramSettings,
  setTelegramBotToken,
  clearTelegramBotToken,
  testTelegramBotToken,
  type AdminMFAPolicy,
  type TelegramSettings,
} from '@/api/security';
import { SensitiveAdminAction, withPasswordReauthentication } from '@/api/reauthentication';

const auth = useAuthStore();
const toast = useToast();

const loading = ref(true);
const saving = ref(false);
const policy = ref<AdminMFAPolicy | null>(null);
const telegram = ref<TelegramSettings | null>(null);
const telegramTokenInput = ref('');
const telegramBusy = ref(false);
const error = ref<string | null>(null);

const canToggle = computed(() => policy.value?.can_toggle === true && auth.isSuperAdmin);
const canManageTelegram = computed(() => auth.isSuperAdmin && auth.hasPermission('settings.manage'));

async function load() {
  loading.value = true;
  error.value = null;
  try {
    policy.value = await getAdminMFAPolicy();
    try {
      telegram.value = await getTelegramSettings();
    } catch {
      telegram.value = { configured: false, source: 'none' };
    }
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

async function promptReauthPassword(): Promise<string> {
  return window.prompt(t('securitySettings.reauthPrompt') || 'Confirm your admin password:') || '';
}

async function saveTelegramToken() {
  if (!canManageTelegram.value || telegramBusy.value) return;
  const token = telegramTokenInput.value.trim();
  if (!token) {
    toast.error(t('securitySettings.telegramTokenRequired') || 'Bot token is required');
    return;
  }
  const password = await promptReauthPassword();
  if (!password) return;
  telegramBusy.value = true;
  try {
    telegram.value = await withPasswordReauthentication(
      {
        password,
        action: SensitiveAdminAction.TelegramBotToken,
        resourceId: 'telegram_bot_token',
      },
      (grant) => setTelegramBotToken(token, grant),
    );
    telegramTokenInput.value = '';
    toast.success(t('securitySettings.telegramSaved') || 'Telegram bot token updated');
  } catch (e: unknown) {
    const msg =
      (e as { response?: { data?: { error?: string } } })?.response?.data?.error ||
      t('securitySettings.telegramSaveError') ||
      'Could not update Telegram bot token';
    toast.error(String(msg));
  } finally {
    telegramBusy.value = false;
  }
}

async function clearTelegramToken() {
  if (!canManageTelegram.value || telegramBusy.value) return;
  const password = await promptReauthPassword();
  if (!password) return;
  telegramBusy.value = true;
  try {
    telegram.value = await withPasswordReauthentication(
      {
        password,
        action: SensitiveAdminAction.TelegramBotToken,
        resourceId: 'telegram_bot_token',
      },
      (grant) => clearTelegramBotToken(grant),
    );
    telegramTokenInput.value = '';
    toast.success(t('securitySettings.telegramCleared') || 'Telegram bot token cleared');
  } catch (e: unknown) {
    const msg =
      (e as { response?: { data?: { error?: string } } })?.response?.data?.error ||
      t('securitySettings.telegramSaveError') ||
      'Could not clear Telegram bot token';
    toast.error(String(msg));
  } finally {
    telegramBusy.value = false;
  }
}

async function testTelegramConnection() {
  if (!canManageTelegram.value || telegramBusy.value) return;
  const password = await promptReauthPassword();
  if (!password) return;
  telegramBusy.value = true;
  try {
    const result = await withPasswordReauthentication(
      {
        password,
        action: SensitiveAdminAction.TelegramBotToken,
        resourceId: 'telegram_bot_token',
      },
      (grant) => testTelegramBotToken(grant),
    );
    toast.success(
      (t('securitySettings.telegramTestOk') || 'Connected') +
        (result.bot_user ? `: @${result.bot_user}` : ''),
    );
  } catch (e: unknown) {
    const msg =
      (e as { response?: { data?: { error?: string } } })?.response?.data?.error ||
      t('securitySettings.telegramTestError') ||
      'Telegram connection test failed';
    toast.error(String(msg));
  } finally {
    telegramBusy.value = false;
  }
}

onMounted(load);
</script>

<template>
  <div class="security-page" dir="auto">
    <header class="page-header">
      <h1>{{ t('securitySettings.title') || 'System Security' }}</h1>
      <p class="sub">
        {{
          t('securitySettings.subtitle') ||
          'Protected system settings: Admin MFA policy and Telegram Mini App credentials.'
        }}
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

    <section v-if="!loading && !error" class="card telegram-card">
      <div class="copy">
        <h2>{{ t('securitySettings.telegramTitle') || 'Telegram Mini App' }}</h2>
        <p>
          {{
            t('securitySettings.telegramDesc') ||
            'Bot token is required to verify Telegram.WebApp initData (HMAC). Stored encrypted. Raw token is never returned by the API.'
          }}
        </p>
        <p class="status">
          <span class="label">{{ t('securitySettings.current') || 'Current state' }}:</span>
          <strong :class="telegram?.configured ? 'on' : 'off'">
            {{
              telegram?.configured
                ? (t('securitySettings.telegramConfigured') || 'Configured') +
                  (telegram?.masked ? ` (${telegram.masked})` : '') +
                  (telegram?.source ? ` · ${telegram.source}` : '')
                : t('securitySettings.telegramMissing') || 'Not configured (auth returns 503)'
            }}
          </strong>
        </p>
        <div v-if="canManageTelegram" class="telegram-form">
          <label class="token-label" for="tg-bot-token">
            {{ t('securitySettings.telegramTokenLabel') || 'Bot token' }}
          </label>
          <input
            id="tg-bot-token"
            v-model="telegramTokenInput"
            class="token-input"
            type="password"
            autocomplete="new-password"
            :placeholder="t('securitySettings.telegramTokenPlaceholder') || '123456:ABC…'"
          />
          <div class="telegram-actions">
            <button type="button" class="btn primary" :disabled="telegramBusy" @click="saveTelegramToken">
              {{ telegramBusy ? '…' : t('securitySettings.telegramSave') || 'Save / rotate token' }}
            </button>
            <button type="button" class="btn" :disabled="telegramBusy" @click="testTelegramConnection">
              {{ t('securitySettings.telegramTest') || 'Test connection' }}
            </button>
            <button
              type="button"
              class="btn danger"
              :disabled="telegramBusy || !telegram?.configured"
              @click="clearTelegramToken"
            >
              {{ t('securitySettings.telegramClear') || 'Clear' }}
            </button>
          </div>
        </div>
        <p v-else class="hint">
          {{ t('securitySettings.telegramSuperAdminOnly') || 'Only Super Admin with settings.manage can change the token.' }}
        </p>
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
.telegram-card {
  margin-top: 16px;
}
.telegram-form {
  margin-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.token-label {
  font-size: 0.85rem;
  color: var(--color-text-secondary, #a0aabe);
}
.token-input {
  width: min(100%, 420px);
  padding: 10px 12px;
  border-radius: 8px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(0, 0, 0, 0.25);
  color: inherit;
}
.telegram-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}
.btn.danger {
  border-color: rgba(239, 68, 68, 0.45);
  color: #fca5a5;
}
.hint {
  margin-top: 8px;
  font-size: 0.85rem;
  color: var(--color-text-secondary, #8b95a8);
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
