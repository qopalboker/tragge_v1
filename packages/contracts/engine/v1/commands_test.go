package v1

import (
	"encoding/json"
	"os"
	"path/filepath"
	"runtime"
	"testing"
	"time"
)

func TestContestConfigurationRejectsEmpty(t *testing.T) {
	var c ContestConfigurationCommand
	if err := c.Validate(); err == nil {
		t.Fatal("expected validation failure")
	}
}

func TestContestConfigurationGoldenRoundTrip(t *testing.T) {
	c := ContestConfigurationCommand{
		EventID:          "11111111-1111-1111-1111-111111111111",
		CorrelationID:    "22222222-2222-2222-2222-222222222222",
		SchemaName:       "contest_configuration",
		SchemaVersion:    ContractVersion,
		AggregateVersion: 1,
		OrderingKey:      "contest:c1",
		OccurredAt:       time.Date(2026, 8, 25, 12, 0, 0, 0, time.UTC),
		ContestID:        "c1",
		AssetClass:       "forex",
		Symbols:          []string{"EURUSD"},
		QtyAllocation:    100000,
		DurationMinutes:  30,
		PlatformFeeBPS:   2000,
		IsFreePractice:   false,
		JoinCutoffAt:     time.Date(2026, 8, 25, 12, 0, 0, 0, time.UTC),
		TradingStartsAt:  time.Date(2026, 8, 25, 12, 5, 0, 0, time.UTC),
		TradingEndsAt:    time.Date(2026, 8, 25, 12, 35, 0, 0, time.UTC),
	}
	if err := c.Validate(); err != nil {
		t.Fatal(err)
	}
	raw, err := json.Marshal(c)
	if err != nil {
		t.Fatal(err)
	}
	// Policy: target engine contracts must not carry banned product fields.
	if containsBanned(string(raw)) {
		t.Fatalf("banned product field present in payload: %s", raw)
	}

	_, thisFile, _, _ := runtime.Caller(0)
	golden := filepath.Join(filepath.Dir(thisFile), "testdata", "contest_configuration.v1.json")
	want, err := os.ReadFile(golden)
	if err != nil {
		t.Fatal(err)
	}
	var decoded ContestConfigurationCommand
	if err := json.Unmarshal(want, &decoded); err != nil {
		t.Fatal(err)
	}
	if err := decoded.Validate(); err != nil {
		t.Fatal(err)
	}
	_ = raw
}

func TestOrderAndLifecycleCommands(t *testing.T) {
	now := time.Now().UTC()
	order := OrderCommand{
		EventID: "o1", CorrelationID: "c", SchemaName: "order_command", SchemaVersion: 1,
		AggregateVersion: 1, OrderingKey: "contest:c1", OccurredAt: now,
		OrderID: "ord1", ContestID: "c1", UserID: "u1", ParticipantID: "p1",
		Symbol: "EURUSD", Side: "buy", OrderType: "market", Qty: 10,
	}
	if err := order.Validate(); err != nil {
		t.Fatal(err)
	}
	freeze := FreezeTradingCommand{
		EventID: "f1", CorrelationID: "c", SchemaName: "freeze_trading", SchemaVersion: 1,
		AggregateVersion: 2, OrderingKey: "contest:c1", OccurredAt: now, ContestID: "c1", Reason: "ending",
	}
	if err := freeze.Validate(); err != nil {
		t.Fatal(err)
	}
	closeCmd := CloseContestCommand{
		EventID: "x1", CorrelationID: "c", SchemaName: "close_contest", SchemaVersion: 1,
		AggregateVersion: 3, OrderingKey: "contest:c1", OccurredAt: now, ContestID: "c1", Reason: "ended",
	}
	if err := closeCmd.Validate(); err != nil {
		t.Fatal(err)
	}
	act := ParticipantActivationCommand{
		EventID: "a1", CorrelationID: "c", SchemaName: "participant_activation", SchemaVersion: 1,
		AggregateVersion: 1, OrderingKey: "contest:c1", OccurredAt: now,
		ContestID: "c1", UserID: "u1", ParticipantID: "p1", QtyAllocation: 100000,
	}
	if err := act.Validate(); err != nil {
		t.Fatal(err)
	}
	snap := EngineSnapshotEvent{
		EventID: "s1", CorrelationID: "c", SchemaName: "engine_snapshot", SchemaVersion: 1,
		AggregateVersion: 4, OrderingKey: "contest:c1", OccurredAt: now,
		ContestID: "c1", SnapshotID: "snap1",
	}
	if err := snap.Validate(); err != nil {
		t.Fatal(err)
	}
	result := ContestResultEvent{
		EventID: "r1", CorrelationID: "c", SchemaName: "contest_result", SchemaVersion: 1,
		AggregateVersion: 5, OrderingKey: "contest:c1", OccurredAt: now,
		ContestID: "c1", ResultID: "res1", ParticipantCount: 1,
		FinalScores: []ParticipantScore{{ParticipantID: "p1", UserID: "u1", ScoreUnits: 0, ScoreScale: 0}},
	}
	if err := result.Validate(); err != nil {
		t.Fatal(err)
	}
}

func containsBanned(s string) bool {
	for _, banned := range []string{"commission_rate", "max_participants", "participant_capacity", "second_chance"} {
		if jsonContainsKey(s, banned) {
			return true
		}
	}
	return false
}

func jsonContainsKey(s, key string) bool {
	return len(s) > 0 && (containsLiteral(s, `"`+key+`"`))
}

func containsLiteral(s, lit string) bool {
	return len(s) >= len(lit) && (stringIndex(s, lit) >= 0)
}

func stringIndex(s, lit string) int {
	for i := 0; i+len(lit) <= len(s); i++ {
		if s[i:i+len(lit)] == lit {
			return i
		}
	}
	return -1
}
