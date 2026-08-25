package prizedistribution

import (
	"math"
)

// TralentV1 is the policy algorithm from FIXED_PRODUCT_AND_TECHNICAL_POLICIES §11.
// Canonical config: distribution_version=tralent_v1, winner_ratio=0.30,
// decay_factor=0.80, rounding=half_up.

const (
	TralentV1DecayFactor   = 0.80
	TralentV1WinnerRatio   = 0.30
	TralentV1Version       = "tralent_v1"
)

// Rank bands from policy §11.2 (upper boundaries used for planned_winners snap).
var tralentV1RankBands = [][2]int{
	{1, 1}, {2, 2}, {3, 3}, {4, 4}, {5, 5}, {6, 6}, {7, 7}, {8, 8}, {9, 9}, {10, 10},
	{11, 15}, {16, 20}, {21, 25}, {26, 30}, {31, 35}, {36, 40}, {41, 50}, {51, 60},
	{61, 75}, {76, 100}, {101, 125}, {126, 150}, {151, 175}, {176, 200}, {201, 225},
	{226, 250}, {251, 275}, {276, 300}, {301, 375}, {376, 450}, {451, 525}, {526, 600},
	{601, 750}, {751, 900}, {901, 1050}, {1051, 1200}, {1201, 1500}, {1501, 1800},
	{1801, 2100}, {2101, 2400}, {2401, 3000},
}

// TralentV1PlannedWinners returns planned winner count for real registered participants.
func TralentV1PlannedWinners(participants int) int {
	if participants < 2 {
		return 0
	}
	if participants <= 3 {
		return 1
	}
	if participants <= 6 {
		return 2
	}
	if participants <= 11 {
		return 3
	}
	// raw_winners = floor(participants × 0.30 + 0.5)  (half-up)
	raw := int(math.Floor(float64(participants)*TralentV1WinnerRatio + 0.5))
	if raw < 1 {
		raw = 1
	}
	return tralentV1SnapToBandUpper(raw)
}

func tralentV1SnapToBandUpper(raw int) int {
	for _, b := range tralentV1RankBands {
		if raw >= b[0] && raw <= b[1] {
			return b[1]
		}
	}
	// Beyond last band: use raw capped sensibly
	last := tralentV1RankBands[len(tralentV1RankBands)-1][1]
	if raw > last {
		return raw
	}
	return raw
}

// TralentV1SmallContestPercents returns explicit fixture shares for <12 participants.
// Returns nil if participants >= 12 (use geometric buckets instead).
func TralentV1SmallContestPercents(participants int) []float64 {
	switch {
	case participants >= 2 && participants <= 3:
		return []float64{100}
	case participants == 4:
		return []float64{80, 20}
	case participants == 5:
		return []float64{75, 25}
	case participants == 6:
		return []float64{70, 30}
	case participants == 7:
		return []float64{65, 25, 10}
	case participants == 8:
		return []float64{60, 25, 15}
	case participants == 9:
		return []float64{55, 30, 15}
	case participants == 10 || participants == 11:
		return []float64{50, 30, 20}
	default:
		return nil
	}
}

// TralentV1ActiveBuckets returns the list of prize buckets for plannedWinners.
// Ranks 1–10 are individual buckets; higher ranks use policy bands wholly contained
// in 1..plannedWinners (band upper <= plannedWinners, or partial last band).
func TralentV1ActiveBuckets(plannedWinners int) [][2]int {
	if plannedWinners <= 0 {
		return nil
	}
	var out [][2]int
	for rank := 1; rank <= plannedWinners && rank <= 10; rank++ {
		out = append(out, [2]int{rank, rank})
	}
	if plannedWinners <= 10 {
		return out
	}
	for _, b := range tralentV1RankBands {
		if b[1] <= 10 {
			continue
		}
		if b[0] > plannedWinners {
			break
		}
		lo, hi := b[0], b[1]
		if lo < 11 {
			lo = 11
		}
		if hi > plannedWinners {
			hi = plannedWinners
		}
		if lo <= hi {
			out = append(out, [2]int{lo, hi})
		}
	}
	return out
}

// TralentV1CalculatePrizeDistribution allocates prizePoolCents for the given
// participant count using policy §11 (small fixtures or geometric buckets).
// actualWinners defaults to planned when eligibleCount <= 0.
func TralentV1CalculatePrizeDistribution(prizePoolCents int64, participants, eligibleCount int) []PrizeShare {
	if prizePoolCents <= 0 || participants < 2 {
		return nil
	}
	planned := TralentV1PlannedWinners(participants)
	if planned <= 0 {
		return nil
	}
	actual := planned
	if eligibleCount > 0 && eligibleCount < planned {
		actual = eligibleCount
	}
	if actual <= 0 {
		return nil
	}

	if pcts := TralentV1SmallContestPercents(participants); pcts != nil {
		n := actual
		if n > len(pcts) {
			n = len(pcts)
		}
		// Renormalize first n shares to 100% when fewer eligible than fixture ranks.
		var sumPct float64
		for i := 0; i < n; i++ {
			sumPct += pcts[i]
		}
		shares := make([]PrizeShare, n)
		var allocated int64
		for i := 0; i < n; i++ {
			norm := pcts[i] / sumPct * 100.0
			// half_up to cents of pool
			cents := int64(math.Floor(float64(prizePoolCents)*norm/100.0 + 0.5))
			shares[i] = PrizeShare{Rank: i + 1, AmountCents: cents, Percentage: norm}
			allocated += cents
		}
		// Residual to highest individual non-tied ranks (rank 1 here).
		if rem := prizePoolCents - allocated; rem != 0 && len(shares) > 0 {
			shares[0].AmountCents += rem
		}
		return shares
	}

	buckets := TralentV1ActiveBuckets(actual)
	if len(buckets) == 0 {
		return nil
	}
	weights := make([]float64, len(buckets))
	var wSum float64
	for i := range buckets {
		weights[i] = math.Pow(TralentV1DecayFactor, float64(i))
		wSum += weights[i]
	}

	// Expand buckets to per-rank shares (equal split within band).
	type rankAlloc struct {
		rank int
		pct  float64
	}
	var ranks []rankAlloc
	for i, b := range buckets {
		bucketPct := (weights[i] / wSum) * 100.0
		span := b[1] - b[0] + 1
		each := bucketPct / float64(span)
		for r := b[0]; r <= b[1]; r++ {
			ranks = append(ranks, rankAlloc{rank: r, pct: each})
		}
	}

	shares := make([]PrizeShare, len(ranks))
	var allocated int64
	for i, ra := range ranks {
		cents := int64(math.Floor(float64(prizePoolCents)*ra.pct/100.0 + 0.5))
		shares[i] = PrizeShare{Rank: ra.rank, AmountCents: cents, Percentage: ra.pct}
		allocated += cents
	}
	if rem := prizePoolCents - allocated; rem != 0 && len(shares) > 0 {
		// Assign residual only to highest individual non-tied ranks (rank 1..10 singles).
		for i := range shares {
			if shares[i].Rank <= 10 {
				shares[i].AmountCents += rem
				break
			}
		}
	}
	return shares
}
