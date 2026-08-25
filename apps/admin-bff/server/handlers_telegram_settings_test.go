package server

import (
	"bytes"
	"context"
	"encoding/hex"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
)

func TestMaskAndPlaceholderTelegramTokenHelpers(t *testing.T) {
	if !looksLikePlaceholderBotToken("changeme") {
		t.Fatal("expected placeholder")
	}
	if looksLikePlaceholderBotToken("7123456789:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw") {
		t.Fatal("real-looking token rejected")
	}
	mask := auth.MaskSecret("7123456789:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw")
	if mask == "" || strings.Contains(mask, "AAHdq") || !strings.HasPrefix(mask, "****") {
		t.Fatalf("bad mask %q", mask)
	}
}

func TestGetTelegramSettingsNeverReturnsRawToken(t *testing.T) {
	key := make([]byte, 32)
	for i := range key {
		key[i] = byte(i + 3)
	}
	hexKey := hex.EncodeToString(key)
	t.Setenv("ADMIN_MFA_ENCRYPTION_KEY", hexKey)
	t.Setenv("TELEGRAM_BOT_TOKEN", "7123456789:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw")

	app := &App{config: &Config{AdminMFA: auth.AdminMFAConfig{EncryptionKey: key}}}
	req := httptest.NewRequestWithContext(context.Background(), http.MethodGet, "/api/admin/security/telegram", nil)
	rec := httptest.NewRecorder()
	app.handleGetTelegramSettings(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
	body := rec.Body.String()
	if strings.Contains(body, "AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw") {
		t.Fatal("raw token leaked in GET response")
	}
	var parsed telegramSettingsResponse
	if err := json.Unmarshal(rec.Body.Bytes(), &parsed); err != nil {
		t.Fatal(err)
	}
	if !parsed.Configured || parsed.Source != "env" || parsed.Masked == "" {
		t.Fatalf("unexpected response %#v", parsed)
	}
}

func TestPutTelegramSettingsRejectsEmptyTokenWithoutLeak(t *testing.T) {
	app := &App{config: &Config{}}
	body, _ := json.Marshal(map[string]string{"token": "changeme"})
	req := httptest.NewRequestWithContext(context.Background(), http.MethodPut, "/api/admin/security/telegram", bytes.NewReader(body))
	rec := httptest.NewRecorder()
	app.handlePutTelegramSettings(rec, req)
	if rec.Code != http.StatusBadRequest {
		t.Fatalf("status=%d", rec.Code)
	}
	respBody := rec.Body.String()
	if strings.Contains(respBody, `"token"`) {
		t.Fatal("response echoed token field")
	}
	if strings.Count(respBody, "changeme") > 0 {
		t.Fatal("response echoed placeholder token value")
	}
}
