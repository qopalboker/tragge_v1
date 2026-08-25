package modules

import "context"

// Job is a Platform worker-mode background workload (ARCH-003).
// Jobs are started by platform --mode=worker; they are not separate domain services.
type Job interface {
	// Name is a stable job identifier.
	Name() string
	// Start begins the job. It must return promptly after starting background work
	// or block until ctx is cancelled, depending on implementation.
	Start(ctx context.Context) error
	// Stop requests graceful shutdown.
	Stop(ctx context.Context) error
}
