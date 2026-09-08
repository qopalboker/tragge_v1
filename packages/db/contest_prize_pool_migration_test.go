package db

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestContestPrizePoolMigrationContract(t *testing.T) {
	upRaw, err := os.ReadFile(filepath.Join(migrationDir(), "0118_contest_prize_pool.up.sql"))
	if err != nil {
		t.Fatal(err)
	}
	downRaw, err := os.ReadFile(filepath.Join(migrationDir(), "0118_contest_prize_pool.down.sql"))
	if err != nil {
		t.Fatal(err)
	}
	combined := string(upRaw) + string(downRaw)
	for _, required := range []string{
		"funds_policy_version", "DEFAULT 'legacy'", "SET DEFAULT 'contest_funds_v1'",
		"contest_prize_pool_accounts", "contest_prize_pool_ledger", "contest_id UUID NOT NULL UNIQUE",
		"idempotency_key VARCHAR(220) NOT NULL UNIQUE", "BEFORE UPDATE OR DELETE",
		"contest_pool_allocation", "refusing to remove contest Prize Pool financial history",
	} {
		if !strings.Contains(combined, required) {
			t.Fatalf("Prize Pool migration missing %q", required)
		}
	}
	if strings.Contains(string(upRaw), "INSERT INTO contest_prize_pool_ledger SELECT") {
		t.Fatal("migration fabricates historical Prize Pool movements")
	}
	accountAt := strings.Index(string(upRaw), "CREATE TABLE contest_prize_pool_accounts")
	triggerAt := strings.Index(string(upRaw), "CREATE TRIGGER modern_contest_prize_pool_on_create")
	activateAt := strings.Index(string(upRaw), "SET DEFAULT 'contest_funds_v1'")
	if accountAt < 0 || triggerAt < accountAt || activateAt < triggerAt {
		t.Fatal("contest_funds_v1 activates before Prize Pool schema provisioning is ready")
	}
}
