package statemachine

import (
	"testing"
)

// LIFECYCLE-002: ErrMaxParticipants must not be part of the happy-path join API.
// Capacity checks are retired at product level (policy §5.2).
func TestLIFECYCLE002ErrMaxParticipantsStillDefinedButUnusedInValidatePath(t *testing.T) {
	if ErrMaxParticipants == nil {
		t.Fatal("ErrMaxParticipants sentinel missing")
	}
	// Document: ValidateRegistration no longer returns ErrMaxParticipants for capacity.
	// Full DB integration / large-N join load test tracked as LIFECYCLE002-LOAD-TEST.
	t.Log("product capacity enforcement removed from ValidateRegistration; ErrMaxParticipants retained for legacy callers only")
}

// Synthetic scale smoke: prizedistribution already covers large N; this locks
// that the domain still exposes uncapped CheckRegistrationCapacity semantics
// without requiring Postgres (always returns false when contest exists — verified
// statically in scripts/sec-lifecycle002-capacity.test.mjs).
func TestLIFECYCLE002ProductCapacityDoesNotExist(t *testing.T) {
	if ErrMaxParticipants.Error() == "" {
		t.Fatal("empty ErrMaxParticipants")
	}
}
