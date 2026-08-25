package scheduler

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestLIFECYCLE003AuditRetentionYears(t *testing.T) {
	if AuditRetentionYears != 7 {
		t.Fatalf("AuditRetentionYears=%d want 7 (product decision)", AuditRetentionYears)
	}
}

func TestLIFECYCLE003ArchivePathNeverHardDeletesContests(t *testing.T) {
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	src, err := os.ReadFile(filepath.Join(filepath.Dir(thisFile), "cleanup.go"))
	if err != nil {
		t.Fatal(err)
	}
	text := string(src)

	// Isolate archiveCompletedTournaments … next top-level func.
	start := strings.Index(text, "func (cs *CleanupService) archiveCompletedTournaments")
	if start < 0 {
		t.Fatal("archiveCompletedTournaments missing")
	}
	end := strings.Index(text[start+1:], "\nfunc (cs *CleanupService) cancelStaleTournaments")
	if end < 0 {
		// fall back: end at archiveOneContest is included until cancelStale
		end = strings.Index(text[start+1:], "\nfunc (cs *CleanupService)")
	}
	body := text[start : start+1+end]

	if strings.Contains(strings.ToUpper(body), "DELETE FROM CONTESTS") {
		t.Fatal("LIFECYCLE-003: archive path must not hard-DELETE contests")
	}
	if !strings.Contains(body, "SET archived_at") {
		t.Fatal("LIFECYCLE-003: expected soft-delete SET archived_at")
	}
	if !strings.Contains(body, "contest_participants_archive") {
		t.Fatal("LIFECYCLE-003: expected participants archive copy")
	}
	if !strings.Contains(body, "retain_until") && !strings.Contains(body, "AuditRetentionYears") {
		t.Fatal("LIFECYCLE-003: expected retention years wiring")
	}
}

func TestLIFECYCLE003MigrationCreatesArchiveTables(t *testing.T) {
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	// repo root: apps/contest-scheduler/internal/scheduler -> ../../../../
	root := filepath.Clean(filepath.Join(filepath.Dir(thisFile), "..", "..", "..", ".."))
	up, err := os.ReadFile(filepath.Join(root, "packages", "db", "migrations", "0111_lifecycle003_audit_safe_archival.up.sql"))
	if err != nil {
		t.Fatal(err)
	}
	s := string(up)
	for _, needle := range []string{
		"archived_at",
		"contest_participants_archive",
		"contest_symbols_archive",
		"contest_status_history_archive",
		"retain_until",
		"7 years",
	} {
		if !strings.Contains(s, needle) {
			t.Fatalf("migration missing %q", needle)
		}
	}
}
