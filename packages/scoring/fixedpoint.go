// DATA-001: scoring package re-exports Score defaults via money primitives.
package scoring

import "github.com/Parsaeffatravesh/tragge/packages/money"

// CanonicalScoreScale is the DATA-001 default T-Score scale.
const CanonicalScoreScale = money.DefaultScoreScale

// NewCanonicalScore builds a Score at the canonical scale.
func NewCanonicalScore(units int64) (money.Score, error) {
	return money.NewScore(units, CanonicalScoreScale)
}
