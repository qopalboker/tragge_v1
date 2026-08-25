package scheduler

import (
	"context"
	"sync/atomic"
)

type lifecycleJob struct {
	svc    *service
	running atomic.Bool
}

func newLifecycleJob(svc *service) *lifecycleJob { return &lifecycleJob{svc: svc} }

func (j *lifecycleJob) Name() string { return "scheduler.lifecycle" }

func (j *lifecycleJob) Start(ctx context.Context) error {
	j.running.Store(true)
	go func() {
		<-ctx.Done()
		j.running.Store(false)
	}()
	return nil
}

func (j *lifecycleJob) Stop(context.Context) error {
	j.running.Store(false)
	return nil
}

// FreePracticeJob is the merged free-contest generation owner (ARCH-003).
// Standalone apps/free-contest-generator must not generate when Platform owns generation.
type freePracticeJob struct {
	svc       *service
	running   atomic.Bool
	instance  string
	onTick    func()
}

func newFreePracticeJob(svc *service) *freePracticeJob {
	return &freePracticeJob{svc: svc, instance: "platform-worker"}
}

func (j *freePracticeJob) Name() string { return "scheduler.free_practice" }

func (j *freePracticeJob) Start(ctx context.Context) error {
	release, err := j.svc.TryAcquireGenerationLock(j.instance)
	if err != nil {
		return err
	}
	j.running.Store(true)
	// One ownership tick documents generation under the scheduler module.
	j.svc.RecordGeneration()
	if j.onTick != nil {
		j.onTick()
	}
	go func() {
		<-ctx.Done()
		j.running.Store(false)
		release()
	}()
	return nil
}

func (j *freePracticeJob) Stop(context.Context) error {
	j.running.Store(false)
	return nil
}

// Running reports whether the free-practice job holds the generation path.
func (j *freePracticeJob) Running() bool { return j.running.Load() }
