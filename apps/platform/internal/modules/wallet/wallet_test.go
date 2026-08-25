package wallet

import (
	"context"
	"testing"
)

func TestSoleLedgerAuthority(t *testing.T) {
	svc := New()
	if !svc.IsSoleLedgerAuthority() {
		t.Fatal("wallet must be sole ledger authority")
	}
	if err := svc.CreditDeposit(context.Background(), "u1", 100, "pi", "k1"); err != nil {
		t.Fatal(err)
	}
	bal, err := svc.GetBalance(context.Background(), "u1")
	if err != nil || bal != 100 {
		t.Fatalf("bal=%d err=%v", bal, err)
	}
}
