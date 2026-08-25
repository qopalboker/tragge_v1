// Package admin owns the Platform admin identity + authorization boundary (ARCH-002).
// Role/permission enforcement lives in the application service, not only HTTP handlers.
package admin

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
	"github.com/Parsaeffatravesh/tragge/packages/auth"
)

var (
	ErrNotAdminContext = errors.New("admin: auth context is not admin")
	ErrForbidden       = errors.New("admin: forbidden")
	ErrUnauthorized    = errors.New("admin: unauthorized")
)

// Service is the only application surface other packages may depend on.
// Admin repository types are intentionally unexported.
type Service interface {
	modules.Service
	auth.PermissionAuthorizer
	AuthContext() auth.AuthContext
	Auth() *auth.Auth
	AuthorizeRole(claims *auth.Claims, roles ...string) error
	AuthorizePermission(claims *auth.Claims, permissions ...string) error
}

// adminRepository is private — must never be imported by user/identity handlers (ARCH-002).
type adminRepository interface {
	Ping(ctx context.Context) error
	// PermissionsForRole returns granted permissions for a role name (read model).
	PermissionsForRole(ctx context.Context, role string) ([]string, error)
}

type memoryAdminRepository struct {
	rolePerms map[string][]string
}

func newMemoryAdminRepository() *memoryAdminRepository {
	return &memoryAdminRepository{
		rolePerms: map[string][]string{
			auth.RoleSuperAdmin: {"*"},
		},
	}
}

func (r *memoryAdminRepository) Ping(context.Context) error { return nil }

func (r *memoryAdminRepository) PermissionsForRole(_ context.Context, role string) ([]string, error) {
	if perms, ok := r.rolePerms[role]; ok {
		return append([]string(nil), perms...), nil
	}
	return nil, nil
}

type service struct {
	repo adminRepository
	auth *auth.Auth
}

// New constructs a memory-backed admin module.
func New() Service {
	return &service{repo: newMemoryAdminRepository()}
}

// NewWithAuth constructs admin with the Admin authentication trust domain.
func NewWithAuth(adminAuth *auth.Auth, repo adminRepository) (Service, error) {
	if adminAuth == nil {
		return nil, errors.New("admin: admin auth is required")
	}
	if adminAuth.Context() != auth.ContextAdmin {
		return nil, ErrNotAdminContext
	}
	if repo == nil {
		repo = newMemoryAdminRepository()
	}
	return &service{repo: repo, auth: adminAuth}, nil
}

func (s *service) Name() string { return "admin" }

func (s *service) Ready(ctx context.Context) error {
	return s.repo.Ping(ctx)
}

func (s *service) AuthContext() auth.AuthContext { return auth.ContextAdmin }

func (s *service) Auth() *auth.Auth { return s.auth }

// AuthorizePermission enforces RBAC in the application layer (ARCH-002).
func (s *service) AuthorizePermission(claims *auth.Claims, permissions ...string) error {
	if claims == nil {
		return ErrUnauthorized
	}
	if claims.IsSuperAdmin() {
		return nil
	}
	if claims.HasAnyPermission(permissions...) {
		return nil
	}
	// Optional enrichment from admin repository (role → permissions read model).
	for _, role := range claims.Roles {
		perms, err := s.repo.PermissionsForRole(context.Background(), role)
		if err != nil {
			return ErrForbidden
		}
		for _, need := range permissions {
			for _, have := range perms {
				if have == "*" || have == need {
					return nil
				}
			}
		}
	}
	return ErrForbidden
}

// AuthorizeRole enforces role checks in the application layer.
func (s *service) AuthorizeRole(claims *auth.Claims, roles ...string) error {
	if claims == nil {
		return ErrUnauthorized
	}
	if claims.HasAnyRole(roles...) {
		return nil
	}
	return ErrForbidden
}

// RegisterRoutes mounts admin boundary + authorize endpoints on Platform API mode.
func RegisterRoutes(mux *http.ServeMux, svc Service) {
	mux.HandleFunc("/api/admin/auth/v1/boundary", func(w http.ResponseWriter, r *http.Request) {
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

	mux.HandleFunc("/api/admin/auth/v1/authorize", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		var body struct {
			Permission string   `json:"permission"`
			Roles      []string `json:"roles"`
			Claims     struct {
				UserID      string   `json:"user_id"`
				Roles       []string `json:"roles"`
				Permissions []string `json:"permissions"`
			} `json:"claims"`
		}
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid_body"})
			return
		}
		claims := &auth.Claims{
			UserID:      body.Claims.UserID,
			Roles:       body.Claims.Roles,
			Permissions: body.Claims.Permissions,
		}
		var err error
		if body.Permission != "" {
			err = svc.AuthorizePermission(claims, body.Permission)
		} else if len(body.Roles) > 0 {
			err = svc.AuthorizeRole(claims, body.Roles...)
		} else {
			writeJSON(w, http.StatusBadRequest, map[string]string{"error": "permission_or_roles_required"})
			return
		}
		if errors.Is(err, ErrUnauthorized) {
			writeJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
			return
		}
		if err != nil {
			writeJSON(w, http.StatusForbidden, map[string]string{"error": "forbidden"})
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{"allowed": true, "auth_context": string(svc.AuthContext())})
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
var _ auth.PermissionAuthorizer = (*service)(nil)
