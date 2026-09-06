package wallet

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestTreasuryPostingUsesIntegerMoneyAndCanonicalDepositBoundary(t *testing.T) {
	_, thisFile, _, _ := runtime.Caller(0)
	walletDir := filepath.Dir(thisFile)
	walletSource, err := os.ReadFile(filepath.Join(walletDir, "wallet.go"))
	if err != nil {
		t.Fatal(err)
	}
	source := string(walletSource)
	start := strings.Index(source, "func (s *Service) PostConfirmedDeposit(")
	if start < 0 {
		t.Fatal("canonical confirmed-deposit posting boundary is missing")
	}
	end := strings.Index(source[start:], "\n}\n")
	if end < 0 {
		t.Fatal("cannot locate confirmed-deposit posting boundary end")
	}
	posting := source[start : start+end]
	for _, forbidden := range []string{"float32", "float64", "math.Round", "redis."} {
		if strings.Contains(posting, forbidden) {
			t.Fatalf("authoritative Treasury posting contains forbidden %q", forbidden)
		}
	}

	repositoryRoot := filepath.Clean(filepath.Join(walletDir, "..", ".."))
	for _, relative := range []string{
		"apps/payment-service/handlers/webhook.go",
		"apps/payment-service/server/inquiry.go",
		"apps/payment-service/server/expiry.go",
	} {
		raw, err := os.ReadFile(filepath.Join(repositoryRoot, relative))
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(raw), "PostConfirmedDeposit(") {
			t.Fatalf("%s bypasses canonical confirmed-deposit posting", relative)
		}
	}
}
