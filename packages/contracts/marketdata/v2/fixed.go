// Package v2 defines the MD-001 canonical fixed-point market-data contracts.
package v2

import (
	"fmt"

	"github.com/Parsaeffatravesh/tragge/packages/money"
)

const (
	// SchemaName is the canonical tick event schema name.
	SchemaName = "tick_event"
	// SchemaVersion is the MD-001 major contract version.
	SchemaVersion = 2
	// DefaultPriceScale is the DATA-001 default market price scale.
	DefaultPriceScale = money.DefaultPriceScale
	// NormalizationVersion is the current bid/ask normalization algorithm version.
	NormalizationVersion = 1
)

// FixedPrice is a wire-safe fixed-point price (no binary float).
type FixedPrice struct {
	Units int64 `json:"units"`
	Scale int   `json:"scale"`
}

// ToMoneyPrice converts to packages/money.Price.
func (p FixedPrice) ToMoneyPrice() (money.Price, error) {
	return money.NewPrice(p.Units, p.Scale)
}

// NewFixedPrice builds a FixedPrice from money.Price.
func NewFixedPrice(p money.Price) FixedPrice {
	return FixedPrice{Units: p.Units, Scale: p.Scale}
}

// Validate checks scale bounds.
func (p FixedPrice) Validate() error {
	if p.Scale < 0 || p.Scale > money.MaxScale {
		return fmt.Errorf("marketdata/v2: invalid price scale %d", p.Scale)
	}
	return nil
}
