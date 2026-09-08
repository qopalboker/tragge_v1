package wallet

import (
	"context"
	"database/sql"
	"sync"
	"testing"
)

func postPool(t *testing.T, db *sql.DB, svc *Service, contestID, userID string, amount int64) bool {
	t.Helper()
	tx, err := db.BeginTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback()
	if _, err = svc.LockTreasuryForFinancialOperation(context.Background(), tx); err != nil {
		t.Fatal(err)
	}
	duplicate, err := svc.PostContestPrizeContribution(context.Background(), tx, contestID, userID, amount)
	if err != nil {
		t.Fatal(err)
	}
	if err = tx.Commit(); err != nil {
		t.Fatal(err)
	}
	return duplicate
}

func TestContestPrizePoolCreationContributionRetryAndRollback(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)
	svc := NewService(env.db)
	contestID := createFeeContest(t, env.db, "pool")
	userID := createTestUser(context.Background(), t, env.db, "pool@example.com")
	var accountCount int
	if err := env.db.QueryRow(`SELECT COUNT(*) FROM contest_prize_pool_accounts WHERE contest_id=$1`, contestID).Scan(&accountCount); err != nil {
		t.Fatal(err)
	}
	if accountCount != 1 {
		t.Fatalf("pool account count=%d want=1", accountCount)
	}
	if _, err := env.db.Exec(`UPDATE treasury_accounts SET balance_cents=100 WHERE purpose=$1`, SuperAdminTreasuryPurpose); err != nil {
		t.Fatal(err)
	}
	if postPool(t, env.db, svc, contestID, userID, 80) {
		t.Fatal("first contribution reported duplicate")
	}
	if !postPool(t, env.db, svc, contestID, userID, 80) {
		t.Fatal("retry was not idempotent")
	}
	view, err := svc.GetContestPrizePool(context.Background(), contestID, 10, 0)
	if err != nil {
		t.Fatal(err)
	}
	if view.BalanceCents != 80 || len(view.Entries) != 1 || view.Entries[0].AmountCents != 80 {
		t.Fatalf("unexpected pool view: %+v", view)
	}
	var treasury int64
	if err := env.db.QueryRow(`SELECT balance_cents FROM treasury_accounts WHERE purpose=$1`, SuperAdminTreasuryPurpose).Scan(&treasury); err != nil {
		t.Fatal(err)
	}
	if treasury != 20 {
		t.Fatalf("treasury=%d want=20", treasury)
	}

	other := createTestUser(context.Background(), t, env.db, "rollback-pool@example.com")
	tx, err := env.db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	if _, err = svc.LockTreasuryForFinancialOperation(context.Background(), tx); err != nil {
		t.Fatal(err)
	}
	if _, err = svc.PostContestPrizeContribution(context.Background(), tx, contestID, other, 20); err != nil {
		t.Fatal(err)
	}
	if err = tx.Rollback(); err != nil {
		t.Fatal(err)
	}
	if err = env.db.QueryRow(`SELECT balance_cents FROM contest_prize_pool_accounts WHERE contest_id=$1`, contestID).Scan(&treasury); err != nil {
		t.Fatal(err)
	}
	if treasury != 80 {
		t.Fatalf("rollback left pool balance=%d", treasury)
	}
}

func TestContestPrizePoolConcurrentAdmissions(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)
	svc := NewService(env.db)
	contestID := createFeeContest(t, env.db, "pool-concurrent")
	users := []string{createTestUser(context.Background(), t, env.db, "pool-a@example.com"), createTestUser(context.Background(), t, env.db, "pool-b@example.com")}
	if _, err := env.db.Exec(`UPDATE treasury_accounts SET balance_cents=160 WHERE purpose=$1`, SuperAdminTreasuryPurpose); err != nil {
		t.Fatal(err)
	}
	errCh := make(chan error, 2)
	var wg sync.WaitGroup
	for _, userID := range users {
		wg.Add(1)
		go func(uid string) {
			defer wg.Done()
			tx, err := env.db.Begin()
			if err == nil {
				_, err = svc.LockTreasuryForFinancialOperation(context.Background(), tx)
			}
			if err == nil {
				_, err = svc.PostContestPrizeContribution(context.Background(), tx, contestID, uid, 80)
			}
			if err == nil {
				err = tx.Commit()
			} else if tx != nil {
				_ = tx.Rollback()
			}
			errCh <- err
		}(userID)
	}
	wg.Wait()
	close(errCh)
	for err := range errCh {
		if err != nil {
			t.Fatal(err)
		}
	}
	var balance, ledgerSum int64
	var count int
	if err := env.db.QueryRow(`SELECT a.balance_cents,COALESCE(SUM(l.amount_cents),0),COUNT(l.id) FROM contest_prize_pool_accounts a LEFT JOIN contest_prize_pool_ledger l ON l.pool_account_id=a.id WHERE a.contest_id=$1 GROUP BY a.id`, contestID).Scan(&balance, &ledgerSum, &count); err != nil {
		t.Fatal(err)
	}
	if balance != 160 || ledgerSum != 160 || count != 2 {
		t.Fatalf("balance=%d ledger=%d count=%d", balance, ledgerSum, count)
	}
}

func TestContestPrizePoolRejectsWrongAccountAndMutation(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)
	c1, c2 := createFeeContest(t, env.db, "owner-a"), createFeeContest(t, env.db, "owner-b")
	u := createTestUser(context.Background(), t, env.db, "owner@example.com")
	var account string
	if err := env.db.QueryRow(`SELECT id FROM contest_prize_pool_accounts WHERE contest_id=$1`, c2).Scan(&account); err != nil {
		t.Fatal(err)
	}
	if _, err := env.db.Exec(`INSERT INTO contest_prize_pool_ledger(contest_id,pool_account_id,amount_cents,direction,reason,reference_type,reference_id,participant_user_id,policy_version,balance_after_cents,idempotency_key) VALUES($1,$2,1,'credit','contest_admission','contest_admission','wrong',$3,$4,1,'wrong')`, c1, account, u, ContestPrizePoolPolicyV1); err == nil {
		t.Fatal("wrong contest/account ownership accepted")
	}
	if _, err := env.db.Exec(`INSERT INTO contest_prize_pool_ledger(contest_id,pool_account_id,amount_cents,direction,reason,reference_type,reference_id,participant_user_id,policy_version,balance_after_cents,idempotency_key) VALUES($1,$2,1,'credit','contest_admission','contest_admission','valid',$3,$4,1,'valid')`, c2, account, u, ContestPrizePoolPolicyV1); err != nil {
		t.Fatal(err)
	}
	if _, err := env.db.Exec(`UPDATE contest_prize_pool_ledger SET amount_cents=2 WHERE pool_account_id=$1`, account); err == nil {
		t.Fatal("ledger mutation accepted")
	}
	if _, err := env.db.Exec(`UPDATE contest_prize_pool_accounts SET balance_cents=2 WHERE id=$1`, account); err == nil {
		t.Fatal("direct pool balance update accepted")
	}
}
