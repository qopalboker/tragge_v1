// MD-001: Engine admission of canonical market-data tick v2.
package server

import (
	"fmt"
	"time"

	mdv2 "github.com/Parsaeffatravesh/tragge/packages/contracts/marketdata/v2"
)

// AcceptTickV2 rejects stale or incompatible v2 ticks before pricebook mutation.
// Legacy ticks.v1 float path remains until MD cutover (MD001-KAFKA-V2-CUTOVER).
func AcceptTickV2(ev mdv2.TickEvent, now time.Time, maxAge time.Duration) error {
	if err := mdv2.AcceptForEngine(ev, mdv2.EngineAcceptOptions{
		Now:                 now,
		MaxAge:              maxAge,
		MinNormalizationVer: mdv2.NormalizationVersion,
		AllowSynthetic:      false,
		RequireQuality:      []mdv2.TickQuality{mdv2.QualityGood, mdv2.QualityDegraded},
	}); err != nil {
		return fmt.Errorf("engine tick v2 rejected: %w", err)
	}
	return nil
}
