package main

import (
	"strings"
	"testing"
)

func TestPositiveIntFromEnv(t *testing.T) {
	getenv := func(k string) string {
		switch k {
		case "OK":
			return "12"
		case "NEG":
			return "-1"
		case "BAD":
			return "x"
		default:
			return ""
		}
	}
	if got := positiveIntFromEnv(getenv, "OK", 3); got != 12 {
		t.Fatalf("got %d", got)
	}
	if got := positiveIntFromEnv(getenv, "NEG", 3); got != 3 {
		t.Fatalf("neg fallback got %d", got)
	}
	if got := positiveIntFromEnv(getenv, "BAD", 3); got != 3 {
		t.Fatalf("bad fallback got %d", got)
	}
	if got := positiveIntFromEnv(getenv, "MISSING", 7); got != 7 {
		t.Fatalf("missing fallback got %d", got)
	}
	if got := positiveIntFromEnv(nil, "OK", 9); got != 9 {
		t.Fatalf("nil getenv got %d", got)
	}
}

func TestTradingCoreDeprecationNotice(t *testing.T) {
	n := tradingCoreDeprecationNotice()
	if !strings.Contains(n, "DEPRECATED") || !strings.Contains(n, "profile=target") {
		t.Fatalf("unexpected notice: %q", n)
	}
}
