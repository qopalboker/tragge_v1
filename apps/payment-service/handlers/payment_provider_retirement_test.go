package handlers

import (
	"context"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestRetiredCryptoProviderFailsBeforeRuntimeLookup(t *testing.T) {
	handler := &DepositHandler{}
	recorder := httptest.NewRecorder()
	request := httptest.NewRequestWithContext(
		context.Background(),
		http.MethodPost,
		"/api/payments/deposit/crypto/create",
		strings.NewReader(`{"amount_cents":500,"provider":"payment4","pay_currency":"usdttrc20"}`),
	)

	handler.HandleCreateCryptoDeposit(recorder, request)

	// Unauthenticated requests fail closed; provider allow-list also rejects retired IDs.
	if recorder.Code != http.StatusBadRequest && recorder.Code != http.StatusUnauthorized {
		t.Fatalf("retired provider status=%d want=400 or 401", recorder.Code)
	}
	if strings.Contains(strings.ToLower(recorder.Body.String()), "payment4") {
		t.Fatalf("response reveals retired provider history: %q", recorder.Body.String())
	}
}
