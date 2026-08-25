package server

import (
	"testing"

	v1 "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
	mdv2 "github.com/Parsaeffatravesh/tragge/packages/contracts/marketdata/v2"
)

func TestTranslateLegacySnapshot(t *testing.T) {
	snap := v1.TickSnapshot{
		Ts: 1_700_000_000_000,
		Symbols: []v1.SymbolTick{
			{Symbol: "BTCUSDT", Bid: 50000.12, Ask: 50000.34, Last: 50000.2},
		},
	}
	events, err := TranslateLegacySnapshot(snap, "nobitex", mdv2.AssetGroupCrypto, 1, 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(events) != 1 || events[0].Symbol != "BTCUSDT" {
		t.Fatalf("%+v", events)
	}
}

func TestNewGapEventRequiresMissing(t *testing.T) {
	if _, err := NewGapEvent("g1", "EURUSD", mdv2.AssetGroupForex, "deriv", 1, 5, 6, 1); err == nil {
		t.Fatal("expected missing_count validation failure for adjacent sequences")
	}
	ev, err := NewGapEvent("g2", "EURUSD", mdv2.AssetGroupForex, "deriv", 1, 5, 8, 100)
	if err != nil {
		t.Fatal(err)
	}
	if ev.MissingCount != 2 {
		t.Fatalf("missing=%d", ev.MissingCount)
	}
}
