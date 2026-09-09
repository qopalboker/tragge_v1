package db

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestECON_ADJMigrationContract(t *testing.T) {
	upRaw, err := os.ReadFile(filepath.Join(migrationDir(), "0122_econ_adj_001_economic_snapshot.up.sql"))
	if err != nil {
		t.Fatal(err)
	}
	downRaw, err := os.ReadFile(filepath.Join(migrationDir(), "0122_econ_adj_001_economic_snapshot.down.sql"))
	if err != nil {
		t.Fatal(err)
	}
	up, down := string(upRaw), string(downRaw)
	for _, required := range []string{
		"joined_participant_count",
		"economic_participant_count",
		"leaderboard_eligible_count",
		"winner_capacity_shortfall",
		"economic_adjustment_events",
		"ECONOMIC_SNAPSHOT_CREATED",
		"PARTICIPANT_REMOVED_BEFORE_CUTOFF",
		"PARTICIPANT_REFUNDED",
		"PARTICIPANT_DISQUALIFIED",
		"BEFORE UPDATE OR DELETE ON economic_adjustment_events",
	} {
		if !strings.Contains(up, required) {
			t.Fatalf("ECON-ADJ migration missing %q", required)
		}
	}
	for _, forbidden := range []string{"CHANGE_PRIZE_POOL", "CHANGE_WINNER_COUNT", "REWRITE_SNAPSHOT", "wallet_ledger", "treasury_ledger"} {
		if strings.Contains(up, forbidden) {
			t.Fatalf("ECON-ADJ migration contains forbidden authority %q", forbidden)
		}
	}
	if !strings.Contains(down, "DROP TABLE IF EXISTS economic_adjustment_events") {
		t.Fatal("ECON-ADJ down migration does not remove its event table")
	}
}
