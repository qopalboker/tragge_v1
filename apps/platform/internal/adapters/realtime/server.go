// Package realtime runs platform --mode=realtime.
// Skeleton exposes health/readiness only; projection delivery arrives in later ARCH tasks.
package realtime

import (
	"context"
	"net"
	"net/http"
	"time"

	cfghealth "github.com/Parsaeffatravesh/tragge/packages/config/health"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/compose"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/mode"
)

// Server is the realtime-mode HTTP health process (websocket adapters later).
type Server struct {
	platform *compose.Platform
	http     *http.Server
	checker  *cfghealth.Checker
}

// New constructs the realtime-mode server.
func New(platform *compose.Platform, addr, version string) *Server {
	checker := cfghealth.NewChecker(mode.Realtime.ServiceName(), cfghealth.WithVersion(version))
	checker.AddDependency("modules", true, func(ctx context.Context) error {
		return platform.Ready(ctx)
	})

	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", checker.LivenessHandler())
	mux.HandleFunc("/readyz", checker.ReadinessHandler())

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

// ListenAndServe starts the realtime health HTTP server.
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
