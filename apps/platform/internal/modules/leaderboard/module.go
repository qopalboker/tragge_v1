// Package leaderboard owns live/final leaderboard *projection* only (ARCH-003).
// It has no settlement / wallet-credit authority (FIN-003 / ARCH-005).
package leaderboard

import (
	"context"
	"errors"
	"sync/atomic"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
)

var ErrNoSettlementAuthority = errors.New("leaderboard: no settlement authority")

// Service is the projection surface. Settlement APIs are intentionally absent.
type Service interface {
	modules.Service
	// HasSettlementAuthority is always false (acceptance criterion).
	HasSettlementAuthority() bool
	// ProjectRanks records a projection-only finalize step (ranks/scores).
	ProjectRanks(ctx context.Context, contestID string) error
	// CreditWallets is rejected — settlement-service owns credits.
	CreditWallets(ctx context.Context, contestID string) error
	Jobs() []modules.Job
}

type repository interface {
	Ping(ctx context.Context) error
	WriteRanks(ctx context.Context, contestID string) error
}

type memoryRepository struct {
	ranksWritten atomic.Uint64
}

func (r *memoryRepository) Ping(context.Context) error { return nil }

func (r *memoryRepository) WriteRanks(_ context.Context, _ string) error {
	r.ranksWritten.Add(1)
	return nil
}

type service struct {
	repo *memoryRepository
}

// New constructs the leaderboard projection module.
func New() Service {
	return &service{repo: &memoryRepository{}}
}

func (s *service) Name() string { return "leaderboard" }

func (s *service) Ready(ctx context.Context) error { return s.repo.Ping(ctx) }

func (s *service) HasSettlementAuthority() bool { return false }

func (s *service) ProjectRanks(ctx context.Context, contestID string) error {
	return s.repo.WriteRanks(ctx, contestID)
}

func (s *service) CreditWallets(context.Context, string) error {
	return ErrNoSettlementAuthority
}

func (s *service) Jobs() []modules.Job {
	return []modules.Job{&projectionJob{svc: s}}
}

type projectionJob struct {
	svc     *service
	running atomic.Bool
}

func (j *projectionJob) Name() string { return "leaderboard.projection" }

func (j *projectionJob) Start(ctx context.Context) error {
	j.running.Store(true)
	go func() {
		<-ctx.Done()
		j.running.Store(false)
	}()
	return nil
}

func (j *projectionJob) Stop(context.Context) error {
	j.running.Store(false)
	return nil
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
