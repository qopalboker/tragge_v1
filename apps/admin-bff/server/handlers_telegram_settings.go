package server

import (
	"context"
	"database/sql"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
	"github.com/Parsaeffatravesh/tragge/packages/secrets"
	"go.uber.org/zap"
)

const (
	telegramBotTokenSettingKey = "telegram_bot_token"
	telegramTokenReloadChannel = "system:telegram_bot_token:reload"
	telegramSettingsResourceID = "telegram_bot_token"
)

type telegramSettingsResponse struct {
	Configured bool       `json:"configured"`
	Source     string     `json:"source,omitempty"` // admin_db | env | none — never includes secret
	Masked     string     `json:"masked,omitempty"`
	UpdatedAt  *time.Time `json:"updated_at,omitempty"`
	UpdatedBy  *string    `json:"updated_by,omitempty"`
}

func (a *App) systemSecretKey() ([]byte, error) {
	for _, name := range []string{"SYSTEM_SETTINGS_ENCRYPTION_KEY", "ADMIN_MFA_ENCRYPTION_KEY"} {
		raw := strings.TrimSpace(secrets.Load(name))
		if raw == "" && name == "ADMIN_MFA_ENCRYPTION_KEY" && len(a.config.AdminMFA.EncryptionKey) == 32 {
			return a.config.AdminMFA.EncryptionKey, nil
		}
		if raw == "" {
			continue
		}
		return auth.ParseSystemSecretKey(raw)
	}
	if len(a.config.AdminMFA.EncryptionKey) == 32 {
		return a.config.AdminMFA.EncryptionKey, nil
	}
	return nil, auth.ErrSystemSecretInvalid
}

func (a *App) handleGetTelegramSettings(w http.ResponseWriter, r *http.Request) {
	key, err := a.systemSecretKey()
	resp := telegramSettingsResponse{Configured: false, Source: "none"}
	if err == nil && a.pool != nil {
		var ciphertext string
		var updatedAt time.Time
		var updatedBy sql.NullString
		qErr := a.pool.Replica().QueryRowContext(r.Context(),
			`SELECT ciphertext, updated_at, updated_by::text FROM system_encrypted_settings WHERE key=$1`,
			telegramBotTokenSettingKey,
		).Scan(&ciphertext, &updatedAt, &updatedBy)
		if qErr == nil && ciphertext != "" {
			plain, decErr := auth.DecryptSystemSecret(ciphertext, key)
			if decErr == nil && strings.TrimSpace(plain) != "" {
				resp.Configured = true
				resp.Source = "admin_db"
				resp.Masked = auth.MaskSecret(plain)
				resp.UpdatedAt = &updatedAt
				if updatedBy.Valid {
					u := updatedBy.String
					resp.UpdatedBy = &u
				}
			}
		}
	}
	if !resp.Configured {
		envTok := strings.TrimSpace(secrets.Load("TELEGRAM_BOT_TOKEN"))
		if envTok != "" {
			resp.Configured = true
			resp.Source = "env"
			resp.Masked = auth.MaskSecret(envTok)
		}
	}
	writeJSON(w, http.StatusOK, resp)
}

func (a *App) handlePutTelegramSettings(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Token string `json:"token"`
	}
	if err := json.NewDecoder(io.LimitReader(r.Body, 1<<20)).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid body"})
		return
	}
	token := strings.TrimSpace(req.Token)
	if token == "" || looksLikePlaceholderBotToken(token) {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid telegram bot token", "code": "telegram_token_invalid"})
		return
	}
	key, err := a.systemSecretKey()
	if err != nil {
		a.log().Error("system secret key unavailable for telegram settings")
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "encryption key unavailable", "code": "telegram_settings_crypto_unavailable"})
		return
	}
	ciphertext, err := auth.EncryptSystemSecret(token, key)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "could not store token", "code": "telegram_token_invalid"})
		return
	}
	actor := auth.GetUserID(r.Context())
	_, err = a.pool.Primary().ExecContext(r.Context(), `
		INSERT INTO system_encrypted_settings (key, ciphertext, updated_at, updated_by)
		VALUES ($1, $2, NOW(), NULLIF($3, '')::uuid)
		ON CONFLICT (key) DO UPDATE
		SET ciphertext = EXCLUDED.ciphertext,
		    updated_at = NOW(),
		    updated_by = EXCLUDED.updated_by
	`, telegramBotTokenSettingKey, ciphertext, actor)
	if err != nil {
		a.log().Error("failed to persist telegram bot token setting", zap.Error(err))
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "internal error"})
		return
	}
	a.logAuditEvent(r.Context(), actor, "settings.telegram_bot_token.set", "system_setting", telegramBotTokenSettingKey, map[string]string{
		"configured": "true",
		"masked":     auth.MaskSecret(token),
	})
	a.publishTelegramTokenReload(r.Context())
	writeJSON(w, http.StatusOK, telegramSettingsResponse{
		Configured: true,
		Source:     "admin_db",
		Masked:     auth.MaskSecret(token),
	})
}

func (a *App) handleDeleteTelegramSettings(w http.ResponseWriter, r *http.Request) {
	actor := auth.GetUserID(r.Context())
	_, err := a.pool.Primary().ExecContext(r.Context(),
		`DELETE FROM system_encrypted_settings WHERE key=$1`, telegramBotTokenSettingKey)
	if err != nil {
		a.log().Error("failed to clear telegram bot token setting", zap.Error(err))
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": "internal error"})
		return
	}
	a.logAuditEvent(r.Context(), actor, "settings.telegram_bot_token.clear", "system_setting", telegramBotTokenSettingKey, map[string]string{
		"configured": "false",
	})
	a.publishTelegramTokenReload(r.Context())
	writeJSON(w, http.StatusOK, telegramSettingsResponse{Configured: false, Source: "none"})
}

func (a *App) handleTestTelegramSettings(w http.ResponseWriter, r *http.Request) {
	key, err := a.systemSecretKey()
	if err != nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "encryption key unavailable", "code": "telegram_settings_crypto_unavailable"})
		return
	}
	token := ""
	var ciphertext string
	qErr := a.pool.Replica().QueryRowContext(r.Context(),
		`SELECT ciphertext FROM system_encrypted_settings WHERE key=$1`, telegramBotTokenSettingKey,
	).Scan(&ciphertext)
	if qErr == nil {
		if plain, decErr := auth.DecryptSystemSecret(ciphertext, key); decErr == nil {
			token = strings.TrimSpace(plain)
		}
	}
	if token == "" {
		token = strings.TrimSpace(secrets.Load("TELEGRAM_BOT_TOKEN"))
	}
	if token == "" || looksLikePlaceholderBotToken(token) {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": "telegram bot token not configured", "code": "telegram_auth_unavailable"})
		return
	}
	ok, username, testErr := telegramGetMe(r.Context(), token)
	actor := auth.GetUserID(r.Context())
	okStr := "false"
	if ok {
		okStr = "true"
	}
	a.logAuditEvent(r.Context(), actor, "settings.telegram_bot_token.test", "system_setting", telegramBotTokenSettingKey, map[string]string{
		"ok": okStr,
	})
	if testErr != nil || !ok {
		// Never include upstream bodies that might echo the token.
		writeJSON(w, http.StatusBadGateway, map[string]string{"error": "telegram connection test failed", "code": "telegram_connection_failed"})
		return
	}
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"ok":       true,
		"bot_user": username,
	})
}

func (a *App) requireTelegramBotTokenSensitive() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if err := a.consumeSensitiveGrant(r, actionTelegramBotToken, telegramSettingsResourceID, "settings.manage"); err != nil {
				writeJSON(w, http.StatusForbidden, map[string]string{"error": "sensitive action denied"})
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}

func (a *App) publishTelegramTokenReload(ctx context.Context) {
	if a.redis == nil {
		return
	}
	_ = a.redis.Publish(ctx, telegramTokenReloadChannel, "1").Err()
}

func looksLikePlaceholderBotToken(token string) bool {
	lower := strings.ToLower(strings.TrimSpace(token))
	for _, m := range []string{"placeholder", "changeme", "your-bot-token", "test-bot-token", "xxx", "todo"} {
		if strings.Contains(lower, m) {
			return true
		}
	}
	return !strings.Contains(token, ":")
}

func telegramGetMe(ctx context.Context, token string) (bool, string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "https://api.telegram.org/bot"+token+"/getMe", nil)
	if err != nil {
		return false, "", err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return false, "", err
	}
	defer resp.Body.Close()
	body, _ := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	var parsed struct {
		OK     bool `json:"ok"`
		Result struct {
			Username string `json:"username"`
		} `json:"result"`
	}
	if err := json.Unmarshal(body, &parsed); err != nil {
		return false, "", err
	}
	return parsed.OK, parsed.Result.Username, nil
}
