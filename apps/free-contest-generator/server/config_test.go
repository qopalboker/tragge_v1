package server

import (
	"os"
	"testing"
)

func TestFreeContestPortDefaultAndOverride(t *testing.T) {
	t.Setenv("FREE_CONTEST_GENERATOR_PORT", "")
	t.Setenv("PORT", "")
	if got := freeContestPort(); got != "8089" {
		t.Fatalf("default port = %q", got)
	}
	t.Setenv("FREE_CONTEST_GENERATOR_PORT", "9099")
	if got := freeContestPort(); got != "9099" {
		t.Fatalf("override = %q", got)
	}
}

func TestLoadConfigDefaultsAndAssetClasses(t *testing.T) {
	// Clear overrides that would skew defaults.
	keys := []string{
		"FREE_CONTEST_GENERATOR_PORT", "PORT",
		"FREE_CONTEST_ENABLED", "FREE_CONTEST_INTERVAL_MINUTES",
		"FREE_CONTEST_DURATION_MINUTES", "FREE_CONTEST_WEEKDAYS_ONLY",
		"FREE_CONTEST_START_HOUR_UTC", "FREE_CONTEST_END_HOUR_UTC",
		"FREE_CONTEST_LEAD_TIME_MINUTES", "FREE_CONTEST_ASSET_CLASSES",
		"FREE_CONTEST_CLEANUP_ENABLED",
	}
	for _, k := range keys {
		_ = os.Unsetenv(k)
	}
	cfg := loadConfig()
	if cfg.Port != "8089" {
		t.Fatalf("port=%q", cfg.Port)
	}
	if cfg.IntervalMinutes != 60 || cfg.DurationMinutes != 60 {
		t.Fatalf("interval/duration = %d/%d", cfg.IntervalMinutes, cfg.DurationMinutes)
	}
	if !cfg.WeekdaysOnly || cfg.StartHourUTC != 6 || cfg.EndHourUTC != 22 {
		t.Fatalf("schedule window unexpected: %+v", cfg)
	}
	if len(cfg.AssetClasses) != 2 || cfg.AssetClasses[0] != "forex" || cfg.AssetClasses[1] != "crypto" {
		t.Fatalf("asset classes = %#v", cfg.AssetClasses)
	}

	t.Setenv("FREE_CONTEST_ASSET_CLASSES", " crypto , forex ")
	cfg2 := loadConfig()
	if len(cfg2.AssetClasses) != 2 || cfg2.AssetClasses[0] != "crypto" || cfg2.AssetClasses[1] != "forex" {
		t.Fatalf("trimmed asset classes = %#v", cfg2.AssetClasses)
	}
}

func TestMustGetEnvPanicsWhenMissing(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Fatal("expected panic")
		}
	}()
	_ = os.Unsetenv("CI002_MUST_GET_ENV_MISSING")
	_ = mustGetEnv("CI002_MUST_GET_ENV_MISSING")
}
