// Package mode defines Platform runtime modes (ADR-0001 / policy §2.2).
package mode

import (
	"fmt"
	"strings"
)

// Mode is a Platform operational mode. Modes are deployment units, not
// independent domain microservices.
type Mode string

const (
	API      Mode = "api"
	Realtime Mode = "realtime"
	Worker   Mode = "worker"
)

// Parse validates and returns a Mode.
func Parse(raw string) (Mode, error) {
	m := Mode(strings.ToLower(strings.TrimSpace(raw)))
	switch m {
	case API, Realtime, Worker:
		return m, nil
	default:
		return "", fmt.Errorf("invalid platform mode %q (want api|realtime|worker)", raw)
	}
}

// All returns the supported modes in stable order.
func All() []Mode {
	return []Mode{API, Realtime, Worker}
}

func (m Mode) String() string { return string(m) }

// ServiceName is the health/metrics identity for a mode process.
func (m Mode) ServiceName() string {
	return "platform-" + string(m)
}
