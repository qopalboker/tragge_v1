export const removalReasons = [
  'CHEATING',
  'USER_IMMEDIATE_EXIT_REQUEST',
  'OTHER',
] as const;

export type RemovalReason = typeof removalReasons[number];

export interface RemovalRequest {
  reason: RemovalReason;
  refund?: boolean;
  admin_note?: string;
}

export function removalDecisionIsValid(
  reason: RemovalReason | '',
  refund: boolean | null,
  adminNote: string,
): boolean {
  if (!reason) return false;
  if (reason === 'CHEATING') return refund !== null;
  if (reason === 'OTHER') return adminNote.trim().length > 0;
  return true;
}

export function buildRemovalRequest(
  reason: RemovalReason | '',
  refund: boolean | null,
  adminNote: string,
): RemovalRequest {
  if (!removalDecisionIsValid(reason, refund, adminNote) || !reason) {
    throw new Error('Incomplete participant removal decision');
  }
  const note = adminNote.trim();
  if (reason === 'CHEATING') {
    return { reason, refund: refund as boolean, ...(note ? { admin_note: note } : {}) };
  }
  if (reason === 'OTHER') return { reason, admin_note: note };
  return { reason, ...(note ? { admin_note: note } : {}) };
}

