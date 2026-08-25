// Package v1 defines Platform → Trading Engine commands (ENG-001).
// Target contracts use platform_fee_bps only; banned product capacity fields are omitted.
package v1

import (
	"fmt"
	"time"
)

const (
	// ContractFamily identifies this contract set.
	ContractFamily = "engine_platform"
	// ContractVersion is the ENG-001 major version.
	ContractVersion = 1
)

// ContestConfigurationCommand delivers immutable contest trading parameters to Engine.
type ContestConfigurationCommand struct {
	EventID          string    `json:"event_id"`
	CorrelationID    string    `json:"correlation_id"`
	CausationID      string    `json:"causation_id,omitempty"`
	SchemaName       string    `json:"schema_name"`
	SchemaVersion    int       `json:"schema_version"`
	AggregateVersion int64     `json:"aggregate_version"`
	OrderingKey      string    `json:"ordering_key"`
	OccurredAt       time.Time `json:"occurred_at"`

	ContestID         string   `json:"contest_id"`
	AssetClass        string   `json:"asset_class"`
	Symbols           []string `json:"symbols"`
	QtyAllocation     int64    `json:"qty_allocation"`
	DurationMinutes   int      `json:"duration_minutes"`
	PlatformFeeBPS    int      `json:"platform_fee_bps"`
	IsFreePractice    bool     `json:"is_free_practice"`
	JoinCutoffAt      time.Time `json:"join_cutoff_at"`
	TradingStartsAt   time.Time `json:"trading_starts_at"`
	TradingEndsAt     time.Time `json:"trading_ends_at"`
}

// ParticipantActivationCommand activates a participant session inside Engine.
type ParticipantActivationCommand struct {
	EventID          string    `json:"event_id"`
	CorrelationID    string    `json:"correlation_id"`
	CausationID      string    `json:"causation_id,omitempty"`
	SchemaName       string    `json:"schema_name"`
	SchemaVersion    int       `json:"schema_version"`
	AggregateVersion int64     `json:"aggregate_version"`
	OrderingKey      string    `json:"ordering_key"`
	OccurredAt       time.Time `json:"occurred_at"`

	ContestID     string `json:"contest_id"`
	UserID        string `json:"user_id"`
	ParticipantID string `json:"participant_id"`
	QtyAllocation int64  `json:"qty_allocation"`
}

// OrderCommand is the Platform-validated order intent for Engine execution.
type OrderCommand struct {
	EventID          string    `json:"event_id"`
	CorrelationID    string    `json:"correlation_id"`
	CausationID      string    `json:"causation_id,omitempty"`
	SchemaName       string    `json:"schema_name"`
	SchemaVersion    int       `json:"schema_version"`
	AggregateVersion int64     `json:"aggregate_version"`
	OrderingKey      string    `json:"ordering_key"`
	OccurredAt       time.Time `json:"occurred_at"`

	OrderID       string `json:"order_id"`
	ContestID     string `json:"contest_id"`
	UserID        string `json:"user_id"`
	ParticipantID string `json:"participant_id"`
	Symbol        string `json:"symbol"`
	Side          string `json:"side"`
	OrderType     string `json:"order_type"`
	Qty           int64  `json:"qty"`
	ClientOrderID string `json:"client_order_id,omitempty"`
}

// FreezeTradingCommand freezes order entry for a contest (Engine-local).
type FreezeTradingCommand struct {
	EventID          string    `json:"event_id"`
	CorrelationID    string    `json:"correlation_id"`
	SchemaName       string    `json:"schema_name"`
	SchemaVersion    int       `json:"schema_version"`
	AggregateVersion int64     `json:"aggregate_version"`
	OrderingKey      string    `json:"ordering_key"`
	OccurredAt       time.Time `json:"occurred_at"`

	ContestID string `json:"contest_id"`
	Reason    string `json:"reason"`
}

// CloseContestCommand ends trading and requests Engine result production.
type CloseContestCommand struct {
	EventID          string    `json:"event_id"`
	CorrelationID    string    `json:"correlation_id"`
	SchemaName       string    `json:"schema_name"`
	SchemaVersion    int       `json:"schema_version"`
	AggregateVersion int64     `json:"aggregate_version"`
	OrderingKey      string    `json:"ordering_key"`
	OccurredAt       time.Time `json:"occurred_at"`

	ContestID string `json:"contest_id"`
	Reason    string `json:"reason"`
}

func requireMeta(eventID, correlationID, schemaName string, schemaVersion int, orderingKey string, occurredAt time.Time) error {
	if eventID == "" || correlationID == "" {
		return fmt.Errorf("engine contract: event_id and correlation_id are required")
	}
	if schemaName == "" || schemaVersion <= 0 {
		return fmt.Errorf("engine contract: schema_name/version are required")
	}
	if orderingKey == "" || occurredAt.IsZero() {
		return fmt.Errorf("engine contract: ordering_key and occurred_at are required")
	}
	return nil
}

// Validate checks ContestConfigurationCommand required fields and policy bans.
func (c ContestConfigurationCommand) Validate() error {
	if err := requireMeta(c.EventID, c.CorrelationID, c.SchemaName, c.SchemaVersion, c.OrderingKey, c.OccurredAt); err != nil {
		return err
	}
	if c.ContestID == "" || len(c.Symbols) == 0 {
		return fmt.Errorf("contest_configuration: contest_id and symbols are required")
	}
	if c.QtyAllocation <= 0 {
		return fmt.Errorf("contest_configuration: qty_allocation must be > 0")
	}
	if c.PlatformFeeBPS < 0 {
		return fmt.Errorf("contest_configuration: platform_fee_bps must be >= 0")
	}
	return nil
}

// Validate checks ParticipantActivationCommand.
func (c ParticipantActivationCommand) Validate() error {
	if err := requireMeta(c.EventID, c.CorrelationID, c.SchemaName, c.SchemaVersion, c.OrderingKey, c.OccurredAt); err != nil {
		return err
	}
	if c.ContestID == "" || c.UserID == "" || c.ParticipantID == "" {
		return fmt.Errorf("participant_activation: contest_id, user_id, participant_id required")
	}
	if c.QtyAllocation <= 0 {
		return fmt.Errorf("participant_activation: qty_allocation must be > 0")
	}
	return nil
}

// Validate checks OrderCommand.
func (c OrderCommand) Validate() error {
	if err := requireMeta(c.EventID, c.CorrelationID, c.SchemaName, c.SchemaVersion, c.OrderingKey, c.OccurredAt); err != nil {
		return err
	}
	if c.OrderID == "" || c.ContestID == "" || c.UserID == "" || c.Symbol == "" {
		return fmt.Errorf("order_command: order_id, contest_id, user_id, symbol required")
	}
	if c.Qty <= 0 {
		return fmt.Errorf("order_command: qty must be > 0")
	}
	return nil
}

// Validate checks FreezeTradingCommand.
func (c FreezeTradingCommand) Validate() error {
	if err := requireMeta(c.EventID, c.CorrelationID, c.SchemaName, c.SchemaVersion, c.OrderingKey, c.OccurredAt); err != nil {
		return err
	}
	if c.ContestID == "" {
		return fmt.Errorf("freeze_trading: contest_id required")
	}
	return nil
}

// Validate checks CloseContestCommand.
func (c CloseContestCommand) Validate() error {
	if err := requireMeta(c.EventID, c.CorrelationID, c.SchemaName, c.SchemaVersion, c.OrderingKey, c.OccurredAt); err != nil {
		return err
	}
	if c.ContestID == "" {
		return fmt.Errorf("close_contest: contest_id required")
	}
	return nil
}
