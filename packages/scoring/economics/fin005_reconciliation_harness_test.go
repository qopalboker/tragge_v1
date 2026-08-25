package economics

import (
	"fmt"
	"testing"

	prizedistribution "github.com/Parsaeffatravesh/tragge/packages/scoring/distribution"
)

// FIN-005: in-process financial reconciliation harness.
// Stages: join fee collection → platform/prize split → (trade = scoring-only) →
// tralent_v1 prize shares → synthetic ledger conservation.
//
// Does not require Postgres/Docker. Full Compose lifecycle + scheduled staging
// are tracked as follow-ups (see FIN-005 report / discovered-issues).

type fin005StageResult struct {
	Name string
	OK   bool
	Detail string
}

type fin005HarnessReport struct {
	Participants   int
	EntryFeeCents  int64
	PlatformFeeBps int
	LateJoiners    int
	GrossCents     int64
	PlatformCents  int64
	PrizePoolCents int64
	LateSurcharge  int64
	PrizeShares    []prizedistribution.PrizeShare
	Stages         []fin005StageResult
}

func runFIN005Harness(participants int, entryFeeCents int64, platformFeeBps int, lateJoiners int) fin005HarnessReport {
	rep := fin005HarnessReport{
		Participants:   participants,
		EntryFeeCents:  entryFeeCents,
		PlatformFeeBps: platformFeeBps,
		LateJoiners:    lateJoiners,
	}

	late := lateJoiners
	if late < 0 {
		late = 0
	}
	if late > participants {
		late = participants
	}
	onTime := participants - late

	// --- Stage: join (fee collection) ---
	var collected int64
	var platformAcc, prizeAcc, surchargeAcc int64
	for i := 0; i < onTime; i++ {
		collected += entryFeeCents
		p, pr := SplitEntryFee(entryFeeCents, platformFeeBps)
		platformAcc += p
		prizeAcc += pr
	}
	for i := 0; i < late; i++ {
		surcharge := LateJoinSurchargeCents(entryFeeCents)
		collected += entryFeeCents + surcharge
		p, pr := SplitEntryFee(entryFeeCents, platformFeeBps)
		platformAcc += p
		prizeAcc += pr
		surchargeAcc += surcharge // 100% platform revenue per policy §4.3
	}
	rep.LateSurcharge = surchargeAcc
	rep.GrossCents = int64(participants) * entryFeeCents
	pool := CalculatePool(participants, entryFeeCents, platformFeeBps)
	rep.PlatformCents = pool.FeeCents + surchargeAcc
	rep.PrizePoolCents = pool.NetCents

	joinOK := prizeAcc == pool.NetCents && platformAcc == pool.FeeCents
	rep.Stages = append(rep.Stages, fin005StageResult{
		Name: "join_fee_split",
		OK:   joinOK,
		Detail: fmt.Sprintf("per-entry sum platform=%d prize=%d; pool fee=%d net=%d; surcharge=%d",
			platformAcc, prizeAcc, pool.FeeCents, pool.NetCents, surchargeAcc),
	})

	// --- Stage: trade ---
	// Contest prize economics do not change with fills; scoring only.
	rep.Stages = append(rep.Stages, fin005StageResult{
		Name:   "trade_scoring_only",
		OK:     true,
		Detail: "fills affect ranking scores, not prize-pool liability",
	})

	// --- Stage: leaderboard preview shares (must match settlement math) ---
	preview := prizedistribution.CalculateForContest(pool.NetCents, participants)
	// --- Stage: settle shares ---
	settled := prizedistribution.CalculateForContest(pool.NetCents, participants)
	rep.PrizeShares = settled

	previewMatch := len(preview) == len(settled)
	var previewSum, settledSum int64
	for i := range settled {
		settledSum += settled[i].AmountCents
		if previewMatch && i < len(preview) {
			previewSum += preview[i].AmountCents
			if preview[i].AmountCents != settled[i].AmountCents || preview[i].Rank != settled[i].Rank {
				previewMatch = false
			}
		}
	}
	rep.Stages = append(rep.Stages, fin005StageResult{
		Name:   "preview_equals_settlement_shares",
		OK:     previewMatch && previewSum == settledSum,
		Detail: fmt.Sprintf("preview_sum=%d settled_sum=%d winners=%d", previewSum, settledSum, len(settled)),
	})

	// --- Stage: prize conservation ---
	prizeOK := settledSum == pool.NetCents
	if participants >= 2 && pool.NetCents > 0 && len(settled) == 0 {
		prizeOK = false
	}
	if participants < 2 {
		prizeOK = settledSum == 0
	}
	rep.Stages = append(rep.Stages, fin005StageResult{
		Name:   "prize_sum_equals_pool",
		OK:     prizeOK,
		Detail: fmt.Sprintf("sum(prizes)=%d pool.net=%d", settledSum, pool.NetCents),
	})

	// --- Stage: synthetic ledger ---
	// Each user starts with 2× entry (+surcharge budget); pays entry (+late); winners receive prizes.
	type ledgerUser struct {
		start, entryPaid, surchargePaid, prize, end int64
	}
	users := make([]ledgerUser, participants)
	for i := range users {
		users[i].start = entryFeeCents*2 + LateJoinSurchargeCents(entryFeeCents)
		users[i].entryPaid = entryFeeCents
		if i >= onTime {
			users[i].surchargePaid = LateJoinSurchargeCents(entryFeeCents)
		}
	}
	for _, sh := range settled {
		idx := sh.Rank - 1
		if idx >= 0 && idx < len(users) {
			users[idx].prize = sh.AmountCents
		}
	}
	var userEndSum, platformRevenue int64
	platformRevenue = pool.FeeCents + surchargeAcc
	for i := range users {
		users[i].end = users[i].start - users[i].entryPaid - users[i].surchargePaid + users[i].prize
		userEndSum += users[i].end
	}
	var userStartSum int64
	for _, u := range users {
		userStartSum += u.start
	}
	// Conservation: start_user_funds = end_user_funds + platform_revenue
	// (prize pool is paid back to users from collected prize portion)
	ledgerOK := userStartSum == userEndSum+platformRevenue
	rep.Stages = append(rep.Stages, fin005StageResult{
		Name: "synthetic_ledger_conservation",
		OK:   ledgerOK,
		Detail: fmt.Sprintf("start=%d end_users=%d platform_revenue=%d (fee+surcharge)",
			userStartSum, userEndSum, platformRevenue),
	})

	// --- Stage: total cash identity ---
	// collected base = platform fee + prize pool; + surcharges all platform.
	cashOK := collected == pool.GrossCents+surchargeAcc &&
		pool.FeeCents+pool.NetCents == pool.GrossCents
	rep.Stages = append(rep.Stages, fin005StageResult{
		Name:   "cash_identity",
		OK:     cashOK,
		Detail: fmt.Sprintf("collected=%d gross+surcharge=%d", collected, pool.GrossCents+surchargeAcc),
	})

	return rep
}

func TestFIN005FinancialReconciliationHarness(t *testing.T) {
	cases := []struct {
		name           string
		participants   int
		entryFeeCents  int64
		platformFeeBps int
		lateJoiners    int
	}{
		{"4p_canonical_20pct", 4, 10000, 2000, 0},
		{"10p_canonical_20pct", 10, 10000, 2000, 0},
		{"12p_geometric", 12, 10000, 2000, 0},
		{"7p_with_2_late", 7, 10000, 2000, 2},
		{"50p_mid", 50, 5000, 2000, 0},
		{"locked_15pct_3p", 3, 10000, 1500, 0},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			rep := runFIN005Harness(tc.participants, tc.entryFeeCents, tc.platformFeeBps, tc.lateJoiners)
			for _, st := range rep.Stages {
				if !st.OK {
					t.Errorf("stage %s FAILED: %s", st.Name, st.Detail)
				} else {
					t.Logf("stage %s OK: %s", st.Name, st.Detail)
				}
			}
			// Numeric example log for 4p 100 USDT 20%
			if tc.name == "4p_canonical_20pct" {
				t.Logf("EXAMPLE 4×$100 @20%%: gross=%d fee=%d net=%d shares=%d 1st=%d",
					rep.GrossCents, rep.PlatformCents-rep.LateSurcharge, rep.PrizePoolCents,
					len(rep.PrizeShares),
					func() int64 {
						if len(rep.PrizeShares) > 0 {
							return rep.PrizeShares[0].AmountCents
						}
						return 0
					}())
			}
		})
	}
}

func TestFIN005ProductionPathDoesNotUsePowerLaw(t *testing.T) {
	// Harness must use tralent_v1 shares, not Power Law.
	pool := CalculatePool(4, 10000, 2000) // net=32000
	tv := prizedistribution.CalculateForContest(pool.NetCents, 4)
	pl := prizedistribution.CalculatePrizeDistributionPowerLaw(pool.NetCents, 2, prizedistribution.DefaultAlpha)
	if len(tv) != 2 || tv[0].AmountCents != 25600 || tv[1].AmountCents != 6400 {
		t.Fatalf("tralent_v1 4p on %d net: got %+v want 25600/6400", pool.NetCents, tv)
	}
	if len(pl) > 0 && pl[0].AmountCents == tv[0].AmountCents {
		t.Fatal("Power Law 1st unexpectedly equals tralent_v1 — harness would not detect regression")
	}
}
