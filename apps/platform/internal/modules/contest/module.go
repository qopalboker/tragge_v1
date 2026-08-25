// Package contest owns contest catalog/lifecycle application ports (ARCH-003).
package contest

import (
	"context"
	"errors"
	"sync"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
)

var ErrNotFound = errors.New("contest: not found")

// Contest is a minimal domain projection for Platform APIs.
type Contest struct {
	ID     string
	Status string
	IsFree bool
}

// Service is the contest application surface.
type Service interface {
	modules.Service
	Get(ctx context.Context, id string) (*Contest, error)
	Upsert(ctx context.Context, c Contest) error
}

type repository interface {
	Ping(ctx context.Context) error
	Get(ctx context.Context, id string) (*Contest, error)
	Upsert(ctx context.Context, c Contest) error
}

type memoryRepository struct {
	mu   sync.RWMutex
	byID map[string]Contest
}

func newMemoryRepository() *memoryRepository {
	return &memoryRepository{byID: map[string]Contest{}}
}

func (r *memoryRepository) Ping(context.Context) error { return nil }

func (r *memoryRepository) Get(_ context.Context, id string) (*Contest, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	c, ok := r.byID[id]
	if !ok {
		return nil, ErrNotFound
	}
	cp := c
	return &cp, nil
}

func (r *memoryRepository) Upsert(_ context.Context, c Contest) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.byID[c.ID] = c
	return nil
}

type service struct {
	repo repository
}

// New constructs the contest module.
func New() Service {
	return &service{repo: newMemoryRepository()}
}

func (s *service) Name() string { return "contest" }

func (s *service) Ready(ctx context.Context) error { return s.repo.Ping(ctx) }

func (s *service) Get(ctx context.Context, id string) (*Contest, error) {
	return s.repo.Get(ctx, id)
}

func (s *service) Upsert(ctx context.Context, c Contest) error {
	return s.repo.Upsert(ctx, c)
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
