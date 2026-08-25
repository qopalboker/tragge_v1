// Package admin is the public facade for Platform admin authz services (ARCH-002).
// BFFs import this package; admin repositories stay unexported under internal/.
package admin

import (
	"net/http"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/admin"
	"github.com/Parsaeffatravesh/tragge/packages/auth"
)

// Service is the application surface for admin identity + authorization.
type Service = admin.Service

// NewMemory returns a memory-backed admin service (tests / Ready).
func NewMemory() Service { return admin.New() }

// NewWithAuth binds the Admin authentication trust domain (SEC-001).
func NewWithAuth(adminAuth *auth.Auth) (Service, error) {
	return admin.NewWithAuth(adminAuth, nil)
}

// RegisterRoutes mounts admin endpoints for Platform API mode.
func RegisterRoutes(mux *http.ServeMux, svc Service) {
	admin.RegisterRoutes(mux, svc)
}
