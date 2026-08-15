/** Currency for Mini App — always LTR-friendly ASCII $ amounts. */
export function formatUsdFromCents(cents?: number | null): string {
  const value = (cents ?? 0) / 100;
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatUsd(amount?: number | null): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount ?? 0);
}

export function formatCount(n?: number | null): string {
  return new Intl.NumberFormat('en-US').format(n ?? 0);
}

export function formatPercent(n?: number | null, digits = 2): string {
  const value = n ?? 0;
  const sign = value > 0 ? '+' : '';
  return `${sign}${value.toFixed(digits)}%`;
}

export function shortId(id?: string | null): string {
  if (!id) return '—';
  return id.replace(/-/g, '').slice(0, 8).toUpperCase();
}

export function formatDateTime(iso?: string | null): string {
  if (!iso) return '—';
  try {
    return new Intl.DateTimeFormat('fa-IR', {
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(new Date(iso));
  } catch {
    return iso;
  }
}
