package v2

import (
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"testing"
	"time"

	v1 "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
)

func sampleTick() TickEvent {
	last := FixedPrice{Units: 110000000, Scale: 8}
	return TickEvent{
		SchemaVersion:        SchemaVersion,
		EventID:              "evt-1",
		Symbol:               "EURUSD",
		AssetGroup:           AssetGroupForex,
		Bid:                  FixedPrice{Units: 109990000, Scale: 8},
		Ask:                  FixedPrice{Units: 110010000, Scale: 8},
		Last:                 &last,
		Provider:             "deriv",
		ProviderTimestampMS:  1_700_000_000_000,
		ReceivedAtMS:         1_700_000_000_050,
		PublishedAtMS:        1_700_000_000_100,
		Sequence:             42,
		SourceEpoch:          1,
		Quality:              QualityGood,
		IsSynthetic:          false,
		NormalizationVersion: NormalizationVersion,
	}
}

func TestTickEventValidateAndGolden(t *testing.T) {
	ev := sampleTick()
	if err := ev.Validate(); err != nil {
		t.Fatal(err)
	}
	raw, err := json.Marshal(ev)
	if err != nil {
		t.Fatal(err)
	}
	_, thisFile, _, _ := runtime.Caller(0)
	golden := filepath.Join(filepath.Dir(thisFile), "testdata", "tick_event.v2.json")
	want, err := os.ReadFile(golden)
	if err != nil {
		t.Fatal(err)
	}
	var decoded TickEvent
	if err := json.Unmarshal(want, &decoded); err != nil {
		t.Fatal(err)
	}
	if err := decoded.Validate(); err != nil {
		t.Fatal(err)
	}
	if decoded.Bid.Units != ev.Bid.Units || decoded.SchemaVersion != 2 {
		t.Fatalf("golden mismatch: %s vs %s", want, raw)
	}
}

func TestCompatFromV1(t *testing.T) {
	snap := v1.TickSnapshot{
		Ts: 1_700_000_000_000,
		Symbols: []v1.SymbolTick{
			{Symbol: "EURUSD", Bid: 1.0999, Ask: 1.1001, Last: 1.1},
		},
	}
	events, err := FromV1Snapshot(snap, CompatOptions{
		Provider: "legacy",
		AssetGroup: AssetGroupForex,
		SourceEpoch: 1,
		StartSeq: 1,
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(events) != 1 {
		t.Fatalf("len=%d", len(events))
	}
	if events[0].Quality != QualityDegraded {
		t.Fatal("legacy float translation must be degraded")
	}
	if events[0].Bid.Scale != DefaultPriceScale {
		t.Fatalf("scale=%d", events[0].Bid.Scale)
	}
}

func TestDetectSequenceGap(t *testing.T) {
	prev := sampleTick()
	next := sampleTick()
	next.EventID = "evt-2"
	next.Sequence = prev.Sequence + 3
	gap, ok, err := DetectSequenceGap(prev, next, "gap-1", next.PublishedAtMS)
	if err != nil || !ok {
		t.Fatalf("ok=%v err=%v", ok, err)
	}
	if gap.MissingCount != 2 {
		t.Fatalf("missing=%d", gap.MissingCount)
	}
}

func TestAcceptForEngineRejectsStaleAndIncompatible(t *testing.T) {
	ev := sampleTick()
	now := time.UnixMilli(ev.PublishedAtMS).Add(1 * time.Second).UTC()
	if err := AcceptForEngine(ev, EngineAcceptOptions{Now: now, MaxAge: 5 * time.Second}); err != nil {
		t.Fatalf("expected accept: %v", err)
	}
	stale := ev
	stale.PublishedAtMS = now.Add(-30 * time.Second).UnixMilli()
	if err := AcceptForEngine(stale, EngineAcceptOptions{Now: now, MaxAge: 5 * time.Second}); err == nil {
		t.Fatal("expected stale reject")
	}
	bad := ev
	bad.SchemaVersion = 1
	if err := AcceptForEngine(bad, EngineAcceptOptions{Now: now}); err == nil {
		t.Fatal("expected incompatible reject")
	}
}

func BenchmarkTickEventMarshal(b *testing.B) {
	ev := sampleTick()
	b.ReportAllocs()
	for i := 0; i < b.N; i++ {
		if _, err := json.Marshal(ev); err != nil {
			b.Fatal(err)
		}
	}
}
