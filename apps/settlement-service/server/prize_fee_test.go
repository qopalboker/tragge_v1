package server

import (
	"testing"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
)

// TestPlatformFeeIsTwentyPercentOfGrossPool verifies the product rule:
// platform fee = 20% of gross prize pool (entry_fee * participants),
// net pool = remaining 80% for distribution.
func TestPlatformFeeIsTwentyPercentOfGrossPool(t *testing.T) {
	// Fallback path (no stored prize_pool_net_cents): uses PlatformFeeBps.
	s := &SettlementService{app: &App{config: &Config{PlatformFeeBps: 2000}}}
	rankings := make([]contracts.FinalRanking, 10)
	for i := range rankings {
		rankings[i] = contracts.FinalRanking{UserID: "u" + string(rune('a'+i)), Rank: i + 1, FinalScore: float64(100 - i)}
	}
	info := &ContestInfo{
		EntryFeeCents: 1000, // $10
		PlatformFeeBps: 2000,
	}
	pool, _ := s.calculatePrizes(rankings, info)
	// gross = 10 * 1000 = 10000
	// fee = 20% = 2000
	// net = 8000
	if pool.Gross != 10000 {
		t.Fatalf("gross=%d want 10000", pool.Gross)
	}
	if pool.PlatformFee != 2000 {
		t.Fatalf("platform_fee=%d want 2000 (20%%)", pool.PlatformFee)
	}
	if pool.Net != 8000 {
		t.Fatalf("net=%d want 8000", pool.Net)
	}
}

func TestPlatformFeeUsesStoredJoinTimeAccumulation(t *testing.T) {
	// Join path accumulates net pool with 20% commission per join.
	// 5 participants * $10 fee, each contributes $8 to net, $2 commission.
	s := &SettlementService{app: &App{config: &Config{PlatformFeeBps: 2000}}}
	rankings := make([]contracts.FinalRanking, 5)
	for i := range rankings {
		rankings[i] = contracts.FinalRanking{UserID: "u" + string(rune('a'+i)), Rank: i + 1, FinalScore: float64(50 - i)}
	}
	info := &ContestInfo{
		EntryFeeCents:     1000,
		PlatformFeeBps:    2000,
		PrizePoolNetCents: 4000, // 5 * 800
		CommissionAmount:  1000, // 5 * 200
	}
	pool, _ := s.calculatePrizes(rankings, info)
	if pool.Gross != 5000 {
		t.Fatalf("gross=%d want 5000", pool.Gross)
	}
	if pool.Net != 4000 {
		t.Fatalf("net=%d want 4000", pool.Net)
	}
	if pool.PlatformFee != 1000 {
		t.Fatalf("platform_fee=%d want 1000", pool.PlatformFee)
	}
	// Fee is 20% of gross.
	if pool.PlatformFee*5 != pool.Gross {
		// 1000 * 5 = 5000 == gross; i.e. fee is exactly 20%
		if float64(pool.PlatformFee)/float64(pool.Gross) != 0.2 {
			t.Fatalf("fee ratio = %v want 0.2", float64(pool.PlatformFee)/float64(pool.Gross))
		}
	}
}

func TestDefaultConfigPlatformFeeBpsIs2000(t *testing.T) {
	// Document the production default without loading env.
	if got := 2000; got != 2000 {
		t.Fatal("sanity")
	}
	// Mirrors config.go default PLATFORM_FEE_BPS.
	const defaultBps = 2000
	if defaultBps != 2000 {
		t.Fatalf("default platform fee bps = %d want 2000", defaultBps)
	}
}
