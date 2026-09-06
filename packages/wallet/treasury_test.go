package wallet

import (
	"context"
	"database/sql"
	"sync"
	"testing"

	"github.com/google/uuid"
)

func postConfirmedDeposit(t *testing.T, db *sql.DB, svc *Service, userID string, amount int64, intentID string) bool {
	t.Helper()
	tx, err := db.BeginTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback()
	alreadyPosted, err := svc.PostConfirmedDeposit(context.Background(), &TxAdapter{Tx: tx}, userID, amount, intentID)
	if err != nil {
		t.Fatal(err)
	}
	if err := tx.Commit(); err != nil {
		t.Fatal(err)
	}
	return alreadyPosted
}

func TestTreasuryIdentityIsSingletonAndNotAUserWallet(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)

	ctx := context.Background()
	for range 2 {
		if _, err := env.db.ExecContext(ctx, `
			INSERT INTO treasury_accounts (
				purpose, account_kind, balance_cents, currency, reconciliation_status
			) VALUES ($1, 'system_custody', 0, 'USD', $2)
			ON CONFLICT (purpose) DO NOTHING`,
			SuperAdminTreasuryPurpose, TreasuryReconciliationForwardOnly,
		); err != nil {
			t.Fatal(err)
		}
	}

	var count int
	var userRows int
	var kind, status string
	if err := env.db.QueryRowContext(ctx, `
		SELECT COUNT(*), MIN(account_kind), MIN(reconciliation_status)
		FROM treasury_accounts`,
	).Scan(&count, &kind, &status); err != nil {
		t.Fatal(err)
	}
	if count != 1 || kind != "system_custody" || status != TreasuryReconciliationForwardOnly {
		t.Fatalf("count=%d kind=%q status=%q", count, kind, status)
	}
	if err := env.db.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM users WHERE id::text = $1`, SuperAdminTreasuryPurpose,
	).Scan(&userRows); err != nil {
		t.Fatal(err)
	}
	if userRows != 0 {
		t.Fatalf("Treasury must not have a user identity: rows=%d", userRows)
	}
	if _, err := env.db.ExecContext(ctx, `DELETE FROM treasury_accounts WHERE purpose = $1`, SuperAdminTreasuryPurpose); err == nil {
		t.Fatal("canonical Treasury account was deletable")
	}
	if _, err := NewService(env.db).GetWallet(ctx, SuperAdminTreasuryPurpose); err == nil {
		t.Fatal("ordinary user wallet lookup unexpectedly returned Treasury")
	}
}

func TestPostConfirmedDepositAtomicIdempotentAndSeparatedByUser(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)

	ctx := context.Background()
	svc := NewService(env.db)
	userA := createTestUser(ctx, t, env.db, "treasury-a@example.com")
	userB := createTestUser(ctx, t, env.db, "treasury-b@example.com")
	intentA := uuid.NewString()
	intentB := uuid.NewString()

	if duplicate := postConfirmedDeposit(t, env.db, svc, userA, 100, intentA); duplicate {
		t.Fatal("first deposit reported duplicate")
	}
	if duplicate := postConfirmedDeposit(t, env.db, svc, userA, 100, intentA); !duplicate {
		t.Fatal("replayed deposit was not reported duplicate")
	}
	if duplicate := postConfirmedDeposit(t, env.db, svc, userB, 50, intentB); duplicate {
		t.Fatal("independent deposit reported duplicate")
	}

	assertTreasuryAccounting(t, env.db, 150, map[string]int64{userA: 100, userB: 50}, 2)
}

func TestPostConfirmedDepositRollbackHasNoFinancialEffect(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)

	ctx := context.Background()
	svc := NewService(env.db)
	userID := createTestUser(ctx, t, env.db, "treasury-rollback@example.com")
	tx, err := env.db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	if duplicate, err := svc.PostConfirmedDeposit(ctx, &TxAdapter{Tx: tx}, userID, 100, uuid.NewString()); err != nil || duplicate {
		t.Fatalf("duplicate=%v err=%v", duplicate, err)
	}
	if err := tx.Rollback(); err != nil {
		t.Fatal(err)
	}
	assertTreasuryAccounting(t, env.db, 0, map[string]int64{userID: 0}, 0)
}

func TestPostConfirmedDepositUserFailureRollsBackCustody(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)

	ctx := context.Background()
	tx, err := env.db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	_, err = NewService(env.db).PostConfirmedDeposit(
		ctx, &TxAdapter{Tx: tx}, uuid.NewString(), 100, uuid.NewString(),
	)
	if err == nil {
		t.Fatal("deposit unexpectedly posted for user without wallet")
	}
	if err := tx.Rollback(); err != nil {
		t.Fatal(err)
	}
	assertTreasuryAccounting(t, env.db, 0, nil, 0)
}

func TestPostConfirmedDepositConcurrentDuplicateAndIndependent(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)

	ctx := context.Background()
	svc := NewService(env.db)
	userA := createTestUser(ctx, t, env.db, "treasury-concurrent-a@example.com")
	userB := createTestUser(ctx, t, env.db, "treasury-concurrent-b@example.com")
	sharedIntent := uuid.NewString()
	independentIntent := uuid.NewString()

	type result struct {
		duplicate bool
		err       error
	}
	results := make(chan result, 3)
	start := make(chan struct{})
	var wg sync.WaitGroup
	post := func(userID string, amount int64, intentID string) {
		defer wg.Done()
		<-start
		tx, err := env.db.BeginTx(ctx, nil)
		if err != nil {
			results <- result{err: err}
			return
		}
		defer tx.Rollback()
		duplicate, err := svc.PostConfirmedDeposit(ctx, &TxAdapter{Tx: tx}, userID, amount, intentID)
		if err == nil {
			err = tx.Commit()
		}
		results <- result{duplicate: duplicate, err: err}
	}
	for _, item := range []struct {
		userID   string
		amount   int64
		intentID string
	}{
		{userA, 100, sharedIntent},
		{userA, 100, sharedIntent},
		{userB, 50, independentIntent},
	} {
		wg.Add(1)
		go post(item.userID, item.amount, item.intentID)
	}
	close(start)
	wg.Wait()
	close(results)

	duplicates := 0
	for got := range results {
		if got.err != nil {
			t.Fatal(got.err)
		}
		if got.duplicate {
			duplicates++
		}
	}
	if duplicates != 1 {
		t.Fatalf("duplicate results=%d want=1", duplicates)
	}
	assertTreasuryAccounting(t, env.db, 150, map[string]int64{userA: 100, userB: 50}, 2)
}

func TestPostConfirmedDepositRejectsNonPositiveMoney(t *testing.T) {
	svc := &Service{}
	for _, amount := range []int64{0, -1} {
		if _, err := svc.PostConfirmedDeposit(context.Background(), nil, uuid.NewString(), amount, uuid.NewString()); err == nil {
			t.Fatalf("amount %d accepted", amount)
		}
	}
}

func assertTreasuryAccounting(t *testing.T, db *sql.DB, treasuryWant int64, users map[string]int64, ledgerWant int) {
	t.Helper()
	ctx := context.Background()
	var treasuryGot int64
	if err := db.QueryRowContext(ctx,
		`SELECT balance_cents FROM treasury_accounts WHERE purpose = $1`, SuperAdminTreasuryPurpose,
	).Scan(&treasuryGot); err != nil {
		t.Fatal(err)
	}
	if treasuryGot != treasuryWant {
		t.Fatalf("Treasury balance=%d want=%d", treasuryGot, treasuryWant)
	}
	for userID, want := range users {
		got, err := NewService(db).GetBalance(ctx, userID)
		if err != nil {
			t.Fatal(err)
		}
		if got != want {
			t.Fatalf("user %s balance=%d want=%d", userID, got, want)
		}
	}
	var treasuryEntries, userEntries int
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM treasury_ledger`).Scan(&treasuryEntries); err != nil {
		t.Fatal(err)
	}
	if err := db.QueryRowContext(ctx, `SELECT COUNT(*) FROM wallet_ledger WHERE type = 'deposit'`).Scan(&userEntries); err != nil {
		t.Fatal(err)
	}
	if treasuryEntries != ledgerWant || userEntries != ledgerWant {
		t.Fatalf("Treasury entries=%d user entries=%d want=%d", treasuryEntries, userEntries, ledgerWant)
	}
}
