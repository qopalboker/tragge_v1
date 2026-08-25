package money

import "fmt"

const (
	// DefaultPriceScale is the DATA-001 default market price scale.
	DefaultPriceScale = 8
	// DefaultRateScale is the DATA-001 default rate scale.
	DefaultRateScale = 8
	// DefaultPnLScale is the DATA-001 default PnL scale.
	DefaultPnLScale = 8
	// DefaultScoreScale is the DATA-001 default T-Score scale.
	DefaultScoreScale = 6
	// MaxScale is the maximum allowed fixed-point scale.
	MaxScale = 18
)

// Fixed is a signed fixed-point value: Units * 10^(-Scale).
type Fixed struct {
	Units int64
	Scale int
}

// Price, Rate, PnL, and Score are distinct nominal types so they cannot be
// accidentally mixed in APIs (same representation, incompatible Go types).

// Price is a fixed-point market price.
type Price Fixed

// Rate is a fixed-point rate (non-BPS).
type Rate Fixed

// PnL is a fixed-point profit-and-loss amount (not Money minor units).
type PnL Fixed

// Score is a fixed-point T-Score / trade score.
type Score Fixed

// NewPrice builds a Price with validation.
func NewPrice(units int64, scale int) (Price, error) {
	if err := validateScale(scale); err != nil {
		return Price{}, err
	}
	return Price{Units: units, Scale: scale}, nil
}

// NewRate builds a Rate with validation.
func NewRate(units int64, scale int) (Rate, error) {
	if err := validateScale(scale); err != nil {
		return Rate{}, err
	}
	return Rate{Units: units, Scale: scale}, nil
}

// NewPnL builds a PnL with validation.
func NewPnL(units int64, scale int) (PnL, error) {
	if err := validateScale(scale); err != nil {
		return PnL{}, err
	}
	return PnL{Units: units, Scale: scale}, nil
}

// NewScore builds a Score with validation.
func NewScore(units int64, scale int) (Score, error) {
	if err := validateScale(scale); err != nil {
		return Score{}, err
	}
	return Score{Units: units, Scale: scale}, nil
}

func validateScale(scale int) error {
	if scale < 0 || scale > MaxScale {
		return fmt.Errorf("money: invalid scale %d", scale)
	}
	return nil
}

// Format returns the decimal string for a Fixed value.
func (f Fixed) Format() string { return formatUnits(f.Units, f.Scale) }

// Format helpers keep call sites type-safe.
func (p Price) Format() string { return Fixed(p).Format() }
func (r Rate) Format() string  { return Fixed(r).Format() }
func (p PnL) Format() string   { return Fixed(p).Format() }
func (s Score) Format() string { return Fixed(s).Format() }

// ParsePrice parses s into Price at the given scale (fail closed on excess precision).
func ParsePrice(s string, scale int) (Price, error) {
	u, err := parseToUnits(s, scale)
	if err != nil {
		return Price{}, err
	}
	return NewPrice(u, scale)
}

// ParseScore parses s into Score at the given scale.
func ParseScore(s string, scale int) (Score, error) {
	u, err := parseToUnits(s, scale)
	if err != nil {
		return Score{}, err
	}
	return NewScore(u, scale)
}

// Rescale converts Fixed to a new scale with half-up rounding; fails on overflow.
func (f Fixed) Rescale(newScale int) (Fixed, error) {
	if err := validateScale(newScale); err != nil {
		return Fixed{}, err
	}
	if newScale == f.Scale {
		return f, nil
	}
	if newScale > f.Scale {
		factor, err := pow10(newScale - f.Scale)
		if err != nil {
			return Fixed{}, err
		}
		units, err := mulInt64(f.Units, factor)
		if err != nil {
			return Fixed{}, err
		}
		return Fixed{Units: units, Scale: newScale}, nil
	}
	factor, err := pow10(f.Scale - newScale)
	if err != nil {
		return Fixed{}, err
	}
	units, err := divRoundHalfUp(f.Units, factor)
	if err != nil {
		return Fixed{}, err
	}
	return Fixed{Units: units, Scale: newScale}, nil
}
