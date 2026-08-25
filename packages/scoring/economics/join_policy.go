package economics

import "time"

// Contest status strings used by join authorization (product §5.6).
const (
	JoinStatusRegistrationOpen = "registration_open"
	JoinStatusScheduled        = "scheduled"
	JoinStatusRunning          = "running"
)

// JoinAllowed implements product policy §5.6.
// Free contests: registration_open only (no late entry).
// Paid contests: registration_open, or running until LateJoinCutoff when enabled.
// Scoring for late joiners is filled-trade based (not pro-rata); they contribute
// the same base prize-pool amount as on-time joiners (§4.3).
func JoinAllowed(status string, isFree, lateJoinEnabled bool, startsAt, endsAt, now time.Time) (ok bool, isLate bool, reason string) {
	switch status {
	case JoinStatusRegistrationOpen:
		return true, false, ""
	case JoinStatusScheduled:
		return false, false, "contest_not_open"
	case JoinStatusRunning:
		if isFree {
			return false, false, "free_contest_no_late_join"
		}
		if !lateJoinEnabled {
			return false, false, "late_join_disabled"
		}
		cutoff := LateJoinCutoff(startsAt, endsAt)
		if !now.Before(cutoff) {
			return false, false, "late_join_cutoff_passed"
		}
		return true, true, ""
	default:
		return false, false, "contest_not_open"
	}
}
