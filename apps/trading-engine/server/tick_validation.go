package server

import (
	"fmt"
	"math"
	"time"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
)

// Timestamp validation policy for market data (Phase 2 Task 17).
//
// Internal representation: Unix milliseconds (UTC). No timezone-aware wall clocks.
// Seconds-scale values (< 1e12) are normalized to milliseconds.
//
// Reject as non-authoritative:
//   - zero / negative timestamps
//   - future beyond MaxFutureSkew
//   - older than MaxAcceptableAge (extremely old)
//   - NaN/Inf prices
//   - non-positive last/bid/ask when those fields are provided as non-zero intent
//
// Backward time movement: a tick with ts < currently stored quote ts is dropped
// so a stale/fallback source cannot override a newer primary.

const (
	// MaxFutureSkew allows small clock skew between producers and engine.
	MaxFutureSkew = 2 * time.Second
	// MaxAcceptableTickAge rejects extremely old timestamps as market state.
	// Staleness for trading is tighter (MaxPriceAge*); this is a hard validity bound.
	MaxAcceptableTickAge = 24 * time.Hour
)

// TickAcceptResult describes whether a tick may update market state.
type TickAcceptResult struct {
	Accepted bool
	Reason   string
	TsMillis int64
}

// resolveTickTimestamp picks the best timestamp for a symbol tick.
// Prefers per-symbol timestamp when present; otherwise snapshot-level Ts.
func resolveTickTimestamp(snapshotTs int64, symbolTs int64) int64 {
	ts := snapshotTs
	if symbolTs > 0 {
		ts = symbolTs
	}
	return normalizeToMillis(ts)
}

// validateTickTimestamp normalizes and validates a candidate market timestamp.
func validateTickTimestamp(tsMillis int64, now time.Time) TickAcceptResult {
	if tsMillis <= 0 {
		return TickAcceptResult{Accepted: false, Reason: "missing_or_zero_timestamp"}
	}
	// Guard absurd unit mistakes (microseconds accidentally treated as ms would be huge).
	// Unix ms year ~33658 is ~1e15; anything beyond that is not a valid ms epoch for us.
	if tsMillis > 1e15 {
		return TickAcceptResult{Accepted: false, Reason: "timestamp_unit_mismatch"}
	}

	tickTime := time.UnixMilli(tsMillis)
	age := now.Sub(tickTime)
	if age < -MaxFutureSkew {
		return TickAcceptResult{Accepted: false, Reason: "future_timestamp", TsMillis: tsMillis}
	}
	if age > MaxAcceptableTickAge {
		return TickAcceptResult{Accepted: false, Reason: "extremely_old_timestamp", TsMillis: tsMillis}
	}
	return TickAcceptResult{Accepted: true, Reason: "ok", TsMillis: tsMillis}
}

// validateSymbolPrices rejects clearly invalid numeric market state.
func validateSymbolPrices(st contracts.SymbolTick) error {
	check := func(name string, v float64, allowZero bool) error {
		if math.IsNaN(v) || math.IsInf(v, 0) {
			return fmt.Errorf("%s is not finite", name)
		}
		if !allowZero && v < 0 {
			return fmt.Errorf("%s must not be negative", name)
		}
		if v < 0 {
			return fmt.Errorf("%s must not be negative", name)
		}
		return nil
	}
	if err := check("last", st.Last, true); err != nil {
		return err
	}
	if err := check("bid", st.Bid, true); err != nil {
		return err
	}
	if err := check("ask", st.Ask, true); err != nil {
		return err
	}
	// If both bid and ask present, require bid <= ask (crossed book is invalid).
	if st.Bid > 0 && st.Ask > 0 && st.Bid > st.Ask {
		return fmt.Errorf("crossed book: bid %v > ask %v", st.Bid, st.Ask)
	}
	// At least one price must be positive to be authoritative market state.
	if st.Last <= 0 && st.Bid <= 0 && st.Ask <= 0 {
		return fmt.Errorf("no positive price fields")
	}
	return nil
}
