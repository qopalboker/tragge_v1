package economics

import (
	"testing"
	"time"
)

func TestResolvePlatformFeeBps(t *testing.T) {
	tests := []struct {
		name string
		bps  int
		rate float64
		want int
	}{
		{"canonical bps wins", 2500, 20.0, 2500},
		{"fallback commission percent", 0, 20.0, 2000},
		{"default when both empty", 0, 0, DefaultPlatformFeeBps},
		{"ignore invalid high bps", 20000, 15.0, 1500},
		{"commission 17%", 0, 17.0, 1700},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := ResolvePlatformFeeBps(tt.bps, tt.rate); got != tt.want {
				t.Fatalf("got %d want %d", got, tt.want)
			}
		})
	}
}

func TestCalculatePool_Conservation(t *testing.T) {
	pool := CalculatePool(10, 10000, 2000) // 10 * $100, 20% fee
	if pool.GrossCents != 100000 {
		t.Fatalf("gross=%d", pool.GrossCents)
	}
	if pool.FeeCents+pool.NetCents != pool.GrossCents {
		t.Fatalf("fee+net != gross: %d+%d != %d", pool.FeeCents, pool.NetCents, pool.GrossCents)
	}
	if pool.NetCents != 80000 {
		t.Fatalf("net=%d want 80000", pool.NetCents)
	}
}

func TestSplitEntryFee(t *testing.T) {
	fee, prize := SplitEntryFee(10000, 2000)
	if fee != 2000 || prize != 8000 {
		t.Fatalf("fee=%d prize=%d", fee, prize)
	}
}

func TestLateJoinSurcharge(t *testing.T) {
	if got := LateJoinSurchargeCents(10000); got != 1000 {
		t.Fatalf("surcharge=%d", got)
	}
	ch := ComputeJoinCharge(10000, 2000, true)
	if ch.TotalCents != 11000 || ch.PrizeCents != 8000 || ch.SurchargeCents != 1000 {
		t.Fatalf("%+v", ch)
	}
}

func TestLateJoinCutoff(t *testing.T) {
	start := time.Date(2026, 1, 1, 12, 0, 0, 0, time.UTC)
	// 1 day contest → 30m cap
	end := start.Add(24 * time.Hour)
	cut := LateJoinCutoff(start, end)
	if !cut.Equal(start.Add(30 * time.Minute)) {
		t.Fatalf("cutoff=%v", cut)
	}
	// 30m contest → 3m window
	end2 := start.Add(30 * time.Minute)
	cut2 := LateJoinCutoff(start, end2)
	if !cut2.Equal(start.Add(3 * time.Minute)) {
		t.Fatalf("cutoff2=%v", cut2)
	}
}

func TestAllocatePayouts_ConservationAndNoNegative(t *testing.T) {
	ranked := []RankedUser{
		{UserID: "u1", Rank: 1, Score: 100},
		{UserID: "u2", Rank: 2, Score: 90},
		{UserID: "u3", Rank: 3, Score: 80},
		{UserID: "u4", Rank: 4, Score: 70},
		{UserID: "u5", Rank: 5, Score: 60},
		{UserID: "u6", Rank: 6, Score: 50},
		{UserID: "u7", Rank: 7, Score: 40},
		{UserID: "u8", Rank: 8, Score: 30},
		{UserID: "u9", Rank: 9, Score: 20},
		{UserID: "u10", Rank: 10, Score: 10},
	}
	pool := int64(80000)
	payouts, err := AllocatePayouts(ranked, pool)
	if err != nil {
		t.Fatal(err)
	}
	if err := AssertConservation(payouts, pool); err != nil {
		t.Fatal(err)
	}
	sum := SumPayouts(payouts)
	// Power-law distributes to winners subset; sum of winner slots equals full pool.
	if sum != pool {
		// prizedistribution puts remainder on rank 1 so total shares == pool
		t.Fatalf("sum=%d pool=%d payouts=%+v", sum, pool, payouts)
	}
	// Determinism
	p2, _ := AllocatePayouts(ranked, pool)
	if SumPayouts(p2) != sum {
		t.Fatal("non-deterministic sum")
	}
}

func TestAllocatePayouts_Empty(t *testing.T) {
	p, err := AllocatePayouts(nil, 1000)
	if err != nil || p != nil {
		t.Fatalf("got %v %v", p, err)
	}
}
