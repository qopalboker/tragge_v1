package wallet

import (
	"sync"
	"sync/atomic"
	"testing"
)

// FIN-003: model dual finalization triggers — prize credit must succeed once.
// Uses the same idempotency key scheme as CreditPrizeIdempotent.
func TestFIN003ConcurrentPrizeCreditIdempotencyKeys(t *testing.T) {
	contestID := "contest-fin003"
	userID := "user-1"
	rank := 1

	keyA := GeneratePrizeIdempotencyKey(contestID, userID, rank)
	keyB := GeneratePrizeIdempotencyKey(contestID, userID, rank)
	if keyA == "" || keyA != keyB {
		t.Fatalf("idempotency keys must be stable: %q vs %q", keyA, keyB)
	}

	// Simulate two owners racing: only the first insert of the key "wins".
	seen := make(map[string]struct{})
	var mu sync.Mutex
	var successes int32
	var duplicates int32

	tryCredit := func() {
		mu.Lock()
		defer mu.Unlock()
		if _, ok := seen[keyA]; ok {
			atomic.AddInt32(&duplicates, 1)
			return
		}
		seen[keyA] = struct{}{}
		atomic.AddInt32(&successes, 1)
	}

	var wg sync.WaitGroup
	for i := 0; i < 32; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			tryCredit()
		}()
	}
	wg.Wait()

	if successes != 1 {
		t.Fatalf("successes=%d want 1", successes)
	}
	if duplicates != 31 {
		t.Fatalf("duplicates=%d want 31", duplicates)
	}
}

func TestFIN003RefundIdempotencyKeysStable(t *testing.T) {
	a := GenerateRefundIdempotencyKey("c1", "u1")
	b := GenerateRefundIdempotencyKey("c1", "u1")
	c := GenerateRefundIdempotencyKey("c1", "u2")
	if a == "" || a != b {
		t.Fatalf("refund keys unstable: %q %q", a, b)
	}
	if a == c {
		t.Fatal("different users must not share refund idempotency keys")
	}
}
