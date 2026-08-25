package money

import (
	"fmt"
	"math"
)

// MoneyDisplayScale is the USDT display/decimal scale for minor units (cents).
const MoneyDisplayScale = 2

// Money is canonical wallet/economics money in integer minor units.
// It cannot be mixed with Price/Rate/Score without an explicit conversion API.
type Money int64

// ZeroMoney is the zero money value.
const ZeroMoney Money = 0

// NewMoney returns Money from minor units.
func NewMoney(minor int64) Money { return Money(minor) }

// Minor returns the integer minor-unit representation.
func (m Money) Minor() int64 { return int64(m) }

// Add returns m+o or an overflow error.
func (m Money) Add(o Money) (Money, error) {
	a, b := int64(m), int64(o)
	if (b > 0 && a > math.MaxInt64-b) || (b < 0 && a < math.MinInt64-b) {
		return 0, fmt.Errorf("money: add overflow")
	}
	return Money(a + b), nil
}

// Sub returns m-o or an overflow error.
func (m Money) Sub(o Money) (Money, error) {
	return m.Add(-o)
}

// MustAdd panics on overflow (tests only).
func (m Money) MustAdd(o Money) Money {
	out, err := m.Add(o)
	if err != nil {
		panic(err)
	}
	return out
}

// ApplyBPS applies basis points to money using half-up rounding on the absolute product.
// Example: 10000 minor * 2000 bps = 2000 minor.
func (m Money) ApplyBPS(bps BPS) (Money, error) {
	if bps < 0 {
		return 0, fmt.Errorf("money: negative bps not supported for ApplyBPS")
	}
	prod, err := mulInt64(int64(m), int64(bps))
	if err != nil {
		return 0, err
	}
	rounded, err := divRoundHalfUp(prod, 10_000)
	if err != nil {
		return 0, err
	}
	return Money(rounded), nil
}

// FormatFixed formats money as a decimal string using MoneyDisplayScale.
func (m Money) FormatFixed() string {
	return formatUnits(int64(m), MoneyDisplayScale)
}

// ParseMoney parses a decimal string into minor units at MoneyDisplayScale.
func ParseMoney(s string) (Money, error) {
	units, err := parseToUnits(s, MoneyDisplayScale)
	if err != nil {
		return 0, err
	}
	return Money(units), nil
}
