// Package wallet is the Platform wallet module skeleton (ARCH-001).
// Real use-case migration is owned by later ARCH-* tasks.
package wallet

import (
	"context"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
)

// Service is the only application surface other packages may depend on.
type Service interface {
	modules.Service
}

// repository is private to this module. Handlers and foreign modules must
// not depend on it (ARCH-001 import-boundary rule).
type repository interface {
	Ping(ctx context.Context) error
}

type memoryRepository struct{}

func (memoryRepository) Ping(context.Context) error { return nil }

type service struct {
	repo repository
}

// New constructs the wallet module with an in-memory repository stub.
// Composition root only — adapters receive Service, never repository.
func New() Service {
	return &service{repo: memoryRepository{}}
}

func (s *service) Name() string { return "wallet" }

func (s *service) Ready(ctx context.Context) error {
	return s.repo.Ping(ctx)
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
