package server

import (
	"testing"

	dbevents "github.com/Parsaeffatravesh/tragge/packages/db/events"
)

func TestEngineSchemaOwnerBoundary(t *testing.T) {
	if EngineSchemaOwner != dbevents.OwnerEngine {
		t.Fatalf("expected engine owner")
	}
	store, err := NewEngineEventStore()
	if err != nil {
		t.Fatal(err)
	}
	if store.Owner() != dbevents.OwnerEngine {
		t.Fatalf("store owner=%s", store.Owner())
	}
	if err := ForbidCrossSchemaSQL(dbevents.OwnerPlatform); err == nil {
		t.Fatal("expected cross-schema forbid")
	}
	if err := ForbidCrossSchemaSQL(dbevents.OwnerEngine); err != nil {
		t.Fatal(err)
	}
}
