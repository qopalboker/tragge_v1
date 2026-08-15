package handlers

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sort"
	"strings"
	"testing"

	"github.com/Parsaeffatravesh/tragge/apps/payment-service/providers"
	"go.uber.org/zap"
)

func signPlisioForHandlerTest(t *testing.T, secret string, payload map[string]interface{}) string {
	t.Helper()
	clone := make(map[string]interface{}, len(payload))
	for k, v := range payload {
		if k == "verify_hash" {
			continue
		}
		clone[k] = v
	}
	raw, err := marshalSortedCompactJSONForTest(clone)
	if err != nil {
		t.Fatal(err)
	}
	mac := hmac.New(sha1.New, []byte(secret))
	_, _ = mac.Write(raw)
	return hex.EncodeToString(mac.Sum(nil))
}

func marshalSortedCompactJSONForTest(v interface{}) ([]byte, error) {
	switch val := v.(type) {
	case map[string]interface{}:
		keys := make([]string, 0, len(val))
		for k := range val {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		var b strings.Builder
		b.WriteByte('{')
		for i, k := range keys {
			if i > 0 {
				b.WriteByte(',')
			}
			kb, err := json.Marshal(k)
			if err != nil {
				return nil, err
			}
			b.Write(kb)
			b.WriteByte(':')
			vb, err := marshalSortedCompactJSONForTest(val[k])
			if err != nil {
				return nil, err
			}
			b.Write(vb)
		}
		b.WriteByte('}')
		return []byte(b.String()), nil
	case []interface{}:
		var b strings.Builder
		b.WriteByte('[')
		for i, elem := range val {
			if i > 0 {
				b.WriteByte(',')
			}
			eb, err := marshalSortedCompactJSONForTest(elem)
			if err != nil {
				return nil, err
			}
			b.Write(eb)
		}
		b.WriteByte(']')
		return []byte(b.String()), nil
	default:
		return json.Marshal(val)
	}
}

func TestPlisioWebhookHandlerRejectsInvalidSignature(t *testing.T) {
	registry := providers.NewProviderRegistry()
	registry.Register(providers.NewPlisio(providers.PlisioConfig{SecretKey: "unit-test-secret"}))
	h := NewWebhookHandler(nil, nil, registry, nil, zap.NewNop(), "", "", nil, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"txn_id": "x", "order_number": "y", "status": "completed",
		"source_amount": "10.00", "verify_hash": "deadbeef",
	})
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/webhooks/plisio", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	h.HandlePlisioWebhook(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 401 body=%s", rec.Code, rec.Body.String())
	}
}

func TestPlisioWebhookHandlerRejectsMissingHash(t *testing.T) {
	registry := providers.NewProviderRegistry()
	registry.Register(providers.NewPlisio(providers.PlisioConfig{SecretKey: "unit-test-secret"}))
	h := NewWebhookHandler(nil, nil, registry, nil, zap.NewNop(), "", "", nil, nil)

	body, _ := json.Marshal(map[string]interface{}{
		"txn_id": "x", "order_number": "y", "status": "completed", "source_amount": "10.00",
	})
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/webhooks/plisio", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	h.HandlePlisioWebhook(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 401", rec.Code)
	}
}

func TestPlisioWebhookHandlerRejectsUnknownProvider(t *testing.T) {
	// Registry without Plisio registered.
	registry := providers.NewProviderRegistry()
	h := NewWebhookHandler(nil, nil, registry, nil, zap.NewNop(), "", "", nil, nil)

	payload := map[string]interface{}{
		"txn_id": "x", "order_number": "y", "status": "completed",
		"source_amount": "10.00", "source_currency": "USD",
	}
	// Even with a hash, missing provider registration must fail closed.
	payload["verify_hash"] = "00"
	body, _ := json.Marshal(payload)
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/webhooks/plisio", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	h.HandlePlisioWebhook(rec, req)
	if rec.Code != http.StatusInternalServerError && rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 500 or 401", rec.Code)
	}
}

func TestPlisioWebhookHandlerRejectsValidSignatureWithoutSecurityPolicy(t *testing.T) {
	// Fail closed when signature verifies but replay/freshness policy is unavailable.
	secret := "unit-test-secret"
	registry := providers.NewProviderRegistry()
	registry.Register(providers.NewPlisio(providers.PlisioConfig{SecretKey: secret}))
	h := NewWebhookHandler(nil, nil, registry, nil, zap.NewNop(), "", "", nil, nil)

	payload := map[string]interface{}{
		"txn_id":          "txn-sec",
		"order_number":    "ord-sec",
		"status":          "completed",
		"source_currency": "USD",
		"source_amount":   "10.00",
	}
	payload["verify_hash"] = signPlisioForHandlerTest(t, secret, payload)
	body, _ := json.Marshal(payload)

	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/webhooks/plisio", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	h.HandlePlisioWebhook(rec, req)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status=%d want 503 (security policy required)", rec.Code)
	}
}
