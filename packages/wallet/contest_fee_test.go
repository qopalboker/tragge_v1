package wallet

import (
	"context"
	"database/sql"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
)

func createFeeContest(t *testing.T, db *sql.DB, name string) string {
	t.Helper()
	var id string
	if err := db.QueryRow(`INSERT INTO contests (name) VALUES ($1) RETURNING id`, name).Scan(&id); err != nil {
		t.Fatal(err)
	}
	return id
}

func postFee(t *testing.T, db *sql.DB, svc *Service, contestID, userID string, kind ContestFeeKind, amount int64) bool {
	t.Helper()
	tx, err := db.BeginTx(context.Background(), nil)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback()
	duplicate, err := svc.PostContestFee(context.Background(), &TxAdapter{Tx: tx}, contestID, userID, kind, amount, 2000)
	if err != nil {
		t.Fatal(err)
	}
	if err := tx.Commit(); err != nil {
		t.Fatal(err)
	}
	return duplicate
}

func TestContestFeeWalletIdentityAndPurposeRestrictions(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)
	var count int
	if err := env.db.QueryRow(`SELECT COUNT(*) FROM contest_fee_accounts WHERE purpose=$1 AND account_kind='system_fee_revenue'`, ContestFeeWalletPurpose).Scan(&count); err != nil {
		t.Fatal(err)
	}
	if count != 1 {
		t.Fatalf("fee wallet count=%d", count)
	}
	if _, err := NewService(env.db).GetWallet(context.Background(), ContestFeeWalletPurpose); err == nil {
		t.Fatal("fee wallet exposed as user wallet")
	}
	if _, err := env.db.Exec(`DELETE FROM contest_fee_accounts WHERE purpose=$1`, ContestFeeWalletPurpose); err == nil {
		t.Fatal("fee wallet was deletable")
	}
	if _, err := env.db.Exec(`INSERT INTO contest_fee_accounts(purpose,account_kind) VALUES ('other','system_fee_revenue')`); err == nil {
		t.Fatal("second fee account accepted")
	}
}

func TestContestFeePostingBaseLateIdempotentAndAttributable(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)
	svc := NewService(env.db)
	userA := createTestUser(context.Background(), t, env.db, "fee-a@example.com")
	userB := createTestUser(context.Background(), t, env.db, "fee-b@example.com")
	contestA := createFeeContest(t, env.db, "A")
	contestB := createFeeContest(t, env.db, "B")
	if _, err := env.db.Exec(`UPDATE treasury_accounts SET balance_cents=1000 WHERE purpose=$1`, SuperAdminTreasuryPurpose); err != nil {
		t.Fatal(err)
	}
	if postFee(t, env.db, svc, contestA, userA, ContestFeeKindBase, 20) {
		t.Fatal("first base fee duplicate")
	}
	if postFee(t, env.db, svc, contestA, userA, ContestFeeKindLateSurcharge, 10) {
		t.Fatal("first surcharge duplicate")
	}
	if !postFee(t, env.db, svc, contestA, userA, ContestFeeKindBase, 20) {
		t.Fatal("replay not duplicate")
	}
	if postFee(t, env.db, svc, contestB, userB, ContestFeeKindBase, 20) {
		t.Fatal("independent contest duplicate")
	}
	view, err := svc.GetContestFeeWallet(context.Background(), 10, 0)
	if err != nil {
		t.Fatal(err)
	}
	if view.BalanceCents != 50 || view.BaseFeeTotalCents != 40 || view.SurchargeTotalCents != 10 || view.TotalEntries != 3 {
		t.Fatalf("unexpected view: %+v", view)
	}
	var treasuryBalance int64
	if err := env.db.QueryRow(`SELECT balance_cents FROM treasury_accounts WHERE purpose=$1`, SuperAdminTreasuryPurpose).Scan(&treasuryBalance); err != nil {
		t.Fatal(err)
	}
	if treasuryBalance != 950 {
		t.Fatalf("Treasury balance=%d want=950", treasuryBalance)
	}
	var pairedAmount int64
	if err := env.db.QueryRow(`SELECT amount_cents FROM treasury_ledger
		WHERE entry_kind='contest_fee_allocation' AND admission_id=$1 AND fee_kind=$2`,
		contestA+":"+userA, ContestFeeKindBase).Scan(&pairedAmount); err != nil {
		t.Fatal(err)
	}
	if pairedAmount != -20 {
		t.Fatalf("paired Treasury amount=%d want=-20", pairedAmount)
	}
	seen := map[string]bool{}
	for _, entry := range view.Entries {
		seen[entry.ContestID] = true
	}
	if !seen[contestA] || !seen[contestB] {
		t.Fatalf("contest attribution missing: %+v", seen)
	}
}

func TestContestFeePostingRollbackAndUnsupportedKinds(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)
	svc := NewService(env.db)
	userID := createTestUser(context.Background(), t, env.db, "fee-rollback@example.com")
	contestID := createFeeContest(t, env.db, "rollback")
	tx, err := env.db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	if _, err := env.db.Exec(`UPDATE treasury_accounts SET balance_cents=1000 WHERE purpose=$1`, SuperAdminTreasuryPurpose); err != nil {
		t.Fatal(err)
	}
	if _, err := svc.PostContestFee(context.Background(), &TxAdapter{Tx: tx}, contestID, userID, ContestFeeKindBase, 20, 2000); err != nil {
		t.Fatal(err)
	}
	if err := tx.Rollback(); err != nil {
		t.Fatal(err)
	}
	view, err := svc.GetContestFeeWallet(context.Background(), 10, 0)
	if err != nil {
		t.Fatal(err)
	}
	if view.BalanceCents != 0 || view.TotalEntries != 0 {
		t.Fatalf("rollback left effect: %+v", view)
	}
	var treasuryBalance int64
	var treasuryFeeEntries int
	if err := env.db.QueryRow(`SELECT balance_cents FROM treasury_accounts WHERE purpose=$1`, SuperAdminTreasuryPurpose).Scan(&treasuryBalance); err != nil {
		t.Fatal(err)
	}
	if err := env.db.QueryRow(`SELECT COUNT(*) FROM treasury_ledger WHERE entry_kind='contest_fee_allocation'`).Scan(&treasuryFeeEntries); err != nil {
		t.Fatal(err)
	}
	if treasuryBalance != 1000 || treasuryFeeEntries != 0 {
		t.Fatalf("rollback Treasury balance=%d entries=%d want 1000/0", treasuryBalance, treasuryFeeEntries)
	}
	for _, kind := range []ContestFeeKind{"deposit", "prize", "forfeiture", "withdrawal", "adjustment"} {
		if _, err := svc.PostContestFee(context.Background(), nil, contestID, userID, kind, 20, 2000); err == nil {
			t.Fatalf("unsupported kind %q accepted", kind)
		}
	}
}

func TestConfirmedDepositAndContestJoinUseCompatibleLockOrder(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)
	ctx := context.Background()
	svc := NewService(env.db)
	userID := createTestUser(ctx, t, env.db, "fee-lock-order@example.com")
	contestID := createFeeContest(t, env.db, "lock-order")
	if _, err := env.db.Exec(`UPDATE wallets SET balance_cents=100 WHERE user_id=$1`, userID); err != nil {
		t.Fatal(err)
	}
	if _, err := env.db.Exec(`UPDATE treasury_accounts SET balance_cents=1000 WHERE purpose=$1`, SuperAdminTreasuryPurpose); err != nil {
		t.Fatal(err)
	}

	depositTx, err := env.db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer depositTx.Rollback()
	if _, err := svc.LockTreasuryForFinancialOperation(ctx, &TxAdapter{Tx: depositTx}); err != nil {
		t.Fatal(err)
	}

	joinResult := make(chan error, 1)
	go func() {
		tx, err := env.db.BeginTx(ctx, nil)
		if err != nil {
			joinResult <- err
			return
		}
		defer tx.Rollback()
		if _, err = tx.ExecContext(ctx, `SET LOCAL application_name='fee_wallet_join_lock_test'`); err == nil {
			_, err = svc.LockTreasuryForFinancialOperation(ctx, &TxAdapter{Tx: tx})
		}
		if err == nil {
			_, err = svc.DeductContestEntryFeeWithName(ctx, &TxAdapter{Tx: tx}, userID, contestID, "lock-order", 100)
		}
		if err == nil {
			_, err = svc.PostContestFee(ctx, &TxAdapter{Tx: tx}, contestID, userID, ContestFeeKindBase, 20, 2000)
		}
		if err == nil {
			err = tx.Commit()
		}
		joinResult <- err
	}()

	deadline := time.Now().Add(5 * time.Second)
	for {
		var waiting bool
		err := env.db.QueryRow(`SELECT EXISTS (
			SELECT 1 FROM pg_stat_activity
			WHERE application_name='fee_wallet_join_lock_test' AND wait_event_type='Lock'
		)`).Scan(&waiting)
		if err != nil {
			t.Fatal(err)
		}
		if waiting {
			break
		}
		if time.Now().After(deadline) {
			t.Fatal("join never overlapped while waiting for Treasury lock")
		}
		time.Sleep(10 * time.Millisecond)
	}

	intentID := uuid.NewString()
	if duplicate, err := svc.PostConfirmedDeposit(ctx, &TxAdapter{Tx: depositTx}, userID, 50, intentID); err != nil || duplicate {
		t.Fatalf("deposit duplicate=%v err=%v", duplicate, err)
	}
	if err := depositTx.Commit(); err != nil {
		t.Fatal(err)
	}
	select {
	case err := <-joinResult:
		if err != nil {
			t.Fatal(err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("deposit-vs-join deadlocked")
	}

	var userBalance, treasuryBalance, feeBalance int64
	var depositEntries, entryDebits, treasuryDeposits, treasuryFees, feeEntries int
	if err := env.db.QueryRow(`SELECT balance_cents FROM wallets WHERE user_id=$1`, userID).Scan(&userBalance); err != nil {
		t.Fatal(err)
	}
	if err := env.db.QueryRow(`SELECT balance_cents FROM treasury_accounts WHERE purpose=$1`, SuperAdminTreasuryPurpose).Scan(&treasuryBalance); err != nil {
		t.Fatal(err)
	}
	if err := env.db.QueryRow(`SELECT balance_cents FROM contest_fee_accounts WHERE purpose=$1`, ContestFeeWalletPurpose).Scan(&feeBalance); err != nil {
		t.Fatal(err)
	}
	if err := env.db.QueryRow(`SELECT COUNT(*) FILTER (WHERE type='deposit'), COUNT(*) FILTER (WHERE type='contest_entry') FROM wallet_ledger`).Scan(&depositEntries, &entryDebits); err != nil {
		t.Fatal(err)
	}
	if err := env.db.QueryRow(`SELECT COUNT(*) FILTER (WHERE entry_kind='external_deposit'), COUNT(*) FILTER (WHERE entry_kind='contest_fee_allocation') FROM treasury_ledger`).Scan(&treasuryDeposits, &treasuryFees); err != nil {
		t.Fatal(err)
	}
	if err := env.db.QueryRow(`SELECT COUNT(*) FROM contest_fee_ledger`).Scan(&feeEntries); err != nil {
		t.Fatal(err)
	}
	if userBalance != 50 || treasuryBalance != 1030 || feeBalance != 20 ||
		depositEntries != 1 || entryDebits != 1 || treasuryDeposits != 1 || treasuryFees != 1 || feeEntries != 1 {
		t.Fatalf("balances user/treasury/fee=%d/%d/%d entries=%d/%d/%d/%d/%d", userBalance, treasuryBalance, feeBalance, depositEntries, entryDebits, treasuryDeposits, treasuryFees, feeEntries)
	}
}

func insertFeeSide(t *testing.T, db *sql.DB, contestID, userID string, kind ContestFeeKind, amount int64) string {
	t.Helper()
	admissionID := contestID + ":" + userID
	var id string
	if err := db.QueryRow(`INSERT INTO contest_fee_ledger (
		fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,
		participant_user_id,admission_id,policy_version,platform_fee_bps
	) VALUES ($1,$2,$3,$3,$4,$5,$6,$7,2000) RETURNING id`,
		ContestFeeWalletPurpose, kind, amount, contestID, userID, admissionID, ContestFundsPolicyVersion,
	).Scan(&id); err != nil {
		t.Fatal(err)
	}
	return id
}

func insertTreasuryFeeSide(t *testing.T, db *sql.DB, contestID, userID, admissionID string, kind ContestFeeKind, amount int64) {
	t.Helper()
	if _, err := db.Exec(`INSERT INTO treasury_ledger (
		treasury_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,
		participant_user_id,admission_id,fee_kind
	) VALUES ($1,'contest_fee_allocation',$2,980,$3,$4,$5,$6)`,
		SuperAdminTreasuryPurpose, amount, contestID, userID, admissionID, kind,
	); err != nil {
		t.Fatal(err)
	}
}

func replayFee(t *testing.T, db *sql.DB, contestID, userID string, kind ContestFeeKind, amount int64) error {
	t.Helper()
	tx, err := db.Begin()
	if err != nil {
		return err
	}
	defer tx.Rollback()
	_, err = NewService(db).PostContestFee(context.Background(), &TxAdapter{Tx: tx}, contestID, userID, kind, amount, 2000)
	return err
}

func TestContestFeeReplayRequiresExactTreasuryPair(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}

	t.Run("fee side only", func(t *testing.T) {
		env := setupTestDB(t)
		defer env.cleanup(t)
		userID := createTestUser(context.Background(), t, env.db, "pair-fee-only@example.com")
		contestID := createFeeContest(t, env.db, "fee-only")
		if _, err := env.db.Exec(`UPDATE treasury_accounts SET balance_cents=1000`); err != nil {
			t.Fatal(err)
		}
		insertFeeSide(t, env.db, contestID, userID, ContestFeeKindBase, 20)
		if err := replayFee(t, env.db, contestID, userID, ContestFeeKindBase, 20); err == nil {
			t.Fatal("fee-only replay accepted")
		}
	})

	t.Run("treasury side only", func(t *testing.T) {
		env := setupTestDB(t)
		defer env.cleanup(t)
		userID := createTestUser(context.Background(), t, env.db, "pair-treasury-only@example.com")
		contestID := createFeeContest(t, env.db, "treasury-only")
		if _, err := env.db.Exec(`UPDATE treasury_accounts SET balance_cents=980`); err != nil {
			t.Fatal(err)
		}
		insertTreasuryFeeSide(t, env.db, contestID, userID, contestID+":"+userID, ContestFeeKindBase, -20)
		if err := replayFee(t, env.db, contestID, userID, ContestFeeKindBase, 20); err == nil {
			t.Fatal("Treasury-only replay accepted")
		}
	})

	for _, mismatch := range []string{"amount", "contest", "participant", "fee kind"} {
		t.Run("mismatch "+mismatch, func(t *testing.T) {
			env := setupTestDB(t)
			defer env.cleanup(t)
			userID := createTestUser(context.Background(), t, env.db, "pair-"+strings.ReplaceAll(mismatch, " ", "-")+"@example.com")
			otherUser := createTestUser(context.Background(), t, env.db, "pair-other-"+strings.ReplaceAll(mismatch, " ", "-")+"@example.com")
			contestID := createFeeContest(t, env.db, "pair")
			otherContest := createFeeContest(t, env.db, "pair-other")
			if _, err := env.db.Exec(`UPDATE treasury_accounts SET balance_cents=1000`); err != nil {
				t.Fatal(err)
			}
			insertFeeSide(t, env.db, contestID, userID, ContestFeeKindBase, 20)
			treasuryContest, treasuryUser := contestID, userID
			treasuryKind, treasuryAmount := ContestFeeKindBase, int64(-20)
			switch mismatch {
			case "amount":
				treasuryAmount = -21
			case "contest":
				treasuryContest = otherContest
			case "participant":
				treasuryUser = otherUser
			case "fee kind":
				treasuryKind = ContestFeeKindLateSurcharge
			}
			insertTreasuryFeeSide(t, env.db, treasuryContest, treasuryUser, contestID+":"+userID, treasuryKind, treasuryAmount)
			if err := replayFee(t, env.db, contestID, userID, ContestFeeKindBase, 20); err == nil {
				t.Fatalf("%s mismatch accepted", mismatch)
			}
		})
	}
}

func TestLateAdmissionAllowsTwoExactIndependentReversals(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)
	userID := createTestUser(context.Background(), t, env.db, "reversal@example.com")
	otherUser := createTestUser(context.Background(), t, env.db, "reversal-other@example.com")
	contestID := createFeeContest(t, env.db, "late")
	otherContest := createFeeContest(t, env.db, "other")
	admissionID := contestID + ":" + userID
	baseID := insertFeeSide(t, env.db, contestID, userID, ContestFeeKindBase, 20)
	lateID := insertFeeSide(t, env.db, contestID, userID, ContestFeeKindLateSurcharge, 10)

	insertReversal := func(originalID string, amount int64, contest, participant, admission, policy string, bps int) error {
		_, err := env.db.Exec(`INSERT INTO contest_fee_ledger (
			fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,contest_id,
			participant_user_id,admission_id,policy_version,platform_fee_bps,original_entry_id
		) VALUES ($1,'contest_fee_refund_reversal',$2,0,$3,$4,$5,$6,$7,$8)`,
			ContestFeeWalletPurpose, amount, contest, participant, admission, policy, bps, originalID)
		return err
	}
	for name, change := range map[string]func() error{
		"wrong amount": func() error {
			return insertReversal(baseID, -19, contestID, userID, admissionID, ContestFundsPolicyVersion, 2000)
		},
		"wrong contest": func() error {
			return insertReversal(baseID, -20, otherContest, userID, admissionID, ContestFundsPolicyVersion, 2000)
		},
		"wrong participant": func() error {
			return insertReversal(baseID, -20, contestID, otherUser, admissionID, ContestFundsPolicyVersion, 2000)
		},
		"wrong admission": func() error {
			return insertReversal(baseID, -20, contestID, userID, "wrong", ContestFundsPolicyVersion, 2000)
		},
		"wrong policy": func() error { return insertReversal(baseID, -20, contestID, userID, admissionID, "wrong", 2000) },
		"wrong bps": func() error {
			return insertReversal(baseID, -20, contestID, userID, admissionID, ContestFundsPolicyVersion, 2001)
		},
	} {
		t.Run(name, func(t *testing.T) {
			if err := change(); err == nil {
				t.Fatalf("%s accepted", name)
			}
		})
	}
	if err := insertReversal(baseID, -20, contestID, userID, admissionID, ContestFundsPolicyVersion, 2000); err != nil {
		t.Fatal(err)
	}
	if err := insertReversal(lateID, -10, contestID, userID, admissionID, ContestFundsPolicyVersion, 2000); err != nil {
		t.Fatal(err)
	}
	if err := insertReversal(baseID, -20, contestID, userID, admissionID, ContestFundsPolicyVersion, 2000); err == nil {
		t.Fatal("second base reversal accepted")
	}
	if err := insertReversal(lateID, -10, contestID, userID, admissionID, ContestFundsPolicyVersion, 2000); err == nil {
		t.Fatal("second surcharge reversal accepted")
	}
	var reversals int
	if err := env.db.QueryRow(`SELECT COUNT(*) FROM contest_fee_ledger WHERE entry_kind='contest_fee_refund_reversal'`).Scan(&reversals); err != nil {
		t.Fatal(err)
	}
	if reversals != 2 {
		t.Fatalf("reversals=%d want=2", reversals)
	}
}

func TestContestFeeLedgerAppendOnlyAndConcurrentDuplicate(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)
	svc := NewService(env.db)
	userID := createTestUser(context.Background(), t, env.db, "fee-concurrent@example.com")
	contestID := createFeeContest(t, env.db, "concurrent")
	if _, err := env.db.Exec(`UPDATE treasury_accounts SET balance_cents=1000 WHERE purpose=$1`, SuperAdminTreasuryPurpose); err != nil {
		t.Fatal(err)
	}
	start := make(chan struct{})
	results := make(chan error, 2)
	var wg sync.WaitGroup
	for range 2 {
		wg.Add(1)
		go func() {
			defer wg.Done()
			<-start
			tx, err := env.db.Begin()
			if err != nil {
				results <- err
				return
			}
			defer tx.Rollback()
			_, err = svc.PostContestFee(context.Background(), &TxAdapter{Tx: tx}, contestID, userID, ContestFeeKindBase, 20, 2000)
			if err == nil {
				err = tx.Commit()
			}
			results <- err
		}()
	}
	close(start)
	wg.Wait()
	close(results)
	for err := range results {
		if err != nil {
			t.Fatal(err)
		}
	}
	view, err := svc.GetContestFeeWallet(context.Background(), 10, 0)
	if err != nil {
		t.Fatal(err)
	}
	if view.BalanceCents != 20 || view.TotalEntries != 1 {
		t.Fatalf("concurrent duplicate effect: %+v", view)
	}
	entryID := view.Entries[0].ID
	if _, err := env.db.Exec(`UPDATE contest_fee_ledger SET amount_cents=21 WHERE id=$1`, entryID); err == nil {
		t.Fatal("ledger update accepted")
	}
	if _, err := env.db.Exec(`DELETE FROM contest_fee_ledger WHERE id=$1`, entryID); err == nil {
		t.Fatal("ledger delete accepted")
	}
}

func TestContestFeePostingRejectsInvalidMoneyAndIdentity(t *testing.T) {
	svc := &Service{}
	for _, amount := range []int64{0, -1} {
		if _, err := svc.PostContestFee(context.Background(), nil, uuid.NewString(), uuid.NewString(), ContestFeeKindBase, amount, 2000); err == nil {
			t.Fatalf("amount %d accepted", amount)
		}
	}
	if _, err := svc.PostContestFee(context.Background(), nil, "public-input", uuid.NewString(), ContestFeeKindBase, 1, 2000); err == nil {
		t.Fatal("invalid contest identity accepted")
	}
}
