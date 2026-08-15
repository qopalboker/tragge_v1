import { describe, expect, it } from 'vitest';
import { durationLabel, resolveDisplayQty } from './qty';

describe('resolveDisplayQty', () => {
  it('uses duration policy for product quantities', () => {
    expect(resolveDisplayQty('rush_30min', 999999)).toBe(5);
    expect(resolveDisplayQty('hourly', 0)).toBe(10);
    expect(resolveDisplayQty('four_hour')).toBe(10);
    expect(resolveDisplayQty('daily')).toBe(20);
    expect(resolveDisplayQty('weekly')).toBe(20);
  });

  it('never surfaces legacy scaled qty values', () => {
    expect(resolveDisplayQty(undefined, 50000)).toBe(10);
    expect(resolveDisplayQty(undefined, 100000)).toBe(10);
    expect(resolveDisplayQty(undefined, 500000)).toBe(10);
  });

  it('accepts allowed raw qty when duration missing', () => {
    expect(resolveDisplayQty(undefined, 5)).toBe(5);
    expect(resolveDisplayQty(undefined, 20)).toBe(20);
  });
});

describe('durationLabel', () => {
  it('maps duration types to compact labels', () => {
    expect(durationLabel('rush_30min')).toBe('30M');
    expect(durationLabel('hourly')).toBe('1H');
    expect(durationLabel('four_hour')).toBe('4H');
    expect(durationLabel('daily')).toBe('1D');
    expect(durationLabel('weekly')).toBe('1W');
  });
});
