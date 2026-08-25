package server

import (
	"testing"

	dbevents "github.com/Parsaeffatravesh/tragge/packages/db/events"
)

func TestMarketDataSchemaOwnerBoundary(t *testing.T) {
	if MarketDataSchemaOwner != dbevents.OwnerMarketData {
		t.Fatalf("expected market_data owner")
	}
	store, err := NewMarketDataEventStore()
	if err != nil {
		t.Fatal(err)
	}
	if store.Owner() != dbevents.OwnerMarketData {
		t.Fatalf("store owner=%s", store.Owner())
	}
	if err := ForbidCrossSchemaSQL(dbevents.OwnerEngine); err == nil {
		t.Fatal("expected cross-schema forbid")
	}
}
