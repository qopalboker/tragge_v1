// Package events owns Platform schema-bound transactional outbox/inbox ports (ARCH-006).
package events

import (
	"context"
	"fmt"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
	envelopev1 "github.com/Parsaeffatravesh/tragge/packages/contracts/envelope/v1"
	dbevents "github.com/Parsaeffatravesh/tragge/packages/db/events"
)

// Service is the Platform events application surface.
type Service interface {
	modules.Service
	// SchemaOwner returns the Platform schema owner token.
	SchemaOwner() dbevents.SchemaOwner
	// Store exposes the durable outbox/inbox store for this owner.
	Store() dbevents.Store
	// PublishInTx writes an envelope to the Platform outbox inside a TX.
	PublishInTx(ctx context.Context, env envelopev1.Envelope) error
	// ConsumeOnce records an inbox identity; false means duplicate replay.
	ConsumeOnce(ctx context.Context, consumer string, env envelopev1.Envelope) (bool, error)
	Jobs() []modules.Job
}

type service struct {
	store dbevents.Store
}

// New constructs the Platform events module with an in-memory durable store.
func New() (Service, error) {
	store, err := dbevents.NewMemoryStore(dbevents.OwnerPlatform)
	if err != nil {
		return nil, err
	}
	return &service{store: store}, nil
}

func (s *service) Name() string { return "events" }

func (s *service) Ready(context.Context) error {
	if s.store == nil {
		return fmt.Errorf("events: store not configured")
	}
	return nil
}

func (s *service) SchemaOwner() dbevents.SchemaOwner { return s.store.Owner() }

func (s *service) Store() dbevents.Store { return s.store }

func (s *service) PublishInTx(ctx context.Context, env envelopev1.Envelope) error {
	tx, err := s.store.Begin(ctx)
	if err != nil {
		return err
	}
	if err := tx.InsertOutbox(ctx, env); err != nil {
		_ = tx.Rollback(ctx)
		return err
	}
	return tx.Commit(ctx)
}

func (s *service) ConsumeOnce(ctx context.Context, consumer string, env envelopev1.Envelope) (bool, error) {
	tx, err := s.store.Begin(ctx)
	if err != nil {
		return false, err
	}
	inserted, err := tx.RecordInbox(ctx, consumer, env)
	if err != nil {
		_ = tx.Rollback(ctx)
		return false, err
	}
	if !inserted {
		_ = tx.Rollback(ctx)
		return false, nil
	}
	if err := tx.Commit(ctx); err != nil {
		return false, err
	}
	return true, nil
}

func (s *service) Jobs() []modules.Job {
	return []modules.Job{&outboxRelayJob{store: s.store}}
}

type outboxRelayJob struct {
	store   dbevents.Store
	running bool
}

func (j *outboxRelayJob) Name() string { return "events.outbox_relay" }

func (j *outboxRelayJob) Start(ctx context.Context) error {
	j.running = true
	go func() {
		<-ctx.Done()
		j.running = false
	}()
	return nil
}

func (j *outboxRelayJob) Stop(context.Context) error {
	j.running = false
	return nil
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
