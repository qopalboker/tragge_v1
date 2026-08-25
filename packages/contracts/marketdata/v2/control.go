package v2

import "fmt"

// FeedControlType enumerates continuity/control events required by MD-001.
type FeedControlType string

const (
	ControlGap          FeedControlType = "gap"
	ControlStale        FeedControlType = "stale"
	ControlPause        FeedControlType = "pause"
	ControlResume       FeedControlType = "resume"
	ControlSourceSwitch FeedControlType = "source_switch"
)

// FeedControlEvent records measurable feed continuity changes.
// Silent sequence drops are prohibited; gaps must be explicit events.
type FeedControlEvent struct {
	SchemaVersion int             `json:"schema_version"`
	EventID       string          `json:"event_id"`
	Type          FeedControlType `json:"type"`
	Symbol        string          `json:"symbol,omitempty"`
	AssetGroup    AssetGroup      `json:"asset_group,omitempty"`
	Provider      string          `json:"provider,omitempty"`
	FromProvider  string          `json:"from_provider,omitempty"`
	ToProvider    string          `json:"to_provider,omitempty"`
	SourceEpoch   int64           `json:"source_epoch"`
	PrevSequence  int64           `json:"prev_sequence,omitempty"`
	NextSequence  int64           `json:"next_sequence,omitempty"`
	MissingCount  int64           `json:"missing_count,omitempty"`
	Reason        string          `json:"reason"`
	OccurredAtMS  int64           `json:"occurred_at_ms"`
}

// Validate checks control-event required fields.
func (e FeedControlEvent) Validate() error {
	if e.SchemaVersion != SchemaVersion {
		return fmt.Errorf("marketdata/v2: unsupported schema_version %d", e.SchemaVersion)
	}
	if e.EventID == "" {
		return fmt.Errorf("marketdata/v2: event_id is required")
	}
	switch e.Type {
	case ControlGap, ControlStale, ControlPause, ControlResume, ControlSourceSwitch:
	default:
		return fmt.Errorf("marketdata/v2: invalid control type %q", e.Type)
	}
	if e.Reason == "" {
		return fmt.Errorf("marketdata/v2: reason is required")
	}
	if e.OccurredAtMS <= 0 {
		return fmt.Errorf("marketdata/v2: occurred_at_ms is required")
	}
	if e.Type == ControlGap && e.MissingCount <= 0 {
		return fmt.Errorf("marketdata/v2: gap events require missing_count > 0")
	}
	if e.Type == ControlSourceSwitch && (e.FromProvider == "" || e.ToProvider == "") {
		return fmt.Errorf("marketdata/v2: source_switch requires from_provider and to_provider")
	}
	return nil
}

// DetectSequenceGap returns a gap control event when sequence jumps within an epoch.
// A gap is distinguishable from valid continuity: missing_count is always > 0.
func DetectSequenceGap(prev, next TickEvent, eventID string, nowMS int64) (FeedControlEvent, bool, error) {
	if prev.Symbol != next.Symbol || prev.SourceEpoch != next.SourceEpoch {
		return FeedControlEvent{}, false, nil
	}
	if next.Sequence <= prev.Sequence {
		return FeedControlEvent{}, false, fmt.Errorf("marketdata/v2: non-increasing sequence within source_epoch")
	}
	missing := next.Sequence - prev.Sequence - 1
	if missing <= 0 {
		return FeedControlEvent{}, false, nil
	}
	ev := FeedControlEvent{
		SchemaVersion: SchemaVersion,
		EventID:       eventID,
		Type:          ControlGap,
		Symbol:        next.Symbol,
		AssetGroup:    next.AssetGroup,
		Provider:      next.Provider,
		SourceEpoch:   next.SourceEpoch,
		PrevSequence:  prev.Sequence,
		NextSequence:  next.Sequence,
		MissingCount:  missing,
		Reason:        "sequence_gap",
		OccurredAtMS:  nowMS,
	}
	if err := ev.Validate(); err != nil {
		return FeedControlEvent{}, false, err
	}
	return ev, true, nil
}
