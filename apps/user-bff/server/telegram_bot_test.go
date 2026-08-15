package server

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"

	"go.uber.org/zap"
)

func TestTelegramWebhookRejectsMissingSecretInStaging(t *testing.T) {
	t.Setenv("APP_ENV", "staging")
	app := &App{
		telegramBot: &TelegramBot{
			token:         "unit-test-token-not-real",
			webhookSecret: "",
			miniAppURL:    "https://app.example/miniapp",
			logger:        zap.NewNop(),
		},
	}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/api/user/telegram/webhook", bytes.NewReader([]byte(`{}`)))
	app.handleTelegramWebhook(rec, req)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status=%d want 503", rec.Code)
	}
}

func TestTelegramWebhookRejectsInvalidSecret(t *testing.T) {
	app := &App{
		telegramBot: &TelegramBot{
			token:         "unit-test-token-not-real",
			webhookSecret: "expected-secret",
			miniAppURL:    "https://app.example/miniapp",
			logger:        zap.NewNop(),
		},
	}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/api/user/telegram/webhook", bytes.NewReader([]byte(`{}`)))
	req.Header.Set("X-Telegram-Bot-Api-Secret-Token", "wrong")
	app.handleTelegramWebhook(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d want 401", rec.Code)
	}
}

func TestTelegramWebhookAcceptsValidSecretAndStart(t *testing.T) {
	// Use a transport that swallows Telegram API calls.
	var sent bool
	bot := &TelegramBot{
		token:         "unit-test-token-not-real",
		webhookSecret: "expected-secret",
		miniAppURL:    "https://app.example/miniapp",
		logger:        zap.NewNop(),
		httpClient: &http.Client{
			Transport: roundTripFunc(func(r *http.Request) (*http.Response, error) {
				sent = true
				// Ensure token path is used server-side only (not asserted in response).
				if !bytes.Contains([]byte(r.URL.Path), []byte("sendMessage")) {
					// path includes bot token — do not log
				}
				return &http.Response{
					StatusCode: 200,
					Body:       ioNopCloser(`{"ok":true}`),
					Header:     make(http.Header),
				}, nil
			}),
		},
	}
	app := &App{telegramBot: bot}
	body, _ := json.Marshal(map[string]interface{}{
		"update_id": 1,
		"message": map[string]interface{}{
			"message_id": 1,
			"text":       "/start",
			"chat":       map[string]interface{}{"id": 42},
		},
	})
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/api/user/telegram/webhook", bytes.NewReader(body))
	req.Header.Set("X-Telegram-Bot-Api-Secret-Token", "expected-secret")
	app.handleTelegramWebhook(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
	if !sent {
		t.Fatal("expected sendMessage to Telegram API")
	}
}

func TestTelegramWebhookUnavailableWithoutBot(t *testing.T) {
	app := &App{}
	rec := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/api/user/telegram/webhook", bytes.NewReader([]byte(`{}`)))
	app.handleTelegramWebhook(rec, req)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("status=%d", rec.Code)
	}
}

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(r *http.Request) (*http.Response, error) { return f(r) }

type nopCloser struct{ *bytes.Reader }

func (nopCloser) Close() error { return nil }

func ioNopCloser(s string) *nopCloser {
	return &nopCloser{bytes.NewReader([]byte(s))}
}
