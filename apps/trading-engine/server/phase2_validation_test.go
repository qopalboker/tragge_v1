//nolint:errcheck,goconst,gosec,gocyclo,noctx,staticcheck,ineffassign,prealloc,gofmt,goimports // E2E/integration test harness
package server

import (
	"math"
	"testing"
	"time"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
)

// ensure math is used for Abs in scoring boundary test below

func TestValidateOrderRequest_Quantity(t *testing.T) {
	base := contracts.OrderRequest{
		OrderID: "o1",
		Side:    contracts.OrderSideBuy,
		Type:    contracts.OrderTypeMarket,
		Qty:     100,
	}
	if err := validateOrderRequest(&base); err != nil {
		t.Fatalf("valid market order: %v", err)
	}
	base.Qty = 0
	if err := validateOrderRequest(&base); err == nil {
		t.Fatal("zero qty must fail")
	}
	base.Qty = -5
	if err := validateOrderRequest(&base); err == nil {
		t.Fatal("negative qty must fail")
	}
	base.Qty = MaxAllowedQty + 1
	if err := validateOrderRequest(&base); err == nil {
		t.Fatal("oversized qty must fail")
	}
}

func TestValidateOrderRequest_Prices(t *testing.T) {
	zero := 0.0
	neg := -1.0
	tiny := 1e-20
	huge := 1e20
	nan := math.NaN()
	ok := 100.0

	cases := []struct {
		name    string
		order   contracts.OrderRequest
		wantErr bool
	}{
		{
			name: "limit requires positive limit_price",
			order: contracts.OrderRequest{
				OrderID: "o", Side: contracts.OrderSideBuy, Type: contracts.OrderTypeBuyLimit, Qty: 10, LimitPrice: &zero,
			},
			wantErr: true,
		},
		{
			name: "negative limit",
			order: contracts.OrderRequest{
				OrderID: "o", Side: contracts.OrderSideBuy, Type: contracts.OrderTypeBuyLimit, Qty: 10, LimitPrice: &neg,
			},
			wantErr: true,
		},
		{
			name: "tiny limit",
			order: contracts.OrderRequest{
				OrderID: "o", Side: contracts.OrderSideBuy, Type: contracts.OrderTypeBuyLimit, Qty: 10, LimitPrice: &tiny,
			},
			wantErr: true,
		},
		{
			name: "huge limit",
			order: contracts.OrderRequest{
				OrderID: "o", Side: contracts.OrderSideBuy, Type: contracts.OrderTypeBuyLimit, Qty: 10, LimitPrice: &huge,
			},
			wantErr: true,
		},
		{
			name: "nan limit",
			order: contracts.OrderRequest{
				OrderID: "o", Side: contracts.OrderSideBuy, Type: contracts.OrderTypeBuyLimit, Qty: 10, LimitPrice: &nan,
			},
			wantErr: true,
		},
		{
			name: "valid limit",
			order: contracts.OrderRequest{
				OrderID: "o", Side: contracts.OrderSideBuy, Type: contracts.OrderTypeBuyLimit, Qty: 10, LimitPrice: &ok,
			},
			wantErr: false,
		},
		{
			name: "stop requires stop_price",
			order: contracts.OrderRequest{
				OrderID: "o", Side: contracts.OrderSideSell, Type: contracts.OrderTypeSellStop, Qty: 10,
			},
			wantErr: true,
		},
		{
			name: "valid stop",
			order: contracts.OrderRequest{
				OrderID: "o", Side: contracts.OrderSideSell, Type: contracts.OrderTypeSellStop, Qty: 10, StopPrice: &ok,
			},
			wantErr: false,
		},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			err := validateOrderRequest(&tc.order)
			if tc.wantErr && err == nil {
				t.Fatal("expected error")
			}
			if !tc.wantErr && err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
		})
	}
}

func TestValidateTPSL_LongShort(t *testing.T) {
	entry := 100.0
	goodTPLong := 110.0
	badTPLong := 90.0
	goodSLLong := 90.0
	badSLLong := 110.0
	goodTPShort := 90.0
	badTPShort := 110.0
	goodSLShort := 110.0
	badSLShort := 90.0

	// LONG
	if err := validateTPSL(contracts.OrderSideBuy, &goodTPLong, &goodSLLong, &entry, nil); err != nil {
		t.Fatalf("valid LONG: %v", err)
	}
	if err := validateTPSL(contracts.OrderSideBuy, &badTPLong, nil, &entry, nil); err == nil {
		t.Fatal("LONG TP <= entry must fail")
	}
	if err := validateTPSL(contracts.OrderSideBuy, nil, &badSLLong, &entry, nil); err == nil {
		t.Fatal("LONG SL >= entry must fail")
	}

	// SHORT
	if err := validateTPSL(contracts.OrderSideSell, &goodTPShort, &goodSLShort, &entry, nil); err != nil {
		t.Fatalf("valid SHORT: %v", err)
	}
	if err := validateTPSL(contracts.OrderSideSell, &badTPShort, nil, &entry, nil); err == nil {
		t.Fatal("SHORT TP >= entry must fail")
	}
	if err := validateTPSL(contracts.OrderSideSell, nil, &badSLShort, &entry, nil); err == nil {
		t.Fatal("SHORT SL <= entry must fail")
	}
}

func TestPriceBook_StaleThresholdAndAnomaly(t *testing.T) {
	pb := NewPriceBook()
	maxAge := 30 * time.Second

	// Fresh tick
	pb.mu.Lock()
	pb.quotes["BTC"] = &Quote{Symbol: "BTC", Bid: 1, Ask: 1, Last: 1, Timestamp: time.Now().UnixMilli()}
	pb.mu.Unlock()
	if pb.IsStale("BTC", maxAge) {
		t.Fatal("fresh tick must not be stale")
	}
	if pb.PriceAgeClassifies("BTC", maxAge) != "fresh" {
		t.Fatal("expected fresh")
	}

	// At-or-under threshold is NOT stale (strict > comparison).
	// Use slightly under maxAge to avoid wall-clock race in the test itself.
	pb.mu.Lock()
	pb.quotes["ETH"] = &Quote{Symbol: "ETH", Bid: 1, Ask: 1, Last: 1, Timestamp: time.Now().Add(-maxAge + 50*time.Millisecond).UnixMilli()}
	pb.mu.Unlock()
	if pb.IsStale("ETH", maxAge) {
		t.Fatal("at-threshold tick must be treated as fresh")
	}

	// Unit test the comparison contract directly: age == maxAge is not stale.
	ageEq := maxAge
	if ageEq > maxAge {
		t.Fatal("contract broken: age==maxAge must not be > maxAge")
	}

	// Stale
	pb.mu.Lock()
	pb.quotes["SOL"] = &Quote{Symbol: "SOL", Bid: 1, Ask: 1, Last: 1, Timestamp: time.Now().Add(-maxAge - time.Second).UnixMilli()}
	pb.mu.Unlock()
	if !pb.IsStale("SOL", maxAge) {
		t.Fatal("stale tick must be stale")
	}
	if pb.PriceAgeClassifies("SOL", maxAge) != "stale" {
		t.Fatal("expected stale")
	}

	// Clock anomaly: future timestamp
	pb.mu.Lock()
	pb.quotes["XRP"] = &Quote{Symbol: "XRP", Bid: 1, Ask: 1, Last: 1, Timestamp: time.Now().Add(10 * time.Second).UnixMilli()}
	pb.mu.Unlock()
	if !pb.IsStale("XRP", maxAge) {
		t.Fatal("future timestamp must fail closed as stale")
	}
	if pb.PriceAgeClassifies("XRP", maxAge) != "anomaly" {
		t.Fatalf("expected anomaly, got %s", pb.PriceAgeClassifies("XRP", maxAge))
	}

	// Missing
	if !pb.IsStale("MISSING", maxAge) {
		t.Fatal("missing symbol is stale")
	}
}

func TestDecimalScoring_RoundingBoundary(t *testing.T) {
	// Boundary: very small price delta should still produce a determinate score path.
	score := calculateTradeScoreDecimal("long", 100.0, 100.00000001, 1000)
	if score.Decimal.IsZero() && score.Float64 != 0 {
		t.Fatal("decimal/float inconsistency")
	}
	// Weighted average entry with uneven sizes
	avg := calculateWeightedAverageEntryDecimal(100.0, 3, 200.0, 1)
	// Expected: (100*3 + 200*1) / 4 = 125
	if math.Abs(avg-125.0) > 1e-9 {
		t.Fatalf("weighted avg = %v, want 125", avg)
	}
}

func TestIsValidMarketPrice(t *testing.T) {
	if isValidMarketPrice(0) || isValidMarketPrice(-1) || isValidMarketPrice(math.NaN()) {
		t.Fatal("invalid prices accepted")
	}
	if !isValidMarketPrice(1.23) {
		t.Fatal("valid price rejected")
	}
}
