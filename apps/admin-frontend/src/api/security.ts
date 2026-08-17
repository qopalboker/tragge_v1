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
