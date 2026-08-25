package economics

import (
	"testing"
	"time"
)

func TestJoinAllowed(t *testing.T) {
	start := time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC)
	end := start.Add(time.Hour)
	cutoff := LateJoinCutoff(start, end)

	tests := []struct {
		name     string
		status   string
		isFree   bool
		lateOn   bool
		now      time.Time
		wantOK   bool
		wantLate bool
	}{
		{"registration open paid", JoinStatusRegistrationOpen, false, true, start.Add(-time.Hour), true, false},
		{"registration open free", JoinStatusRegistrationOpen, true, true, start.Add(-time.Hour), true, false},
		{"running free blocked", JoinStatusRunning, true, true, start.Add(time.Minute), false, false},
		{"running paid within cutoff", JoinStatusRunning, false, true, start.Add(time.Minute), true, true},
		{"running paid at start", JoinStatusRunning, false, true, start, true, true},
		{"running paid just before cutoff", JoinStatusRunning, false, true, cutoff.Add(-time.Millisecond), true, true},
		{"running paid after cutoff", JoinStatusRunning, false, true, cutoff.Add(time.Second), false, false},
		{"running paid at cutoff exclusive", JoinStatusRunning, false, true, cutoff, false, false},
		{"running late disabled", JoinStatusRunning, false, false, start.Add(time.Minute), false, false},
		{"completed blocked", "completed", false, true, start.Add(time.Minute), false, false},
		{"settling blocked", "settling", false, true, start.Add(time.Minute), false, false},
		{"scheduled not open", JoinStatusScheduled, false, true, start.Add(-time.Hour), false, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ok, late, reason := JoinAllowed(tt.status, tt.isFree, tt.lateOn, start, end, tt.now)
			if ok != tt.wantOK || late != tt.wantLate {
				t.Fatalf("ok=%v late=%v reason=%q want ok=%v late=%v", ok, late, reason, tt.wantOK, tt.wantLate)
			}
		})
	}
}

func TestLIFECYCLE001LateJoinCutoffPolicyExamples(t *testing.T) {
	start := time.Date(2026, 6, 1, 12, 0, 0, 0, time.UTC)
	cases := []struct {
		name     string
		duration time.Duration
		wantWin  time.Duration
	}{
		{"30 minutes → 3 minutes", 30 * time.Minute, 3 * time.Minute},
		{"4 hours → 24 minutes", 4 * time.Hour, 24 * time.Minute},
		{"1 day → 30 minutes cap", 24 * time.Hour, 30 * time.Minute},
		{"1 week → 30 minutes cap", 7 * 24 * time.Hour, 30 * time.Minute},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			cut := LateJoinCutoff(start, start.Add(tc.duration))
			got := cut.Sub(start)
			if got != tc.wantWin {
				t.Fatalf("window=%v want %v", got, tc.wantWin)
			}
		})
	}
}

func TestLIFECYCLE001LateJoinChargeNotProRataPrize(t *testing.T) {
	onTime := ComputeJoinCharge(10000, 2000, false)
	late := ComputeJoinCharge(10000, 2000, true)
	if onTime.PrizeCents != late.PrizeCents || onTime.PrizeCents != 8000 {
		t.Fatalf("prize contribution on-time=%d late=%d want 8000", onTime.PrizeCents, late.PrizeCents)
	}
	if late.SurchargeCents != 1000 || late.TotalCents != 11000 {
		t.Fatalf("late surcharge=%d total=%d want 1000/11000", late.SurchargeCents, late.TotalCents)
	}
	if onTime.SurchargeCents != 0 || onTime.TotalCents != 10000 {
		t.Fatalf("on-time surcharge=%d total=%d", onTime.SurchargeCents, onTime.TotalCents)
	}
}
