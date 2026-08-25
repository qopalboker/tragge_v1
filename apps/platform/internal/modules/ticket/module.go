// Package ticket owns support-ticket application ports with outbox hooks (ARCH-003).
package ticket

import (
	"context"
	"errors"
	"sync"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/notification"
)

var ErrNotFound = errors.New("ticket: not found")

// Ticket is a minimal support ticket record.
type Ticket struct {
	ID       string
	UserID   string
	Subject  string
	Status   string
}

// Service is the ticket application surface.
type Service interface {
	modules.Service
	Create(ctx context.Context, t Ticket) error
	Get(ctx context.Context, id string) (*Ticket, error)
}

type repository interface {
	Ping(ctx context.Context) error
	Create(ctx context.Context, t Ticket) error
	Get(ctx context.Context, id string) (*Ticket, error)
}

type memoryRepository struct {
	mu   sync.RWMutex
	byID map[string]Ticket
}

func newMemoryRepository() *memoryRepository {
	return &memoryRepository{byID: map[string]Ticket{}}
}

func (r *memoryRepository) Ping(context.Context) error { return nil }

func (r *memoryRepository) Create(_ context.Context, t Ticket) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.byID[t.ID] = t
	return nil
}

func (r *memoryRepository) Get(_ context.Context, id string) (*Ticket, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	t, ok := r.byID[id]
	if !ok {
		return nil, ErrNotFound
	}
	cp := t
	return &cp, nil
}

type service struct {
	repo     repository
	notifier notification.Service
}

// New constructs the ticket module. Optional notifier receives outbox events on create.
func New(notifier notification.Service) Service {
	return &service{repo: newMemoryRepository(), notifier: notifier}
}

func (s *service) Name() string { return "ticket" }

func (s *service) Ready(ctx context.Context) error { return s.repo.Ping(ctx) }

func (s *service) Create(ctx context.Context, t Ticket) error {
	if err := s.repo.Create(ctx, t); err != nil {
		return err
	}
	if s.notifier != nil {
		_ = s.notifier.EnqueueOutbox(ctx, notification.OutboxEvent{
			ID:      "ticket-created-" + t.ID,
			Topic:   "tickets.v1.created",
			Payload: t.ID,
		})
	}
	return nil
}

func (s *service) Get(ctx context.Context, id string) (*Ticket, error) {
	return s.repo.Get(ctx, id)
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
