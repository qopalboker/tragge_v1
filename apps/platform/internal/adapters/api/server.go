// Package api runs platform --mode=api (HTTP APIs).
// Handlers depend only on module Service interfaces from compose — never
// foreign repositories (ARCH-001).
package api

import (
	"context"
	"encoding/json"
	"net"
	"net/http"
	"time"

	cfghealth "github.com/Parsaeffatravesh/tragge/packages/config/health"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/compose"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/mode"
	platformadmin "github.com/Parsaeffatravesh/tragge/apps/platform/pkg/admin"
	platformidentity "github.com/Parsaeffatravesh/tragge/apps/platform/pkg/identity"
)

// Server is the api-mode HTTP process.
type Server struct {
	platform *compose.Platform
	http     *http.Server
	checker  *cfghealth.Checker
}

// New constructs the api-mode server. addr is host:port (e.g. ":8080").
func New(platform *compose.Platform, addr, version string) *Server {
	checker := cfghealth.NewChecker(mode.API.ServiceName(), cfghealth.WithVersion(version))
	checker.AddDependency("modules", true, func(ctx context.Context) error {
		return platform.Ready(ctx)
	})

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", checker.LivenessHandler())
	mux.HandleFunc("/readyz", checker.ReadinessHandler())
	mux.HandleFunc("/v1/platform/modules", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		names := make([]string, 0, len(platform.Modules()))
		for _, m := range platform.Modules() {
			names = append(names, m.Name())
		}
		w.Header().Set("Content-Type", "application/json")
		_ = json.NewEncoder(w).Encode(map[string]any{
			"mode":    mode.API.String(),
			"modules": names,
		})
	})

	// ARCH-002: identity + admin endpoints run from Platform API mode.
	platformidentity.RegisterRoutes(mux, platform.Identity)
	platformadmin.RegisterRoutes(mux, platform.Admin)

	return &Server{
		platform: platform,
		checker:  checker,
		http: &http.Server{
			Addr:              addr,
			Handler:           mux,
			ReadHeaderTimeout: 5 * time.Second,
		},
	}
}

// ListenAndServe starts the api HTTP server.
func (s *Server) ListenAndServe() error {
	return s.http.ListenAndServe()
}

// Serve serves on an existing listener (tests).
func (s *Server) Serve(lis net.Listener) error {
	s.http.Addr = lis.Addr().String()
	return s.http.Serve(lis)
}

// Shutdown gracefully stops the server.
func (s *Server) Shutdown(ctx context.Context) error {
	return s.http.Shutdown(ctx)
}

// Addr returns the configured listen address.
func (s *Server) Addr() string { return s.http.Addr }
