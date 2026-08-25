// Package modules defines the shared Platform module surface.
// Modules communicate through in-process application interfaces only
// (policy §2.3); they must not call each other over HTTP.
package modules

import "context"

// Module is the lifecycle surface every Platform domain module exposes
// to the composition root and runtime modes.
type Module interface {
	// Name is a stable module identifier (e.g. "identity").
	Name() string
	// Ready reports whether the module can accept work (used by /readyz).
	Ready(ctx context.Context) error
}

// Service is the application-layer port handlers and other modules may
// depend on. Handlers must never depend on another module's repository.
type Service interface {
	Module
}
