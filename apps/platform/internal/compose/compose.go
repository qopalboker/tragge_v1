// Package compose is the Platform composition root (ARCH-001).
// It constructs modules and exposes only Service interfaces to adapters.
package compose

import (
	"context"
	"fmt"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/admin"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/contest"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/identity"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/kyc"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/leaderboard"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/notification"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/payment"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/scheduler"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/settlement"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/ticket"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/wallet"
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
}

// New builds the skeleton Platform with stub module implementations.
func New() *Platform {
	return &Platform{
		Identity:     identity.New(),
		Contest:      contest.New(),
		Wallet:       wallet.New(),
		Payment:      payment.New(),
		KYC:          kyc.New(),
		Settlement:   settlement.New(),
		Leaderboard:  leaderboard.New(),
		Notification: notification.New(),
		Ticket:       ticket.New(),
		Admin:        admin.New(),
		Scheduler:    scheduler.New(),
	}
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
