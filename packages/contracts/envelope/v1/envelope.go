// Package v1 defines the ARCH-006 cross-system command/event envelope.
package v1

import (
	"encoding/json"
	"fmt"
	"time"
)

// SchemaName is the canonical envelope contract name.
const SchemaName = "envelope"

// SchemaVersion is the envelope major version introduced by ARCH-006.
const SchemaVersion = 1

// Envelope wraps every cross-bounded-system command or event (ADR-0001).
type Envelope struct {
	EventID          string          `json:"event_id"`
	CorrelationID    string          `json:"correlation_id"`
	CausationID      string          `json:"causation_id,omitempty"`
	SchemaName       string          `json:"schema_name"`
	SchemaVersion    int             `json:"schema_version"`
	AggregateType    string          `json:"aggregate_type"`
	AggregateID      string          `json:"aggregate_id"`
	AggregateVersion int64           `json:"aggregate_version"`
	OrderingKey      string          `json:"ordering_key"`
	OccurredAt       time.Time       `json:"occurred_at"`
	Payload          json.RawMessage `json:"payload"`
}

// Validate checks required ADR-0001 envelope fields.
func (e Envelope) Validate() error {
	if e.EventID == "" {
		return fmt.Errorf("envelope: event_id is required")
	}
	if e.CorrelationID == "" {
		return fmt.Errorf("envelope: correlation_id is required")
	}
	if e.SchemaName == "" {
		return fmt.Errorf("envelope: schema_name is required")
	}
	if e.SchemaVersion <= 0 {
		return fmt.Errorf("envelope: schema_version must be > 0")
	}
	if e.AggregateType == "" || e.AggregateID == "" {
		return fmt.Errorf("envelope: aggregate_type and aggregate_id are required")
	}
	if e.AggregateVersion < 0 {
		return fmt.Errorf("envelope: aggregate_version must be >= 0")
	}
	if e.OrderingKey == "" {
		return fmt.Errorf("envelope: ordering_key is required")
	}
	if e.OccurredAt.IsZero() {
		return fmt.Errorf("envelope: occurred_at is required")
	}
	if len(e.Payload) == 0 {
		return fmt.Errorf("envelope: payload is required")
	}
	return nil
}
