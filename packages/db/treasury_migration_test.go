package db

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestTreasuryMigrationIsSingletonForwardOnlyAndNonUserOwned(t *testing.T) {
	raw, err := os.ReadFile(filepath.Join(migrationDir(), "0115_treasury_custody_account.up.sql"))
	if err != nil {
		t.Fatal(err)
	}
	sql := string(raw)
	for _, required := range []string{
		"CHECK (purpose = 'super_admin_treasury')",
		"CHECK (account_kind = 'system_custody')",
		"CHECK (reconciliation_status = 'forward_only_unreconciled')",
		"CONSTRAINT uq_treasury_ledger_payment_intent UNIQUE (payment_intent_id)",
		"BEFORE UPDATE OR DELETE ON treasury_ledger",
		"BEFORE DELETE ON treasury_accounts",
		"'super_admin_treasury',\n    'system_custody',\n    0,",
	} {
		if !strings.Contains(sql, required) {
			t.Fatalf("Treasury migration missing %q", required)
		}
	}
	for _, forbidden := range []string{"SUM(", "FROM wallets", "user_id UUID PRIMARY KEY REFERENCES users"} {
		if strings.Contains(sql, forbidden) {
			t.Fatalf("Treasury migration contains forbidden historical/user ownership pattern %q", forbidden)
		}
	}
}
