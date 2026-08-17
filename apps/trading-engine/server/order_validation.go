package server

import (
	"fmt"
	"math"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
)

// Financial representation policy (Phase 2):
//   - quantity: int64 whole units (never float)
//   - money/score/PnL (internal calc): shopspring/decimal via packages/scoring
//   - wire/pricebook last-mile: float64 only for market-data transport; validated before use
//   - fee: integer basis points / integer cents (settlement path)
//
// Never trust zero/negative/NaN/Inf prices on executable paths.

const (
	// minExecutablePrice rejects zero/subnormal prices that can poison PnL.
	minExecutablePrice = 1e-12
	// maxExecutablePrice guards against overflow in score calculations.
	maxExecutablePrice = 1e12
)

// validateOrderRequest enforces quantity, price, and TP/SL rules before any DB write.
func validateOrderRequest(order *contracts.OrderRequest) error {
	if order == nil {
		return fmt.Errorf("order is nil")
	}
	if order.OrderID == "" {
		return fmt.Errorf("order_id is required")
	}
	if order.Qty <= 0 {
		return fmt.Errorf("order quantity must be positive, got %d", order.Qty)
	}
	if order.Qty > MaxAllowedQty {
		return fmt.Errorf("order quantity %d exceeds absolute maximum %d", order.Qty, MaxAllowedQty)
	}

	switch order.Type {
	case contracts.OrderTypeBuyLimit, contracts.OrderTypeSellLimit, contracts.OrderTypeLimit:
		if err := requirePositivePrice("limit_price", order.LimitPrice); err != nil {
			return err
		}
	case contracts.OrderTypeBuyStop, contracts.OrderTypeSellStop, contracts.OrderTypeStop:
		if err := requirePositivePrice("stop_price", order.StopPrice); err != nil {
			return err
		}
	case contracts.OrderTypeMarket:
		// market orders do not require limit/stop
	default:
		// unknown types rejected later by ProcessOrder switch
	}

	// Optional limit/stop when present must still be valid (legacy dual-typed requests).
	if order.LimitPrice != nil {
		if err := requirePositivePrice("limit_price", order.LimitPrice); err != nil {
			return err
		}
	}
	if order.StopPrice != nil {
		if err := requirePositivePrice("stop_price", order.StopPrice); err != nil {
			return err
		}
	}

	if err := validateTPSL(order.Side, order.TakeProfit, order.StopLoss, order.LimitPrice, order.StopPrice); err != nil {
		return err
	}
	return nil
}

func requirePositivePrice(field string, p *float64) error {
	if p == nil {
		return fmt.Errorf("%s is required", field)
	}
	return validatePriceValue(field, *p)
}

func validatePriceValue(field string, price float64) error {
	if math.IsNaN(price) || math.IsInf(price, 0) {
		return fmt.Errorf("%s must be a finite number, got %v", field, price)
	}
	if price <= 0 {
		return fmt.Errorf("%s must be positive, got %v", field, price)
	}
	if price < minExecutablePrice {
		return fmt.Errorf("%s %v is below minimum executable price", field, price)
	}
	if price > maxExecutablePrice {
		return fmt.Errorf("%s %v exceeds maximum executable price", field, price)
	}
	return nil
}

// validateTPSL enforces directional TP/SL relative to a reference entry price when known.
// For market orders without an entry yet, only positivity is checked; once filled the
// engine tracks TP/SL against the fill. When limit/stop provides a proxy entry, full
// directional rules apply.
//
// LONG (buy):  TP > entry, SL < entry (when both set relative to entry)
// SHORT (sell): TP < entry, SL > entry
func validateTPSL(side contracts.OrderSide, takeProfit, stopLoss, limitPrice, stopPrice *float64) error {
	if takeProfit != nil {
		if err := validatePriceValue("take_profit", *takeProfit); err != nil {
			return err
		}
	}
	if stopLoss != nil {
		if err := validatePriceValue("stop_loss", *stopLoss); err != nil {
			return err
		}
	}

	entry := referenceEntryPrice(limitPrice, stopPrice)
	if entry == nil {
		// No reference entry — positivity already enforced.
		return nil
	}

	isLong := side == contracts.OrderSideBuy
	if takeProfit != nil {
		if isLong && *takeProfit <= *entry {
			return fmt.Errorf("LONG take_profit (%v) must be greater than entry (%v)", *takeProfit, *entry)
		}
		if !isLong && *takeProfit >= *entry {
			return fmt.Errorf("SHORT take_profit (%v) must be less than entry (%v)", *takeProfit, *entry)
		}
	}
	if stopLoss != nil {
		if isLong && *stopLoss >= *entry {
			return fmt.Errorf("LONG stop_loss (%v) must be less than entry (%v)", *stopLoss, *entry)
		}
		if !isLong && *stopLoss <= *entry {
			return fmt.Errorf("SHORT stop_loss (%v) must be greater than entry (%v)", *stopLoss, *entry)
		}
	}
	return nil
}

func referenceEntryPrice(limitPrice, stopPrice *float64) *float64 {
	if limitPrice != nil && *limitPrice > 0 {
		return limitPrice
	}
	if stopPrice != nil && *stopPrice > 0 {
		return stopPrice
	}
	return nil
}

// isValidMarketPrice reports whether a live fill price is executable.
func isValidMarketPrice(price float64) bool {
	return validatePriceValue("market_price", price) == nil
}

// isPriceTimestampAnomalous detects future-skewed or invalid timestamps that would
// make staleness checks meaningless (negative age).
func isPriceTimestampAnomalous(ageSeconds float64) bool {
	// Negative age => quote timestamp in the future beyond small clock skew.
	// Large negative is always anomalous; allow 2s skew.
	return ageSeconds < -2
}
