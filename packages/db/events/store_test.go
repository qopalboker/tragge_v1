package events

import (
	"context"
	"testing"
	"time"

	envelopev1 "github.com/Parsaeffatravesh/tragge/packages/contracts/envelope/v1"
)

func sampleEnvelope(id string, version int64) envelopev1.Envelope {
	return envelopev1.Envelope{
		EventID:          id,
		CorrelationID:    "corr-1",
		SchemaName:       "contest_state",
		SchemaVersion:    1,
		AggregateType:    "contest",
		AggregateID:      "c1",
		AggregateVersion: version,
		OrderingKey:      "contest:c1",
		OccurredAt:       time.Now().UTC(),
		Payload:          MustJSON(map[string]any{"state": "ended"}),
	}
}

func TestOutboxSurvivesCommitCrashWindow(t *testing.T) {
	store, err := NewMemoryStore(OwnerPlatform)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()

	tx, err := store.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if err := tx.InsertOutbox(ctx, sampleEnvelope("e-crash", 1)); err != nil {
		t.Fatal(err)
	}
	// Crash before commit: rollback discards staged work.
	if err := tx.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	pending, err := store.PendingOutbox(ctx, 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(pending) != 0 {
		t.Fatalf("expected no pending after crash-before-commit, got %d", len(pending))
	}

	tx2, err := store.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if err := tx2.InsertOutbox(ctx, sampleEnvelope("e-ok", 2)); err != nil {
		t.Fatal(err)
	}
	if err := tx2.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	// Process "crash" after commit: new store handle is not needed; durability is in store.
	pending, err = store.PendingOutbox(ctx, 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(pending) != 1 || pending[0].Envelope.EventID != "e-ok" {
		t.Fatalf("expected committed outbox to survive, got %+v", pending)
	}
}

func TestInboxDedupesReplay(t *testing.T) {
	store, err := NewMemoryStore(OwnerEngine)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	env := sampleEnvelope("e-replay", 1)

	tx, err := store.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	inserted, err := tx.RecordInbox(ctx, "leaderboard-projector", env)
	if err != nil || !inserted {
		t.Fatalf("first insert: inserted=%v err=%v", inserted, err)
	}
	if err := tx.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	tx2, err := store.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	inserted, err = tx2.RecordInbox(ctx, "leaderboard-projector", env)
	if err != nil {
		t.Fatal(err)
	}
	if inserted {
		t.Fatal("expected duplicate inbox event to be rejected")
	}
	_ = tx2.Rollback(ctx)

	ok, err := store.HasInbox(ctx, "leaderboard-projector", env.EventID)
	if err != nil || !ok {
		t.Fatalf("expected inbox presence, ok=%v err=%v", ok, err)
	}
}

func TestOrderingKeyAggregateVersionSort(t *testing.T) {
	store, err := NewMemoryStore(OwnerMarketData)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	tx, err := store.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	_ = tx.InsertOutbox(ctx, sampleEnvelope("e2", 2))
	_ = tx.InsertOutbox(ctx, sampleEnvelope("e1", 1))
	if err := tx.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	pending, err := store.PendingOutbox(ctx, 10)
	if err != nil {
		t.Fatal(err)
	}
	if len(pending) != 2 {
		t.Fatalf("expected 2, got %d", len(pending))
	}
	if pending[0].Envelope.AggregateVersion != 1 || pending[1].Envelope.AggregateVersion != 2 {
		t.Fatalf("expected aggregate_version order, got %d then %d",
			pending[0].Envelope.AggregateVersion, pending[1].Envelope.AggregateVersion)
	}
}

func TestCrossSchemaAccessForbidden(t *testing.T) {
	if err := CrossSchemaAccessForbidden(OwnerPlatform, OwnerPlatform); err != nil {
		t.Fatal(err)
	}
	if err := CrossSchemaAccessForbidden(OwnerPlatform, OwnerEngine); err == nil {
		t.Fatal("expected cross-schema access to be forbidden")
	}
}

func TestMigrationChecksumMismatch(t *testing.T) {
	store, err := NewMemoryStore(OwnerPlatform)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	rec := MigrationRecord{
		MigrationID:    "0002_platform_outbox_inbox",
		ChecksumSHA256: "abc",
		AppliedBy:      "test",
		DurationMS:     1,
	}
	if err := store.RecordMigration(ctx, rec); err != nil {
		t.Fatal(err)
	}
	rec.ChecksumSHA256 = "def"
	if err := store.RecordMigration(ctx, rec); err == nil {
		t.Fatal("expected checksum mismatch")
	}
}

func TestDeadLetterQuarantine(t *testing.T) {
	store, err := NewMemoryStore(OwnerPlatform)
	if err != nil {
		t.Fatal(err)
	}
	ctx := context.Background()
	env := sampleEnvelope("e-bad", 1)
	tx, err := store.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if err := tx.DeadLetter(ctx, "inbox", "projector", "incompatible schema", env); err != nil {
		t.Fatal(err)
	}
	if err := tx.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	dead, err := store.DeadLetters(ctx)
	if err != nil || len(dead) != 1 {
		t.Fatalf("expected 1 dead letter, got %d err=%v", len(dead), err)
	}
}
