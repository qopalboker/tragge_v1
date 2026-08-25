package money

import "fmt"

// CanonicalPlatformFeeBPS is the sole Platform Fee source (policy §4.2).
const CanonicalPlatformFeeBPS BPS = 2000

// BPS is integer basis points (1% = 100 bps).
type BPS int

// NewBPS constructs BPS and rejects values outside [0, 10000] for fee contexts.
func NewBPS(v int) (BPS, error) {
	if v < 0 || v > 10_000 {
		return 0, fmt.Errorf("money: bps out of range %d", v)
	}
	return BPS(v), nil
}

// Int returns the integer basis-point value.
func (b BPS) Int() int { return int(b) }
