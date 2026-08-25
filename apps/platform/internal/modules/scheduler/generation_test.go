package scheduler

import (
	"context"
	"fmt"
	"sync"
	"testing"
)

func TestOwnsContestGeneration(t *testing.T) {
	if !New().OwnsContestGeneration() {
		t.Fatal("scheduler must own contest generation")
	}
}

func TestDuplicateGenerationLock(t *testing.T) {
	svc := New().(*service)
	release1, err := svc.TryAcquireGenerationLock("a")
	if err != nil {
		t.Fatal(err)
	}
	if _, err := svc.TryAcquireGenerationLock("b"); err == nil {
		t.Fatal("expected lock held")
	}
	release1()
	release2, err := svc.TryAcquireGenerationLock("b")
	if err != nil {
		t.Fatal(err)
	}
	release2()
}

func TestFreePracticeJobSingleOwnerUnderRace(t *testing.T) {
	svc := New().(*service)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	var wg sync.WaitGroup
	var started int
	var mu sync.Mutex
	for i := 0; i < 8; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			job := newFreePracticeJob(svc)
			job.instance = fmt.Sprintf("inst-%d", id)
			if err := job.Start(ctx); err == nil {
				mu.Lock()
				started++
				mu.Unlock()
			}
		}(i)
	}
	wg.Wait()
	if started != 1 {
		t.Fatalf("started=%d want 1 (single generation owner)", started)
	}
	if svc.GenerationCount() != 1 {
		t.Fatalf("generation count=%d want 1", svc.GenerationCount())
	}
}
