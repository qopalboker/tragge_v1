package prize

import (
	"fmt"
	"math"

	"github.com/Parsaeffatravesh/tragge/packages/scoring/economics"
)

// CommissionPercentToFraction converts a commission rate from percentage
// representation (e.g. 20.0 for 20%) to fraction representation (e.g. 0.20).
//
// Deprecated for fee authority (FIN-001/FIN-002): prefer platform_fee_bps.
// Kept for legacy call sites that still pass fractions into PreviewPrizes.
//
// Valid range: 0.0 to 100.0 (inclusive). Returns an error for out-of-range values.
func CommissionPercentToFraction(pct float64) (float64, error) {
	if pct < 0 || pct > 100.0 {
		return 0, fmt.Errorf("prize: commission rate %.2f%% is out of valid range [0, 100]", pct)
	}
	return pct / 100.0, nil
}

// FractionToPlatformFeeBps converts a commission fraction (0.20) to bps (2000).
func FractionToPlatformFeeBps(fraction float64) int {
	if fraction <= 0 {
		return 0
	}
	bps := int(math.Round(fraction * 10000))
	return economics.ResolvePlatformFeeBps(bps, 0)
}

// MustCommissionPercentToFraction is like CommissionPercentToFraction but panics
// on invalid input. Use only when the value has already been validated (e.g., from
// database storage where CHECK constraints enforce the range).
func MustCommissionPercentToFraction(pct float64) float64 {
	f, err := CommissionPercentToFraction(pct)
	if err != nil {
		panic(err)
	}
	return f
}
