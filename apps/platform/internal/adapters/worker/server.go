// Package worker runs platform --mode=worker.
// ARCH-003: starts Platform module jobs (scheduler, leaderboard projection, notification outbox).
package worker

import (
	"context"
	"log"
	"net"
	"net/http"
	"sync"
	"time"

	cfghealth "github.com/Parsaeffatravesh/tragge/packages/config/health"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/compose"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/mode"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
)

// Server is the worker-mode process (health HTTP + background jobs).
type Server struct {
	platform *compose.Platform
	http     *http.Server
	checker  *cfghealth.Checker
	jobs     []modules.Job
	cancel   context.CancelFunc
	wg       sync.WaitGroup
}

// New constructs the worker-mode server and prepares module jobs.
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
		jobs:     platform.WorkerJobs(),
		http: &http.Server{
			Addr:              addr,
			Handler:           mux,
			ReadHeaderTimeout: 5 * time.Second,
		},
	}
}

// ListenAndServe starts jobs then the health HTTP server.
func (s *Server) ListenAndServe() error {
	ctx, cancel := context.WithCancel(context.Background())
	s.cancel = cancel
	s.startJobs(ctx)
	return s.http.ListenAndServe()
}

// Serve serves on an existing listener (tests).
func (s *Server) Serve(lis net.Listener) error {
	ctx, cancel := context.WithCancel(context.Background())
	s.cancel = cancel
	s.startJobs(ctx)
	s.http.Addr = lis.Addr().String()
	return s.http.Serve(lis)
}

func (s *Server) startJobs(ctx context.Context) {
	for _, job := range s.jobs {
		job := job
		s.wg.Add(1)
		go func() {
			defer s.wg.Done()
			if err := job.Start(ctx); err != nil {
				log.Printf("platform-worker: job %s start: %v", job.Name(), err)
				return
			}
			<-ctx.Done()
			_ = job.Stop(context.Background())
		}()
	}
}

// Shutdown gracefully stops jobs and the HTTP server.
func (s *Server) Shutdown(ctx context.Context) error {
	if s.cancel != nil {
		s.cancel()
	}
	done := make(chan struct{})
	go func() {
		s.wg.Wait()
		close(done)
	}()
	select {
	case <-done:
	case <-ctx.Done():
	}
	return s.http.Shutdown(ctx)
}

// Addr returns the configured listen address.
func (s *Server) Addr() string { return s.http.Addr }

// JobNames returns started job names (tests).
func (s *Server) JobNames() []string {
	names := make([]string, 0, len(s.jobs))
	for _, j := range s.jobs {
		names = append(names, j.Name())
	}
	return names
}
