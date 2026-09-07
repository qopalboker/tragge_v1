package auth

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"encoding/hex"
	"errors"
	"strings"
)

//nolint:gosec // G101: ciphertext format prefix, not a credential
const SystemSecretCiphertextPrefix = "enc:system:v1:"

var (
	ErrSystemSecretInvalid = errors.New("system secret crypto invalid")
	ErrSystemSecretEmpty   = errors.New("system secret empty")
)

// ParseSystemSecretKey parses a 32-byte AES key from hex (64 hex chars).
func ParseSystemSecretKey(hexKey string) ([]byte, error) {
	hexKey = strings.TrimSpace(hexKey)
	if hexKey == "" {
		return nil, ErrSystemSecretInvalid
	}
	raw, err := hex.DecodeString(hexKey)
	if err != nil || len(raw) != 32 {
		return nil, ErrSystemSecretInvalid
	}
	return raw, nil
}

// EncryptSystemSecret seals plaintext with AES-256-GCM (AAD = prefix).
func EncryptSystemSecret(plaintext string, key []byte) (string, error) {
	if len(key) != 32 || strings.TrimSpace(plaintext) == "" {
		return "", ErrSystemSecretInvalid
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", ErrSystemSecretInvalid
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", ErrSystemSecretInvalid
	}
	nonce := make([]byte, gcm.NonceSize())
	if _, err := rand.Read(nonce); err != nil {
		return "", err
	}
	sealed := gcm.Seal(nil, nonce, []byte(plaintext), []byte(SystemSecretCiphertextPrefix))
	out := make([]byte, 0, len(nonce)+len(sealed))
	out = append(out, nonce...)
	out = append(out, sealed...)
	return SystemSecretCiphertextPrefix + base64.RawStdEncoding.EncodeToString(out), nil
}

// DecryptSystemSecret opens ciphertext produced by EncryptSystemSecret.
func DecryptSystemSecret(stored string, key []byte) (string, error) {
	if len(key) != 32 || !strings.HasPrefix(stored, SystemSecretCiphertextPrefix) {
		return "", ErrSystemSecretInvalid
	}
	payload, err := base64.RawStdEncoding.DecodeString(strings.TrimPrefix(stored, SystemSecretCiphertextPrefix))
	if err != nil {
		return "", ErrSystemSecretInvalid
	}
	block, err := aes.NewCipher(key)
	if err != nil {
		return "", ErrSystemSecretInvalid
	}
	gcm, err := cipher.NewGCM(block)
	if err != nil || len(payload) < gcm.NonceSize() {
		return "", ErrSystemSecretInvalid
	}
	plaintext, err := gcm.Open(nil, payload[:gcm.NonceSize()], payload[gcm.NonceSize():], []byte(SystemSecretCiphertextPrefix))
	if err != nil {
		return "", ErrSystemSecretInvalid
	}
	if strings.TrimSpace(string(plaintext)) == "" {
		return "", ErrSystemSecretEmpty
	}
	return string(plaintext), nil
}

// MaskSecret returns a non-reversible display mask (last 4 runes when long enough).
func MaskSecret(secret string) string {
	s := strings.TrimSpace(secret)
	if s == "" {
		return ""
	}
	runes := []rune(s)
	if len(runes) <= 4 {
		return "****"
	}
	return "****" + string(runes[len(runes)-4:])
}
