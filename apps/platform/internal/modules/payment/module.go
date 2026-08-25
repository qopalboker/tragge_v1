// Package payment owns deposit/withdrawal orchestration (ARCH-004).
// Providers remain replaceable adapters; external calls stay outside DB transactions.
// Withdrawal lives here (no separate withdrawal module in compose).
package payment

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"sync"
	"sync/atomic"
	"time"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules"
	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/wallet"
)

var (
	ErrInvalidAmount     = errors.New("payment: invalid amount")
	ErrProviderMissing   = errors.New("payment: provider not registered")
	ErrIntentNotFound    = errors.New("payment: intent not found")
	ErrInvalidTransition = errors.New("payment: invalid state transition")
	ErrPayoutNotFound    = errors.New("payment: payout not found")
)

// Provider is the replaceable payment-gateway adapter contract (ARCH-004).
type Provider interface {
	Name() string
	CreatePayment(ctx context.Context, req CreatePaymentRequest) (*CreatePaymentResponse, error)
}

// CreatePaymentRequest is sent to adapters outside any DB transaction.
type CreatePaymentRequest struct {
	AmountCents int64
	Currency    string
	UserID      string
	OrderID     string
}

// CreatePaymentResponse is returned by adapters.
type CreatePaymentResponse struct {
	ProviderPaymentID string
	PaymentURL        string
	Status            string
}

// DepositIntent is local payment state.
type DepositIntent struct {
	ID                string
	UserID            string
	Provider          string
	AmountCents       int64
	Status            string
	ProviderPaymentID string
	PaymentURL        string
}

// Payout is local withdrawal state.
type Payout struct {
	ID          string
	UserID      string
	AmountCents int64
	Status      string
}

// Service orchestrates deposits/withdrawals with wallet ledger postings.
type Service interface {
	modules.Service
	RegisterProvider(p Provider)
	CreateDeposit(ctx context.Context, userID, provider string, amountCents int64) (*DepositIntent, error)
	ApplyDepositCredit(ctx context.Context, intentID, idempotencyKey string) error
	RequestWithdraw(ctx context.Context, userID string, amountCents int64) (*Payout, error)
	ApproveWithdraw(ctx context.Context, payoutID string) error
	RejectWithdraw(ctx context.Context, payoutID string) error
	CompleteWithdraw(ctx context.Context, payoutID string) error
	Jobs() []modules.Job
}

type intentRepo interface {
	Ping(ctx context.Context) error
	SaveIntent(ctx context.Context, in DepositIntent) error
	GetIntent(ctx context.Context, id string) (*DepositIntent, error)
	UpdateIntent(ctx context.Context, in DepositIntent) error
	SavePayout(ctx context.Context, p Payout) error
	GetPayout(ctx context.Context, id string) (*Payout, error)
	UpdatePayout(ctx context.Context, p Payout) error
}

type memoryStore struct {
	mu      sync.Mutex
	intents map[string]DepositIntent
	payouts map[string]Payout
	seq     atomic.Uint64
}

func newMemoryStore() *memoryStore {
	return &memoryStore{
		intents: map[string]DepositIntent{},
		payouts: map[string]Payout{},
	}
}

func (m *memoryStore) Ping(context.Context) error { return nil }

func (m *memoryStore) nextID(prefix string) string {
	return prefix + "-" + time.Now().UTC().Format("150405") + "-" + itoa(m.seq.Add(1))
}

func itoa(n uint64) string {
	if n == 0 {
		return "0"
	}
	var b [20]byte
	i := len(b)
	for n > 0 {
		i--
		b[i] = byte('0' + n%10)
		n /= 10
	}
	return string(b[i:])
}

func (m *memoryStore) SaveIntent(_ context.Context, in DepositIntent) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.intents[in.ID] = in
	return nil
}

func (m *memoryStore) GetIntent(_ context.Context, id string) (*DepositIntent, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	in, ok := m.intents[id]
	if !ok {
		return nil, ErrIntentNotFound
	}
	cp := in
	return &cp, nil
}

func (m *memoryStore) UpdateIntent(ctx context.Context, in DepositIntent) error {
	return m.SaveIntent(ctx, in)
}

func (m *memoryStore) SavePayout(_ context.Context, p Payout) error {
	m.mu.Lock()
	defer m.mu.Unlock()
	m.payouts[p.ID] = p
	return nil
}

func (m *memoryStore) GetPayout(_ context.Context, id string) (*Payout, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	p, ok := m.payouts[id]
	if !ok {
		return nil, ErrPayoutNotFound
	}
	cp := p
	return &cp, nil
}

func (m *memoryStore) UpdatePayout(ctx context.Context, p Payout) error {
	return m.SavePayout(ctx, p)
}

type service struct {
	store     *memoryStore
	wallet    wallet.Service
	providers map[string]Provider
	mu        sync.RWMutex
}

// New constructs payment orchestration with memory store + Platform wallet.
func New(wallets wallet.Service) Service {
	return &service{
		store:     newMemoryStore(),
		wallet:    wallets,
		providers: map[string]Provider{},
	}
}

func (s *service) Name() string { return "payment" }

func (s *service) Ready(ctx context.Context) error { return s.store.Ping(ctx) }

func (s *service) RegisterProvider(p Provider) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.providers[p.Name()] = p
}

func (s *service) provider(name string) (Provider, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	p, ok := s.providers[name]
	if !ok {
		return nil, ErrProviderMissing
	}
	return p, nil
}

// CreateDeposit records local intent, then calls the provider outside any DB transaction.
func (s *service) CreateDeposit(ctx context.Context, userID, providerName string, amountCents int64) (*DepositIntent, error) {
	if amountCents <= 0 {
		return nil, ErrInvalidAmount
	}
	p, err := s.provider(providerName)
	if err != nil {
		return nil, err
	}
	intent := DepositIntent{
		ID:          s.store.nextID("pi"),
		UserID:      userID,
		Provider:    providerName,
		AmountCents: amountCents,
		Status:      "pending",
	}
	// Local state first (transaction boundary for intent row).
	if err := s.store.SaveIntent(ctx, intent); err != nil {
		return nil, err
	}
	// Provider call OUTSIDE transaction.
	resp, err := p.CreatePayment(ctx, CreatePaymentRequest{
		AmountCents: amountCents,
		Currency:    "USDT",
		UserID:      userID,
		OrderID:     intent.ID,
	})
	if err != nil {
		intent.Status = "failed"
		_ = s.store.UpdateIntent(ctx, intent)
		return nil, err
	}
	intent.Status = "processing"
	intent.ProviderPaymentID = resp.ProviderPaymentID
	intent.PaymentURL = resp.PaymentURL
	if err := s.store.UpdateIntent(ctx, intent); err != nil {
		return nil, err
	}
	return &intent, nil
}

// ApplyDepositCredit credits the wallet and marks intent succeeded in one logical boundary.
func (s *service) ApplyDepositCredit(ctx context.Context, intentID, idempotencyKey string) error {
	intent, err := s.store.GetIntent(ctx, intentID)
	if err != nil {
		return err
	}
	if intent.Status == "succeeded" {
		return nil
	}
	if intent.Status != "processing" && intent.Status != "pending" {
		return ErrInvalidTransition
	}
	if err := s.wallet.CreditDeposit(ctx, intent.UserID, intent.AmountCents, intent.ID, idempotencyKey); err != nil {
		return err
	}
	intent.Status = "succeeded"
	return s.store.UpdateIntent(ctx, *intent)
}

func (s *service) RequestWithdraw(ctx context.Context, userID string, amountCents int64) (*Payout, error) {
	if amountCents <= 0 {
		return nil, ErrInvalidAmount
	}
	payout := Payout{
		ID:          s.store.nextID("po"),
		UserID:      userID,
		AmountCents: amountCents,
		Status:      "pending",
	}
	// One boundary: debit + local payout row.
	if err := s.wallet.DebitWithdrawal(ctx, userID, amountCents, payout.ID, "withdraw:"+payout.ID); err != nil {
		return nil, err
	}
	if err := s.store.SavePayout(ctx, payout); err != nil {
		return nil, err
	}
	return &payout, nil
}

func (s *service) ApproveWithdraw(ctx context.Context, payoutID string) error {
	return s.transitionPayout(ctx, payoutID, "pending", "processing")
}

func (s *service) RejectWithdraw(ctx context.Context, payoutID string) error {
	p, err := s.store.GetPayout(ctx, payoutID)
	if err != nil {
		return err
	}
	if p.Status != "pending" && p.Status != "processing" {
		return ErrInvalidTransition
	}
	// Release held funds.
	if err := s.wallet.CreditDeposit(ctx, p.UserID, p.AmountCents, p.ID, "withdraw_refund:"+p.ID); err != nil {
		return err
	}
	p.Status = "cancelled"
	return s.store.UpdatePayout(ctx, *p)
}

func (s *service) CompleteWithdraw(ctx context.Context, payoutID string) error {
	return s.transitionPayout(ctx, payoutID, "processing", "succeeded")
}

func (s *service) transitionPayout(ctx context.Context, payoutID, from, to string) error {
	p, err := s.store.GetPayout(ctx, payoutID)
	if err != nil {
		return err
	}
	if p.Status != from {
		return ErrInvalidTransition
	}
	p.Status = to
	return s.store.UpdatePayout(ctx, *p)
}

func (s *service) Jobs() []modules.Job {
	return []modules.Job{
		&inquiryJob{svc: s},
		&expiryJob{svc: s},
	}
}

type inquiryJob struct {
	svc     *service
	running atomic.Bool
}

func (j *inquiryJob) Name() string { return "payment.inquiry" }
func (j *inquiryJob) Start(ctx context.Context) error {
	j.running.Store(true)
	go func() {
		<-ctx.Done()
		j.running.Store(false)
	}()
	return nil
}
func (j *inquiryJob) Stop(context.Context) error { j.running.Store(false); return nil }

type expiryJob struct {
	svc     *service
	running atomic.Bool
}

func (j *expiryJob) Name() string { return "payment.expiry" }
func (j *expiryJob) Start(ctx context.Context) error {
	j.running.Store(true)
	go func() {
		<-ctx.Done()
		j.running.Store(false)
	}()
	return nil
}
func (j *expiryJob) Stop(context.Context) error { j.running.Store(false); return nil }

// RegisterRoutes mounts payment/withdrawal boundary APIs on Platform API mode.
func RegisterRoutes(mux *http.ServeMux, svc Service) {
	mux.HandleFunc("/api/payments/v1/boundary", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}
		writeJSON(w, http.StatusOK, map[string]any{
			"module":  svc.Name(),
			"ready":   svc.Ready(r.Context()) == nil,
			"owns":    []string{"deposit", "withdrawal"},
			"ledger":  "platform.wallet",
			"note":    "providers remain adapters; FIN-006 out of scope",
		})
	})
}

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(v)
}

var _ modules.Module = (*service)(nil)
var _ Service = (*service)(nil)
