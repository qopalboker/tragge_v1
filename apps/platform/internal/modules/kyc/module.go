// Package kyc owns KYC application ports (ARCH-004).
// External KYC providers (e.g. Jibit) remain adapters under packages/kyc.
package kyc

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"sync"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
)

var (
	ErrNotFound          = errors.New("kyc: not found")
	ErrInvalidTransition = errors.New("kyc: invalid transition")
)

// Status values for the durable KYC review state machine.
const (
	StatusNone       = "none"
	StatusSubmitted  = "submitted"
	StatusApproved   = "approved"
	StatusRejected   = "rejected"
	StatusNeedInfo   = "need_info"
)

// Record is a user's KYC application state.
type Record struct {
	UserID string
	Status string
	Notes  string
}

// Service is the KYC application surface.
type Service interface {
	modules.Service
	GetStatus(ctx context.Context, userID string) (*Record, error)
	Submit(ctx context.Context, userID string) error
	Approve(ctx context.Context, userID, notes string) error
	Reject(ctx context.Context, userID, notes string) error
	RequireApproved(ctx context.Context, userID string) error
}

type repository interface {
	Ping(ctx context.Context) error
	Get(ctx context.Context, userID string) (*Record, error)
	Save(ctx context.Context, rec Record) error
}

type memoryRepository struct {
	mu   sync.RWMutex
	byID map[string]Record
}

func newMemoryRepository() *memoryRepository {
	return &memoryRepository{byID: map[string]Record{}}
}

func (r *memoryRepository) Ping(context.Context) error { return nil }

func (r *memoryRepository) Get(_ context.Context, userID string) (*Record, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	rec, ok := r.byID[userID]
	if !ok {
		return &Record{UserID: userID, Status: StatusNone}, nil
	}
	cp := rec
	return &cp, nil
}

func (r *memoryRepository) Save(_ context.Context, rec Record) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	r.byID[rec.UserID] = rec
	return nil
}

type service struct {
	repo repository
}

// New constructs the KYC module.
func New() Service {
	return &service{repo: newMemoryRepository()}
}

func (s *service) Name() string { return "kyc" }

func (s *service) Ready(ctx context.Context) error { return s.repo.Ping(ctx) }

func (s *service) GetStatus(ctx context.Context, userID string) (*Record, error) {
	return s.repo.Get(ctx, userID)
}

func (s *service) Submit(ctx context.Context, userID string) error {
	rec, err := s.repo.Get(ctx, userID)
	if err != nil {
		return err
	}
	if rec.Status != StatusNone && rec.Status != StatusRejected && rec.Status != StatusNeedInfo {
		return ErrInvalidTransition
	}
	rec.Status = StatusSubmitted
	return s.repo.Save(ctx, *rec)
}

func (s *service) Approve(ctx context.Context, userID, notes string) error {
	rec, err := s.repo.Get(ctx, userID)
	if err != nil {
		return err
	}
	if rec.Status != StatusSubmitted && rec.Status != StatusNeedInfo {
		return ErrInvalidTransition
	}
	rec.Status = StatusApproved
	rec.Notes = notes
	return s.repo.Save(ctx, *rec)
}

func (s *service) Reject(ctx context.Context, userID, notes string) error {
	rec, err := s.repo.Get(ctx, userID)
	if err != nil {
		return err
	}
	if rec.Status != StatusSubmitted && rec.Status != StatusNeedInfo {
		return ErrInvalidTransition
	}
	rec.Status = StatusRejected
	rec.Notes = notes
	return s.repo.Save(ctx, *rec)
}

func (s *service) RequireApproved(ctx context.Context, userID string) error {
	rec, err := s.repo.Get(ctx, userID)
	if err != nil {
		return err
	}
	if rec.Status != StatusApproved {
		return errors.New("kyc: verification required")
	}
	return nil
}

// RegisterRoutes mounts KYC boundary APIs on Platform API mode.
func RegisterRoutes(mux *http.ServeMux, svc Service) {
	mux.HandleFunc("/api/kyc/v1/boundary", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"module": svc.Name(),
			"ready":  svc.Ready(r.Context()) == nil,
		})
	})
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
