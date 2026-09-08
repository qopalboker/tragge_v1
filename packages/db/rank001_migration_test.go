package db

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestRANK001MigrationContract(t *testing.T) {
	upRaw, err := os.ReadFile(filepath.Join(migrationDir(), "0121_rank001_ranking_eligibility.up.sql"))
	if err != nil {
		t.Fatal(err)
	}
	downRaw, err := os.ReadFile(filepath.Join(migrationDir(), "0121_rank001_ranking_eligibility.down.sql"))
	if err != nil {
		t.Fatal(err)
	}
	up, down := string(upRaw), string(downRaw)
	for _, required := range []string{
		"has_started_trading BOOLEAN NOT NULL DEFAULT FALSE",
		"ranking_started_at TIMESTAMPTZ",
		"has_started_trading = FALSE AND ranking_started_at IS NULL",
		"has_started_trading = TRUE AND ranking_started_at IS NOT NULL",
		"participant ranking activation is permanent",
		"participant ranking activation timestamp is immutable",
		"lifecycle_status = 'ACTIVE' AND has_started_trading = TRUE",
	} {
		if !strings.Contains(up, required) {
			t.Fatalf("RANK-001 migration missing %q", required)
		}
	}
	for _, forbidden := range []string{"UPDATE contest_participants SET has_started_trading", "INSERT INTO contest_participants"} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("RANK-001 migration invents historical activation with %q", forbidden)
		}
	}
	for _, required := range []string{"DROP COLUMN IF EXISTS ranking_started_at", "DROP COLUMN IF EXISTS has_started_trading"} {
		if !strings.Contains(down, required) {
			t.Fatalf("RANK-001 down migration missing %q", required)
		}
	}
}
