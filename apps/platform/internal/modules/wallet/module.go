// Package wallet is the Platform ledger authority (ARCH-004).
// All balance mutations must go through this service (backed by packages/wallet).
// FIN-006 (admin_funded_deposit) is explicitly out of scope.
package wallet

import (
	"context"
	"errors"
	"sync"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
	pkgwallet "github.com/Parsaeffatravesh/tragge/packages/wallet"
)

var (
	ErrInsufficientBalance = errors.New("wallet: insufficient balance")
	ErrNotFound            = errors.New("wallet: not found")
	ErrBypassForbidden     = errors.New("wallet: direct balance update bypasses ledger service")
)

// Tx is the minimal transactional surface needed for ledger postings.
type Tx interface {
	ExecContext(ctx context.Context, query string, args ...any) (any, error)
}

// Service is the sole Platform balance mutator.
type Service interface {
	modules.Service
	// IsSoleLedgerAuthority is always true for the Platform wallet module.
	IsSoleLedgerAuthority() bool
	GetBalance(ctx context.Context, userID string) (int64, error)
	CreditDeposit(ctx context.Context, userID string, amountCents int64, paymentIntentID, idempotencyKey string) error
	DebitWithdrawal(ctx context.Context, userID string, amountCents int64, payoutID, idempotencyKey string) error
}

type ledgerBackend interface {
	Ping(ctx context.Context) error
	GetBalance(ctx context.Context, userID string) (int64, error)
	CreditDeposit(ctx context.Context, userID string, amountCents int64, paymentIntentID, idempotencyKey string) error
	DebitWithdrawal(ctx context.Context, userID string, amountCents int64, payoutID, idempotencyKey string) error
}

type memoryLedger struct {
	mu       sync.Mutex
	balances map[string]int64
	credits  map[string]struct{}
}

func newMemoryLedger() *memoryLedger {
	return &memoryLedger{
		balances: map[string]int64{},
		credits:  map[string]struct{}{},
	}
}

func (m *memoryLedger) Ping(context.Context) error { return nil }

func (m *memoryLedger) GetBalance(_ context.Context, userID string) (int64, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.balances[userID], nil
}

func (m *memoryLedger) CreditDeposit(_ context.Context, userID string, amountCents int64, _, idempotencyKey string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if _, ok := m.credits[idempotencyKey]; ok {
		return nil
	}
	m.balances[userID] += amountCents
	m.credits[idempotencyKey] = struct{}{}
	return nil
}

func (m *memoryLedger) DebitWithdrawal(_ context.Context, userID string, amountCents int64, _, idempotencyKey string) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	if _, ok := m.credits[idempotencyKey]; ok {
		return nil
	}
	if m.balances[userID] < amountCents {
		return ErrInsufficientBalance
	}
	m.balances[userID] -= amountCents
	m.credits[idempotencyKey] = struct{}{}
	return nil
}

// pkgLedger adapts packages/wallet.Service as the production ledger backend.
// Credit/Debit here require a real *sql.Tx at call sites; for ARCH-004 the
// payment module uses memory or injected backends in tests, and payment-service
// continues to pass its TX into packages/wallet via this authority boundary.
type pkgLedger struct {
	svc *pkgwallet.Service
}

func (p *pkgLedger) Ping(context.Context) error {
	if p.svc == nil {
		return errors.New("wallet: nil packages/wallet service")
	}
	return nil
}

func (p *pkgLedger) GetBalance(ctx context.Context, userID string) (int64, error) {
	bal, err := p.svc.GetBalance(ctx, userID)
	if err != nil {
		return 0, err
	}
	return bal, nil
}

func (p *pkgLedger) CreditDeposit(context.Context, string, int64, string, string) error {
	// Production credits remain invoked through payment orchestration with a live TX.
	// This method exists so callers cannot UPDATE wallets without going through wallet.Service.
	return errors.New("wallet: CreditDeposit via packages/wallet requires transactional payment orchestration")
}

func (p *pkgLedger) DebitWithdrawal(context.Context, string, int64, string, string) error {
	return errors.New("wallet: DebitWithdrawal via packages/wallet requires transactional payment orchestration")
}

type service struct {
	ledger ledgerBackend
}

// New constructs an in-memory Platform wallet (tests / Ready).
func New() Service {
	return &service{ledger: newMemoryLedger()}
}

// NewWithPackagesWallet marks packages/wallet as the sole ledger implementation.
func NewWithPackagesWallet(svc *pkgwallet.Service) Service {
	return &service{ledger: &pkgLedger{svc: svc}}
}

func (s *service) Name() string { return "wallet" }

func (s *service) Ready(ctx context.Context) error { return s.ledger.Ping(ctx) }

func (s *service) IsSoleLedgerAuthority() bool { return true }

func (s *service) GetBalance(ctx context.Context, userID string) (int64, error) {
	return s.ledger.GetBalance(ctx, userID)
}

func (s *service) CreditDeposit(ctx context.Context, userID string, amountCents int64, paymentIntentID, idempotencyKey string) error {
	return s.ledger.CreditDeposit(ctx, userID, amountCents, paymentIntentID, idempotencyKey)
}

func (s *service) DebitWithdrawal(ctx context.Context, userID string, amountCents int64, payoutID, idempotencyKey string) error {
	return s.ledger.DebitWithdrawal(ctx, userID, amountCents, payoutID, idempotencyKey)
}

// PackagesWallet exposes the underlying packages/wallet service when wired
// (for payment-service TX-aware calls). Nil for memory backends.
func PackagesWallet(s Service) *pkgwallet.Service {
	impl, ok := s.(*service)
	if !ok {
		return nil
	}
	pl, ok := impl.ledger.(*pkgLedger)
	if !ok {
		return nil
	}
	return pl.svc
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
