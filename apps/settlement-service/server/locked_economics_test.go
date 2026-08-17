package server

import (
	"testing"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
	"github.com/Parsaeffatravesh/tragge/packages/scoring/economics"
)

// Locked economics must dominate mutable row fields and config defaults.
func TestCalculatePrizes_UsesLockedFeeNotGlobalDefault(t *testing.T) {
	s := &SettlementService{app: &App{config: &Config{PlatformFeeBps: 5000}}} // global would be 50%

	rankings := []contracts.FinalRanking{
		{UserID: "u1", Rank: 1, FinalScore: 100},
		{UserID: "u2", Rank: 2, FinalScore: 90},
		{UserID: "u3", Rank: 3, FinalScore: 80},
	}
	// Row says 50% fee; lock says 15%; stored pool empty so recalculation path runs.
	info := &ContestInfo{
		EntryFeeCents:        10000,
		PlatformFeeBps:       5000,
		EconomicsLocked:      true,
		LockedEntryFeeCents:  10000,
		LockedPlatformFeeBps: 1500,
		PrizePoolNetCents:    0,
	}
	// getContestInfo would overwrite Entry/Platform from lock; simulate that:
	info.EntryFeeCents = info.LockedEntryFeeCents
	info.PlatformFeeBps = info.LockedPlatformFeeBps

	pool, prizes := s.calculatePrizes(rankings, info)
	want := economics.CalculatePool(3, 10000, 1500)
	if pool.Net != want.NetCents {
		t.Fatalf("net=%d want %d (locked 15%%); gross=%d fee=%d", pool.Net, want.NetCents, pool.Gross, pool.PlatformFee)
	}
	if pool.Net == economics.CalculatePool(3, 10000, 5000).NetCents {
		t.Fatal("used global/default 50% fee instead of locked 15%")
	}
	if len(prizes) == 0 {
		t.Fatal("expected prize allocations")
	}
}
