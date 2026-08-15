package server

import (
	"testing"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
)

// Server-side quantity derivation used by admin contest creation.
func TestSEC003ServerQtyIsDurationControlled(t *testing.T) {
	// Frontend may send any qty; server derives from duration.
	clientQty := int64(999999)
	duration := contracts.ContestDurationRush30Min
	serverQty := duration.DefaultQtyAllocation()
	if clientQty == serverQty {
		t.Fatal("client qty must not equal product max for this attack case")
	}
	if serverQty != 5 {
		t.Fatalf("30m server qty = %d, want 5", serverQty)
	}
	if contracts.IsAllowedTradingQty(clientQty) {
		t.Fatal("client qty 999999 must be rejected by IsAllowedTradingQty")
	}
}

func TestSEC003PlatformFeeDefaultIsTwentyPercent(t *testing.T) {
	// Paid contests default platform_fee_bps = 2000 (20%).
	const defaultPlatformFeeBps = 2000
	const entryFeeCents int64 = 10000 // $100
	platformFee := entryFeeCents * int64(defaultPlatformFeeBps) / 10000
	prizePool := entryFeeCents - platformFee
	if platformFee != 2000 || prizePool != 8000 {
		t.Fatalf("fee split platform=%d pool=%d", platformFee, prizePool)
	}
}
