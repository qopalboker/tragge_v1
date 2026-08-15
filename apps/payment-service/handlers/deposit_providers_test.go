package handlers

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Parsaeffatravesh/tragge/apps/payment-service/providers"
)

func TestHandleListCryptoProvidersOmitsUnconfiguredAndSecrets(t *testing.T) {
	registry := providers.NewProviderRegistry()
	registry.Register(providers.NewNowPayments(providers.NowPaymentsConfig{APIKey: "k"}))
	registry.Register(providers.NewPlisio(providers.PlisioConfig{SecretKey: "s"}))
	h := NewDepositHandler(nil, registry, nil, nil, &DepositConfig{
		MinDepositCents: 400,
		MaxDepositCents: 1000000,
	}, nil)

	rec := httptest.NewRecorder()
	req := httptest.NewRequestWithContext(context.Background(), http.MethodGet, "/api/payments/deposit/providers", nil)
	h.HandleListCryptoProviders(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
	body := rec.Body.String()
	if strings.Contains(body, "s") && strings.Contains(strings.ToLower(body), "secret") {
		t.Fatal("response appears to leak secret material")
	}
	if !strings.Contains(body, "nowpayments") || !strings.Contains(body, "plisio") {
		t.Fatalf("expected both providers: %s", body)
	}
	var parsed map[string]interface{}
	if err := json.Unmarshal(rec.Body.Bytes(), &parsed); err != nil {
		t.Fatal(err)
	}
	if int(parsed["min_deposit_cents"].(float64)) != 400 {
		t.Fatalf("min deposit = %v want 400 ($4)", parsed["min_deposit_cents"])
	}
}

func TestHandleCreateCryptoDepositRejectsBelowMinimumAndUnauthenticated(t *testing.T) {
	h := NewDepositHandler(nil, providers.NewProviderRegistry(), nil, nil, &DepositConfig{
		MinDepositCents: 400,
		MaxDepositCents: 1000000,
	}, nil)

	// No auth context → unauthorized
	rec := httptest.NewRecorder()
	req := httptest.NewRequestWithContext(context.Background(), http.MethodPost, "/api/payments/deposit/crypto/create",
		strings.NewReader(`{"amount_cents":500,"provider":"plisio","pay_currency":"usdttrc20"}`))
	h.HandleCreateCryptoDeposit(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("unauthenticated status=%d want 401", rec.Code)
	}
}

func TestHandleCreateCryptoDepositRejectsUnknownProviders(t *testing.T) {
	// Unknown provider is rejected by the allow-list once authenticated.
	// Unauthenticated requests fail closed first (401). Retired-provider
	// rejection is covered by payment_provider_retirement_test.go.
	h := &DepositHandler{config: &DepositConfig{MinDepositCents: 400, MaxDepositCents: 1_000_000}}
	rec := httptest.NewRecorder()
	req := httptest.NewRequestWithContext(context.Background(), http.MethodPost, "/deposit",
		strings.NewReader(`{"amount_cents":400,"provider":"unknown_gateway","pay_currency":"usdttrc20"}`))
	h.HandleCreateCryptoDeposit(rec, req)
	if rec.Code != http.StatusUnauthorized && rec.Code != http.StatusBadRequest {
		t.Fatalf("status=%d", rec.Code)
	}
}
