// Package notification owns notification enqueue via transactional outbox (ARCH-003).
package notification

import (
	"context"
	"sync"
	"sync/atomic"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
)

// OutboxEvent is a pending notification/event row written in the same TX as domain state.
type OutboxEvent struct {
	ID      string
	Topic   string
	Payload string
}

// Service is the notification application surface.
type Service interface {
	modules.Service
	// EnqueueOutbox records an event for async delivery (transactional outbox port).
	EnqueueOutbox(ctx context.Context, ev OutboxEvent) error
	// PendingOutbox returns undelivered events (test/inspection).
	PendingOutbox(ctx context.Context) ([]OutboxEvent, error)
	Jobs() []modules.Job
}

type repository interface {
	Ping(ctx context.Context) error
	Enqueue(ctx context.Context, ev OutboxEvent) error
	ListPending(ctx context.Context) ([]OutboxEvent, error)
}

type memoryRepository struct {
	mu    sync.Mutex
	pending []OutboxEvent
}

func (r *memoryRepository) Ping(context.Context) error { return nil }

func (r *memoryRepository) Enqueue(_ context.Context, ev OutboxEvent) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.pending = append(r.pending, ev)
	return nil
}

func (r *memoryRepository) ListPending(context.Context) ([]OutboxEvent, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	out := make([]OutboxEvent, len(r.pending))
	copy(out, r.pending)
	return out, nil
}

type service struct {
	repo repository
}

// New constructs the notification module with an in-memory outbox.
func New() Service {
	return &service{repo: &memoryRepository{}}
}

func (s *service) Name() string { return "notification" }

func (s *service) Ready(ctx context.Context) error { return s.repo.Ping(ctx) }

func (s *service) EnqueueOutbox(ctx context.Context, ev OutboxEvent) error {
	return s.repo.Enqueue(ctx, ev)
}

func (s *service) PendingOutbox(ctx context.Context) ([]OutboxEvent, error) {
	return s.repo.ListPending(ctx)
}

func (s *service) Jobs() []modules.Job {
	return []modules.Job{&outboxRelayJob{svc: s}}
}

type outboxRelayJob struct {
	svc     *service
	running atomic.Bool
}

func (j *outboxRelayJob) Name() string { return "notification.outbox_relay" }

func (j *outboxRelayJob) Start(ctx context.Context) error {
	j.running.Store(true)
	go func() {
		<-ctx.Done()
		j.running.Store(false)
	}()
	return nil
}

func (j *outboxRelayJob) Stop(context.Context) error {
	j.running.Store(false)
	return nil
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
