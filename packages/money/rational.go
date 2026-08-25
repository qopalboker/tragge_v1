package money

import "fmt"

// Rational is an exact rational weight (numerator/denominator) for prize math.
// Denominator must be > 0. Float conversion is intentionally omitted.
type Rational struct {
	Num int64
	Den int64
}

// NewRational constructs a rational weight; fails closed on den <= 0.
func NewRational(num, den int64) (Rational, error) {
	if den <= 0 {
		return Rational{}, fmt.Errorf("money: rational denominator must be > 0")
	}
	return Rational{Num: num, Den: den}, nil
}

// ApplyToMoney multiplies money by num/den with half-up rounding.
func (r Rational) ApplyToMoney(m Money) (Money, error) {
	prod, err := mulInt64(int64(m), r.Num)
	if err != nil {
		return 0, err
	}
	out, err := divRoundHalfUp(prod, r.Den)
	if err != nil {
		return 0, err
	}
	return Money(out), nil
}
