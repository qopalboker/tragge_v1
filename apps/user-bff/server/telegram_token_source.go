package server

import (
	"context"
	"database/sql"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
	"github.com/Parsaeffatravesh/tragge/packages/secrets"
	"go.uber.org/zap"
)

const (
	telegramBotTokenSettingKey = "telegram_bot_token"
	telegramTokenReloadChannel = "system:telegram_bot_token:reload"
)

// resolveTelegramBotToken returns the active bot token.
// Precedence (product decision): Admin DB ciphertext wins over env/file secrets.
func resolveTelegramBotToken(ctx context.Context, db *sql.DB, cryptoKey []byte) (token string, source string) {
	if db != nil && len(cryptoKey) == 32 {
		var ciphertext string
		err := db.QueryRowContext(ctx,
			`SELECT ciphertext FROM system_encrypted_settings WHERE key = $1`,
			telegramBotTokenSettingKey,
		).Scan(&ciphertext)
		if err == nil && strings.TrimSpace(ciphertext) != "" {
			plain, decErr := auth.DecryptSystemSecret(ciphertext, cryptoKey)
			if decErr == nil {
				plain = strings.TrimSpace(plain)
				if plain != "" && !isPlaceholderTelegramBotToken(plain) {
					return plain, "admin_db"
				}
			}
		}
	}
	envToken := strings.TrimSpace(secrets.Load("TELEGRAM_BOT_TOKEN"))
	if envToken != "" && !isPlaceholderTelegramBotToken(envToken) {
		return envToken, "env"
	}
	return "", ""
}

func loadSystemSecretKey() []byte {
	// Prefer dedicated system settings key; fall back to Admin MFA key so
	// api-server (which already mounts ADMIN_MFA_ENCRYPTION_KEY) can decrypt.
	for _, name := range []string{"SYSTEM_SETTINGS_ENCRYPTION_KEY", "ADMIN_MFA_ENCRYPTION_KEY"} {
		raw := strings.TrimSpace(secrets.Load(name))
		if raw == "" {
			continue
		}
		key, err := auth.ParseSystemSecretKey(raw)
		if err == nil {
			return key
		}
	}
	return nil
}

func (a *App) telegramVerifierSnapshot() *auth.TelegramWebAppVerifier {
	if a == nil {
		return nil
	}
	return a.telegramVerifier.Load()
}

func (a *App) reloadTelegramVerifier(ctx context.Context) {
	if a == nil {
		return
	}
	db := (*sql.DB)(nil)
	if a.pool != nil {
		db = a.pool.Primary()
	}
	token, source := resolveTelegramBotToken(ctx, db, a.systemSecretKey)
	if token == "" {
		a.telegramVerifier.Store(nil)
		if a.obs != nil {
			a.log().Info("Telegram Mini App authentication not configured")
		}
		return
	}
	maxAge := auth.DefaultTelegramAuthMaxAge
	if raw := strings.TrimSpace(os.Getenv("TELEGRAM_AUTH_MAX_AGE_SECONDS")); raw != "" {
		if secs, err := strconv.Atoi(raw); err == nil && secs > 0 && secs <= 900 {
			maxAge = time.Duration(secs) * time.Second
		}
	}
	verifier, err := auth.NewTelegramWebAppVerifier(token, maxAge)
	if err != nil {
		if a.obs != nil {
			a.log().Warn("Telegram verifier rebuild failed", zap.String("source", source))
		}
		a.telegramVerifier.Store(nil)
		return
	}
	a.telegramVerifier.Store(verifier)
	if a.obs != nil {
		a.log().Info("Telegram Mini App authentication enabled", zap.String("source", source))
	}
}

func (a *App) startTelegramTokenReloadListener(ctx context.Context) {
	if a == nil || a.redis == nil {
		return
	}
	pubsub := a.redis.Subscribe(ctx, telegramTokenReloadChannel)
	go func() {
		ch := pubsub.Channel()
		for {
			select {
			case <-ctx.Done():
				_ = pubsub.Close()
				return
			case msg, ok := <-ch:
				if !ok {
					return
				}
				if msg == nil {
					continue
				}
				a.reloadTelegramVerifier(context.Background())
			}
		}
	}()
}

