package scheduler

import (
	"testing"
	"time"
)

func TestCalculateNextOccurrence_Every10Min(t *testing.T) {
	// 18:30 → next exclusive 10-min boundary is 18:40
	from := time.Date(2026, 8, 17, 18, 30, 0, 0, time.UTC)
	next, err := calculateNextOccurrence("EVERY_10_MIN", from)
	if err != nil {
		t.Fatal(err)
	}
	want := time.Date(2026, 8, 17, 18, 40, 0, 0, time.UTC)
	if !next.Equal(want) {
		t.Fatalf("got %v want %v", next, want)
	}

	// Chain: 18:40 → 18:50
	next2, err := calculateNextOccurrence("EVERY_10_MIN", next)
	if err != nil {
		t.Fatal(err)
	}
	want2 := time.Date(2026, 8, 17, 18, 50, 0, 0, time.UTC)
	if !next2.Equal(want2) {
		t.Fatalf("got %v want %v", next2, want2)
	}
}

func TestGetDurationTypeFromMinutes_FourHour(t *testing.T) {
	if got := getDurationTypeFromMinutes(240); got != "four_hour" {
		t.Fatalf("got %q want four_hour", got)
	}
	if got := getDurationTypeFromMinutes(30); got != "rush_30min" {
		t.Fatalf("got %q want rush_30min", got)
	}
}

func TestSlotHorizon_30m(t *testing.T) {
	if h := slotHorizon(30); h < 60*time.Minute {
		t.Fatalf("30m horizon too small: %v", h)
	}
}
