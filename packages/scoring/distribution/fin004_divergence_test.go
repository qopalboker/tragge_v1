package prizedistribution

import (
	"fmt"
	"testing"
)

// FIN-004: quantify Power Law (current production path) vs policy tralent_v1.
func TestFIN004PowerLawVsTralentV1Divergence(t *testing.T) {
	const poolCents int64 = 80000 // $800 net pool (e.g. 10 × $100 entry @ 20% fee)

	cases := []struct {
		participants int
		note         string
	}{
		{2, "small fixture 100%"},
		{4, "small fixture 80/20"},
		{7, "small fixture 65/25/10"},
		{10, "small fixture 50/30/20"},
		{12, "first geometric band"},
		{20, "geometric ~6 winners planned"},
		{50, "geometric mid"},
		{100, "geometric large"},
	}

	type row struct {
		participants int
		plWinners    int
		tvWinners    int
		plFirst      int64
		tvFirst      int64
		firstDiffUSD float64
		maxAbsDiff   int64
		note         string
	}
	var rows []row

	for _, tc := range cases {
		plW := GetWinnersCountPowerLaw(tc.participants, DefaultWinnerPercent)
		pl := CalculatePrizeDistributionPowerLaw(poolCents, plW, DefaultAlpha)

		tvW := TralentV1PlannedWinners(tc.participants)
		tv := TralentV1CalculatePrizeDistribution(poolCents, tc.participants, 0)

		var plFirst, tvFirst int64
		if len(pl) > 0 {
			plFirst = pl[0].AmountCents
		}
		if len(tv) > 0 {
			tvFirst = tv[0].AmountCents
		}

		// Compare overlapping ranks
		n := len(pl)
		if len(tv) < n {
			n = len(tv)
		}
		var maxAbs int64
		for i := 0; i < n; i++ {
			d := pl[i].AmountCents - tv[i].AmountCents
			if d < 0 {
				d = -d
			}
			if d > maxAbs {
				maxAbs = d
			}
		}
		// Count mismatch when winner counts differ
		if len(pl) != len(tv) {
			// Treat entire missing ranks as divergence at least pool/winner
			maxAbs = poolCents // flag structural divergence
		}

		rows = append(rows, row{
			participants: tc.participants,
			plWinners:    plW,
			tvWinners:    tvW,
			plFirst:      plFirst,
			tvFirst:      tvFirst,
			firstDiffUSD: float64(plFirst-tvFirst) / 100.0,
			maxAbsDiff:   maxAbs,
			note:         tc.note,
		})
	}

	t.Log("FIN-004 divergence (pool=$800.00 net):")
	t.Log("participants | PL winners | TV winners | PL 1st $ | TV 1st $ | 1st Δ$ | max|Δ| cents | note")
	anyStructural := false
	for _, r := range rows {
		t.Logf("%12d | %10d | %10d | %8.2f | %8.2f | %+7.2f | %12d | %s",
			r.participants, r.plWinners, r.tvWinners,
			float64(r.plFirst)/100.0, float64(r.tvFirst)/100.0,
			r.firstDiffUSD, r.maxAbsDiff, r.note)
		if r.plWinners != r.tvWinners || r.maxAbsDiff > 100 { // > $1
			anyStructural = true
		}
	}

	// Sanity: small-contest TV fixtures must match policy exactly for 4 players.
	tv4 := TralentV1CalculatePrizeDistribution(10000, 4, 0) // $100 pool
	if len(tv4) != 2 || tv4[0].AmountCents != 8000 || tv4[1].AmountCents != 2000 {
		t.Fatalf("tralent_v1 4-player fixture: got %+v want 80/20 of 10000", tv4)
	}

	// Document that paths diverge (expected until FIN-004 lands).
	if !anyStructural {
		t.Fatal("expected Power Law vs tralent_v1 structural divergence; comparison may be wrong")
	}

	// Keep a machine-readable summary for the evidence report.
	summary := fmt.Sprintf("pool_cents=%d cases=%d diverged=true", poolCents, len(rows))
	t.Log(summary)
}

func TestFIN004TralentV1PlannedWinnersTable(t *testing.T) {
	cases := []struct {
		n, want int
	}{
		{1, 0}, {2, 1}, {3, 1}, {4, 2}, {6, 2}, {7, 3}, {11, 3},
		{12, 4},  // floor(12*0.3+0.5)=4 → band {4,4}
		{20, 6},  // floor(6.5)=6 → band {6,6}
		{100, 30}, // floor(30.5)=30 → band {26,30} → 30
	}
	for _, tc := range cases {
		if got := TralentV1PlannedWinners(tc.n); got != tc.want {
			t.Errorf("participants=%d planned=%d want %d", tc.n, got, tc.want)
		}
	}
}
