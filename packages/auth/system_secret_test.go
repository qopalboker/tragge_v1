package auth

import (
	"encoding/hex"
	"strings"
	"testing"
)

func TestSystemSecretRoundTripAndMask(t *testing.T) {
	key := make([]byte, 32)
	for i := range key {
		key[i] = byte(i + 1)
	}
	plain := "123456:ABCDEF-telegram-bot-token"
	ct, err := EncryptSystemSecret(plain, key)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.HasPrefix(ct, SystemSecretCiphertextPrefix) {
		t.Fatalf("prefix missing: %s", ct[:20])
	}
	if strings.Contains(ct, plain) {
		t.Fatal("ciphertext leaked plaintext")
	}
	got, err := DecryptSystemSecret(ct, key)
	if err != nil {
		t.Fatal(err)
	}
	if got != plain {
		t.Fatalf("got %q", got)
	}
	mask := MaskSecret(plain)
	if mask == plain || strings.Contains(mask, "ABCDEF") {
		t.Fatalf("bad mask %q", mask)
	}
	if !strings.HasSuffix(mask, "oken") && !strings.HasPrefix(mask, "****") {
		t.Fatalf("unexpected mask %q", mask)
	}
}

func TestParseSystemSecretKey(t *testing.T) {
	raw := make([]byte, 32)
	hexKey := hex.EncodeToString(raw)
	got, err := ParseSystemSecretKey(hexKey)
	if err != nil || len(got) != 32 {
		t.Fatalf("parse failed: %v len=%d", err, len(got))
	}
	if _, err := ParseSystemSecretKey("abcd"); err == nil {
		t.Fatal("expected invalid short key")
	}
}
