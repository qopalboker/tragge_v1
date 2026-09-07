package wallet

import (
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"testing"
)

func TestContestFeePostingIsIntegerAndJoinUsesBoundary(t *testing.T) {
	_, file, _, _ := runtime.Caller(0)
	dir := filepath.Dir(file)
	raw, err := os.ReadFile(filepath.Join(dir, "wallet.go"))
	if err != nil {
		t.Fatal(err)
	}
	source := string(raw)
	start := strings.Index(source, "func (s *Service) PostContestFee(")
	end := strings.Index(source[start:], "\n}\n")
	if start < 0 || end < 0 {
		t.Fatal("PostContestFee boundary missing")
	}
	posting := source[start : start+end]
	for _, forbidden := range []string{"float32", "float64", "math.Round", "redis.", "LedgerTypeAdjustment"} {
		if strings.Contains(posting, forbidden) {
			t.Fatalf("posting contains forbidden %q", forbidden)
		}
	}
	joinRaw, err := os.ReadFile(filepath.Join(dir, "..", "..", "apps", "user-bff", "server", "contest_handlers.go"))
	if err != nil {
		t.Fatal(err)
	}
	join := string(joinRaw)
	lockAt := strings.Index(join, "a.wallet.LockTreasuryForFinancialOperation(")
	debitAt := strings.Index(join, "a.wallet.DeductContestEntryFeeWithName(")
	postAt := strings.Index(join, "a.wallet.PostContestFee(")
	commitAt := strings.Index(join, "tx.Commit()")
	if lockAt < 0 || debitAt < 0 || postAt < 0 || commitAt < 0 ||
		lockAt > debitAt || debitAt > postAt || postAt > commitAt {
		t.Fatal("join lock/post order is not Treasury -> user wallet -> Fee Wallet -> commit")
	}
	for _, required := range []string{"charge.PlatformCents", "charge.SurchargeCents", "wallet.ContestFeeKindBase", "wallet.ContestFeeKindLateSurcharge"} {
		if !strings.Contains(join[postAt:commitAt], required) {
			t.Fatalf("join fee integration missing %q", required)
		}
	}
}
