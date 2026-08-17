package server

import (
	"testing"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/scoring/economics"
)

func TestContestJoinAllowed(t *testing.T) {
	start := time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC)
	end := start.Add(time.Hour)
	cutoff := economics.LateJoinCutoff(start, end) // 6 minutes for 1h contest

	tests := []struct {
		name    string
		status  string
		isFree  bool
		lateOn  bool
		now     time.Time
		wantOK  bool
		wantLate bool
	}{
		{"registration open paid", "registration_open", false, true, start.Add(-time.Hour), true, false},
		{"running free blocked", "running", true, true, start.Add(time.Minute), false, false},
		{"running paid within cutoff", "running", false, true, start.Add(time.Minute), true, true},
		{"running paid after cutoff", "running", false, true, cutoff.Add(time.Second), false, false},
		{"running late disabled", "running", false, false, start.Add(time.Minute), false, false},
		{"completed blocked", "completed", false, true, start.Add(time.Minute), false, false},
		{"scheduled not open", "scheduled", false, true, start.Add(-time.Hour), false, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ok, late, _ := contestJoinAllowed(tt.status, tt.isFree, tt.lateOn, start, end, tt.now)
			if ok != tt.wantOK || late != tt.wantLate {
				t.Fatalf("ok=%v late=%v want ok=%v late=%v", ok, late, tt.wantOK, tt.wantLate)
			}
		})
	}
}
