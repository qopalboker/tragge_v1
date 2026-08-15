package server

import (
	"testing"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
)

func TestMVP004QuantityPolicy(t *testing.T) {
	// Server-side duration → QTY mapping must match product policy.
	cases := map[contracts.ContestDurationType]int64{
		contracts.ContestDurationRush30Min: 5,
		contracts.ContestDurationHourly:    10,
		contracts.ContestDurationFourHour:  10,
		contracts.ContestDurationDaily:     20,
		contracts.ContestDurationWeekly:    20,
	}
	for d, want := range cases {
		if got := d.DefaultQtyAllocation(); got != want {
			t.Fatalf("%s qty=%d want %d", d, got, want)
		}
	}
	// Client-supplied legacy scaled values must not be accepted as trading QTY.
	for _, bad := range []int64{0, 1, 999999, 50000, 100000, 200000, 500000} {
		if contracts.IsAllowedTradingQty(bad) {
			t.Fatalf("%d must not be allowed trading qty", bad)
		}
	}
}

func TestMVP004PlatformFeeDefault2000Bps(t *testing.T) {
	if DefaultPlatformFeeBps != 2000 {
		t.Fatalf("DefaultPlatformFeeBps=%d want 2000 (20%%)", DefaultPlatformFeeBps)
	}
	// When neither column is set, effective fee is 20%.
	if got := ResolveEffectiveFeeBps(0, 0); got != 2000 {
		t.Fatalf("ResolveEffectiveFeeBps(0,0)=%d want 2000", got)
	}
}

func TestMVP004PrizePoolNetAfter20Percent(t *testing.T) {
	// 10 participants * $10 = $100 gross; 20% fee → $80 net.
	participants := 10
	entryFee := 1000
	bps := ResolveEffectiveFeeBps(0, 20.0)
	if bps != 2000 {
		t.Fatalf("bps=%d", bps)
	}
	gross := int64(participants * entryFee)
	net := (gross * int64(10000-bps)) / 10000
	if net != 8000 {
		t.Fatalf("net=%d want 8000", net)
	}
	fee := gross - net
	if fee != 2000 {
		t.Fatalf("fee=%d want 2000", fee)
	}
}
