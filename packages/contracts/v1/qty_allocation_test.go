package v1

import "testing"

func TestDefaultQtyAllocationMatchesProductPolicy(t *testing.T) {
	tests := []struct {
		duration ContestDurationType
		want     int64
	}{
		{ContestDurationRush30Min, 5},
		{ContestDurationHourly, 10},
		{ContestDurationFourHour, 10},
		{ContestDurationDaily, 20},
		{ContestDurationWeekly, 20},
	}
	for _, test := range tests {
		if got := test.duration.DefaultQtyAllocation(); got != test.want {
			t.Fatalf("%s qty = %d, want %d", test.duration, got, test.want)
		}
	}
}

func TestIsAllowedTradingQty(t *testing.T) {
	for _, qty := range []int64{5, 10, 20} {
		if !IsAllowedTradingQty(qty) {
			t.Fatalf("%d should be allowed", qty)
		}
	}
	for _, qty := range []int64{0, 1, 4, 6, 15, 999999, -1} {
		if IsAllowedTradingQty(qty) {
			t.Fatalf("%d must be rejected", qty)
		}
	}
}

func TestContestTemplatesUseDurationQty(t *testing.T) {
	for key, template := range ContestTemplates {
		want := template.DurationType.DefaultQtyAllocation()
		if template.QtyAllocation != want {
			t.Fatalf("template %s qty = %d, want %d from duration %s",
				key, template.QtyAllocation, want, template.DurationType)
		}
	}
}
