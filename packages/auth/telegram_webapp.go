package auth

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

// Telegram WebApp initData validation follows:
// https://core.telegram.org/bots/webapps#validating-data-received-via-the-mini-app
//
// The Mini App must never be trusted for identity. Only a server-verified
// initData payload may establish a User application session.

const (
	// DefaultTelegramAuthMaxAge is the maximum age of initData auth_date
	// accepted for session exchange. After exchange, the application JWT
	// session is used and initData is not re-sent on every request.
	DefaultTelegramAuthMaxAge = 5 * time.Minute

	telegramWebAppDataKey = "WebAppData"
)

var (
	// ErrTelegramAuthInvalid indicates the initData payload failed validation.
	ErrTelegramAuthInvalid = errors.New("auth: telegram authentication invalid")
	// ErrTelegramAuthExpired indicates auth_date is outside the allowed window.
	ErrTelegramAuthExpired = errors.New("auth: telegram authentication expired")
	// ErrTelegramAuthConfig indicates bot token / verifier configuration is missing.
	ErrTelegramAuthConfig = errors.New("auth: telegram authentication is not configured")
)

// TelegramUser is the verified user object from Telegram initData.
type TelegramUser struct {
	ID           int64  `json:"id"`
	FirstName    string `json:"first_name"`
	LastName     string `json:"last_name,omitempty"`
	Username     string `json:"username,omitempty"`
	LanguageCode string `json:"language_code,omitempty"`
	IsPremium    bool   `json:"is_premium,omitempty"`
	PhotoURL     string `json:"photo_url,omitempty"`
}

// TelegramWebAppAuth is the verified result of Mini App initData validation.
type TelegramWebAppAuth struct {
	User      TelegramUser
	AuthDate  time.Time
	QueryID   string
	ChatType  string
	ChatInstance string
	StartParam string
}

// TelegramWebAppVerifier validates Telegram Mini App initData using the bot token.
// The bot token must remain server-side only and must never be logged.
type TelegramWebAppVerifier struct {
	botToken []byte
	maxAge   time.Duration
	now      func() time.Time
}

// NewTelegramWebAppVerifier constructs a verifier. botToken must be non-empty.
// maxAge <= 0 selects DefaultTelegramAuthMaxAge.
func NewTelegramWebAppVerifier(botToken string, maxAge time.Duration) (*TelegramWebAppVerifier, error) {
	token := strings.TrimSpace(botToken)
	if token == "" {
		return nil, ErrTelegramAuthConfig
	}
	if maxAge <= 0 {
		maxAge = DefaultTelegramAuthMaxAge
	}
	return &TelegramWebAppVerifier{
		botToken: []byte(token),
		maxAge:   maxAge,
		now:      time.Now,
	}, nil
}

// VerifyInitData validates the raw Telegram WebApp initData query string.
// It returns only cryptographically verified identity data.
func (v *TelegramWebAppVerifier) VerifyInitData(initData string) (*TelegramWebAppAuth, error) {
	if v == nil || len(v.botToken) == 0 {
		return nil, ErrTelegramAuthConfig
	}
	raw := strings.TrimSpace(initData)
	if raw == "" {
		return nil, ErrTelegramAuthInvalid
	}

	values, err := url.ParseQuery(raw)
	if err != nil {
		return nil, fmt.Errorf("%w: malformed init data", ErrTelegramAuthInvalid)
	}

	receivedHash := strings.TrimSpace(values.Get("hash"))
	if receivedHash == "" {
		return nil, fmt.Errorf("%w: missing hash", ErrTelegramAuthInvalid)
	}
	// Remove hash before building the data-check string.
	values.Del("hash")

	// Telegram signs the exact key=value pairs sorted by key, joined by '\n'.
	// url.Values may hold multiple values; Telegram sends single values.
	keys := make([]string, 0, len(values))
	for key := range values {
		keys = append(keys, key)
	}
	sort.Strings(keys)

	parts := make([]string, 0, len(keys))
	for _, key := range keys {
		// Use the first value only; multi-value fields are not part of the
		// Telegram contract and would break the signature.
		parts = append(parts, key+"="+values.Get(key))
	}
	dataCheckString := strings.Join(parts, "\n")

	secretKey := hmacSHA256([]byte(telegramWebAppDataKey), v.botToken)
	expectedMAC := hmacSHA256(secretKey, []byte(dataCheckString))
	receivedMAC, err := hex.DecodeString(receivedHash)
	if err != nil || len(receivedMAC) != len(expectedMAC) || !hmac.Equal(expectedMAC, receivedMAC) {
		return nil, ErrTelegramAuthInvalid
	}

	authDateRaw := strings.TrimSpace(values.Get("auth_date"))
	if authDateRaw == "" {
		return nil, fmt.Errorf("%w: missing auth_date", ErrTelegramAuthInvalid)
	}
	authUnix, err := strconv.ParseInt(authDateRaw, 10, 64)
	if err != nil || authUnix <= 0 {
		return nil, fmt.Errorf("%w: invalid auth_date", ErrTelegramAuthInvalid)
	}
	authDate := time.Unix(authUnix, 0).UTC()
	now := v.now().UTC()
	if authDate.After(now.Add(time.Minute)) {
		return nil, ErrTelegramAuthInvalid
	}
	if now.Sub(authDate) > v.maxAge {
		return nil, ErrTelegramAuthExpired
	}

	userJSON := values.Get("user")
	if strings.TrimSpace(userJSON) == "" {
		return nil, fmt.Errorf("%w: missing user", ErrTelegramAuthInvalid)
	}
	var user TelegramUser
	if err := json.Unmarshal([]byte(userJSON), &user); err != nil {
		return nil, fmt.Errorf("%w: invalid user payload", ErrTelegramAuthInvalid)
	}
	if user.ID <= 0 {
		return nil, fmt.Errorf("%w: invalid telegram user id", ErrTelegramAuthInvalid)
	}

	return &TelegramWebAppAuth{
		User:         user,
		AuthDate:     authDate,
		QueryID:      values.Get("query_id"),
		ChatType:     values.Get("chat_type"),
		ChatInstance: values.Get("chat_instance"),
		StartParam:   values.Get("start_param"),
	}, nil
}

func hmacSHA256(key, message []byte) []byte {
	mac := hmac.New(sha256.New, key)
	_, _ = mac.Write(message)
	return mac.Sum(nil)
}

// SyntheticTelegramEmail builds a stable, unique placeholder email for
// Telegram-only accounts. It is not a real delivery address.
func SyntheticTelegramEmail(telegramID int64) string {
	return fmt.Sprintf("tg_%d@users.telegram.internal", telegramID)
}
