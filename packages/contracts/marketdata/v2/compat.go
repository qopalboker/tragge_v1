package v2

import (
	"fmt"
	"math"
	"strings"

	v1 "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
	"github.com/Parsaeffatravesh/tragge/packages/money"
)

// CompatOptions controls v1→v2 translation during rollout.
type CompatOptions struct {
	Provider     string
	AssetGroup   AssetGroup
	SourceEpoch  int64
	StartSeq     int64
	EventIDPrefix string
	Scale        int
	ReceivedAtMS int64
	PublishedAtMS int64
	Quality      TickQuality
	IsSynthetic  bool
}

// FromV1Snapshot translates a legacy float TickSnapshot into canonical TickEvents.
// Float conversion uses fail-closed overflow checks and DATA-001 default scale.
func FromV1Snapshot(snap v1.TickSnapshot, opt CompatOptions) ([]TickEvent, error) {
	if opt.Provider == "" {
		return nil, fmt.Errorf("marketdata/v2: compat provider is required")
	}
	if opt.AssetGroup == "" {
		opt.AssetGroup = AssetGroupForex
	}
	if opt.Scale <= 0 {
		opt.Scale = DefaultPriceScale
	}
	if opt.Quality == "" {
		opt.Quality = QualityDegraded // legacy float source is never "good" without provenance
	}
	if opt.ReceivedAtMS <= 0 {
		opt.ReceivedAtMS = snap.Ts
	}
	if opt.PublishedAtMS <= 0 {
		opt.PublishedAtMS = snap.Ts
	}
	if snap.Ts <= 0 {
		return nil, fmt.Errorf("marketdata/v2: v1 snapshot ts is required")
	}
	out := make([]TickEvent, 0, len(snap.Symbols))
	seq := opt.StartSeq
	for i, st := range snap.Symbols {
		bid, err := floatToFixed(st.Bid, opt.Scale)
		if err != nil {
			return nil, fmt.Errorf("symbol %s bid: %w", st.Symbol, err)
		}
		ask, err := floatToFixed(st.Ask, opt.Scale)
		if err != nil {
			return nil, fmt.Errorf("symbol %s ask: %w", st.Symbol, err)
		}
		var last *FixedPrice
		if st.Last != 0 {
			lp, err := floatToFixed(st.Last, opt.Scale)
			if err != nil {
				return nil, fmt.Errorf("symbol %s last: %w", st.Symbol, err)
			}
			last = &lp
		}
		providerTS := st.Timestamp
		if providerTS <= 0 {
			providerTS = snap.Ts
		}
		prefix := opt.EventIDPrefix
		if prefix == "" {
			prefix = "compat"
		}
		ev := TickEvent{
			SchemaVersion:        SchemaVersion,
			EventID:              fmt.Sprintf("%s-%d-%s", prefix, i, strings.ToLower(st.Symbol)),
			Symbol:               st.Symbol,
			AssetGroup:           opt.AssetGroup,
			Bid:                  bid,
			Ask:                  ask,
			Last:                 last,
			Provider:             opt.Provider,
			ProviderTimestampMS:  providerTS,
			ReceivedAtMS:         opt.ReceivedAtMS,
			PublishedAtMS:        opt.PublishedAtMS,
			Sequence:             seq,
			SourceEpoch:          opt.SourceEpoch,
			Quality:              opt.Quality,
			IsSynthetic:          opt.IsSynthetic,
			NormalizationVersion: NormalizationVersion,
		}
		if err := ev.Validate(); err != nil {
			return nil, err
		}
		out = append(out, ev)
		seq++
	}
	return out, nil
}

func floatToFixed(v float64, scale int) (FixedPrice, error) {
	if math.IsNaN(v) || math.IsInf(v, 0) {
		return FixedPrice{}, fmt.Errorf("non-finite float")
	}
	factor, err := pow10(scale)
	if err != nil {
		return FixedPrice{}, err
	}
	// half_up via math.Round (Go Round is half away from zero)
	scaled := math.Round(v * float64(factor))
	if scaled > float64(math.MaxInt64) || scaled < float64(math.MinInt64) {
		return FixedPrice{}, fmt.Errorf("overflow converting float to fixed")
	}
	p, err := money.NewPrice(int64(scaled), scale)
	if err != nil {
		return FixedPrice{}, err
	}
	return NewFixedPrice(p), nil
}

func pow10(exp int) (int64, error) {
	if exp < 0 || exp > money.MaxScale {
		return 0, fmt.Errorf("invalid scale")
	}
	var out int64 = 1
	for i := 0; i < exp; i++ {
		if out > math.MaxInt64/10 {
			return 0, fmt.Errorf("pow10 overflow")
		}
		out *= 10
	}
	return out, nil
}
