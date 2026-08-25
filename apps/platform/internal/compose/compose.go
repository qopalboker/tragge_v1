// Package compose is the Platform composition root.
// It constructs modules and exposes only Service interfaces to adapters.
package compose

import (
	"context"
	"fmt"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/admin"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/contest"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/events"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/identity"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/kyc"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/leaderboard"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/notification"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/payment"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/scheduler"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/settlement"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/ticket"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/wallet"
	"github.com/Parsaeffatravesh/tragge/packages/auth"
)

// Platform holds wired module Services for all runtime modes.
type Platform struct {
	Identity     identity.Service
	Contest      contest.Service
	Wallet       wallet.Service
	Payment      payment.Service
	KYC          kyc.Service
	Settlement   settlement.Service
	Leaderboard  leaderboard.Service
	Notification notification.Service
	Ticket       ticket.Service
	Admin        admin.Service
	Scheduler    scheduler.Service
	Events       events.Service
}

// New builds the Platform with ARCH-003/004/006 modules wired.
func New() *Platform {
	notif := notification.New()
	wallets := wallet.New()
	ev, err := events.New()
	if err != nil {
		panic(err)
	}
	return &Platform{
		Identity:     identity.New(),
		Contest:      contest.New(),
		Wallet:       wallets,
		Payment:      payment.New(wallets),
		KYC:          kyc.New(),
		Settlement:   settlement.New(),
		Leaderboard:  leaderboard.New(),
		Notification: notif,
		Ticket:       ticket.New(notif),
		Admin:        admin.New(),
		Scheduler:    scheduler.New(),
		Events:       ev,
	}
}

// WorkerJobs returns background jobs for platform --mode=worker (ARCH-003/004/006).
func (p *Platform) WorkerJobs() []modules.Job {
	var jobs []modules.Job
	jobs = append(jobs, p.Scheduler.Jobs()...)
	jobs = append(jobs, p.Leaderboard.Jobs()...)
	jobs = append(jobs, p.Notification.Jobs()...)
	jobs = append(jobs, p.Payment.Jobs()...)
	jobs = append(jobs, p.Settlement.Jobs()...)
	jobs = append(jobs, p.Events.Jobs()...)
	return jobs
}

// NewWithIsolatedAuth wires identity/admin to separate User/Admin Auth contexts (SEC-001/ARCH-002).
func NewWithIsolatedAuth(userAuth, adminAuth *auth.Auth) (*Platform, error) {
	if userAuth == nil || adminAuth == nil {
		return nil, fmt.Errorf("compose: user and admin auth are required")
	}
	if userAuth.Context() != auth.ContextUser || adminAuth.Context() != auth.ContextAdmin {
		return nil, fmt.Errorf("compose: auth contexts are not isolated")
	}
	if userAuth == adminAuth {
		return nil, fmt.Errorf("compose: user and admin auth must be distinct instances")
	}
	idSvc, err := identity.NewWithAuth(userAuth, nil)
	if err != nil {
		return nil, err
	}
	admSvc, err := admin.NewWithAuth(adminAuth, nil)
	if err != nil {
		return nil, err
	}
	p := New()
	p.Identity = idSvc
	p.Admin = admSvc
	return p, nil
}

// Modules returns all modules in stable order for readiness aggregation.
func (p *Platform) Modules() []modules.Module {
	return []modules.Module{
		p.Identity,
		p.Contest,
		p.Wallet,
		p.Payment,
		p.KYC,
		p.Settlement,
		p.Leaderboard,
		p.Notification,
		p.Ticket,
		p.Admin,
		p.Scheduler,
		p.Events,
	}
}

// Ready reports aggregate module readiness for /readyz.
func (p *Platform) Ready(ctx context.Context) error {
	for _, m := range p.Modules() {
		if err := m.Ready(ctx); err != nil {
			return fmt.Errorf("module %s not ready: %w", m.Name(), err)
		}
	}
	return nil
}
