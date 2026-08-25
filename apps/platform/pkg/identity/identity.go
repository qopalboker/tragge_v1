// Package identity is the public facade for Platform user-identity services (ARCH-002).
// BFFs import this package; module repositories stay unexported under internal/.
package identity

import (
	"net/http"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/identity"
	"github.com/Parsaeffatravesh/tragge/packages/auth"
)

// Service is the application surface for user identity.
type Service = identity.Service

// NewMemory returns a memory-backed identity service (tests / Ready).
func NewMemory() Service { return identity.New() }

// NewWithAuth binds the User authentication trust domain (SEC-001).
func NewWithAuth(userAuth *auth.Auth) (Service, error) {
	return identity.NewWithAuth(userAuth, nil)
}

// RegisterRoutes mounts identity endpoints for Platform API mode.
func RegisterRoutes(mux *http.ServeMux, svc Service) {
	identity.RegisterRoutes(mux, svc)
}
