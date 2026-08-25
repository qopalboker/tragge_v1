package events

import (
	"context"
	"testing"
	"time"

	envelopev1 "github.com/Parsaeffatravesh/tragge/packages/contracts/envelope/v1"
	dbevents "github.com/Parsaeffatravesh/tragge/packages/db/events"
)

func TestPlatformEventsPublishAndConsume(t *testing.T) {
	svc, err := New()
	if err != nil {
		t.Fatal(err)
	}
	if svc.SchemaOwner() != dbevents.OwnerPlatform {
		t.Fatalf("expected platform owner, got %s", svc.SchemaOwner())
	}
	ctx := context.Background()
	env := envelopev1.Envelope{
		EventID:          "plat-1",
		CorrelationID:    "corr",
		SchemaName:       envelopev1.SchemaName,
		SchemaVersion:    envelopev1.SchemaVersion,
		AggregateType:    "ticket",
		AggregateID:      "t1",
		AggregateVersion: 1,
		OrderingKey:      "ticket:t1",
		OccurredAt:       time.Now().UTC(),
		Payload:          dbevents.MustJSON(map[string]string{"kind": "created"}),
	}
	if err := svc.PublishInTx(ctx, env); err != nil {
		t.Fatal(err)
	}
	pending, err := svc.Store().PendingOutbox(ctx, 10)
	if err != nil || len(pending) != 1 {
		t.Fatalf("pending=%d err=%v", len(pending), err)
	}
	ok, err := svc.ConsumeOnce(ctx, "notification-worker", env)
	if err != nil || !ok {
		t.Fatalf("first consume ok=%v err=%v", ok, err)
	}
	ok, err = svc.ConsumeOnce(ctx, "notification-worker", env)
	if err != nil || ok {
		t.Fatalf("replay should dedupe, ok=%v err=%v", ok, err)
	}
}
