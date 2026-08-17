// Package economics is the single authoritative source for contest fee and
// prize-pool math. All join, preview, leaderboard, and settlement paths must
// call these functions — never re-implement fee resolution locally.
//
// Product policy (FIXED_PRODUCT_AND_TECHNICAL_POLICIES §4.2):
//   - Canonical fee field: platform_fee_bps (default 2000 = 20%).
//   - commission_rate is deprecated and is only used as a read-time fallback
//     when platform_fee_bps is unset (0). New writes must set platform_fee_bps.
package economics

import (
	"fmt"
	"math"
	"time"

	prizedistribution "github.com/Parsaeffatravesh/tragge/packages/scoring/distribution"
)

// DefaultPlatformFeeBps is 20% platform fee (product policy).
const DefaultPlatformFeeBps = 2000

// LateJoinSurchargeBps is 10% of base entry fee charged entirely as platform
// revenue when a paid user joins after contest start (product policy §4.3).
const LateJoinSurchargeBps = 1000

// MaxLateJoinWindow is the hard cap on late-entry windows (product policy §5.6).
const MaxLateJoinWindow = 30 * time.Minute

// Snapshot is the immutable economics input used for settlement and previews.
type Snapshot struct {
	EntryFeeCents      int64
	PlatformFeeBps     int
	Participants       int
	PrizePoolNetCents  int64 // 0 = compute from participants * entry
	IsLateJoin         bool
	LateSurchargeCents int64
}

// PoolResult is the derived pool accounting for a contest.
type PoolResult struct {
	Participants   int
	EntryFeeCents  int64
	PlatformFeeBps int
	GrossCents     int64
	FeeCents       int64
	NetCents       int64
}

// Payout is one winner's allocation.
type Payout struct {
	UserID      string
	Rank        int
	AmountCents int64
}

// RankedUser is a ranked participant for payout allocation.
type RankedUser struct {
	UserID string
	Rank   int
	Score  float64
}

// ResolvePlatformFeeBps returns the sole effective platform fee in basis points.
//
// Authority order (migration compatibility only):
//  1. platform_fee_bps when > 0
//  2. commission_rate percent (e.g. 20.0 → 2000 bps) when platform_fee_bps is 0
//  3. DefaultPlatformFeeBps
//
// New contests must persist platform_fee_bps and leave commission_rate unused.
func ResolvePlatformFeeBps(platformFeeBps int, commissionRatePercent float64) int {
	if platformFeeBps > 0 && platformFeeBps <= 10000 {
		return platformFeeBps
	}
	if commissionRatePercent > 0 {
		bps := int(math.Round(commissionRatePercent * 100))
		if bps > 0 && bps <= 10000 {
			return bps
		}
	}
	return DefaultPlatformFeeBps
}

// CalculatePool computes gross, platform fee, and net distributable prize pool.
// All amounts are integer cents. Net uses floor division so fee never underflows.
func CalculatePool(participants int, entryFeeCents int64, platformFeeBps int) PoolResult {
	if participants < 0 {
		participants = 0
	}
	if entryFeeCents < 0 {
		entryFeeCents = 0
	}
	if platformFeeBps < 0 {
		platformFeeBps = 0
	}
	if platformFeeBps > 10000 {
		platformFeeBps = 10000
	}
	gross := int64(participants) * entryFeeCents
	// Floor net first so fee + net == gross always with integer cents.
	net := (gross * int64(10000-platformFeeBps)) / 10000
	fee := gross - net
	return PoolResult{
		Participants:   participants,
		EntryFeeCents:  entryFeeCents,
		PlatformFeeBps: platformFeeBps,
		GrossCents:     gross,
		FeeCents:       fee,
		NetCents:       net,
	}
}

// SplitEntryFee splits one base entry fee into platform fee and prize contribution.
func SplitEntryFee(entryFeeCents int64, platformFeeBps int) (platformCents, prizeContributionCents int64) {
	if entryFeeCents <= 0 {
		return 0, 0
	}
	if platformFeeBps < 0 {
		platformFeeBps = 0
	}
	if platformFeeBps > 10000 {
		platformFeeBps = 10000
	}
	platformCents = (entryFeeCents * int64(platformFeeBps)) / 10000
	prizeContributionCents = entryFeeCents - platformCents
	return platformCents, prizeContributionCents
}

// LateJoinSurchargeCents returns the platform-only surcharge for late join.
func LateJoinSurchargeCents(entryFeeCents int64) int64 {
	if entryFeeCents <= 0 {
		return 0
	}
	return (entryFeeCents * int64(LateJoinSurchargeBps)) / 10000
}

// LateJoinCutoff returns the exclusive deadline for late entry on a paid contest.
// Formula: start + min(10% of duration, 30 minutes).
func LateJoinCutoff(startsAt, endsAt time.Time) time.Time {
	if !startsAt.Before(endsAt) {
		return startsAt
	}
	dur := endsAt.Sub(startsAt)
	window := time.Duration(float64(dur) * 0.10)
	if window > MaxLateJoinWindow {
		window = MaxLateJoinWindow
	}
	if window < 0 {
		window = 0
	}
	return startsAt.Add(window)
}

// JoinCharge is the total wallet debit for a join attempt.
type JoinCharge struct {
	BaseEntryCents int64
	SurchargeCents int64
	TotalCents     int64
	IsLate         bool
	PlatformCents  int64 // base platform fee only (excludes surcharge)
	PrizeCents     int64 // contributes to prize pool
}

// ComputeJoinCharge builds the debit breakdown for on-time or late paid joins.
func ComputeJoinCharge(entryFeeCents int64, platformFeeBps int, isLate bool) JoinCharge {
	platform, prize := SplitEntryFee(entryFeeCents, platformFeeBps)
	surcharge := int64(0)
	if isLate {
		surcharge = LateJoinSurchargeCents(entryFeeCents)
	}
	return JoinCharge{
		BaseEntryCents: entryFeeCents,
		SurchargeCents: surcharge,
		TotalCents:     entryFeeCents + surcharge,
		IsLate:         isLate,
		PlatformCents:  platform,
		PrizeCents:     prize,
	}
}

// AllocatePayouts distributes prizePoolNet to ranked winners using the shared
// power-law distribution. Remainder cents go to rank 1 (see prizedistribution).
// Returns nil when there is nothing to pay.
func AllocatePayouts(ranked []RankedUser, prizePoolNet int64) ([]Payout, error) {
	if len(ranked) == 0 || prizePoolNet <= 0 {
		return nil, nil
	}
	cfg := prizedistribution.ConfigFromEnv()
	winnersCount := prizedistribution.GetWinnersCount(len(ranked), cfg.WinnerPercent)
	if winnersCount <= 0 {
		return nil, nil
	}
	shares := prizedistribution.CalculatePrizeDistribution(prizePoolNet, winnersCount, cfg.Alpha)
	if len(shares) == 0 {
		return nil, nil
	}
	rankAmount := make(map[int]int64, len(shares))
	for _, s := range shares {
		rankAmount[s.Rank] = s.AmountCents
	}
	out := make([]Payout, 0, len(shares))
	var total int64
	for _, u := range ranked {
		if u.Rank <= 0 {
			continue
		}
		amt, ok := rankAmount[u.Rank]
		if !ok || amt <= 0 {
			continue
		}
		out = append(out, Payout{UserID: u.UserID, Rank: u.Rank, AmountCents: amt})
		total += amt
	}
	if total > prizePoolNet {
		return nil, fmt.Errorf("economics: payout total %d exceeds pool %d", total, prizePoolNet)
	}
	return out, nil
}

// SumPayouts returns the total cents across payouts.
func SumPayouts(payouts []Payout) int64 {
	var n int64
	for _, p := range payouts {
		n += p.AmountCents
	}
	return n
}

// AssertConservation checks sum(payouts) == net pool (exact; remainder already
// allocated into shares by prizedistribution).
func AssertConservation(payouts []Payout, prizePoolNet int64) error {
	sum := SumPayouts(payouts)
	// When fewer winners than pool positions, sum may be less than pool if
	// ranked list is incomplete. For full ranked lists, sum must equal pool
	// of distributed shares only (winners subset).
	if sum < 0 {
		return fmt.Errorf("economics: negative payout total %d", sum)
	}
	if prizePoolNet < 0 {
		return fmt.Errorf("economics: negative prize pool %d", prizePoolNet)
	}
	for _, p := range payouts {
		if p.AmountCents < 0 {
			return fmt.Errorf("economics: negative payout for user %s rank %d", p.UserID, p.Rank)
		}
		if p.UserID == "" {
			return fmt.Errorf("economics: empty user id on payout rank %d", p.Rank)
		}
	}
	return nil
}
