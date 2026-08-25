package main

import "strconv"

// positiveIntFromEnv parses a positive int env var or returns fallback.
// Extracted for CI-002 coverage of this historically untested wrapper.
func positiveIntFromEnv(getenv func(string) string, key string, fallback int) int {
	if getenv == nil {
		return fallback
	}
	v := getenv(key)
	if v == "" {
		return fallback
	}
	n, err := strconv.Atoi(v)
	if err != nil || n <= 0 {
		return fallback
	}
	return n
}

func tradingCoreDeprecationNotice() string {
	return "trading-core: DEPRECATED wrapper starting (engine :8085, ingestor :8084, trade-bff :8082); prefer profile=target"
}
