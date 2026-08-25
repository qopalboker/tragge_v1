package server

import (
	"fmt"
	"sort"

	prizedistribution "github.com/Parsaeffatravesh/tragge/packages/scoring/distribution"
	"github.com/Parsaeffatravesh/tragge/packages/scoring/economics"
)

// PayoutResult is a PREVIEW allocation for ranking/notification metadata.
// Authoritative prize amounts are produced only by settlement-service.
type PayoutResult struct {
	UserID      string `json:"user_id"`
	Rank        int    `json:"rank"`
	PayoutCents int64  `json:"payout_cents"` // preview only — not financial authority
}

// DefaultPlatformFeeBps re-exports canonical default (20% = 2000 bps).
const DefaultPlatformFeeBps = economics.DefaultPlatformFeeBps

// ResolveEffectiveFeeBps delegates to packages/scoring/economics (sole fee authority).
func ResolveEffectiveFeeBps(platformFeeBps int, commissionRate float64) int {
	return economics.ResolvePlatformFeeBps(platformFeeBps, commissionRate)
}

// CalculatePrizePoolGross calculates the gross prize pool.
func CalculatePrizePoolGross(participantsCount int, entryFeeCents int64) int64 {
	return economics.CalculatePool(participantsCount, entryFeeCents, 0).GrossCents
}

// CalculatePrizePoolNet calculates the net prize pool after platform fee deduction.
// FIN-002: delegates to economics.NetFromGross (same math as settlement).
func CalculatePrizePoolNet(prizePoolGross int64, platformFeeBps int) int64 {
	net, _ := economics.NetFromGross(prizePoolGross, platformFeeBps)
	return net
}

// CalculateWinnersCount returns tralent_v1 planned winners (FIN-004).
// winnersPercentage is ignored (signature retained for callers).
func CalculateWinnersCount(participantsCount int, winnersPercentage int) int {
	_ = winnersPercentage
	return prizedistribution.GetWinnersCount(participantsCount, 0)
}

// AllocatePayouts allocates prize payouts to winners based on their ranks
// using the unified Power Law formula from the shared prizedistribution package.
func AllocatePayouts(
	rankedUsers []LeaderboardEntry, // Must be sorted by rank ascending
	prizePoolNet int64,
	platformFeeBps int,
) ([]PayoutResult, error) {
	if len(rankedUsers) == 0 || prizePoolNet <= 0 {
		return nil, nil
	}

	participantsCount := len(rankedUsers)
	// FIN-004: tralent_v1 production path.
	shares := prizedistribution.CalculateForContest(prizePoolNet, participantsCount)
	if len(shares) == 0 {
		return nil, nil
	}
	winnersCount := len(shares)

	// Build rank → amount map
	rankAmount := make(map[int]int64, len(shares))
	for _, s := range shares {
		rankAmount[s.Rank] = s.AmountCents
	}

	// Assign payouts to users by rank
	var results []PayoutResult
	for _, user := range rankedUsers {
		if user.Rank > winnersCount {
			break
		}
		amount, ok := rankAmount[user.Rank]
		if !ok || amount <= 0 {
			continue
		}
		results = append(results, PayoutResult{
			UserID:      user.UserID,
			Rank:        user.Rank,
			PayoutCents: amount,
		})
	}

	return results, nil
}

// AllocatePayoutsFromRanking is a convenience function that takes a map of user scores
// and returns payout allocations.
func AllocatePayoutsFromRanking(
	userScores map[string]float64, // user_id -> score
	prizePoolNet int64,
	platformFeeBps int,
) ([]PayoutResult, error) {
	// Convert to sorted leaderboard entries
	entries := make([]LeaderboardEntry, 0, len(userScores))
	for userID, score := range userScores {
		entries = append(entries, LeaderboardEntry{
			UserID: userID,
			Score:  score,
		})
	}

	// Sort by score descending
	sort.Slice(entries, func(i, j int) bool {
		return entries[i].Score > entries[j].Score
	})

	// Assign ranks
	for i := range entries {
		entries[i].Rank = i + 1
	}

	return AllocatePayouts(entries, prizePoolNet, platformFeeBps)
}

// ContestPayout holds all payout information for a contest.
type ContestPayout struct {
	ContestID         string
	ParticipantsCount int
	EntryFeeCents     int64
	PlatformFeeBps    int
	PrizePoolGross    int64
	PrizePoolNet      int64
	WinnersCount      int
	Payouts           []PayoutResult
	TotalPaidOut      int64
}

// CalculateContestPayouts calculates all payouts for a contest.
func CalculateContestPayouts(
	contestID string,
	rankedUsers []LeaderboardEntry,
	entryFeeCents int64,
	platformFeeBps int,
) (*ContestPayout, error) {
	participantsCount := len(rankedUsers)
	if participantsCount == 0 {
		return &ContestPayout{
			ContestID:         contestID,
			ParticipantsCount: 0,
		}, nil
	}

	prizePoolGross := CalculatePrizePoolGross(participantsCount, entryFeeCents)
	prizePoolNet := CalculatePrizePoolNet(prizePoolGross, platformFeeBps)
	winnersCount := prizedistribution.GetWinnersCount(participantsCount, 0)

	payouts, err := AllocatePayouts(rankedUsers, prizePoolNet, platformFeeBps)
	if err != nil {
		return nil, err
	}

	var totalPaidOut int64
	for _, p := range payouts {
		totalPaidOut += p.PayoutCents
	}

	return &ContestPayout{
		ContestID:         contestID,
		ParticipantsCount: participantsCount,
		EntryFeeCents:     entryFeeCents,
		PlatformFeeBps:    platformFeeBps,
		PrizePoolGross:    prizePoolGross,
		PrizePoolNet:      prizePoolNet,
		WinnersCount:      winnersCount,
		Payouts:           payouts,
		TotalPaidOut:      totalPaidOut,
	}, nil
}

// CalculateContestPayoutsWithStoredPool calculates payouts using a pre-accumulated prize pool
// from the contests table (updated incrementally as participants join) instead of recalculating.
func CalculateContestPayoutsWithStoredPool(
	contestID string,
	rankedUsers []LeaderboardEntry,
	entryFeeCents int64,
	platformFeeBps int,
	storedPrizePoolNet int64,
) (*ContestPayout, error) {
	participantsCount := len(rankedUsers)
	if participantsCount == 0 {
		return &ContestPayout{
			ContestID:         contestID,
			ParticipantsCount: 0,
		}, nil
	}

	prizePoolGross := CalculatePrizePoolGross(participantsCount, entryFeeCents)
	winnersCount := prizedistribution.GetWinnersCount(participantsCount, 0)

	// Use the stored prize pool instead of recalculating
	payouts, err := AllocatePayouts(rankedUsers, storedPrizePoolNet, platformFeeBps)
	if err != nil {
		return nil, err
	}

	var totalPaidOut int64
	for _, p := range payouts {
		totalPaidOut += p.PayoutCents
	}

	return &ContestPayout{
		ContestID:         contestID,
		ParticipantsCount: participantsCount,
		EntryFeeCents:     entryFeeCents,
		PlatformFeeBps:    platformFeeBps,
		PrizePoolGross:    prizePoolGross,
		PrizePoolNet:      storedPrizePoolNet,
		WinnersCount:      winnersCount,
		Payouts:           payouts,
		TotalPaidOut:      totalPaidOut,
	}, nil
}

// formatMaxParticipants formats the max participants value for error messages.
func formatMaxParticipants(max *int) string {
	if max == nil {
		return "unlimited"
	}
	return fmt.Sprintf("%d", *max)
}
