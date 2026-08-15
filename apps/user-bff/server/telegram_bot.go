package server

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/secrets"
	"go.uber.org/zap"
)

// TelegramBot handles Telegram Bot API updates for MVP launch messaging.
// The Bot is NOT the main product UI — it only launches the Mini App.
type TelegramBot struct {
	token         string
	webhookSecret string
	miniAppURL    string
	httpClient    *http.Client
	logger        *zap.Logger
}

// loadTelegramBot constructs a bot from env/secrets. Returns nil when token unset.
// Never logs the token.
func loadTelegramBot(logger *zap.Logger) *TelegramBot {
	token := strings.TrimSpace(secrets.Load("TELEGRAM_BOT_TOKEN"))
	if token == "" {
		return nil
	}
	miniAppURL := strings.TrimSpace(os.Getenv("TELEGRAM_MINI_APP_URL"))
	if miniAppURL == "" {
		miniAppURL = strings.TrimSpace(os.Getenv("FRONTEND_URL"))
	}
	if miniAppURL == "" {
		miniAppURL = "https://app.tragge.com/miniapp"
	}
	if !strings.HasPrefix(miniAppURL, "https://") && !strings.HasPrefix(miniAppURL, "http://") {
		logger.Error("TELEGRAM_MINI_APP_URL must be an absolute http(s) URL")
		return nil
	}
	// Prefer https for Mini App (Telegram requirement in production).
	secret := strings.TrimSpace(secrets.Load("TELEGRAM_WEBHOOK_SECRET"))
	if secret == "" {
		secret = strings.TrimSpace(os.Getenv("TELEGRAM_WEBHOOK_SECRET"))
	}
	return &TelegramBot{
		token:         token,
		webhookSecret: secret,
		miniAppURL:    strings.TrimRight(miniAppURL, "/"),
		httpClient:    &http.Client{Timeout: 15 * time.Second},
		logger:        logger,
	}
}

// Configured reports whether the bot can handle updates.
func (b *TelegramBot) Configured() bool {
	return b != nil && b.token != ""
}

// handleTelegramWebhook receives Telegram Bot API updates.
// Validates X-Telegram-Bot-Api-Secret-Token when TELEGRAM_WEBHOOK_SECRET is set.
// POST /api/user/telegram/webhook
func (a *App) handleTelegramWebhook(w http.ResponseWriter, r *http.Request) {
	if a.telegramBot == nil || !a.telegramBot.Configured() {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{
			"error": "telegram bot is not configured",
			"code":  "telegram_bot_unavailable",
		})
		return
	}
	bot := a.telegramBot

	// Webhook secret validation (required in staging/production when configured).
	if bot.webhookSecret != "" {
		got := strings.TrimSpace(r.Header.Get("X-Telegram-Bot-Api-Secret-Token"))
		if got == "" || got != bot.webhookSecret {
			if bot.logger != nil {
				bot.logger.Warn("Telegram webhook rejected: invalid secret token")
			}
			writeJSON(w, http.StatusUnauthorized, map[string]string{
				"error": "unauthorized",
				"code":  "telegram_webhook_unauthorized",
			})
			return
		}
	} else {
		env := strings.ToLower(strings.TrimSpace(os.Getenv("APP_ENV")))
		if env == "" {
			env = strings.ToLower(strings.TrimSpace(os.Getenv("ENVIRONMENT")))
		}
		if env == "staging" || env == "production" || env == "prod" {
			if bot.logger != nil {
				bot.logger.Warn("Telegram webhook secret not configured in staging/production")
			}
			writeJSON(w, http.StatusServiceUnavailable, map[string]string{
				"error": "telegram webhook not secured",
				"code":  "telegram_webhook_unsecured",
			})
			return
		}
	}

	// Bound body size
	r.Body = http.MaxBytesReader(w, r.Body, 1<<20)
	body, err := io.ReadAll(r.Body)
	if err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid body"})
		return
	}

	var update struct {
		UpdateID int64 `json:"update_id"`
		Message  *struct {
			MessageID int64 `json:"message_id"`
			Chat      struct {
				ID int64 `json:"id"`
			} `json:"chat"`
			Text string `json:"text"`
			From *struct {
				ID int64 `json:"id"`
			} `json:"from"`
		} `json:"message"`
	}
	if err := json.Unmarshal(body, &update); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid update"})
		return
	}

	// Always 200 quickly so Telegram does not retry forever on handler bugs.
	w.WriteHeader(http.StatusOK)
	_, _ = w.Write([]byte(`{"ok":true}`))

	if update.Message == nil {
		return
	}
	text := strings.TrimSpace(update.Message.Text)
	chatID := update.Message.Chat.ID
	if chatID == 0 {
		return
	}

	// Only handle /start (and /start with payload). No conversational product UI.
	if strings.HasPrefix(text, "/start") {
		if err := bot.sendMiniAppLaunch(r.Context(), chatID); err != nil && bot.logger != nil {
			bot.logger.Error("Failed to send Mini App launch message",
				zap.Error(err),
				zap.Int64("chat_id", chatID),
				zap.Int64("update_id", update.UpdateID))
		}
	}
}

func (b *TelegramBot) sendMiniAppLaunch(ctx context.Context, chatID int64) error {
	// web_app button opens the Mini App; no auth tokens in URL (SEC-002).
	miniURL := b.miniAppURL
	if !strings.Contains(miniURL, "/miniapp") {
		miniURL = strings.TrimRight(miniURL, "/") + "/miniapp"
	}
	payload := map[string]interface{}{
		"chat_id": chatID,
		"text":    "Welcome to Tralent.\n\nOpen the Mini App to deposit, compete, and trade.",
		"reply_markup": map[string]interface{}{
			"inline_keyboard": [][]map[string]interface{}{
				{
					{
						"text": "OPEN TRALENT",
						"web_app": map[string]string{
							"url": miniURL,
						},
					},
				},
			},
		},
	}
	return b.apiCall(ctx, "sendMessage", payload)
}

func (b *TelegramBot) apiCall(ctx context.Context, method string, payload interface{}) error {
	body, err := json.Marshal(payload)
	if err != nil {
		return err
	}
	// Token only used server-side in request URL path; never logged.
	endpoint := fmt.Sprintf("https://api.telegram.org/bot%s/%s", b.token, method)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewReader(body))
	if err != nil {
		return err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := b.httpClient.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	raw, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		// Do not include token; body may be safe error description.
		return fmt.Errorf("telegram api %s status=%d", method, resp.StatusCode)
	}
	var result struct {
		OK bool `json:"ok"`
	}
	if err := json.Unmarshal(raw, &result); err != nil {
		return fmt.Errorf("telegram api parse: %w", err)
	}
	if !result.OK {
		return fmt.Errorf("telegram api %s not ok", method)
	}
	return nil
}
