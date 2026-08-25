package server

import (
	"testing"
	"time"

	mdv2 "github.com/Parsaeffatravesh/tragge/packages/contracts/marketdata/v2"
)

func TestAcceptTickV2RejectsStale(t *testing.T) {
	now := time.UnixMilli(1_700_000_010_000).UTC()
	last := mdv2.FixedPrice{Units: 110000000, Scale: 8}
	ev := mdv2.TickEvent{
		SchemaVersion:        mdv2.SchemaVersion,
		EventID:              "e1",
		Symbol:               "EURUSD",
		AssetGroup:           mdv2.AssetGroupForex,
		Bid:                  mdv2.FixedPrice{Units: 109990000, Scale: 8},
		Ask:                  mdv2.FixedPrice{Units: 110010000, Scale: 8},
		Last:                 &last,
		Provider:             "deriv",
		ProviderTimestampMS:  now.Add(-30 * time.Second).UnixMilli(),
		ReceivedAtMS:         now.Add(-30 * time.Second).UnixMilli(),
		PublishedAtMS:        now.Add(-30 * time.Second).UnixMilli(),
		Sequence:             1,
		SourceEpoch:          1,
		Quality:              mdv2.QualityGood,
		NormalizationVersion: mdv2.NormalizationVersion,
	}
	if err := AcceptTickV2(ev, now, 5*time.Second); err == nil {
		t.Fatal("expected stale rejection")
	}
}
