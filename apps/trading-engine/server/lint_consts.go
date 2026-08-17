package server

// Shared string constants used across the engine hot path.
// Defined once so goconst does not flag repeated literals in new code.
const (
	envProduction = "production"
	envStaging    = "staging"
	envProd       = "prod"

	contestStatusRunning = "running"

	orderStatusFilled          = "filled"
	orderStatusAccepted        = "accepted"
	orderStatusOpen            = "open"
	orderStatusPending         = "pending"
	orderStatusPartiallyFilled = "partially_filled"

	priceAgeStale = "stale"
	priceAgeFresh = "fresh"

	metricNameReady = "ready"
)

func isProdLikeEnv(env string) bool {
	return env == envProduction || env == envStaging || env == envProd
}
