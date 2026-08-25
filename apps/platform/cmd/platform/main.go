// Command platform is the Platform modular-monolith entrypoint (ARCH-001).
// One binary, one image, three modes: api | realtime | worker (ADR-0001).
package main

import (
	"context"
	"flag"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/adapters/api"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/adapters/realtime"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/adapters/worker"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/compose"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/mode"
)

// Version is injected at build time via -ldflags "-X main.Version=...".
var Version = "dev"

func main() {
	modeFlag := flag.String("mode", envOr("PLATFORM_MODE", "api"), "runtime mode: api|realtime|worker")
	addr := flag.String("addr", envOr("PLATFORM_ADDR", ":8080"), "listen address for health and mode HTTP")
	flag.Parse()

	m, err := mode.Parse(*modeFlag)
	if err != nil {
		log.Fatalf("platform: %v", err)
	}

	platform := compose.New()
	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGINT, syscall.SIGTERM)
	defer stop()

	log.Printf("platform: starting mode=%s version=%s addr=%s modules=%d",
		m, Version, *addr, len(platform.Modules()))

	errCh := make(chan error, 1)
	switch m {
	case mode.API:
		srv := api.New(platform, *addr, Version)
		go func() { errCh <- srv.ListenAndServe() }()
		waitShutdown(ctx, errCh, srv.Shutdown)
	case mode.Realtime:
		srv := realtime.New(platform, *addr, Version)
		go func() { errCh <- srv.ListenAndServe() }()
		waitShutdown(ctx, errCh, srv.Shutdown)
	case mode.Worker:
		srv := worker.New(platform, *addr, Version)
		go func() { errCh <- srv.ListenAndServe() }()
		waitShutdown(ctx, errCh, srv.Shutdown)
	default:
		log.Fatalf("platform: unhandled mode %q", m)
	}
}

func waitShutdown(ctx context.Context, errCh <-chan error, shutdown func(context.Context) error) {
	select {
	case <-ctx.Done():
		shCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := shutdown(shCtx); err != nil {
			log.Printf("platform: shutdown error: %v", err)
		}
	case err := <-errCh:
		if err != nil && err != http.ErrServerClosed {
			log.Fatalf("platform: serve error: %v", err)
		}
	}
}

func envOr(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
