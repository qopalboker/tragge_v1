import type { ContestDurationType } from '@tragge/contracts/v1';
import { getDefaultQtyAllocation, isAllowedTradingQty } from '@tragge/contracts/v1';

/**
 * Display trading QTY for Mini App. Never trust raw backend qty_total when it
 * looks like a legacy scaled value (e.g. 50000). Prefer duration policy.
 */
export function resolveDisplayQty(
  durationType?: string | null,
  qtyTotal?: number | null,
): number {
  if (durationType) {
    try {
      return getDefaultQtyAllocation(durationType as ContestDurationType);
    } catch {
      // fall through
    }
  }
  if (typeof qtyTotal === 'number' && isAllowedTradingQty(qtyTotal)) {
    return qtyTotal;
  }
  // Legacy scaled values — do not display as-is.
  if (typeof qtyTotal === 'number' && qtyTotal > 100) {
    return 10;
  }
  return typeof qtyTotal === 'number' && qtyTotal > 0 ? qtyTotal : 10;
}

export function durationLabel(durationType?: string | null, durationMinutes?: number | null): string {
  switch (durationType) {
    case 'rush_30min':
      return '30M';
    case 'hourly':
      return '1H';
    case 'four_hour':
      return '4H';
    case 'daily':
      return '1D';
    case 'weekly':
      return '1W';
    default:
      break;
  }
  if (durationMinutes) {
    if (durationMinutes <= 30) return '30M';
    if (durationMinutes <= 60) return '1H';
    if (durationMinutes <= 240) return '4H';
    if (durationMinutes <= 1440) return '1D';
    return '1W';
  }
  return '—';
}

export function marketLabel(market?: string | null): string {
  switch ((market || '').toLowerCase()) {
    case 'forex':
      return 'Forex';
    case 'crypto':
      return 'Crypto';
    case 'stocks':
      return 'Stocks';
    case 'gold':
    case 'commodity':
      return 'Gold';
    default:
      return market || 'Mixed';
  }
}
