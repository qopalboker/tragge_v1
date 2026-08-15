export type CompetitionUiStatus = 'hot' | 'live' | 'upcoming' | 'finished';

export function resolveCompetitionStatus(
  status?: string | null,
  startsAt?: string | null,
  participantCount?: number | null,
): CompetitionUiStatus {
  const s = (status || '').toLowerCase();
  if (s === 'running' || s === 'paused') return 'live';
  if (s === 'completed' || s === 'settling' || s === 'cancelled') return 'finished';
  if (s === 'registration_open' || s === 'scheduled') {
    // Promote high-participation open contests as HOT.
    if ((participantCount ?? 0) >= 50) return 'hot';
    if (startsAt) {
      const ms = new Date(startsAt).getTime() - Date.now();
      if (ms > 0 && ms < 60 * 60 * 1000) return 'hot';
    }
    return 'upcoming';
  }
  return 'upcoming';
}

export function statusLabelFa(status: CompetitionUiStatus): string {
  switch (status) {
    case 'hot':
      return 'HOT';
    case 'live':
      return 'LIVE';
    case 'upcoming':
      return 'به‌زودی';
    case 'finished':
      return 'پایان‌یافته';
  }
}
