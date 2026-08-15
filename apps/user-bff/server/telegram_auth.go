package server

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
	"github.com/Parsaeffatravesh/tragge/packages/secrets"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// handleTelegramMiniAppAuth exchanges verified Telegram WebApp initData for a
// User application session (SEC-001). The frontend must never supply telegram_id
// or user_id as identity — only the signed initData is accepted.
//
// POST /api/user/auth/telegram
// Body: { "init_data": "<Telegram.WebApp.initData>" }
func (a *App) handleTelegramMiniAppAuth(w http.ResponseWriter, r *http.Request) {
	var req struct {
		InitData   string `json:"init_data"`
		TelegramID int64  `json:"telegram_id"`
		UserID     string `json:"user_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSON(w, http.StatusBadRequest, map[string]string{"error": msg.InvalidBody})
		return
	}
	if req.TelegramID != 0 || strings.TrimSpace(req.UserID) != "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{
			"error": "client-supplied identity is not accepted",
			"code":  "telegram_identity_untrusted",
		})
		return
	}
	if strings.TrimSpace(req.InitData) == "" {
		writeJSON(w, http.StatusBadRequest, map[string]string{
			"error": "init_data is required",
			"code":  "telegram_auth_invalid",
		})
		return
	}

	if a.telegramVerifier == nil {
		writeJSON(w, http.StatusServiceUnavailable, map[string]string{
			"error": "telegram authentication is not configured",
			"code":  "telegram_auth_unavailable",
		})
		return
	}

	verified, err := a.telegramVerifier.VerifyInitData(req.InitData)
	if err != nil {
		code := "telegram_auth_invalid"
		if errors.Is(err, auth.ErrTelegramAuthExpired) {
			code = "telegram_auth_expired"
		}
		if a.obs != nil {
			a.log().Warn("Telegram Mini App authentication rejected",
				zap.String("code", code))
		}
		writeJSON(w, http.StatusUnauthorized, map[string]string{
			"error": "telegram authentication failed",
			"code":  code,
		})
		return
	}

	// Replay protection within the freshness window.
	if a.redis != nil {
		replayKey := fmt.Sprintf("telegram:initdata:used:%d:%d", verified.User.ID, verified.AuthDate.Unix())
		ok, setErr := a.redis.SetNX(r.Context(), replayKey, "1", auth.DefaultTelegramAuthMaxAge*2).Result()
		if setErr != nil {
			a.log().Error("Telegram replay store unavailable", zap.Error(setErr))
			writeJSON(w, http.StatusServiceUnavailable, map[string]string{"error": msg.InternalError})
			return
		}
		if !ok {
			writeJSON(w, http.StatusUnauthorized, map[string]string{
				"error": "telegram authentication failed",
				"code":  "telegram_auth_replay",
			})
			return
		}
	}

	userID, err := a.findOrCreateTelegramUser(r.Context(), verified.User)
	if err != nil {
		a.log().Error("Failed to resolve Telegram user", zap.Error(err))
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": msg.InternalError})
		return
	}

	roles, err := a.getUserRoles(r.Context(), userID)
	if err != nil {
		a.log().Error("Failed to load Telegram user roles", zap.Error(err))
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": msg.InternalError})
		return
	}
	// Telegram Mini App never elevates to Admin. Strip elevated roles if present.
	safeRoles := make([]string, 0, len(roles))
	for _, role := range roles {
		switch role {
		case auth.RoleSupportAdmin, auth.RoleSuperAdmin, auth.RoleAdmin, auth.RoleModerator:
			a.log().Error("Telegram auth refused elevated role",
				zap.String("user_id", userID),
				zap.String("role", role))
			writeJSON(w, http.StatusForbidden, map[string]string{"error": "access denied"})
			return
		default:
			safeRoles = append(safeRoles, role)
		}
	}
	if len(safeRoles) == 0 {
		safeRoles = []string{auth.RoleUser}
	}

	pair, sessionID, err := a.auth.Login(r.Context(), userID, safeRoles, r.UserAgent(), getClientIP(r))
	if err != nil {
		a.log().Error("Failed to create Telegram session", zap.Error(err))
		writeJSON(w, http.StatusInternalServerError, map[string]string{"error": msg.InternalError})
		return
	}

	a.setRefreshTokenCookie(w, r, pair.RefreshToken)
	writeJSON(w, http.StatusOK, map[string]interface{}{
		"access_token": pair.AccessToken,
		"expires_at":   pair.ExpiresAt,
		"session_id":   sessionID,
		"user_id":      userID,
		"roles":        safeRoles,
	})
}

func (a *App) findOrCreateTelegramUser(ctx context.Context, tg auth.TelegramUser) (string, error) {
	var userID string
	err := a.pool.Primary().QueryRowContext(ctx, `
		SELECT id FROM users WHERE telegram_id = $1
	`, tg.ID).Scan(&userID)
	if err == nil {
		return userID, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return "", err
	}

	email := auth.SyntheticTelegramEmail(tg.ID)
	username := strings.TrimSpace(tg.Username)
	if username == "" {
		username = fmt.Sprintf("tg_%d", tg.ID)
	}
	displayName := strings.TrimSpace(strings.TrimSpace(tg.FirstName) + " " + strings.TrimSpace(tg.LastName))
	if displayName == "" {
		displayName = username
	}

	tx, err := a.pool.Primary().BeginTx(ctx, nil)
	if err != nil {
		return "", err
	}
	defer tx.Rollback()

	// Create Telegram-only user. Email is a non-delivery synthetic unique key
	// because the users.email column remains NOT NULL UNIQUE.
	err = tx.QueryRowContext(ctx, `
		INSERT INTO users (id, email, password_hash, username, display_name, email_verified, telegram_id, terms_accepted_at, created_at)
		VALUES ($1, $2, NULL, $3, $4, TRUE, $5, NOW(), NOW())
		RETURNING id
	`, uuid.NewString(), email, username, displayName, tg.ID).Scan(&userID)
	if err != nil {
		// Race: another request created the same telegram user.
		if strings.Contains(err.Error(), "duplicate") || strings.Contains(err.Error(), "unique") {
			if selErr := a.pool.Primary().QueryRowContext(ctx, `
				SELECT id FROM users WHERE telegram_id = $1 OR email = $2
			`, tg.ID, email).Scan(&userID); selErr == nil {
				return userID, nil
			}
		}
		return "", err
	}

	var roleID int
	if err := tx.QueryRowContext(ctx, `SELECT id FROM roles WHERE name = 'user'`).Scan(&roleID); err != nil {
		return "", err
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)`, userID, roleID); err != nil {
		return "", err
	}

	if err := tx.Commit(); err != nil {
		return "", err
	}

	if a.wallet != nil {
		if _, werr := a.wallet.CreateWallet(ctx, userID); werr != nil {
			a.log().Warn("Telegram user wallet create deferred", zap.String("user_id", userID), zap.Error(werr))
		}
	}
	return userID, nil
}

func loadTelegramWebAppVerifier() (*auth.TelegramWebAppVerifier, error) {
	token := strings.TrimSpace(secrets.Load("TELEGRAM_BOT_TOKEN"))
	if token == "" {
		env := strings.ToLower(strings.TrimSpace(os.Getenv("ENVIRONMENT")))
		switch env {
		case "development", "local", "test":
			return nil, nil
		default:
			// Production/staging: fail closed only when Telegram is required.
			// Empty ENVIRONMENT is treated as production by isolation config;
			// for Telegram we allow startup without the token so web-only
			// deployments remain available, and the endpoint returns 503.
			return nil, nil
		}
	}
	maxAge := auth.DefaultTelegramAuthMaxAge
	if raw := strings.TrimSpace(os.Getenv("TELEGRAM_AUTH_MAX_AGE_SECONDS")); raw != "" {
		if secs, err := strconv.Atoi(raw); err == nil && secs > 0 && secs <= 900 {
			maxAge = time.Duration(secs) * time.Second
		}
	}
	return auth.NewTelegramWebAppVerifier(token, maxAge)
}
