// Package scheduler owns contest generation and lifecycle scheduling (ARCH-003).
// Free-practice generation is merged here so only one scheduler owns generation.
package scheduler

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
)

var ErrGenerationLockHeld = errors.New("scheduler: contest generation lock held by another instance")

// Service is the application surface for contest scheduling / generation ownership.
type Service interface {
	modules.Service
	// OwnsContestGeneration reports that this module is the sole generation owner.
	OwnsContestGeneration() bool
	// TryAcquireGenerationLock attempts a process-local generation lock (duplicate-instance guard).
	// Production Redis lock wiring remains with the contest-scheduler deployment until cutover.
	TryAcquireGenerationLock(instanceID string) (release func(), err error)
	// Jobs returns worker-mode jobs owned by this module.
	Jobs() []modules.Job
}

type repository interface {
	Ping(ctx context.Context) error
}

type memoryRepository struct{}

func (memoryRepository) Ping(context.Context) error { return nil }

type service struct {
	repo repository

	mu            sync.Mutex
	lockHolder    string
	generationSeq atomic.Uint64
}

// New constructs the scheduler module (canonical contest-generation owner).
func New() Service {
	return &service{repo: memoryRepository{}}
}

func (s *service) Name() string { return "scheduler" }

func (s *service) Ready(ctx context.Context) error { return s.repo.Ping(ctx) }

func (s *service) OwnsContestGeneration() bool { return true }

func (s *service) TryAcquireGenerationLock(instanceID string) (func(), error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.lockHolder != "" && s.lockHolder != instanceID {
		return nil, ErrGenerationLockHeld
	}
	s.lockHolder = instanceID
	return func() {
		s.mu.Lock()
		defer s.mu.Unlock()
		if s.lockHolder == instanceID {
			s.lockHolder = ""
		}
	}, nil
}

func (s *service) Jobs() []modules.Job {
	return []modules.Job{
		newLifecycleJob(s),
		newFreePracticeJob(s),
	}
}

// RecordGeneration increments a counter used by duplicate-owner tests.
func (s *service) RecordGeneration() { s.generationSeq.Add(1) }

// GenerationCount returns how many free-practice generation ticks ran under this owner.
func (s *service) GenerationCount() uint64 { return s.generationSeq.Load() }

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
