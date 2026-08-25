// Package settlement is the sole contest finalization and prize-credit owner (ARCH-005).
package settlement

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
)

var (
	ErrAlreadySettled = errors.New("settlement: contest already settled")
	ErrNotOwner       = errors.New("settlement: caller is not finalization owner")
)

// Service owns final completion and prize payouts.
type Service interface {
	modules.Service
	IsSoleFinalizationOwner() bool
	SettleContest(ctx context.Context, contestID string) error
	IsSettled(ctx context.Context, contestID string) (bool, error)
	Jobs() []modules.Job
}

type repository interface {
	Ping(ctx context.Context) error
	MarkSettled(ctx context.Context, contestID string) error
	IsSettled(ctx context.Context, contestID string) (bool, error)
}

type memoryRepository struct {
	mu      sync.Mutex
	settled map[string]struct{}
}

func newMemoryRepository() *memoryRepository {
	return &memoryRepository{settled: map[string]struct{}{}}
}

func (r *memoryRepository) Ping(context.Context) error { return nil }

func (r *memoryRepository) MarkSettled(_ context.Context, contestID string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if _, ok := r.settled[contestID]; ok {
		return ErrAlreadySettled
	}
	r.settled[contestID] = struct{}{}
	return nil
}

func (r *memoryRepository) IsSettled(_ context.Context, contestID string) (bool, error) {
	r.mu.Lock()
	defer r.mu.Unlock()
	_, ok := r.settled[contestID]
	return ok, nil
}

type service struct {
	repo repository
}

// New constructs the settlement module (sole finalization owner).
func New() Service {
	return &service{repo: newMemoryRepository()}
}

func (s *service) Name() string { return "settlement" }

func (s *service) Ready(ctx context.Context) error { return s.repo.Ping(ctx) }

func (s *service) IsSoleFinalizationOwner() bool { return true }

func (s *service) SettleContest(ctx context.Context, contestID string) error {
	return s.repo.MarkSettled(ctx, contestID)
}

func (s *service) IsSettled(ctx context.Context, contestID string) (bool, error) {
	return s.repo.IsSettled(ctx, contestID)
}

func (s *service) Jobs() []modules.Job {
	return []modules.Job{&settleJob{svc: s}}
}

type settleJob struct {
	svc     *service
	running atomic.Bool
}

func (j *settleJob) Name() string { return "settlement.orchestrator" }

func (j *settleJob) Start(ctx context.Context) error {
	j.running.Store(true)
	go func() {
		<-ctx.Done()
		j.running.Store(false)
	}()
	return nil
}

func (j *settleJob) Stop(context.Context) error {
	j.running.Store(false)
	return nil
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
