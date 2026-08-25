package server

import (
	"testing"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/scoring/economics"
)

// Thin wrapper coverage — authoritative cases live in packages/scoring/economics.
func TestContestJoinAllowedDelegates(t *testing.T) {
	start := time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC)
	end := start.Add(time.Hour)
	ok, late, _ := contestJoinAllowed(contestStatusRunning, false, true, start, end, start.Add(time.Minute))
	wantOK, wantLate, _ := economics.JoinAllowed(economics.JoinStatusRunning, false, true, start, end, start.Add(time.Minute))
	if ok != wantOK || late != wantLate {
		t.Fatalf("wrapper mismatch ok=%v late=%v want %v/%v", ok, late, wantOK, wantLate)
	}
}
