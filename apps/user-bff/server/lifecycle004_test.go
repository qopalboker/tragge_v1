package server

import (
	"os"
	"strings"
	"testing"
)

func TestLIFECYCLE004UserLeaveFailsClosed(t *testing.T) {
	body, err := os.ReadFile("contest_handlers.go")
	if err != nil {
		t.Fatal(err)
	}
	source := string(body)
	start := strings.Index(source, "func (a *App) handleLeaveContest")
	end := strings.Index(source[start:], "\n}\n")
	if start < 0 || end < 0 {
		t.Fatal("leave handler not found")
	}
	handler := source[start : start+end]
	if !strings.Contains(handler, "http.StatusForbidden") || !strings.Contains(handler, "PARTICIPANT_COMMITMENT_IMMUTABLE") {
		t.Fatal("legacy leave endpoint must return an explicit immutable-commitment rejection")
	}
	if strings.Contains(handler, "DELETE FROM contest_participants") || strings.Contains(handler, "RefundContestEntryFee") {
		t.Fatal("user leave rejection must not mutate participant or financial state")
	}
}
