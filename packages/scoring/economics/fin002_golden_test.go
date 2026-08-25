package economics

import (
	"testing"

	prizedistribution "github.com/Parsaeffatravesh/tragge/packages/scoring/distribution"
)

// FIN-002: preview (economics), leaderboard-style net, and settlement-style pool
// must agree for the same inputs.
func TestFIN002PreviewLeaderboardSettlementAgreement(t *testing.T) {
	cases := []struct {
		name           string
		participants   int
		entryFeeCents  int64
		platformFeeBps int
	}{
		{"canonical 20%", 10, 10000, 2000},
		{"locked 15%", 3, 10000, 1500},
		{"odd bps", 7, 3333, 1733},
		{"zero fee", 5, 1000, 0},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			pool := CalculatePool(tc.participants, tc.entryFeeCents, tc.platformFeeBps)
			gross := int64(tc.participants) * tc.entryFeeCents
			if pool.GrossCents != gross {
				t.Fatalf("gross=%d want %d", pool.GrossCents, gross)
			}

			// Leaderboard path: NetFromGross on gross.
			lbNet, lbFee := NetFromGross(gross, tc.platformFeeBps)
			if lbNet != pool.NetCents || lbFee != pool.FeeCents {
				t.Fatalf("leaderboard net/fee=%d/%d want %d/%d", lbNet, lbFee, pool.NetCents, pool.FeeCents)
			}

			// Settlement path: same CalculatePool.
			st := CalculatePool(tc.participants, tc.entryFeeCents, tc.platformFeeBps)
			if st.NetCents != pool.NetCents || st.FeeCents != pool.FeeCents {
				t.Fatalf("settlement pool mismatch: %+v vs %+v", st, pool)
			}

			if pool.FeeCents+pool.NetCents != pool.GrossCents {
				t.Fatalf("conservation broken: fee+net=%d gross=%d", pool.FeeCents+pool.NetCents, pool.GrossCents)
			}

			// Distribution agreement: same shares for same net + participants (tralent_v1).
			if pool.NetCents <= 0 {
				return
			}
			sharesA := prizedistribution.CalculateForContest(pool.NetCents, tc.participants)
			sharesB := prizedistribution.CalculateForContest(lbNet, tc.participants)
			if len(sharesA) != len(sharesB) {
				t.Fatalf("share count %d vs %d", len(sharesA), len(sharesB))
			}
			var sum int64
			for i := range sharesA {
				if sharesA[i].AmountCents != sharesB[i].AmountCents {
					t.Fatalf("rank %d amount %d vs %d", sharesA[i].Rank, sharesA[i].AmountCents, sharesB[i].AmountCents)
				}
				sum += sharesA[i].AmountCents
			}
			if sum != pool.NetCents {
				t.Fatalf("distributed %d != net %d", sum, pool.NetCents)
			}
		})
	}
}
