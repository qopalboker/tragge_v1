package v2

import (
	"fmt"
	"time"
)

// TickQuality is the normalized quality class for a tick.
type TickQuality string

const (
	QualityGood      TickQuality = "good"
	QualityDegraded  TickQuality = "degraded"
	QualitySuspect   TickQuality = "suspect"
	QualityUnusable  TickQuality = "unusable"
)

// AssetGroup identifies the tradable asset class for a symbol.
type AssetGroup string

const (
	AssetGroupForex  AssetGroup = "forex"
	AssetGroupCrypto AssetGroup = "crypto"
)

// TickEvent is the canonical per-symbol market tick (policy §9.7).
type TickEvent struct {
	SchemaVersion        int        `json:"schema_version"`
	EventID              string     `json:"event_id"`
	Symbol               string     `json:"symbol"`
	AssetGroup           AssetGroup `json:"asset_group"`
	Bid                  FixedPrice `json:"bid"`
	Ask                  FixedPrice `json:"ask"`
	Last                 *FixedPrice `json:"last,omitempty"`
	Provider             string     `json:"provider"`
	ProviderTimestampMS  int64      `json:"provider_timestamp_ms"`
	ReceivedAtMS         int64      `json:"received_at_ms"`
	PublishedAtMS        int64      `json:"published_at_ms"`
	Sequence             int64      `json:"sequence"`
	SourceEpoch          int64      `json:"source_epoch"`
	Quality              TickQuality `json:"quality"`
	IsSynthetic          bool       `json:"is_synthetic"`
	NormalizationVersion int        `json:"normalization_version"`
}

// Validate checks required MD-001 tick fields. Fail closed on invalid precision/quality.
func (t TickEvent) Validate() error {
	if t.SchemaVersion != SchemaVersion {
		return fmt.Errorf("marketdata/v2: unsupported schema_version %d", t.SchemaVersion)
	}
	if t.EventID == "" {
		return fmt.Errorf("marketdata/v2: event_id is required")
	}
	if t.Symbol == "" {
		return fmt.Errorf("marketdata/v2: symbol is required")
	}
	if t.AssetGroup != AssetGroupForex && t.AssetGroup != AssetGroupCrypto {
		return fmt.Errorf("marketdata/v2: invalid asset_group %q", t.AssetGroup)
	}
	if err := t.Bid.Validate(); err != nil {
		return err
	}
	if err := t.Ask.Validate(); err != nil {
		return err
	}
	if t.Last != nil {
		if err := t.Last.Validate(); err != nil {
			return err
		}
	}
	if t.Provider == "" {
		return fmt.Errorf("marketdata/v2: provider is required")
	}
	if t.ProviderTimestampMS <= 0 || t.ReceivedAtMS <= 0 || t.PublishedAtMS <= 0 {
		return fmt.Errorf("marketdata/v2: provider/receive/publish timestamps are required")
	}
	if t.Sequence < 0 {
		return fmt.Errorf("marketdata/v2: sequence must be >= 0")
	}
	if t.SourceEpoch < 0 {
		return fmt.Errorf("marketdata/v2: source_epoch must be >= 0")
	}
	switch t.Quality {
	case QualityGood, QualityDegraded, QualitySuspect, QualityUnusable:
	default:
		return fmt.Errorf("marketdata/v2: invalid quality %q", t.Quality)
	}
	if t.NormalizationVersion <= 0 {
		return fmt.Errorf("marketdata/v2: normalization_version must be > 0")
	}
	if t.Ask.Units < t.Bid.Units && t.Ask.Scale == t.Bid.Scale {
		return fmt.Errorf("marketdata/v2: ask must be >= bid at equal scale")
	}
	return nil
}

// Age returns time since published_at relative to now.
func (t TickEvent) Age(now time.Time) time.Duration {
	pub := time.UnixMilli(t.PublishedAtMS)
	if now.Before(pub) {
		return 0
	}
	return now.Sub(pub)
}
