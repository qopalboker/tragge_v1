package main

import (
	"strings"
	"testing"
)

func TestPositiveIntFromEnv(t *testing.T) {
	getenv := func(k string) string {
		if k == "OK" {
			return "10"
		}
		if k == "BAD" {
			return "nope"
		}
		return ""
	}
	if got := positiveIntFromEnv(getenv, "OK", 4); got != 10 {
		t.Fatalf("got %d", got)
	}
	if got := positiveIntFromEnv(getenv, "BAD", 4); got != 4 {
		t.Fatalf("got %d", got)
	}
	if got := positiveIntFromEnv(getenv, "MISS", 4); got != 4 {
		t.Fatalf("got %d", got)
	}
}

func TestWorkerDeprecationNotice(t *testing.T) {
	n := workerDeprecationNotice()
	if !strings.Contains(n, "DEPRECATED") || !strings.Contains(n, "platform --mode=worker") {
		t.Fatalf("unexpected notice: %q", n)
	}
}
