package payment

import (
	"context"
	"errors"
	"testing"

	"github.com/Parsaeffatravesh/tragge/apps/platform/internal/modules/wallet"
)

type fakeProvider struct{}

func (fakeProvider) Name() string { return "fake" }

func (fakeProvider) CreatePayment(_ context.Context, req CreatePaymentRequest) (*CreatePaymentResponse, error) {
	if req.AmountCents <= 0 {
		return nil, errors.New("bad amount")
	}
	return &CreatePaymentResponse{
		ProviderPaymentID: "prov-1",
		PaymentURL:        "https://example.test/pay",
		Status:            "waiting",
	}, nil
}

func TestDepositProviderOutsideThenCreditViaWallet(t *testing.T) {
	wallets := wallet.New()
	svc := New(wallets)
	svc.RegisterProvider(fakeProvider{})

	intent, err := svc.CreateDeposit(context.Background(), "u1", "fake", 5000)
	if err != nil {
		t.Fatal(err)
	}
	if intent.Status != "processing" || intent.ProviderPaymentID == "" {
		t.Fatalf("intent=%+v", intent)
	}
	bal, _ := wallets.GetBalance(context.Background(), "u1")
	if bal != 0 {
		t.Fatalf("balance credited before webhook: %d", bal)
	}
	if err := svc.ApplyDepositCredit(context.Background(), intent.ID, "idemp-1"); err != nil {
		t.Fatal(err)
	}
	bal, _ = wallets.GetBalance(context.Background(), "u1")
	if bal != 5000 {
		t.Fatalf("balance=%d", bal)
	}
	// Idempotent replay
	if err := svc.ApplyDepositCredit(context.Background(), intent.ID, "idemp-1"); err != nil {
		t.Fatal(err)
	}
	bal, _ = wallets.GetBalance(context.Background(), "u1")
	if bal != 5000 {
		t.Fatalf("double credit: %d", bal)
	}
}

func TestWithdrawStateMachine(t *testing.T) {
	wallets := wallet.New()
	_ = wallets.CreditDeposit(context.Background(), "u1", 10_000, "seed", "seed")
	svc := New(wallets)
	payout, err := svc.RequestWithdraw(context.Background(), "u1", 4000)
	if err != nil {
		t.Fatal(err)
	}
	if err := svc.ApproveWithdraw(context.Background(), payout.ID); err != nil {
		t.Fatal(err)
	}
	if err := svc.CompleteWithdraw(context.Background(), payout.ID); err != nil {
		t.Fatal(err)
	}
	bal, _ := wallets.GetBalance(context.Background(), "u1")
	if bal != 6000 {
		t.Fatalf("balance=%d", bal)
	}
}

func TestProviderReplaceable(t *testing.T) {
	svc := New(wallet.New())
	svc.RegisterProvider(fakeProvider{})
	if _, err := svc.CreateDeposit(context.Background(), "u1", "missing", 100); !errors.Is(err, ErrProviderMissing) {
		t.Fatalf("err=%v", err)
	}
}
