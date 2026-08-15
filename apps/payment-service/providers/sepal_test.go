package providers

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestSepalSandboxURLsAndAvailability(t *testing.T) {
	// Production refuses public test key.
	prod := NewSepal(SepalConfig{APIKey: "test", Sandbox: false})
	if prod.IsAvailable(context.Background()) {
		t.Fatal("production must not accept sandbox test key")
	}
	// Sandbox accepts test key.
	sb := NewSepal(SepalConfig{APIKey: "test", Sandbox: true})
	if !sb.IsAvailable(context.Background()) {
		t.Fatal("sandbox should be available with test key")
	}
	if !strings.Contains(sb.requestURL(), "/api/sandbox/request.json") {
		t.Fatalf("sandbox request url: %s", sb.requestURL())
	}
	if !strings.Contains(sb.verifyURL(), "/api/sandbox/verify.json") {
		t.Fatalf("sandbox verify url: %s", sb.verifyURL())
	}
	if !strings.Contains(sb.paymentPageURL("123"), "/sandbox/payment/123") {
		t.Fatalf("sandbox payment url: %s", sb.paymentPageURL("123"))
	}
}

func TestSepalCreatePaymentBuildsInvoice(t *testing.T) {
	var captured string
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		captured = r.URL.Path
		_ = json.NewEncoder(w).Encode(map[string]interface{}{
			"status": true, "paymentNumber": 412843002512,
		})
	}))
	defer server.Close()

	p := NewSepal(SepalConfig{APIKey: "test", BaseURL: server.URL, Sandbox: true})
	resp, err := p.CreatePayment(context.Background(), &CreatePaymentRequest{
		AmountCents:    8500000, // IRR
		OrderID:        "pi-sepal-1",
		IPNCallbackURL: "https://api.example/webhooks/sepal",
		Description:    "Deposit",
	})
	if err != nil {
		t.Fatal(err)
	}
	if resp.ProviderPaymentID != "412843002512" {
		t.Fatalf("paymentNumber=%s", resp.ProviderPaymentID)
	}
	if !strings.Contains(resp.PaymentURL, "412843002512") {
		t.Fatalf("payment url=%s", resp.PaymentURL)
	}
	if !strings.Contains(captured, "sandbox/request") {
		t.Fatalf("path=%s", captured)
	}
	// Secret must not appear in response metadata values beyond sandbox flag.
	for k, v := range resp.Metadata {
		if strings.Contains(strings.ToLower(v), "test") && k != "sandbox" {
			// apiKey must never leak
		}
		if strings.EqualFold(k, "api_key") || strings.EqualFold(k, "apikey") {
			t.Fatalf("secret key leaked in metadata %s=%s", k, v)
		}
	}
}

func TestSepalVerifyWebhookRequiresServerVerify(t *testing.T) {
	// verify endpoint accepts; callback with status=1
	mux := http.NewServeMux()
	mux.HandleFunc("/api/sandbox/verify.json", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]interface{}{"status": true})
	})
	server := httptest.NewServer(mux)
	defer server.Close()

	p := NewSepal(SepalConfig{APIKey: "test", BaseURL: server.URL, Sandbox: true})
	body, _ := json.Marshal(map[string]interface{}{
		"paymentNumber": "999",
		"invoiceNumber": "pi-1",
		"status":        1,
		"amount":        8500000,
	})
	ev, err := p.VerifyWebhook(context.Background(), map[string]string{"content-type": "application/json"}, body)
	if err != nil {
		t.Fatalf("verify rejected: %v", err)
	}
	if ev.Status != PaymentStatusFinished || ev.OrderID != "pi-1" {
		t.Fatalf("event=%+v", ev)
	}
}

func TestSepalVerifyWebhookRejectsFailedVerify(t *testing.T) {
	mux := http.NewServeMux()
	mux.HandleFunc("/api/sandbox/verify.json", func(w http.ResponseWriter, r *http.Request) {
		_ = json.NewEncoder(w).Encode(map[string]interface{}{"status": false, "message": "invalid"})
	})
	server := httptest.NewServer(mux)
	defer server.Close()

	p := NewSepal(SepalConfig{APIKey: "test", BaseURL: server.URL, Sandbox: true})
	body, _ := json.Marshal(map[string]interface{}{
		"paymentNumber": "999", "invoiceNumber": "pi-1", "status": 1,
	})
	_, err := p.VerifyWebhook(context.Background(), map[string]string{"content-type": "application/json"}, body)
	if err == nil {
		t.Fatal("expected rejection when verify fails")
	}
}

func TestSepalVerifyWebhookRejectsMissingPaymentNumber(t *testing.T) {
	p := NewSepal(SepalConfig{APIKey: "test", Sandbox: true})
	_, err := p.VerifyWebhook(context.Background(), map[string]string{"content-type": "application/json"},
		[]byte(`{"status":1}`))
	if err == nil {
		t.Fatal("expected missing paymentNumber rejection")
	}
}

func TestSepalCreateRequiresOrderAndSecret(t *testing.T) {
	p := NewSepal(SepalConfig{APIKey: "", Sandbox: true})
	if p.IsAvailable(context.Background()) {
		t.Fatal("empty key must be unavailable")
	}
	p = NewSepal(SepalConfig{APIKey: "test", Sandbox: true})
	_, err := p.CreatePayment(context.Background(), &CreatePaymentRequest{AmountCents: 1000})
	if err == nil {
		t.Fatal("missing order_id accepted")
	}
}
