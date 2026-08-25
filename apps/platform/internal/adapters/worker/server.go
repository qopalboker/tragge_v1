// Package worker runs platform --mode=worker.
// Skeleton exposes health/readiness; async workloads arrive in later ARCH tasks.
package worker

import (
	"context"
	"net"
	"net/http"
	"time"

	cfghealth "github.com/Parsaeffatravesh/tragge/packages/config/health"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/compose"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/mode"
)

// Server is the worker-mode health HTTP process.
type Server struct {
	platform *compose.Platform
	http     *http.Server
	checker  *cfghealth.Checker
}

// New constructs the worker-mode server.
func New(platform *compose.Platform, addr, version string) *Server {
	checker := cfghealth.NewChecker(mode.Worker.ServiceName(), cfghealth.WithVersion(version))
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

// ListenAndServe starts the worker health HTTP server.
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
