// ARCH-006: Market Data owns the market_data schema only.
// Cross-system communication uses transactional outbox/inbox; no SQL into platform or engine.
package server

import dbevents "github.com/Parsaeffatravesh/tragge/packages/db/events"

// MarketDataSchemaOwner is the ADR-0001 schema owner for this bounded system.
const MarketDataSchemaOwner = dbevents.OwnerMarketData

// NewMarketDataEventStore returns the Market Data-owned outbox/inbox store.
// Postgres-backed adapter cutover remains tracked as ARCH006-POSTGRES-PERMISSIONS-E2E.
func NewMarketDataEventStore() (dbevents.Store, error) {
	return dbevents.NewMemoryStore(MarketDataSchemaOwner)
}

// ForbidCrossSchemaSQL documents the ARCH-006 grant boundary for Market Data runtimes.
func ForbidCrossSchemaSQL(target dbevents.SchemaOwner) error {
	return dbevents.CrossSchemaAccessForbidden(MarketDataSchemaOwner, target)
}
