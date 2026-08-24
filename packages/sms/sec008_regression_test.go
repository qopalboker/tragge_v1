package sms

import (
	"bytes"
	"context"
	"io"
	"log"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// SEC-008 regression lock: OTP values must never appear in application logs.
// FakeProvider is test-only and must not log; production KaveNegar SendOTP must
// not log the code either.

func TestSEC008FakeProviderNeverLogsOTP(t *testing.T) {
	const fixtureOTP = "482917"

	var buf bytes.Buffer
	prev := log.Writer()
	log.SetOutput(&buf)
	defer log.SetOutput(prev)

	// Also capture stdout/stderr in case a provider regresses to fmt.Print.
	stdoutR, stdoutW, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	stderrR, stderrW, err := os.Pipe()
	if err != nil {
		t.Fatal(err)
	}
	oldStdout, oldStderr := os.Stdout, os.Stderr
	os.Stdout, os.Stderr = stdoutW, stderrW
	defer func() {
		os.Stdout, os.Stderr = oldStdout, oldStderr
	}()

	provider := NewFake()
	if err := provider.SendOTP(context.Background(), "+989120000000", fixtureOTP); err != nil {
		t.Fatal(err)
	}
	if got := provider.LastCode(); got != fixtureOTP {
		t.Fatalf("LastCode=%q want %q", got, fixtureOTP)
	}

	_ = stdoutW.Close()
	_ = stderrW.Close()
	stdoutBytes, _ := io.ReadAll(stdoutR)
	stderrBytes, _ := io.ReadAll(stderrR)

	combined := buf.String() + string(stdoutBytes) + string(stderrBytes)
	if strings.Contains(combined, fixtureOTP) {
		t.Fatalf("OTP leaked to logs/stdout/stderr: %q", combined)
	}
}

func TestSEC008SMSSourcesDoNotLogOTPCodes(t *testing.T) {
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("runtime.Caller failed")
	}
	dir := filepath.Dir(thisFile)

	prohibited := []string{
		`zap.String("code"`,
		`zap.String("otp"`,
		`zap.Any("code"`,
		`zap.Any("otp"`,
		`log.Printf`,
		`log.Println`,
		`fmt.Printf`,
		`fmt.Println`,
	}

	entries, err := os.ReadDir(dir)
	if err != nil {
		t.Fatal(err)
	}
	for _, entry := range entries {
		name := entry.Name()
		if entry.IsDir() || !strings.HasSuffix(name, ".go") || strings.HasSuffix(name, "_test.go") {
			continue
		}
		body, err := os.ReadFile(filepath.Join(dir, name))
		if err != nil {
			t.Fatal(err)
		}
		text := string(body)
		for _, needle := range prohibited {
			if strings.Contains(text, needle) {
				t.Fatalf("%s contains prohibited OTP/log pattern %q", name, needle)
			}
		}
		// SendOTP must not interpolate the code into a log-like format string.
		if name == "mock.go" || name == "kavenegar.go" {
			if strings.Contains(text, "OTP:") || strings.Contains(text, "otp=") {
				t.Fatalf("%s looks like it logs OTP material", name)
			}
		}
	}
}
