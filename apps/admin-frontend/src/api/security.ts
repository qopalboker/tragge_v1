import { api } from './index';
import { reauthenticationHeaders } from './reauthentication';

export interface AdminMFAPolicy {
  admin_mfa_enabled: boolean;
  actor_enrolled: boolean;
  updated_at?: string;
  can_toggle: boolean;
  requires_enrollment_to_enable: boolean;
}

export async function getAdminMFAPolicy(): Promise<AdminMFAPolicy> {
  const res = await api.get<AdminMFAPolicy>('/api/admin/security/mfa');
  return res.data;
}

export async function setAdminMFAPolicy(enabled: boolean, grant: string): Promise<AdminMFAPolicy> {
  const res = await api.put<AdminMFAPolicy>(
    '/api/admin/security/mfa',
    { admin_mfa_enabled: enabled },
    { headers: reauthenticationHeaders(grant) },
  );
  return res.data;
}

export interface TelegramSettings {
  configured: boolean;
  source?: 'admin_db' | 'env' | 'none' | string;
  masked?: string;
  updated_at?: string;
  updated_by?: string;
}

export async function getTelegramSettings(): Promise<TelegramSettings> {
  const res = await api.get<TelegramSettings>('/api/admin/security/telegram');
  return res.data;
}

export async function setTelegramBotToken(token: string, grant: string): Promise<TelegramSettings> {
  const res = await api.put<TelegramSettings>(
    '/api/admin/security/telegram',
    { token },
    { headers: reauthenticationHeaders(grant) },
  );
  return res.data;
}

export async function clearTelegramBotToken(grant: string): Promise<TelegramSettings> {
  const res = await api.delete<TelegramSettings>('/api/admin/security/telegram', {
    headers: reauthenticationHeaders(grant),
  });
  return res.data;
}

export async function testTelegramBotToken(grant: string): Promise<{ ok: boolean; bot_user?: string }> {
  const res = await api.post<{ ok: boolean; bot_user?: string }>(
    '/api/admin/security/telegram/test',
    {},
    { headers: reauthenticationHeaders(grant) },
  );
  return res.data;
}
