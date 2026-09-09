package server

import (
	"os"
	"strings"
	"testing"
)

func boolPointer(v bool) *bool { return &v }

func TestLIFECYCLE004RemovalRefundMatrix(t *testing.T) {
	tests := []struct {
		name          string
		req           participantRemovalRequest
		refund, valid bool
	}{
		{"cheating refund", participantRemovalRequest{Reason: "CHEATING", Refund: boolPointer(true)}, true, true},
		{"cheating no refund", participantRemovalRequest{Reason: "CHEATING", Refund: boolPointer(false)}, false, true},
		{"cheating requires decision", participantRemovalRequest{Reason: "CHEATING"}, false, false},
		{"immediate exit refund", participantRemovalRequest{Reason: "USER_IMMEDIATE_EXIT_REQUEST"}, true, true},
		{"other requires note", participantRemovalRequest{Reason: "OTHER"}, true, false},
		{"other rejects whitespace note", participantRemovalRequest{Reason: "OTHER", AdminNote: "   "}, true, false},
		{"other refund", participantRemovalRequest{Reason: "OTHER", AdminNote: "Policy exception"}, true, true},
		{"mandatory refund cannot be disabled", participantRemovalRequest{Reason: "OTHER", AdminNote: "Policy exception", Refund: boolPointer(false)}, true, false},
		{"closed reason enum", participantRemovalRequest{Reason: "invented"}, false, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			refund, valid := tt.req.refundDecision()
			if refund != tt.refund || valid != tt.valid {
				t.Fatalf("got (%v,%v), want (%v,%v)", refund, valid, tt.refund, tt.valid)
			}
		})
	}
}

func TestLIFECYCLE004SensitiveRoutesRequireSuperAdmin(t *testing.T) {
	body, err := os.ReadFile("app.go")
	if err != nil {
		t.Fatal(err)
	}
	source := string(body)
	for _, route := range []string{
		`r.With(app.auth.Middleware.RequireSuperAdmin).Delete("/participants/{user_id}"`,
		`r.With(app.auth.Middleware.RequireSuperAdmin).Post("/cancel"`,
	} {
		if !strings.Contains(source, route) {
			t.Fatalf("missing Super Admin gate: %s", route)
		}
	}
}

func TestLIFECYCLE004FinancialHandlersAreAtomicAndNonDestructive(t *testing.T) {
	financial, err := os.ReadFile("lifecycle004_financial.go")
	if err != nil {
		t.Fatal(err)
	}
	source := string(financial)
	for _, required := range []string{"FOR UPDATE", "contest_participant_lifecycle_events", "ReverseContestAdmission", "INSERT INTO audit_logs", "tx.Commit()", "economics_cutoff"} {
		if !strings.Contains(source, required) {
			t.Fatalf("atomic lifecycle implementation missing %q", required)
		}
	}
	if strings.Contains(source, "DELETE FROM contest_participants") || strings.Contains(source, "UPDATE contest_snapshots") {
		t.Fatal("participant lifecycle must preserve participant rows and immutable snapshots")
	}
}

func TestLIFECYCLE004FinancialHandlersNeverMutateContestMoneySummaries(t *testing.T) {
	financial, err := os.ReadFile("lifecycle004_financial.go")
	if err != nil {
		t.Fatal(err)
	}
	source := string(financial)
	for _, forbidden := range []string{"prize_pool_net_cents", "commission_amount"} {
		if strings.Contains(source, forbidden) {
			t.Fatalf("lifecycle reversal directly mutates %s", forbidden)
		}
	}
	for _, required := range []string{"ReverseContestAdmission", "PARTICIPANT_REFUNDED", "CONTEST_REFUND_COMPLETED"} {
		if !strings.Contains(source, required) {
			t.Fatalf("lifecycle reversal missing ledger/event boundary %q", required)
		}
	}
}

func TestECON_ADJRemovalEventsShareLifecycleTransaction(t *testing.T) {
	financial, err := os.ReadFile("lifecycle004_financial.go")
	if err != nil {
		t.Fatal(err)
	}
	source := string(financial)
	cutoff := strings.Index(source, "if cutoff")
	events := strings.Index(source, "INSERT INTO economic_adjustment_events")
	status := strings.Index(source, "UPDATE contest_participants SET lifecycle_status")
	commit := strings.Index(source, "tx.Commit()")
	if cutoff < 0 || events < cutoff || status < events || commit < status {
		t.Fatalf("economic adjustment is not cutoff-gated and atomic: cutoff=%d events=%d status=%d commit=%d", cutoff, events, status, commit)
	}
	for _, required := range []string{
		"PARTICIPANT_REMOVED_BEFORE_CUTOFF", "PARTICIPANT_REFUNDED", "PARTICIPANT_DISQUALIFIED",
		"previous_state", "new_state", "reason", "actor_id", "if cutoff && refund",
	} {
		if !strings.Contains(source, required) {
			t.Fatalf("economic adjustment recording missing %q", required)
		}
	}
}
