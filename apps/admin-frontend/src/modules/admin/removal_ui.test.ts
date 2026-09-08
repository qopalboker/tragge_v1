import { readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const source = readFileSync(new URL('./views/ContestDetailPage.vue', import.meta.url), 'utf8');

describe('LIFECYCLE-004 participant removal UI integration', () => {
  it('opens with no default reason or refund decision', () => {
    expect(source).toContain("const removeReason = ref<RemovalReason | ''>('')");
    expect(source).toContain('const removeRefund = ref<boolean | null>(null)');
    expect(source).not.toContain("data: { reason: 'OTHER' }");
  });

  it('collects policy input and delegates exact payload construction', () => {
    expect(source).toContain('value="CHEATING"');
    expect(source).toContain('value="USER_IMMEDIATE_EXIT_REQUEST"');
    expect(source).toContain('value="OTHER"');
    expect(source).toContain("removeReason === 'CHEATING'");
    expect(source).toContain("removeReason === 'OTHER'");
    expect(source).toContain('buildRemovalRequest(removeReason.value, removeRefund.value, removeAdminNote.value)');
    expect(source).toContain(':disabled="removeLoading || !removeCanSubmit"');
  });

  it('uses server state after success and exposes removal only to Super Admins', () => {
    expect(source).toContain('await Promise.all([fetchParticipants(), fetchContest(), fetchState()])');
    expect(source).not.toContain('participants.value = participants.value.filter');
    expect(source).toContain("auth.isSuperAdmin && p.lifecycle_status === 'ACTIVE'");
  });

  it('maps lifecycle-specific business errors to operator-facing copy', () => {
    expect(source).toContain("code === 'ECONOMICS_CUTOFF_ADJUSTMENT_REQUIRED'");
    expect(source).toContain("code === 'PARTICIPANT_NOT_ACTIVE'");
  });
});
