// ARCH-006: Trading Engine owns the engine schema only.
// Cross-system communication uses transactional outbox/inbox; no SQL into platform or market_data.
package server

import dbevents "github.com/Parsaeffatravesh/tragge/packages/db/events"

// EngineSchemaOwner is the ADR-0001 schema owner for this bounded system.
const EngineSchemaOwner = dbevents.OwnerEngine

// NewEngineEventStore returns the Engine-owned outbox/inbox store.
// Postgres-backed adapter cutover remains tracked as ARCH006-POSTGRES-PERMISSIONS-E2E.
func NewEngineEventStore() (dbevents.Store, error) {
	return dbevents.NewMemoryStore(EngineSchemaOwner)
}

// ForbidCrossSchemaSQL documents the ARCH-006 grant boundary for Engine runtimes.
func ForbidCrossSchemaSQL(target dbevents.SchemaOwner) error {
	return dbevents.CrossSchemaAccessForbidden(EngineSchemaOwner, target)
}
