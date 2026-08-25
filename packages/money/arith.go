package money

import (
	"fmt"
	"math"
	"strings"
)

func mulInt64(a, b int64) (int64, error) {
	if a == 0 || b == 0 {
		return 0, nil
	}
	if a == math.MinInt64 && b == -1 {
		return 0, fmt.Errorf("money: multiply overflow")
	}
	if b == math.MinInt64 && a == -1 {
		return 0, fmt.Errorf("money: multiply overflow")
	}
	res := a * b
	if a != 0 && res/a != b {
		return 0, fmt.Errorf("money: multiply overflow")
	}
	return res, nil
}

// divRoundHalfUp implements policy rounding half_up (away from zero on .5).
func divRoundHalfUp(num, den int64) (int64, error) {
	if den == 0 {
		return 0, fmt.Errorf("money: division by zero")
	}
	neg := (num < 0) != (den < 0)
	an, ad := abs64(num), abs64(den)
	q := an / ad
	r := an % ad
	if r*2 >= ad {
		q++
	}
	if neg {
		return -q, nil
	}
	return q, nil
}

func abs64(v int64) int64 {
	if v < 0 {
		return -v
	}
	return v
}

func pow10(exp int) (int64, error) {
	if exp < 0 || exp > MaxScale {
		return 0, fmt.Errorf("money: pow10 exponent out of range")
	}
	var out int64 = 1
	for i := 0; i < exp; i++ {
		next, err := mulInt64(out, 10)
		if err != nil {
			return 0, err
		}
		out = next
	}
	return out, nil
}

func formatUnits(units int64, scale int) string {
	if scale == 0 {
		return fmt.Sprintf("%d", units)
	}
	neg := units < 0
	u := abs64(units)
	factor, err := pow10(scale)
	if err != nil {
		return fmt.Sprintf("%d", units)
	}
	whole := u / factor
	frac := u % factor
	fracStr := fmt.Sprintf("%0*d", scale, frac)
	out := fmt.Sprintf("%d.%s", whole, fracStr)
	if neg {
		return "-" + out
	}
	return out
}

// parseToUnits parses a decimal string into integer units at scale.
// Excess precision beyond scale fails closed.
func parseToUnits(s string, scale int) (int64, error) {
	if err := validateScale(scale); err != nil {
		return 0, err
	}
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, fmt.Errorf("money: empty decimal")
	}
	neg := false
	if strings.HasPrefix(s, "-") {
		neg = true
		s = s[1:]
	} else if strings.HasPrefix(s, "+") {
		s = s[1:]
	}
	parts := strings.Split(s, ".")
	if len(parts) > 2 {
		return 0, fmt.Errorf("money: invalid decimal %q", s)
	}
	whole := parts[0]
	if whole == "" {
		whole = "0"
	}
	for _, ch := range whole {
		if ch < '0' || ch > '9' {
			return 0, fmt.Errorf("money: invalid decimal %q", s)
		}
	}
	var frac string
	if len(parts) == 2 {
		frac = parts[1]
		for _, ch := range frac {
			if ch < '0' || ch > '9' {
				return 0, fmt.Errorf("money: invalid decimal %q", s)
			}
		}
		if len(frac) > scale {
			return 0, fmt.Errorf("money: excess precision for scale %d", scale)
		}
		for len(frac) < scale {
			frac += "0"
		}
	} else {
		frac = strings.Repeat("0", scale)
	}

	factor, err := pow10(scale)
	if err != nil {
		return 0, err
	}
	w, err := parseInt64(whole)
	if err != nil {
		return 0, err
	}
	f, err := parseInt64(frac)
	if err != nil {
		return 0, err
	}
	wu, err := mulInt64(w, factor)
	if err != nil {
		return 0, err
	}
	sum, err := addInt64(wu, f)
	if err != nil {
		return 0, err
	}
	if neg {
		sum = -sum
	}
	return sum, nil
}

func parseInt64(s string) (int64, error) {
	var out int64
	for _, ch := range s {
		d := int64(ch - '0')
		next, err := mulInt64(out, 10)
		if err != nil {
			return 0, err
		}
		out, err = addInt64(next, d)
		if err != nil {
			return 0, err
		}
	}
	return out, nil
}

func addInt64(a, b int64) (int64, error) {
	if (b > 0 && a > math.MaxInt64-b) || (b < 0 && a < math.MinInt64-b) {
		return 0, fmt.Errorf("money: add overflow")
	}
	return a + b, nil
}
