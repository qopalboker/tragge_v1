package db

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestContestFeeMigrationPurposeKindsAndRollbackGuard(t *testing.T) {
	upRaw, err := os.ReadFile(filepath.Join(migrationDir(), "0116_contest_fee_wallet.up.sql"))
	if err != nil {
		t.Fatal(err)
	}
	downRaw, err := os.ReadFile(filepath.Join(migrationDir(), "0116_contest_fee_wallet.down.sql"))
	if err != nil {
		t.Fatal(err)
	}
	up, down := string(upRaw), string(downRaw)
	for _, required := range []string{
		"CHECK (purpose = 'contest_fee_wallet')",
		"CHECK (account_kind = 'system_fee_revenue')",
		"'contest_base_fee'",
		"'contest_late_surcharge'",
		"'contest_fee_refund_reversal'",
		"CREATE UNIQUE INDEX uq_contest_fee_inflow_admission_kind",
		"WHERE entry_kind IN ('contest_base_fee', 'contest_late_surcharge')",
		"UNIQUE (original_entry_id)",
		"BEFORE UPDATE OR DELETE ON contest_fee_ledger",
		"BEFORE DELETE ON contest_fee_accounts",
		"BEFORE INSERT ON contest_fee_ledger",
		"NEW.amount_cents <> -original.amount_cents",
		"policy_version = '2026-09-06.1'",
	} {
		if !strings.Contains(up, required) {
			t.Fatalf("migration missing %q", required)
		}
	}
	for _, forbidden := range []string{"'deposit',", "'prize',", "'forfeiture',", "'withdrawal',", "'adjustment',", "user_id UUID PRIMARY KEY"} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("migration contains forbidden fee classification/ownership %q", forbidden)
		}
	}
	if !strings.Contains(down, "IF EXISTS (SELECT 1 FROM contest_fee_ledger)") {
		t.Fatal("down migration can destroy financial evidence")
	}
}
