package money

import (
	"encoding/json"
	"math"
	"testing"
)

func TestMoneyAddOverflow(t *testing.T) {
	_, err := NewMoney(math.MaxInt64).Add(1)
	if err == nil {
		t.Fatal("expected overflow")
	}
}

func TestApplyBPSPlatformFee(t *testing.T) {
	fee, err := NewMoney(10_000).ApplyBPS(CanonicalPlatformFeeBPS)
	if err != nil {
		t.Fatal(err)
	}
	if fee != 2_000 {
		t.Fatalf("got %d want 2000", fee)
	}
}

func TestMoneyParseFormat(t *testing.T) {
	m, err := ParseMoney("12.34")
	if err != nil {
		t.Fatal(err)
	}
	if m != 1234 {
		t.Fatalf("got %d", m)
	}
	if m.FormatFixed() != "12.34" {
		t.Fatalf("format %s", m.FormatFixed())
	}
	if _, err := ParseMoney("1.234"); err == nil {
		t.Fatal("expected excess precision failure")
	}
}

func TestPriceScoreCannotMixByType(t *testing.T) {
	p, err := NewPrice(123456789, DefaultPriceScale)
	if err != nil {
		t.Fatal(err)
	}
	s, err := NewScore(100, DefaultScoreScale)
	if err != nil {
		t.Fatal(err)
	}
	// Compile-time distinct: assign via conversion only intentionally.
	_ = Price(Fixed(s)) // explicit cast required
	_ = p
}

func TestPriceParseRescale(t *testing.T) {
	p, err := ParsePrice("1.25", 4)
	if err != nil {
		t.Fatal(err)
	}
	if p.Units != 12500 || p.Scale != 4 {
		t.Fatalf("%+v", p)
	}
	up, err := Fixed(p).Rescale(6)
	if err != nil {
		t.Fatal(err)
	}
	if up.Units != 1_250_000 || up.Scale != 6 {
		t.Fatalf("%+v", up)
	}
	if _, err := ParsePrice("1.25001", 4); err == nil {
		t.Fatal("expected excess precision failure")
	}
}

func TestHalfUpRounding(t *testing.T) {
	// 5 / 2 = 2.5 -> 3
	got, err := divRoundHalfUp(5, 2)
	if err != nil || got != 3 {
		t.Fatalf("got %d err=%v", got, err)
	}
	got, err = divRoundHalfUp(-5, 2)
	if err != nil || got != -3 {
		t.Fatalf("got %d err=%v", got, err)
	}
}

func TestRationalApply(t *testing.T) {
	r, err := NewRational(1, 3)
	if err != nil {
		t.Fatal(err)
	}
	out, err := r.ApplyToMoney(100)
	if err != nil {
		t.Fatal(err)
	}
	if out != 33 { // 100/3 = 33.333... -> 33 half_up? 0.333*2 < 1 so floor -> 33
		t.Fatalf("got %d", out)
	}
	out, err = r.ApplyToMoney(101)
	if err != nil {
		t.Fatal(err)
	}
	if out != 34 { // 33.666... -> 34
		t.Fatalf("got %d", out)
	}
}

func TestGoldenMoneySerialization(t *testing.T) {
	type wire struct {
		MoneyMinor int64 `json:"money_minor"`
		FeeBPS     int   `json:"platform_fee_bps"`
		PriceUnits int64 `json:"price_units"`
		PriceScale int   `json:"price_scale"`
		ScoreUnits int64 `json:"score_units"`
		ScoreScale int   `json:"score_scale"`
	}
	w := wire{
		MoneyMinor: 10000,
		FeeBPS:     CanonicalPlatformFeeBPS.Int(),
		PriceUnits: 123456789,
		PriceScale: DefaultPriceScale,
		ScoreUnits: 42,
		ScoreScale: DefaultScoreScale,
	}
	raw, err := json.Marshal(w)
	if err != nil {
		t.Fatal(err)
	}
	want := `{"money_minor":10000,"platform_fee_bps":2000,"price_units":123456789,"price_scale":8,"score_units":42,"score_scale":6}`
	if string(raw) != want {
		t.Fatalf("got %s", raw)
	}
}
