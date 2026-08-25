package v1

import (
	"encoding/json"
	"testing"
	"time"
)

func TestEnvelopeValidate(t *testing.T) {
	ok := Envelope{
		EventID:          "e1",
		CorrelationID:    "c1",
		SchemaName:       SchemaName,
		SchemaVersion:    SchemaVersion,
		AggregateType:    "contest",
		AggregateID:      "a1",
		AggregateVersion: 1,
		OrderingKey:      "contest:a1",
		OccurredAt:       time.Now().UTC(),
		Payload:          json.RawMessage(`{"ok":true}`),
	}
	if err := ok.Validate(); err != nil {
		t.Fatalf("expected valid envelope: %v", err)
	}

	bad := ok
	bad.EventID = ""
	if err := bad.Validate(); err == nil {
		t.Fatal("expected missing event_id to fail")
	}
}
