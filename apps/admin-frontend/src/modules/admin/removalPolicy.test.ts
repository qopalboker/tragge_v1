import { describe, expect, it } from 'vitest';
import { buildRemovalRequest, removalDecisionIsValid } from './removalPolicy';

describe('LIFECYCLE-004 participant removal policy', () => {
  it('has no valid default decision', () => {
    expect(removalDecisionIsValid('', null, '')).toBe(false);
    expect(() => buildRemovalRequest('', null, '')).toThrow();
  });

  it('requires an explicit cheating refund choice and preserves both choices', () => {
    expect(removalDecisionIsValid('CHEATING', null, '')).toBe(false);
    expect(buildRemovalRequest('CHEATING', true, '')).toEqual({ reason: 'CHEATING', refund: true });
    expect(buildRemovalRequest('CHEATING', false, '')).toEqual({ reason: 'CHEATING', refund: false });
  });

  it('uses the backend mandatory refund policy for immediate exit', () => {
    expect(removalDecisionIsValid('USER_IMMEDIATE_EXIT_REQUEST', null, '')).toBe(true);
    expect(buildRemovalRequest('USER_IMMEDIATE_EXIT_REQUEST', null, '')).toEqual({
      reason: 'USER_IMMEDIATE_EXIT_REQUEST',
    });
  });

  it('requires and trims an OTHER note without sending a refund override', () => {
    expect(removalDecisionIsValid('OTHER', null, '')).toBe(false);
    expect(removalDecisionIsValid('OTHER', null, '   ')).toBe(false);
    expect(buildRemovalRequest('OTHER', null, '  Account ownership concern  ')).toEqual({
      reason: 'OTHER',
      admin_note: 'Account ownership concern',
    });
  });
});

