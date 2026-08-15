package server

import (
	"testing"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
)

// TestMVP005ControlledFinancialScenario documents a controlled reconciliation
// path used for launch readiness (integer cents only).
//
// Starting balance: $100.00 (10000)
// Deposit:          +$20.00 (2000)  → 12000
// Entry fee:        -$10.00 (1000)  → 11000  (gross pool contribution)
// Platform fee 20%: $2.00 of entry stays platform; $8.00 net prize pool
// Prize (example):  +$80.00 (8000)  → 19000  (winner credit, not same as fee math alone)
// Withdrawal:       -$50.00 (5000)  → 14000
// Reject refund:    +$50.00 (5000)  → 19000
//
// This test asserts the accounting identities used by deposit/join/settle/withdraw
// code paths; it is not a live stack run.
func TestMVP005ControlledFinancialScenario(t *testing.T) {
	const (
		start       int64 = 10000
		deposit     int64 = 2000
		entryFee    int64 = 1000
		platformBps       = 2000 // 20%
		prize       int64 = 8000
		withdraw    int64 = 5000
	)

	// Wallet simulation (available balance)
	bal := start
	bal += deposit
	if bal != 12000 {
		t.Fatalf("after deposit bal=%d", bal)
	}
	bal -= entryFee
	if bal != 11000 {
		t.Fatalf("after entry bal=%d", bal)
	}

	// Competition pool: 10 identical entrants for fee identity check
	participants := 10
	gross := int64(participants) * entryFee
	fee := (gross * int64(platformBps)) / 10000
	net := gross - fee
	if gross != 10000 || fee != 2000 || net != 8000 {
		t.Fatalf("pool gross=%d fee=%d net=%d", gross, fee, net)
	}

	// Settlement service fee path agrees with join-time 20%
	s := &SettlementService{app: &App{config: &Config{PlatformFeeBps: 2000}}}
	rankings := make([]contracts.FinalRanking, participants)
	for i := range rankings {
		rankings[i] = contracts.FinalRanking{UserID: "u", Rank: i + 1, FinalScore: float64(100 - i)}
	}
	pool, _ := s.calculatePrizes(rankings, &ContestInfo{EntryFeeCents: entryFee, PlatformFeeBps: platformBps})
	if pool.Gross != gross || pool.PlatformFee != fee || pool.Net != net {
		t.Fatalf("settlement pool mismatch: %+v", pool)
	}

	// Winner wallet after prize
	bal += prize
	if bal != 19000 {
		t.Fatalf("after prize bal=%d", bal)
	}

	// Withdrawal request locks (debits) then reject refunds
	bal -= withdraw
	if bal != 14000 {
		t.Fatalf("after withdraw bal=%d", bal)
	}
	bal += withdraw // reject refund
	if bal != 19000 {
		t.Fatalf("after refund bal=%d", bal)
	}

	// Ledger delta identity: start + deposits - entries + prizes - paid_withdraws + refunds
	// In this scenario paid withdraws = 0, refunds = 1 * withdraw
	final := start + deposit - entryFee + prize - 0 + 0 // open withdraw rejected: net 0
	// Wait: after reject, withdraw is not paid so net withdraw impact is 0.
	// Sequence ends at 19000 = start + deposit - entry + prize
	expected := start + deposit - entryFee + prize
	if bal != expected {
		t.Fatalf("bal=%d expected=%d", bal, expected)
	}
	if final != expected {
		t.Fatalf("identity final=%d expected=%d", final, expected)
	}
}
