package v1

import (
	"fmt"
	"time"
)

// EngineSnapshotEvent is Engine-owned durable trading state evidence.
type EngineSnapshotEvent struct {
	EventID          string    `json:"event_id"`
	CorrelationID    string    `json:"correlation_id"`
	SchemaName       string    `json:"schema_name"`
	SchemaVersion    int       `json:"schema_version"`
	AggregateVersion int64     `json:"aggregate_version"`
	OrderingKey      string    `json:"ordering_key"`
	OccurredAt       time.Time `json:"occurred_at"`

	ContestID      string `json:"contest_id"`
	SnapshotID     string `json:"snapshot_id"`
	OpenOrders     int    `json:"open_orders"`
	OpenPositions  int    `json:"open_positions"`
	ActiveParticipants int `json:"active_participants"`
}

// ContestResultEvent is the Engine final result evidence for Settlement.
type ContestResultEvent struct {
	EventID          string    `json:"event_id"`
	CorrelationID    string    `json:"correlation_id"`
	SchemaName       string    `json:"schema_name"`
	SchemaVersion    int       `json:"schema_version"`
	AggregateVersion int64     `json:"aggregate_version"`
	OrderingKey      string    `json:"ordering_key"`
	OccurredAt       time.Time `json:"occurred_at"`

	ContestID     string              `json:"contest_id"`
	ResultID      string              `json:"result_id"`
	ParticipantCount int              `json:"participant_count"`
	FinalScores   []ParticipantScore  `json:"final_scores"`
}

// ParticipantScore is one Engine-owned final score row (fixed-point units later via ENG-002).
type ParticipantScore struct {
	ParticipantID string `json:"participant_id"`
	UserID        string `json:"user_id"`
	ScoreUnits    int64  `json:"score_units"`
	ScoreScale    int    `json:"score_scale"`
	Rank          int    `json:"rank,omitempty"`
}

// Validate checks EngineSnapshotEvent.
func (e EngineSnapshotEvent) Validate() error {
	if err := requireMeta(e.EventID, e.CorrelationID, e.SchemaName, e.SchemaVersion, e.OrderingKey, e.OccurredAt); err != nil {
		return err
	}
	if e.ContestID == "" || e.SnapshotID == "" {
		return fmt.Errorf("engine_snapshot: contest_id and snapshot_id required")
	}
	return nil
}

// Validate checks ContestResultEvent.
func (e ContestResultEvent) Validate() error {
	if err := requireMeta(e.EventID, e.CorrelationID, e.SchemaName, e.SchemaVersion, e.OrderingKey, e.OccurredAt); err != nil {
		return err
	}
	if e.ContestID == "" || e.ResultID == "" {
		return fmt.Errorf("contest_result: contest_id and result_id required")
	}
	return nil
}
