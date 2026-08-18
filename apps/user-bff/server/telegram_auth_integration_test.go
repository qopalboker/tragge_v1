package server

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
	"github.com/Parsaeffatravesh/tragge/packages/db"
	"github.com/Parsaeffatravesh/tragge/packages/observability"
	pkgredis "github.com/Parsaeffatravesh/tragge/packages/redis"
	_ "github.com/jackc/pgx/v5/stdlib"
)

const telegramOnboardingBotToken = "123456:TRAGGE-LOCAL-TEST-BOT-TOKEN-NOT-PROD"

// TestTelegramMiniAppOnboardingFirstTimeAndReturningUser proves the full MVP
// Telegram identity path:
//
//	signed initData → HMAC verify → create-or-reuse user by telegram_id → User JWT
//
// and that a second authentication for the same Telegram identity reuses the
// same TRAGGE profile (unique index, no duplicates). initDataUnsafe is never
// accepted as identity.
func TestTelegramMiniAppOnboardingFirstTimeAndReturningUser(t *testing.T) {
	postgresDSN := os.Getenv("TELEGRAM_ONBOARD_POSTGRES_DSN")
	if postgresDSN == "" {
		postgresDSN = os.Getenv("SEC003_POSTGRES_DSN")
	}
	redisAddr := os.Getenv("TELEGRAM_ONBOARD_REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = os.Getenv("SEC003_REDIS_ADDR")
	}
	if postgresDSN == "" || redisAddr == "" {
		t.Skip("TELEGRAM_ONBOARD_POSTGRES_DSN/SEC003_POSTGRES_DSN and REDIS addr required")
	}
	requireTelegramOnboardTargets(t, postgresDSN, redisAddr)

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	sqlDB, err := sql.Open("pgx", postgresDSN)
	if err != nil {
		t.Fatal(err)
	}
	defer sqlDB.Close()
	if err := sqlDB.PingContext(ctx); err != nil {
		t.Fatal(err)
	}
	createTelegramOnboardSchema(t, ctx, sqlDB)

	redisConfig := pkgredis.DefaultConfig()
	redisConfig.Addr = redisAddr
	if pw := os.Getenv("TELEGRAM_ONBOARD_REDIS_PASSWORD"); pw != "" {
		redisConfig.Password = pw
	} else if pw := os.Getenv("SEC003_REDIS_PASSWORD"); pw != "" {
		redisConfig.Password = pw
	} else if pw := os.Getenv("SEC007_REDIS_PASSWORD"); pw != "" {
		redisConfig.Password = pw
	}
	redisClient, err := pkgredis.NewClient(redisConfig)
	if err != nil {
		t.Fatal(err)
	}
	defer redisClient.Close()
	if err := redisClient.PingCheck(ctx); err != nil {
		t.Fatal(err)
	}
	if err := redisClient.Client().FlushDB(ctx).Err(); err != nil {
		t.Fatal(err)
	}

	logger, err := observability.NewLogger(observability.LogConfig{
		Service: "telegram-onboard-test", Env: "test", Level: "error",
	})
	if err != nil {
		t.Fatal(err)
	}
	verifier, err := auth.NewTelegramWebAppVerifier(telegramOnboardingBotToken, 5*time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	userAuth := auth.New(&auth.Config{
		Context:          auth.ContextUser,
		JWTSecret:        "test-only-telegram-user-access-key-0123456789-ABC",
		JWTRefreshSecret: "test-only-telegram-user-refresh-key-0123456789-AB",
		JWTIssuer:        "telegram-onboard-test",
		JWTAudience:      auth.AudienceUser,
		AccessTokenTTL:   15 * time.Minute,
		RefreshTokenTTL:  time.Hour,
		Redis:            redisClient.Client(),
		SessionPrefix:    auth.UserSessionPrefix,
		SessionTTL:       time.Hour,
	})
	app := &App{
		pool:             db.NewPoolFromDB(sqlDB),
		redis:            redisClient,
		auth:             userAuth,
		telegramVerifier: verifier,
		config:           &Config{},
		obs:              &observability.Observability{Logger: logger},
	}

	const telegramID int64 = 9_001_234_567
	tgUser := auth.TelegramUser{
		ID:        telegramID,
		FirstName: "Mina",
		LastName:  "Test",
		Username:  "mina_onboard_tg",
	}

	// --- First-time: no existing TRAGGE user ---
	firstInit := signInitDataForHandler(t, telegramOnboardingBotToken, map[string]string{
		"auth_date": fmt.Sprintf("%d", time.Now().Unix()),
		"user":      mustJSON(t, tgUser),
		"query_id":  "AA-first",
	})
	firstRec := postTelegramAuth(t, app, map[string]interface{}{"init_data": firstInit})
	if firstRec.Code != http.StatusOK {
		t.Fatalf("first-time auth status=%d body=%s", firstRec.Code, firstRec.Body.String())
	}
	firstBody := decodeJSONMap(t, firstRec)
	firstUserID, _ := firstBody["user_id"].(string)
	firstToken, _ := firstBody["access_token"].(string)
	if firstUserID == "" || firstToken == "" {
		t.Fatalf("first-time missing session fields: %v", firstBody)
	}
	roles, _ := firstBody["roles"].([]interface{})
	if len(roles) != 1 || roles[0] != "user" {
		t.Fatalf("first-time roles=%v want [user]", roles)
	}

	var rowCount int
	var storedTG sql.NullInt64
	var email, username, displayName string
	if err := sqlDB.QueryRowContext(ctx, `
		SELECT COUNT(*), MAX(telegram_id), MAX(email), MAX(username), MAX(display_name)
		FROM users WHERE telegram_id = $1
	`, telegramID).Scan(&rowCount, &storedTG, &email, &username, &displayName); err != nil {
		t.Fatal(err)
	}
	if rowCount != 1 || !storedTG.Valid || storedTG.Int64 != telegramID {
		t.Fatalf("first-time rowCount=%d telegram_id=%v", rowCount, storedTG)
	}
	if email != auth.SyntheticTelegramEmail(telegramID) {
		t.Fatalf("synthetic email=%q", email)
	}
	if username != "mina_onboard_tg" || !strings.Contains(displayName, "Mina") {
		t.Fatalf("profile username=%q display=%q", username, displayName)
	}

	// JWT must be a valid User-context access token for the created profile.
	claims, err := userAuth.Token.ValidateAccessToken(firstToken)
	if err != nil || claims.UserID != firstUserID || claims.AuthContext != auth.ContextUser {
		t.Fatalf("first-time token claims invalid: claims=%+v err=%v", claims, err)
	}

	// --- Returning: same Telegram identity, fresh signed initData ---
	// New auth_date (and thus new signature) — same initData would hit replay protection.
	time.Sleep(1100 * time.Millisecond)
	returnInit := signInitDataForHandler(t, telegramOnboardingBotToken, map[string]string{
		"auth_date": fmt.Sprintf("%d", time.Now().Unix()),
		"user":      mustJSON(t, tgUser),
		"query_id":  "AA-return",
	})
	returnRec := postTelegramAuth(t, app, map[string]interface{}{"init_data": returnInit})
	if returnRec.Code != http.StatusOK {
		t.Fatalf("returning auth status=%d body=%s", returnRec.Code, returnRec.Body.String())
	}
	returnBody := decodeJSONMap(t, returnRec)
	returnUserID, _ := returnBody["user_id"].(string)
	if returnUserID != firstUserID {
		t.Fatalf("returning user_id=%s want same as first-time %s", returnUserID, firstUserID)
	}
	if err := sqlDB.QueryRowContext(ctx, `SELECT COUNT(*) FROM users WHERE telegram_id = $1`, telegramID).Scan(&rowCount); err != nil {
		t.Fatal(err)
	}
	if rowCount != 1 {
		t.Fatalf("duplicate accounts created: count=%d", rowCount)
	}

	// --- Uniqueness under concurrent findOrCreate (same telegram_id) ---
	const raceTG int64 = 9_001_999_001
	raceUser := auth.TelegramUser{ID: raceTG, FirstName: "Race", Username: "race_tg"}
	var wg sync.WaitGroup
	ids := make(chan string, 16)
	errs := make(chan error, 16)
	start := make(chan struct{})
	for i := 0; i < 12; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			<-start
			id, createErr := app.findOrCreateTelegramUser(ctx, raceUser)
			if createErr != nil {
				errs <- createErr
				return
			}
			ids <- id
		}()
	}
	close(start)
	wg.Wait()
	close(ids)
	close(errs)
	for e := range errs {
		if e != nil {
			t.Fatalf("concurrent findOrCreate: %v", e)
		}
	}
	seen := map[string]struct{}{}
	for id := range ids {
		seen[id] = struct{}{}
	}
	if len(seen) != 1 {
		t.Fatalf("concurrent findOrCreate for one telegram_id produced %d distinct user ids: %v", len(seen), seen)
	}
	if err := sqlDB.QueryRowContext(ctx, `SELECT COUNT(*) FROM users WHERE telegram_id = $1`, raceTG).Scan(&rowCount); err != nil {
		t.Fatal(err)
	}
	if rowCount != 1 {
		t.Fatalf("race created %d rows for one telegram_id", rowCount)
	}

	// Returning-user auth after concurrent create still reuses that single profile.
	time.Sleep(1100 * time.Millisecond)
	raceInit := signInitDataForHandler(t, telegramOnboardingBotToken, map[string]string{
		"auth_date": fmt.Sprintf("%d", time.Now().Unix()),
		"user":      mustJSON(t, raceUser),
	})
	raceRec := postTelegramAuth(t, app, map[string]interface{}{"init_data": raceInit})
	if raceRec.Code != http.StatusOK {
		t.Fatalf("post-race auth status=%d body=%s", raceRec.Code, raceRec.Body.String())
	}
	raceBody := decodeJSONMap(t, raceRec)
	raceAuthID, _ := raceBody["user_id"].(string)
	var onlyID string
	for id := range seen {
		onlyID = id
	}
	if raceAuthID != onlyID {
		t.Fatalf("auth after race user_id=%s want %s", raceAuthID, onlyID)
	}

	// --- DB unique index rejects a second manual insert ---
	_, err = sqlDB.ExecContext(ctx, `
		INSERT INTO users (id, email, password_hash, username, display_name, email_verified, telegram_id, terms_accepted_at, created_at)
		VALUES ($1, $2, NULL, 'dup', 'dup', TRUE, $3, NOW(), NOW())
	`, "00000000-0000-4000-8000-000000000099", "dup@users.telegram.internal", telegramID)
	if err == nil {
		t.Fatal("expected unique index to reject duplicate telegram_id")
	}
	if !strings.Contains(strings.ToLower(err.Error()), "unique") && !strings.Contains(strings.ToLower(err.Error()), "duplicate") {
		t.Fatalf("unexpected duplicate insert error: %v", err)
	}

	// --- Never trust client-supplied identity (initDataUnsafe equivalent) ---
	evil := postTelegramAuth(t, app, map[string]interface{}{
		"init_data":   firstInit,
		"telegram_id": telegramID,
	})
	if evil.Code != http.StatusBadRequest || !strings.Contains(evil.Body.String(), "telegram_identity_untrusted") {
		t.Fatalf("client telegram_id accepted: status=%d body=%s", evil.Code, evil.Body.String())
	}
	evilUID := postTelegramAuth(t, app, map[string]interface{}{
		"init_data": firstInit,
		"user_id":   firstUserID,
	})
	if evilUID.Code != http.StatusBadRequest || !strings.Contains(evilUID.Body.String(), "telegram_identity_untrusted") {
		t.Fatalf("client user_id accepted: status=%d body=%s", evilUID.Code, evilUID.Body.String())
	}

	// --- Unsigned / tampered identity rejected ---
	forged := url.Values{}
	forged.Set("user", mustJSON(t, map[string]interface{}{"id": telegramID, "first_name": "Eve"}))
	forged.Set("auth_date", fmt.Sprintf("%d", time.Now().Unix()))
	forgedRec := postTelegramAuth(t, app, map[string]interface{}{"init_data": forged.Encode()})
	if forgedRec.Code != http.StatusUnauthorized {
		t.Fatalf("unsigned initData status=%d want 401", forgedRec.Code)
	}
}

// TestTelegramAuthFrontendNeverTrustsInitDataUnsafe is a source-level contract:
// session exchange must send only signed initData, never initDataUnsafe.user.id.
func TestTelegramAuthFrontendNeverTrustsInitDataUnsafe(t *testing.T) {
	authStore := filepath.Join("..", "..", "user-frontend", "src", "stores", "auth.ts")
	// #nosec G304 -- fixed repository path
	raw, err := os.ReadFile(authStore)
	if err != nil {
		t.Fatal(err)
	}
	src := string(raw)
	if !strings.Contains(src, "loginWithTelegram") || !strings.Contains(src, "init_data") {
		t.Fatal("auth store must expose Telegram login with init_data")
	}
	if strings.Contains(src, "initDataUnsafe") {
		t.Fatal("auth store must not reference initDataUnsafe for login")
	}
	if strings.Contains(src, "telegram_id") {
		// Comment-only references are OK if they say "never".
		for _, line := range strings.Split(src, "\n") {
			if strings.Contains(line, "telegram_id") && !strings.Contains(line, "never") && !strings.HasPrefix(strings.TrimSpace(line), "*") && !strings.HasPrefix(strings.TrimSpace(line), "//") {
				t.Fatalf("auth store must not send telegram_id: %s", line)
			}
		}
	}

	mainTS := filepath.Join("..", "..", "user-frontend", "src", "main.ts")
	// #nosec G304 -- fixed repository path
	mainRaw, err := os.ReadFile(mainTS)
	if err != nil {
		t.Fatal(err)
	}
	mainSrc := string(mainRaw)
	// Bootstrap is centralized in auth.bootstrapFull() (runs before router install).
	// That path must call waitForSignedInitData → loginWithTelegram; main must not
	// inline initDataUnsafe or a parallel Telegram login.
	if !strings.Contains(mainSrc, "bootstrapFull") {
		t.Fatal("main bootstrap must await auth.bootstrapFull before router install")
	}
	if !strings.Contains(src, "waitForSignedInitData") || !strings.Contains(src, "loginWithTelegram") {
		t.Fatal("auth store bootstrap must wait for signed initData then call loginWithTelegram")
	}
	if strings.Contains(mainSrc, "initDataUnsafe") {
		t.Fatal("main bootstrap must not use initDataUnsafe for authentication")
	}

	// Migration uniqueness contract.
	mig := filepath.Join("..", "..", "..", "packages", "db", "migrations", "0101_telegram_auth.up.sql")
	// #nosec G304 -- fixed repository path
	migRaw, err := os.ReadFile(mig)
	if err != nil {
		t.Fatal(err)
	}
	migSQL := string(migRaw)
	if !strings.Contains(migSQL, "telegram_id") || !strings.Contains(migSQL, "UNIQUE INDEX") {
		t.Fatal("0101 must create unique index on telegram_id")
	}
}

func requireTelegramOnboardTargets(t *testing.T, postgresDSN, redisAddr string) {
	t.Helper()
	parsed, err := url.Parse(postgresDSN)
	if err != nil {
		t.Fatal("invalid PostgreSQL DSN")
	}
	dbName := strings.TrimPrefix(parsed.EscapedPath(), "/")
	hostOK := false
	switch parsed.Hostname() {
	case "127.0.0.1", "localhost", "postgres":
		hostOK = true
	}
	if !hostOK || !strings.Contains(strings.ToLower(dbName), "test") {
		t.Fatal("refusing non-local or non-test PostgreSQL DSN for Telegram onboarding tests")
	}
	redisHost := redisAddr
	if h, _, err := net.SplitHostPort(redisAddr); err == nil {
		redisHost = h
	}
	switch redisHost {
	case "127.0.0.1", "localhost", "redis":
	default:
		t.Fatal("refusing non-local Redis for Telegram onboarding tests")
	}
}

func createTelegramOnboardSchema(t *testing.T, ctx context.Context, sqlDB *sql.DB) {
	t.Helper()
	statements := []string{
		`DROP TABLE IF EXISTS user_roles, roles, users CASCADE`,
		`CREATE TABLE users (
			id text PRIMARY KEY DEFAULT gen_random_uuid()::text,
			email text UNIQUE,
			password_hash text,
			username text,
			display_name text,
			email_verified boolean NOT NULL DEFAULT false,
			telegram_id bigint,
			terms_accepted_at timestamptz,
			created_at timestamptz NOT NULL DEFAULT now(),
			updated_at timestamptz NOT NULL DEFAULT now()
		)`,
		`CREATE UNIQUE INDEX idx_users_telegram_id ON users (telegram_id) WHERE telegram_id IS NOT NULL`,
		`CREATE TABLE roles (
			id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
			name text NOT NULL UNIQUE
		)`,
		`CREATE TABLE user_roles (
			user_id text NOT NULL REFERENCES users(id),
			role_id integer NOT NULL REFERENCES roles(id),
			PRIMARY KEY (user_id, role_id)
		)`,
		`INSERT INTO roles (name) VALUES ('user')`,
	}
	for _, statement := range statements {
		if _, err := sqlDB.ExecContext(ctx, statement); err != nil {
			t.Fatal("prepare telegram onboard schema:", err)
		}
	}
}

func postTelegramAuth(t *testing.T, app *App, body map[string]interface{}) *httptest.ResponseRecorder {
	t.Helper()
	payload, err := json.Marshal(body)
	if err != nil {
		t.Fatal(err)
	}
	req := httptest.NewRequest(http.MethodPost, "/api/user/auth/telegram", bytes.NewReader(payload))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", "telegram-onboard-test")
	rec := httptest.NewRecorder()
	app.handleTelegramMiniAppAuth(rec, req)
	return rec
}

func decodeJSONMap(t *testing.T, rec *httptest.ResponseRecorder) map[string]interface{} {
	t.Helper()
	var out map[string]interface{}
	if err := json.Unmarshal(rec.Body.Bytes(), &out); err != nil {
		t.Fatalf("decode status=%d body=%s err=%v", rec.Code, rec.Body.String(), err)
	}
	return out
}

func mustJSON(t *testing.T, v interface{}) string {
	t.Helper()
	b, err := json.Marshal(v)
	if err != nil {
		t.Fatal(err)
	}
	return string(b)
}
