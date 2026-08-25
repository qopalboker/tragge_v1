package modules_test

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

// ARCH-004: payment module must not UPDATE wallets directly.
func TestPaymentModuleDoesNotBypassLedger(t *testing.T) {
	_, thisFile, _, ok := runtime.Caller(0)
	if !ok {
		t.Fatal("caller")
	}
	root := filepath.Join(filepath.Dir(thisFile), "payment")
	entries, err := os.ReadDir(root)
	if err != nil {
		t.Fatal(err)
	}
	for _, e := range entries {
		if e.IsDir() || !strings.HasSuffix(e.Name(), ".go") || strings.HasSuffix(e.Name(), "_test.go") {
			continue
		}
		b, err := os.ReadFile(filepath.Join(root, e.Name()))
		if err != nil {
			t.Fatal(err)
		}
		s := string(b)
		if strings.Contains(s, "UPDATE wallets") || strings.Contains(s, "UPDATE wallets ") {
			t.Fatalf("%s must not UPDATE wallets directly", e.Name())
		}
	}
}
