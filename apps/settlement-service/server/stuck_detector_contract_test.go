package server

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// Ensures orphaned-settling recovery never references contests.updated_at
// (column does not exist — caused live SQL errors and blocked settlement recovery).
func TestOrphanedSettlingDetectorUsesEndsAtNotUpdatedAt(t *testing.T) {
	t.Parallel()
	path := filepath.Join("stuck_detector.go")
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	src := string(raw)
	fn := src
	if i := strings.Index(src, "func (a *App) detectOrphanedSettlingContests"); i >= 0 {
		fn = src[i:]
		if j := strings.Index(fn[1:], "\nfunc "); j >= 0 {
			fn = fn[:j+1]
		}
	}
	if strings.Contains(fn, "c.updated_at") {
		t.Fatal("detectOrphanedSettlingContests must not query contests.updated_at")
	}
	if !strings.Contains(fn, "c.ends_at") {
		t.Fatal("detectOrphanedSettlingContests must age orphans by contests.ends_at")
	}
	if !strings.Contains(fn, "LIMIT 5") {
		t.Fatal("detectOrphanedSettlingContests must batch orphans (LIMIT) to avoid stampede")
	}
}
