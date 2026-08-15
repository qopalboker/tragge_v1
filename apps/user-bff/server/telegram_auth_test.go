package server

import (
	"bytes"
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"net/url"
	"sort"
	"strings"
	"testing"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
)

const telegramAuthTestToken = "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"

func signInitDataForHandler(t *testing.T, botToken string, fields map[string]string) string {
	t.Helper()
	keys := make([]string, 0, len(fields))
	for key := range fields {
		keys = append(keys, key)
	}
	sort.Strings(keys)
	parts := make([]string, 0, len(keys))
	for _, key := range keys {
		parts = append(parts, key+"="+fields[key])
	}
	dataCheckString := strings.Join(parts, "\n")
	secret := hmac.New(sha256.New, []byte("WebAppData"))
	_, _ = secret.Write([]byte(botToken))
	mac := hmac.New(sha256.New, secret.Sum(nil))
	_, _ = mac.Write([]byte(dataCheckString))
	fields["hash"] = hex.EncodeToString(mac.Sum(nil))
	values := url.Values{}
	for key, value := range fields {
		values.Set(key, value)
	}
	return values.Encode()
}

func TestHandleTelegramMiniAppAuthRejectsUntrustedIdentityAndInvalidInitData(t *testing.T) {
	verifier, err := auth.NewTelegramWebAppVerifier(telegramAuthTestToken, time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	app := &App{telegramVerifier: verifier}

	// Client-supplied telegram_id must never be trusted.
	body, _ := json.Marshal(map[string]interface{}{
		"init_data":   "irrelevant",
		"telegram_id": 999,
	})
	req := httptest.NewRequest(http.MethodPost, "/api/user/auth/telegram", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	app.handleTelegramMiniAppAuth(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("client telegram_id status=%d want 400 body=%s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "telegram_identity_untrusted") {
		t.Fatalf("expected untrusted identity code, got %s", rec.Body.String())
	}

	// Forged initData without valid signature.
	forgedUser, _ := json.Marshal(map[string]interface{}{"id": 1, "first_name": "Eve"})
	forged := url.Values{}
	forged.Set("user", string(forgedUser))
	forged.Set("auth_date", fmt.Sprintf("%d", time.Now().Unix()))
	body, _ = json.Marshal(map[string]string{"init_data": forged.Encode()})
	req = httptest.NewRequest(http.MethodPost, "/api/user/auth/telegram", bytes.NewReader(body))
	rec = httptest.NewRecorder()
	app.handleTelegramMiniAppAuth(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("forged initData status=%d want 401 body=%s", rec.Code, rec.Body.String())
	}

	// Unavailable when verifier is nil.
	app.telegramVerifier = nil
	body, _ = json.Marshal(map[string]string{"init_data": "x"})
	req = httptest.NewRequest(http.MethodPost, "/api/user/auth/telegram", bytes.NewReader(body))
	rec = httptest.NewRecorder()
	app.handleTelegramMiniAppAuth(rec, req)
	if rec.Code != http.StatusServiceUnavailable {
		t.Fatalf("unconfigured status=%d want 503", rec.Code)
	}
}

func TestHandleTelegramMiniAppAuthRejectsExpiredSignedPayload(t *testing.T) {
	verifier, err := auth.NewTelegramWebAppVerifier(telegramAuthTestToken, time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	// Force now far after auth_date by signing with an old auth_date.
	userJSON, _ := json.Marshal(map[string]interface{}{"id": 77, "first_name": "Old"})
	initData := signInitDataForHandler(t, telegramAuthTestToken, map[string]string{
		"auth_date": fmt.Sprintf("%d", time.Now().Add(-2*time.Hour).Unix()),
		"user":      string(userJSON),
	})
	app := &App{telegramVerifier: verifier}
	body, _ := json.Marshal(map[string]string{"init_data": initData})
	req := httptest.NewRequest(http.MethodPost, "/api/user/auth/telegram", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	app.handleTelegramMiniAppAuth(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("expired status=%d want 401 body=%s", rec.Code, rec.Body.String())
	}
	if !strings.Contains(rec.Body.String(), "telegram_auth_expired") &&
		!strings.Contains(rec.Body.String(), "telegram_auth_invalid") {
		t.Fatalf("expected expiry/invalid code, got %s", rec.Body.String())
	}
}
