// Package events provides bounded-system schema ownership helpers and an
// in-process transactional outbox/inbox store used until Postgres adapters
// are wired at cutover (ARCH-006).
package events

import "fmt"

// SchemaOwner is one of the three ADR-0001 schema owners.
type SchemaOwner string

const (
	OwnerPlatform   SchemaOwner = "platform"
	OwnerEngine     SchemaOwner = "engine"
	OwnerMarketData SchemaOwner = "market_data"
)

// Validate reports whether owner is a known schema owner.
func (o SchemaOwner) Validate() error {
	switch o {
	case OwnerPlatform, OwnerEngine, OwnerMarketData:
		return nil
	default:
		return fmt.Errorf("events: unknown schema owner %q", o)
	}
}

// OutboxTable returns the schema-qualified outbox table name.
func (o SchemaOwner) OutboxTable() string {
	return string(o) + ".outbox"
}

// InboxTable returns the schema-qualified inbox table name.
func (o SchemaOwner) InboxTable() string {
	return string(o) + ".inbox"
}

// DeadLetterTable returns the schema-qualified dead-letter table name.
func (o SchemaOwner) DeadLetterTable() string {
	return string(o) + ".dead_letter"
}

// MigrationsTable returns the schema-qualified migration checksum table.
func (o SchemaOwner) MigrationsTable() string {
	return string(o) + ".schema_migrations"
}

// CrossSchemaAccessForbidden documents that runtime SQL must not cross owners.
func CrossSchemaAccessForbidden(from, to SchemaOwner) error {
	if from == to {
		return nil
	}
	return fmt.Errorf(
		"events: cross-schema SQL access forbidden from %s to %s; use outbox/inbox events",
		from, to,
	)
}
