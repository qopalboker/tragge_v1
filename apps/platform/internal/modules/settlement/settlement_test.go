package settlement

import (
	"context"
	"errors"
	"sync"
	"testing"
)

func TestSoleFinalizationOwner(t *testing.T) {
	svc := New()
	if !svc.IsSoleFinalizationOwner() {
		t.Fatal("settlement must be sole finalization owner")
	}
	if err := svc.SettleContest(context.Background(), "c1"); err != nil {
		t.Fatal(err)
	}
	if err := svc.SettleContest(context.Background(), "c1"); !errors.Is(err, ErrAlreadySettled) {
		t.Fatalf("err=%v", err)
	}
}

func TestSettleContestIdempotentUnderRace(t *testing.T) {
	svc := New()
	var wg sync.WaitGroup
	var wins int
	var mu sync.Mutex
	for i := 0; i < 16; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if err := svc.SettleContest(context.Background(), "race"); err == nil {
				mu.Lock()
				wins++
				mu.Unlock()
			}
		}()
	}
	wg.Wait()
	if wins != 1 {
		t.Fatalf("wins=%d want 1", wins)
	}
}
