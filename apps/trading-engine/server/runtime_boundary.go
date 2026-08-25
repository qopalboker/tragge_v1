// ENG-001: independent Trading Engine runtime boundary.
package server

import (
	"fmt"
	"os"
	"strings"

	dbevents "github.com/Parsaeffatravesh/tragge/packages/db/events"
)

// ForbiddenProviderEnv are Market Data provider credentials that must not be
// required (or present) for Engine startup.
var ForbiddenProviderEnv = []string{
	"FINNHUB_API_KEY",
	"FINNHUB_TOKEN",
	"NOBITEX_API_KEY",
	"NOBITEX_TOKEN",
	"DERIV_API_TOKEN",
	"DERIV_APP_ID",
	"BINANCE_API_KEY",
	"BINANCE_API_SECRET",
	"MASSIVE_API_KEY",
}

// ForbiddenPlatformAuthEnv are Platform JWT/session responsibilities Engine must not own.
var ForbiddenPlatformAuthEnv = []string{
	"JWT_SECRET",
	"USER_JWT_SECRET",
	"ADMIN_JWT_SECRET",
	"SESSION_SECRET",
	"PLATFORM_JWT_SECRET",
}

// ValidateIndependentRuntime enforces ENG-001 startup boundary:
// Engine schema owner, no Market Data provider credentials, no Platform JWT/session secrets.
func ValidateIndependentRuntime() error {
	if EngineSchemaOwner != dbevents.OwnerEngine {
		return fmt.Errorf("eng-001: schema owner must be %s", dbevents.OwnerEngine)
	}
	for _, key := range ForbiddenProviderEnv {
		if strings.TrimSpace(os.Getenv(key)) != "" {
			return fmt.Errorf("eng-001: Market Data provider credential %s must not be set on Engine", key)
		}
	}
	for _, key := range ForbiddenPlatformAuthEnv {
		if strings.TrimSpace(os.Getenv(key)) != "" {
			return fmt.Errorf("eng-001: Platform auth/session secret %s must not be set on Engine", key)
		}
	}
	return nil
}

// UsesPlatformDBGrants reports whether Engine is configured with a Platform-owned DSN role.
// Target runtime uses the engine schema role only (ARCH-006).
func UsesPlatformDBGrants() bool {
	user := strings.ToLower(strings.TrimSpace(firstNonEmptyEnv(
		"POSTGRES_USER",
		"PGUSER",
		"DB_USER",
	)))
	if user == "" {
		return false
	}
	return user == "platform" || strings.HasPrefix(user, "platform_")
}

func firstNonEmptyEnv(keys ...string) string {
	for _, key := range keys {
		if v := strings.TrimSpace(os.Getenv(key)); v != "" {
			return v
		}
	}
	return ""
}
