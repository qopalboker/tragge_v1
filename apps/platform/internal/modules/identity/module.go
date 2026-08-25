// Package identity owns the Platform user-identity boundary (ARCH-002).
// User and admin trust domains stay cryptographically separate (SEC-001).
package identity

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
	"github.com/Parsaeffatravesh/tragge/packages/auth"
)

var (
	ErrNotUserContext = errors.New("identity: auth context is not user")
	ErrUnauthorized   = errors.New("identity: unauthorized")
)

// Service is the only application surface other packages may depend on.
type Service interface {
	modules.Service
	// AuthContext is always auth.ContextUser for this module.
	AuthContext() auth.AuthContext
	// Auth returns the user trust-domain Auth, or nil when running memory-only.
	Auth() *auth.Auth
	// ValidateAccessToken validates a user access token via the user Auth context.
	ValidateAccessToken(ctx context.Context, token string) (*auth.Claims, error)
	// LookupUserID resolves a user by email through the module repository.
	LookupUserID(ctx context.Context, email string) (string, error)
}

// userRepository is private to this module (ARCH-002: not reachable from admin/user handlers abroad).
type userRepository interface {
	Ping(ctx context.Context) error
	FindUserIDByEmail(ctx context.Context, email string) (string, error)
}

type memoryUserRepository struct {
	users map[string]string // email -> id
}

func newMemoryUserRepository() *memoryUserRepository {
	return &memoryUserRepository{users: map[string]string{}}
}

func (r *memoryUserRepository) Ping(context.Context) error { return nil }

func (r *memoryUserRepository) FindUserIDByEmail(_ context.Context, email string) (string, error) {
	id, ok := r.users[strings.ToLower(strings.TrimSpace(email))]
	if !ok {
		return "", ErrUnauthorized
	}
	return id, nil
}

type service struct {
	repo userRepository
	auth *auth.Auth
}

// New constructs a memory-backed identity module (tests / skeleton Ready).
func New() Service {
	return &service{repo: newMemoryUserRepository()}
}

// NewWithAuth constructs identity with the User authentication trust domain.
func NewWithAuth(userAuth *auth.Auth, repo userRepository) (Service, error) {
	if userAuth == nil {
		return nil, errors.New("identity: user auth is required")
	}
	if userAuth.Context() != auth.ContextUser {
		return nil, ErrNotUserContext
	}
	if repo == nil {
		repo = newMemoryUserRepository()
	}
	return &service{repo: repo, auth: userAuth}, nil
}

func (s *service) Name() string { return "identity" }

func (s *service) Ready(ctx context.Context) error {
	return s.repo.Ping(ctx)
}

func (s *service) AuthContext() auth.AuthContext { return auth.ContextUser }

func (s *service) Auth() *auth.Auth { return s.auth }

func (s *service) ValidateAccessToken(ctx context.Context, token string) (*auth.Claims, error) {
	if s.auth == nil {
		return nil, ErrUnauthorized
	}
	claims, err := s.auth.Token.ValidateAccessToken(token)
	if err != nil {
		return nil, ErrUnauthorized
	}
	return claims, nil
}

func (s *service) LookupUserID(ctx context.Context, email string) (string, error) {
	return s.repo.FindUserIDByEmail(ctx, email)
}

// RegisterRoutes mounts identity HTTP endpoints on Platform API mode.
// Paths preserve the /api/user/auth prefix used by the user BFF.
func RegisterRoutes(mux *http.ServeMux, svc Service) {
	mux.HandleFunc("/api/user/auth/v1/boundary", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"module":       svc.Name(),
			"auth_context": string(svc.AuthContext()),
			"ready":        svc.Ready(r.Context()) == nil,
		})
	})

	mux.HandleFunc("/api/user/auth/v1/validate", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		token := bearerToken(r)
		claims, err := svc.ValidateAccessToken(r.Context(), token)
		if err != nil {
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"user_id":      claims.UserID,
			"auth_context": string(svc.AuthContext()),
		})
	})
}

func bearerToken(r *http.Request) string {
	h := r.Header.Get("Authorization")
	if len(h) > 7 && strings.EqualFold(h[:7], "bearer ") {
		return strings.TrimSpace(h[7:])
	}
	return ""
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
