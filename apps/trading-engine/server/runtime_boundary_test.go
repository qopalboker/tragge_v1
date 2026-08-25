package server

import (
	"os"
	"testing"

	dbevents "github.com/Parsaeffatravesh/tragge/packages/db/events"
)

func TestValidateIndependentRuntimeClean(t *testing.T) {
	clear := append(append([]string{}, ForbiddenProviderEnv...), ForbiddenPlatformAuthEnv...)
	for _, key := range clear {
		t.Setenv(key, "")
		_ = os.Unsetenv(key)
	}
	if EngineSchemaOwner != dbevents.OwnerEngine {
		t.Fatal("expected engine schema owner")
	}
	if err := ValidateIndependentRuntime(); err != nil {
		t.Fatal(err)
	}
}

func TestValidateIndependentRuntimeRejectsProviderCreds(t *testing.T) {
	t.Setenv("NOBITEX_API_KEY", "secret")
	if err := ValidateIndependentRuntime(); err == nil {
		t.Fatal("expected provider credential rejection")
	}
}

func TestValidateIndependentRuntimeRejectsJWT(t *testing.T) {
	for _, key := range ForbiddenProviderEnv {
		_ = os.Unsetenv(key)
	}
	t.Setenv("JWT_SECRET", "nope")
	if err := ValidateIndependentRuntime(); err == nil {
		t.Fatal("expected JWT rejection")
	}
}

func TestUsesPlatformDBGrants(t *testing.T) {
	t.Setenv("POSTGRES_USER", "engine")
	if UsesPlatformDBGrants() {
		t.Fatal("engine user should not be platform grants")
	}
	t.Setenv("POSTGRES_USER", "platform")
	if !UsesPlatformDBGrants() {
		t.Fatal("expected platform user detection")
	}
}
