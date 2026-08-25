package wallet

import (
	"strings"
	"testing"
)

func TestFIN006AdminFundedDepositType(t *testing.T) {
	if LedgerTypeAdminFundedDeposit != "admin_funded_deposit" {
		t.Fatalf("unexpected type: %q", LedgerTypeAdminFundedDeposit)
	}
	if LedgerTypeDeposit == LedgerTypeAdminFundedDeposit {
		t.Fatal("admin_funded_deposit must be distinct from deposit")
	}
}

func TestFIN006GatewayDepositRevenuePredicate(t *testing.T) {
	p := GatewayDepositRevenueSQLPredicate
	if !strings.Contains(p, "type = 'deposit'") {
		t.Fatalf("predicate must require deposit type: %s", p)
	}
	if !strings.Contains(p, "WALLET_TOPUP") || !strings.Contains(p, "admin_action") {
		t.Fatalf("predicate must defense-filter residual admin top-ups: %s", p)
	}
	if strings.Contains(p, "admin_funded_deposit") {
		// Explicit: revenue is deposit-only; admin_funded_deposit is excluded by type equality.
		t.Fatal("predicate should not OR-include admin_funded_deposit")
	}
}
