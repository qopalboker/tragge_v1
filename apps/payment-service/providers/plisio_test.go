package providers

import (
	"context"
	"crypto/hmac"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

const plisioTestSecret = "plisio-test-secret-key-not-production"

func signPlisioPayload(t *testing.T, secret string, payload map[string]interface{}) string {
	t.Helper()
	clone := make(map[string]interface{}, len(payload))
	for k, v := range payload {
		if k == "verify_hash" {
			continue
		}
		clone[k] = v
	}
	raw, err := marshalSortedCompactJSON(clone)
	if err != nil {
		t.Fatal(err)
	}
	mac := hmac.New(sha1.New, []byte(secret))
	_, _ = mac.Write(raw)
	return hex.EncodeToString(mac.Sum(nil))
}

func TestPlisioVerifyWebhookAcceptsValidSignature(t *testing.T) {
	p := NewPlisio(PlisioConfig{SecretKey: plisioTestSecret})
	payload := map[string]interface{}{
		"txn_id":          "txn-abc",
		"order_number":    "order-123",
		"status":          "completed",
		"source_currency": "USD",
		"source_amount":   "25.00",
		"amount":          "25.00",
		"currency":        "USDT_TRX",
		"ipn_type":        "invoice",
	}
	payload["verify_hash"] = signPlisioPayload(t, plisioTestSecret, payload)
	body, _ := json.Marshal(payload)

	event, err := p.VerifyWebhook(context.Background(), map[string]string{
		"content-type": "application/json",
	}, body)
	if err != nil {
		t.Fatalf("valid callback rejected: %v", err)
	}
	if event.Provider != ProviderPlisio {
		t.Fatalf("provider=%s", event.Provider)
	}
	if event.OrderID != "order-123" || event.ProviderPaymentID != "txn-abc" {
		t.Fatalf("ids mismatch: %+v", event)
	}
	if event.Status != PaymentStatusFinished {
		t.Fatalf("status=%s want finished", event.Status)
	}
	if event.AmountCents != 2500 {
		t.Fatalf("amount_cents=%d want 2500", event.AmountCents)
	}
}

func TestPlisioVerifyWebhookRejectsInvalidMissingModified(t *testing.T) {
	p := NewPlisio(PlisioConfig{SecretKey: plisioTestSecret})
	base := map[string]interface{}{
		"txn_id":          "txn-1",
		"order_number":    "ord-1",
		"status":          "completed",
		"source_currency": "USD",
		"source_amount":   "10.00",
	}
	validHash := signPlisioPayload(t, plisioTestSecret, base)

	tests := []struct {
		name string
		body []byte
	}{
		{"missing hash", mustJSON(map[string]interface{}{
			"txn_id": "txn-1", "order_number": "ord-1", "status": "completed", "source_amount": "10.00",
		})},
		{"wrong secret", func() []byte {
			m := map[string]interface{}{
				"txn_id": "txn-1", "order_number": "ord-1", "status": "completed",
				"source_currency": "USD", "source_amount": "10.00",
			}
			m["verify_hash"] = signPlisioPayload(t, "other-secret", m)
			return mustJSON(m)
		}()},
		{"modified after sign", func() []byte {
			m := map[string]interface{}{
				"txn_id": "txn-1", "order_number": "ord-1", "status": "completed",
				"source_currency": "USD", "source_amount": "10.00",
			}
			m["verify_hash"] = validHash
			m["source_amount"] = "999.00"
			return mustJSON(m)
		}()},
		{"empty body", []byte{}},
		{"garbage", []byte("not-json")},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := p.VerifyWebhook(context.Background(), map[string]string{"content-type": "application/json"}, test.body)
			if err == nil {
				t.Fatal("expected rejection")
			}
		})
	}
}

func TestPlisioStatusMapping(t *testing.T) {
	tests := []struct {
		in   string
		want PaymentStatus
	}{
		{"new", PaymentStatusPending},
		{"pending", PaymentStatusConfirming},
		{"completed", PaymentStatusFinished},
		{"mismatch", PaymentStatusFailed}, // under/overpayment: no auto-credit
		{"expired", PaymentStatusExpired},
		{"error", PaymentStatusFailed},
		{"cancelled", PaymentStatusFailed},
		{"cancelled duplicate", PaymentStatusFailed},
	}
	for _, test := range tests {
		if got := mapPlisioStatus(test.in); got != test.want {
			t.Fatalf("%s -> %s want %s", test.in, got, test.want)
		}
	}
}

func TestPlisioCreatePaymentRequiresOrderAndSecret(t *testing.T) {
	p := NewPlisio(PlisioConfig{SecretKey: ""})
	if p.IsAvailable(context.Background()) {
		t.Fatal("empty secret must be unavailable")
	}
	p = NewPlisio(PlisioConfig{SecretKey: plisioTestSecret})
	_, err := p.CreatePayment(context.Background(), &CreatePaymentRequest{
		AmountCents: 1000,
		// missing OrderID
	})
	if err == nil {
		t.Fatal("missing order_id accepted")
	}
}

func TestPlisioCreatePaymentBuildsInvoiceRequest(t *testing.T) {
	// Stub HTTP by using a custom transport via replacing client after construction.
	var capturedURL string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		capturedURL = r.URL.String()
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"status": "success",
			"data": map[string]interface{}{
				"txn_id":      "txn-created",
				"invoice_url": "https://plisio.net/invoice/txn-created",
			},
		})
	}))
	defer server.Close()

	p := NewPlisio(PlisioConfig{SecretKey: plisioTestSecret, BaseURL: server.URL})
	resp, err := p.CreatePayment(context.Background(), &CreatePaymentRequest{
		AmountCents:    1500,
		OrderID:        "pi-unique-1",
		Description:    "Deposit",
		PayCurrency:    "usdttrc20",
		IPNCallbackURL: "https://api.example/webhooks/plisio",
		CallbackURL:    "https://app.example/success",
		CancelURL:      "https://app.example/cancel",
	})
	if err != nil {
		t.Fatal(err)
	}
	if resp.ProviderPaymentID != "txn-created" || resp.PaymentURL == "" {
		t.Fatalf("unexpected response: %+v", resp)
	}
	if !strings.Contains(capturedURL, "order_number=pi-unique-1") {
		t.Fatalf("order_number missing from request: %s", capturedURL)
	}
	if !strings.Contains(capturedURL, "source_amount=15.00") {
		t.Fatalf("source_amount missing: %s", capturedURL)
	}
	if !strings.Contains(capturedURL, "json%3Dtrue") && !strings.Contains(capturedURL, "json=true") {
		t.Fatalf("callback json=true missing: %s", capturedURL)
	}
	// Secret is query param to Plisio API only — ensure we don't put it in response metadata.
	for k, v := range resp.Metadata {
		if strings.Contains(strings.ToLower(v), strings.ToLower(plisioTestSecret)) ||
			strings.Contains(strings.ToLower(k), "secret") {
			t.Fatalf("secret leaked in metadata %s=%s", k, v)
		}
	}
}

func mustJSON(v interface{}) []byte {
	b, _ := json.Marshal(v)
	return b
}
