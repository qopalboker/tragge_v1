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

func TestContestAdmissionCanonicalLockOrderAndMigrationGate(t *testing.T) {
	_, file, _, _ := runtime.Caller(0)
	dir := filepath.Dir(file)
	walletRaw, err := os.ReadFile(filepath.Join(dir, "wallet.go"))
	if err != nil {
		t.Fatal(err)
	}
	walletSource := string(walletRaw)
	for _, function := range []struct {
		name, finalLock string
	}{
		{"PostContestFee", "FROM contest_fee_accounts"},
		{"PostContestPrizeContribution", "FROM contests c JOIN contest_prize_pool_accounts"},
	} {
		start := strings.Index(walletSource, "func (s *Service) "+function.name+"(")
		if start < 0 {
			t.Fatalf("%s boundary missing", function.name)
		}
		body := walletSource[start:]
		treasuryAt := strings.Index(body, "s.LockTreasuryForFinancialOperation(")
		finalAt := strings.Index(body, function.finalLock)
		if treasuryAt < 0 || finalAt < 0 || treasuryAt > finalAt {
			t.Fatalf("%s must lock Treasury before its purpose account", function.name)
		}
	}

	joinRaw, err := os.ReadFile(filepath.Join(dir, "..", "..", "apps", "user-bff", "server", "contest_handlers.go"))
	if err != nil {
		t.Fatal(err)
	}
	join := string(joinRaw)
	begin := strings.Index(join, "// Begin transaction")
	commit := strings.Index(join[begin:], "tx.Commit()")
	if begin < 0 || commit < 0 {
		t.Fatal("admission transaction boundary missing")
	}
	transaction := join[begin : begin+commit]
	ordered := []string{
		"FROM contests WHERE id = $1 FOR UPDATE",
		"a.wallet.LockTreasuryForFinancialOperation(",
		"a.wallet.DeductContestEntryFeeWithName(",
		"a.wallet.PostContestFee(",
		"a.wallet.PostContestPrizeContribution(",
	}
	previous := -1
	for _, token := range ordered {
		at := strings.Index(transaction, token)
		if at < 0 || at <= previous {
			t.Fatalf("admission does not preserve canonical order at %q", token)
		}
		previous = at
	}
	if strings.Contains(transaction, `txFundsPolicy = "legacy"`) {
		t.Fatal("admission silently downgrades schema failures to legacy")
	}
	for _, required := range []string{"funds_policy_version", "Migration 0118 is a hard deployment prerequisite"} {
		if !strings.Contains(transaction, required) {
			t.Fatalf("admission migration gate missing %q", required)
		}
	}
}
