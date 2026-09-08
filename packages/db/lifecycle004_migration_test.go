package db

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLIFECYCLE004FinancialReversalMigrationContract(t *testing.T) {
	raw, err := os.ReadFile(filepath.Join(migrationDir(), "0119_lifecycle004_financial_reversal.up.sql"))
	if err != nil {
		t.Fatal(err)
	}
	source := string(raw)
	for _, required := range []string{
		"lifecycle_status", "'ACTIVE','REMOVED','REFUNDED','DISQUALIFIED','CANCELLED'",
		"contest_participant_lifecycle_events", "BEFORE UPDATE OR DELETE",
		"original_transaction_id", "original_ledger_id", "lifecycle_event_id", "reversal_actor_id",
		"treasury_reversal", "participant_refund", "contest participants are immutable",
	} {
		if !strings.Contains(source, required) {
			t.Fatalf("LIFECYCLE-004 migration missing %q", required)
		}
	}
	for _, forbidden := range []string{"DELETE FROM contest_participants", "UPDATE contest_snapshots", "DELETE FROM contest_snapshots"} {
		if strings.Contains(source, forbidden) {
			t.Fatalf("LIFECYCLE-004 migration contains forbidden mutation %q", forbidden)
		}
	}
}

func TestLIFECYCLE004FinancialAuditIsImmutable(t *testing.T) {
	raw, err := os.ReadFile(filepath.Join(migrationDir(), "0120_lifecycle004_immutable_audit.up.sql"))
	if err != nil {
		t.Fatal(err)
	}
	source := string(raw)
	for _, required := range []string{"contest.remove_participant", "contest.cancelled", "BEFORE UPDATE OR DELETE", "append-only"} {
		if !strings.Contains(source, required) {
			t.Fatalf("financial audit migration missing %q", required)
		}
	}
}
