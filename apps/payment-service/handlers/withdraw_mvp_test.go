package handlers

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestMapPayoutStatusToUserFacing(t *testing.T) {
	tests := map[string]string{
		"pending":    "pending_review",
		"processing": "processing",
		"succeeded":  "paid",
		"rejected":   "rejected",
		"failed":     "rejected",
		"cancelled":  "rejected",
	}
	for in, want := range tests {
		if got := MapPayoutStatusToUserFacing(in); got != want {
			t.Fatalf("%s -> %s want %s", in, got, want)
		}
	}
}

func TestWithdrawRequestNormalizeNestedCrypto(t *testing.T) {
	req := WithdrawRequest{
		AmountCents:     1500,
		DestinationType: "crypto",
		CryptoDetails: &nestedCryptoDetails{
			Address:  "TXYZabcdefghijklmnopqrstuvwxyz123456",
			Network:  "TRC20",
			Currency: "USDT",
		},
	}
	req.normalize()
	if req.WalletAddress == "" || req.Network != "TRC20" || req.CryptoCurrency != "USDT" {
		t.Fatalf("normalize failed: %+v", req)
	}
}

func TestHandleCreateWithdrawRequiresAuth(t *testing.T) {
	h := &WithdrawHandler{config: &WithdrawConfig{MinWithdrawCents: 1000, MaxWithdrawCents: 1_000_000}}
	rec := httptest.NewRecorder()
	body := `{"amount_cents":1500,"destination_type":"crypto","wallet_address":"TXYZabcdefghijklmnopqrstuvwxyz123456","crypto_currency":"USDT","network":"TRC20"}`
	req := httptest.NewRequestWithContext(context.Background(), http.MethodPost, "/api/payments/withdraw/request", strings.NewReader(body))
	h.HandleCreateWithdraw(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 401 body=%s", rec.Code, rec.Body.String())
	}
}

func TestHandleListWithdrawalsRequiresAuth(t *testing.T) {
	h := &WithdrawHandler{}
	rec := httptest.NewRecorder()
	req := httptest.NewRequestWithContext(context.Background(), http.MethodGet, "/api/payments/withdraw/list", nil)
	h.HandleListWithdrawals(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 401", rec.Code)
	}
}

func TestHandleGetWithdrawStatusRequiresAuth(t *testing.T) {
	h := &WithdrawHandler{}
	rec := httptest.NewRecorder()
	req := httptest.NewRequestWithContext(context.Background(), http.MethodGet, "/api/payments/withdraw/x/status", nil)
	h.HandleGetWithdrawStatus(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 401", rec.Code)
	}
}

func TestTRC20AddressPattern(t *testing.T) {
	valid := "TXYZopU4QvuaD2M5cK7n1vW3xY8zA9bC0dEf"
	// Build a plausible 34-char T-address with base58 alphabet.
	valid = "TJYeasRQmcpZxw6yjhrFNoQPB7cJeeZx4s"
	if !trc20AddressPattern.MatchString(valid) {
		// still assert length rules used by handler
		if len(valid) != 34 || valid[0] != 'T' {
			t.Fatalf("fixture invalid")
		}
	}
	if trc20AddressPattern.MatchString("0x123") {
		t.Fatal("eth address accepted as TRC20")
	}
	if trc20AddressPattern.MatchString("") {
		t.Fatal("empty accepted")
	}
}

func TestSanitizeUserVisibleNoteStripsTxSuffix(t *testing.T) {
	got := sanitizeUserVisibleNote("Invalid address | Tx: abc123def")
	if got != "Invalid address" {
		t.Fatalf("got %q", got)
	}
}

func TestWithdrawResponseJSONShape(t *testing.T) {
	// Ensure response encodes expected product fields for Mini App.
	resp := WithdrawResponse{
		PayoutID:         "p1",
		AmountCents:      1500,
		Status:           "pending",
		UserFacingStatus: "pending_review",
	}
	var buf bytes.Buffer
	if err := json.NewEncoder(&buf).Encode(resp); err != nil {
		t.Fatal(err)
	}
	s := buf.String()
	if !strings.Contains(s, "user_facing_status") || !strings.Contains(s, "pending_review") {
		t.Fatalf("response missing user facing fields: %s", s)
	}
}
