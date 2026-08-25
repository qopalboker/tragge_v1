package v2

import (
	"fmt"
	"time"
)

// EngineAcceptOptions configures Engine-side tick admission (MD-001).
type EngineAcceptOptions struct {
	Now                 time.Time
	MaxAge              time.Duration
	MinNormalizationVer int
	AllowSynthetic      bool
	RequireQuality      []TickQuality
}

// RejectReason classifies Engine rejection of a tick.
type RejectReason string

const (
	RejectIncompatible RejectReason = "incompatible"
	RejectStale        RejectReason = "stale"
	RejectUnusable     RejectReason = "unusable"
	RejectSynthetic    RejectReason = "synthetic_forbidden"
	RejectFutureDated  RejectReason = "future_dated"
)

// AcceptForEngine validates a v2 tick for Trading Engine consumption.
// Stale or incompatible data is rejected; never treated as silent continuity.
func AcceptForEngine(ev TickEvent, opt EngineAcceptOptions) error {
	if err := ev.Validate(); err != nil {
		return fmt.Errorf("%s: %w", RejectIncompatible, err)
	}
	minNorm := opt.MinNormalizationVer
	if minNorm <= 0 {
		minNorm = 1
	}
	if ev.NormalizationVersion < minNorm {
		return fmt.Errorf("%s: normalization_version %d < %d", RejectIncompatible, ev.NormalizationVersion, minNorm)
	}
	if ev.Quality == QualityUnusable {
		return fmt.Errorf("%s: quality unusable", RejectUnusable)
	}
	if ev.IsSynthetic && !opt.AllowSynthetic {
		return fmt.Errorf("%s: synthetic ticks not allowed", RejectSynthetic)
	}
	now := opt.Now
	if now.IsZero() {
		now = time.Now().UTC()
	}
	pub := time.UnixMilli(ev.PublishedAtMS).UTC()
	if pub.After(now.Add(2 * time.Second)) {
		return fmt.Errorf("%s: published_at in the future", RejectFutureDated)
	}
	maxAge := opt.MaxAge
	if maxAge <= 0 {
		maxAge = 5 * time.Second
	}
	if age := now.Sub(pub); age > maxAge {
		return fmt.Errorf("%s: age %s exceeds max %s", RejectStale, age, maxAge)
	}
	if len(opt.RequireQuality) > 0 {
		ok := false
		for _, q := range opt.RequireQuality {
			if ev.Quality == q {
				ok = true
				break
			}
		}
		if !ok {
			return fmt.Errorf("%s: quality %s not accepted", RejectUnusable, ev.Quality)
		}
	}
	return nil
}
