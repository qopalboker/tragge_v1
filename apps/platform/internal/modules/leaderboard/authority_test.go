package leaderboard

import (
	"context"
	"errors"
	"testing"
)

func TestNoSettlementAuthority(t *testing.T) {
	svc := New()
	if svc.HasSettlementAuthority() {
		t.Fatal("leaderboard must not have settlement authority")
	}
	if err := svc.CreditWallets(context.Background(), "c1"); !errors.Is(err, ErrNoSettlementAuthority) {
		t.Fatalf("CreditWallets: %v", err)
	}
	if err := svc.ProjectRanks(context.Background(), "c1"); err != nil {
		t.Fatal(err)
	}
}
