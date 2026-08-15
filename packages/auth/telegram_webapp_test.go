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
	"strings"
	"testing"
	"time"
)

const fixtureBotToken = "123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11"

func signTelegramInitData(t *testing.T, botToken string, fields map[string]string) string {
	t.Helper()
	keys := make([]string, 0, len(fields))
	for key := range fields {
		if key == "hash" {
			continue
		}
		keys = append(keys, key)
	}
	sort.Strings(keys)
	parts := make([]string, 0, len(keys))
	for _, key := range keys {
		parts = append(parts, key+"="+fields[key])
	}
	dataCheckString := strings.Join(parts, "\n")
	secret := hmac.New(sha256.New, []byte(telegramWebAppDataKey))
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

func TestTelegramWebAppVerifierAcceptsValidInitData(t *testing.T) {
	verifier, err := NewTelegramWebAppVerifier(fixtureBotToken, time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	fixed := time.Unix(1_700_000_100, 0).UTC()
	verifier.now = func() time.Time { return fixed }

	userJSON, _ := json.Marshal(map[string]interface{}{
		"id":         424242,
		"first_name": "Alice",
		"username":   "alice_tg",
	})
	initData := signTelegramInitData(t, fixtureBotToken, map[string]string{
		"auth_date": fmt.Sprintf("%d", fixed.Add(-30*time.Second).Unix()),
		"user":      string(userJSON),
		"query_id":  "AAE",
	})

	authResult, err := verifier.VerifyInitData(initData)
	if err != nil {
		t.Fatalf("valid initData rejected: %v", err)
	}
	if authResult.User.ID != 424242 || authResult.User.Username != "alice_tg" {
		t.Fatalf("unexpected user: %+v", authResult.User)
	}
}

func TestTelegramWebAppVerifierRejectsTamperingExpiryAndConfig(t *testing.T) {
	verifier, err := NewTelegramWebAppVerifier(fixtureBotToken, time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	fixed := time.Unix(1_700_000_100, 0).UTC()
	verifier.now = func() time.Time { return fixed }

	userJSON, _ := json.Marshal(map[string]interface{}{
		"id":         99,
		"first_name": "Bob",
	})
	baseFields := map[string]string{
		"auth_date": fmt.Sprintf("%d", fixed.Add(-10*time.Second).Unix()),
		"user":      string(userJSON),
	}
	valid := signTelegramInitData(t, fixtureBotToken, cloneMap(baseFields))

	// Modified user identity with original signature.
	tamperedValues, _ := url.ParseQuery(valid)
	tamperedUser, _ := json.Marshal(map[string]interface{}{"id": 1, "first_name": "Eve"})
	tamperedValues.Set("user", string(tamperedUser))
	tampered := tamperedValues.Encode()

	// Expired auth_date with valid signature.
	expired := signTelegramInitData(t, fixtureBotToken, map[string]string{
		"auth_date": fmt.Sprintf("%d", fixed.Add(-2*time.Hour).Unix()),
		"user":      string(userJSON),
	})

	// Wrong bot token signature.
	wrongKey := signTelegramInitData(t, "999999:WRONG-TOKEN-VALUE-NOT-VALID-XXXX", cloneMap(baseFields))

	// Frontend-forged identity without signature.
	forged := url.Values{}
	forged.Set("user", string(userJSON))
	forged.Set("auth_date", fmt.Sprintf("%d", fixed.Unix()))

	tests := []struct {
		name     string
		initData string
		wantErr  error
	}{
		{"tampered user", tampered, ErrTelegramAuthInvalid},
		{"expired", expired, ErrTelegramAuthExpired},
		{"wrong signing key", wrongKey, ErrTelegramAuthInvalid},
		{"missing hash", forged.Encode(), ErrTelegramAuthInvalid},
		{"empty", "", ErrTelegramAuthInvalid},
		{"garbage", "not=valid&hash=zz", ErrTelegramAuthInvalid},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, err := verifier.VerifyInitData(test.initData)
			if err == nil {
				t.Fatal("expected rejection")
			}
			if test.wantErr != nil && !errors.Is(err, test.wantErr) {
				t.Fatalf("error = %v, want %v", err, test.wantErr)
			}
		})
	}

	if _, err := NewTelegramWebAppVerifier("", time.Minute); err == nil {
		t.Fatal("empty bot token accepted")
	}
}

func TestTelegramWebAppVerifierRejectsImpersonationPayload(t *testing.T) {
	// Attacker presents victim identity fields but signs with wrong material
	// or reuses another user's signed blob after changing the id.
	verifier, err := NewTelegramWebAppVerifier(fixtureBotToken, time.Minute)
	if err != nil {
		t.Fatal(err)
	}
	fixed := time.Unix(1_700_000_100, 0).UTC()
	verifier.now = func() time.Time { return fixed }

	victimJSON, _ := json.Marshal(map[string]interface{}{"id": 111, "first_name": "Victim"})
	signedVictim := signTelegramInitData(t, fixtureBotToken, map[string]string{
		"auth_date": fmt.Sprintf("%d", fixed.Unix()),
		"user":      string(victimJSON),
	})
	// Mutate only the JSON id while keeping the original hash.
	values, _ := url.ParseQuery(signedVictim)
	attackerJSON, _ := json.Marshal(map[string]interface{}{"id": 222, "first_name": "Victim"})
	values.Set("user", string(attackerJSON))
	if _, err := verifier.VerifyInitData(values.Encode()); err == nil {
		t.Fatal("impersonation payload accepted")
	}
}

func TestSyntheticTelegramEmail(t *testing.T) {
	if got := SyntheticTelegramEmail(42); got != "tg_42@users.telegram.internal" {
		t.Fatalf("got %q", got)
	}
}

func cloneMap(in map[string]string) map[string]string {
	out := make(map[string]string, len(in))
	for k, v := range in {
		out[k] = v
	}
	return out
}
