package wallet

import (
	"context"
	"testing"

	"github.com/google/uuid"
)

func TestContestAdmissionReversalPostgresReconcilesAndRollsBack(t *testing.T) {
	if testing.Short() {
		t.Skip("requires real PostgreSQL via testcontainers")
	}
	env := setupTestDB(t)
	defer env.cleanup(t)
	ctx := context.Background()
	svc := NewService(env.db)
	actor := createTestUser(ctx, t, env.db, "reversal-actor@example.test")
	participant := createTestUser(ctx, t, env.db, "reversal-user@example.test")
	contest := createFeeContest(t, env.db, "reversal")
	if _, err := env.db.Exec(`UPDATE wallets SET balance_cents=100 WHERE user_id=$1`, participant); err != nil {
		t.Fatal(err)
	}
	if _, err := env.db.Exec(`UPDATE treasury_accounts SET balance_cents=100 WHERE purpose=$1`, SuperAdminTreasuryPurpose); err != nil {
		t.Fatal(err)
	}
	tx, err := env.db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	if _, err = svc.LockTreasuryForFinancialOperation(ctx, tx); err != nil {
		t.Fatal(err)
	}
	if _, err = svc.DeductContestEntryFeeWithName(ctx, tx, participant, contest, "reversal", 100); err != nil {
		t.Fatal(err)
	}
	if _, err = svc.PostContestFee(ctx, tx, contest, participant, ContestFeeKindBase, 20, 2000); err != nil {
		t.Fatal(err)
	}
	if _, err = svc.PostContestPrizeContribution(ctx, tx, contest, participant, 80); err != nil {
		t.Fatal(err)
	}
	if _, err = tx.Exec(`INSERT INTO contest_participants(contest_id,user_id) VALUES($1,$2)`, contest, participant); err != nil {
		t.Fatal(err)
	}
	if err = tx.Commit(); err != nil {
		t.Fatal(err)
	}

	event := uuid.NewString()
	tx, err = env.db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	if _, err = tx.Exec(`INSERT INTO contest_participant_lifecycle_events(id,contest_id,participant_id,actor_id,event_type,reason,refund_decision) VALUES($1,$2,$3,$4,'PARTICIPANT_REMOVED','OTHER',true)`, event, contest, participant, actor); err != nil {
		t.Fatal(err)
	}
	r, err := svc.ReverseContestAdmission(ctx, tx, contest, participant, actor, event, "OTHER")
	if err != nil {
		t.Fatal(err)
	}
	if r.WalletCents != 100 || r.FeeCents != 20 || r.PrizePoolCents != 80 || r.TreasuryCents != 100 {
		t.Fatalf("unexpected reconciliation: %+v", r)
	}
	if err = tx.Rollback(); err != nil {
		t.Fatal(err)
	}
	assertReversalCounts(t, env, contest, participant, 0)

	event = uuid.NewString()
	tx, err = env.db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	if _, err = tx.Exec(`INSERT INTO contest_participant_lifecycle_events(id,contest_id,participant_id,actor_id,event_type,reason,refund_decision) VALUES($1,$2,$3,$4,'PARTICIPANT_REMOVED','OTHER',true)`, event, contest, participant, actor); err != nil {
		t.Fatal(err)
	}
	if _, err = svc.ReverseContestAdmission(ctx, tx, contest, participant, actor, event, "OTHER"); err != nil {
		t.Fatal(err)
	}
	if err = tx.Commit(); err != nil {
		t.Fatal(err)
	}
	assertReversalCounts(t, env, contest, participant, 1)
	var walletBalance, feeBalance, poolBalance, treasuryBalance int64
	if err = env.db.QueryRow(`SELECT balance_cents FROM wallets WHERE user_id=$1`, participant).Scan(&walletBalance); err != nil {
		t.Fatal(err)
	}
	if err = env.db.QueryRow(`SELECT balance_cents FROM contest_fee_accounts`).Scan(&feeBalance); err != nil {
		t.Fatal(err)
	}
	if err = env.db.QueryRow(`SELECT balance_cents FROM contest_prize_pool_accounts WHERE contest_id=$1`, contest).Scan(&poolBalance); err != nil {
		t.Fatal(err)
	}
	if err = env.db.QueryRow(`SELECT balance_cents FROM treasury_accounts`).Scan(&treasuryBalance); err != nil {
		t.Fatal(err)
	}
	if walletBalance != 100 || feeBalance != 0 || poolBalance != 0 || treasuryBalance != 100 {
		t.Fatalf("balances wallet=%d fee=%d pool=%d treasury=%d", walletBalance, feeBalance, poolBalance, treasuryBalance)
	}
	duplicateEvent := uuid.NewString()
	tx, err = env.db.Begin()
	if err != nil {
		t.Fatal(err)
	}
	if _, err = tx.Exec(`INSERT INTO contest_participant_lifecycle_events(id,contest_id,participant_id,actor_id,event_type,reason,refund_decision) VALUES($1,$2,$3,$4,'PARTICIPANT_REFUNDED','OTHER',true)`, duplicateEvent, contest, participant, actor); err != nil {
		t.Fatal(err)
	}
	if _, err = svc.ReverseContestAdmission(ctx, tx, contest, participant, actor, duplicateEvent, "OTHER"); err == nil {
		t.Fatal("duplicate reversal unexpectedly succeeded")
	}
	if err = tx.Rollback(); err != nil {
		t.Fatal(err)
	}
	assertReversalCounts(t, env, contest, participant, 1)
	var auditID string
	if err = env.db.QueryRow(`INSERT INTO audit_logs(actor_user_id,action,target_type,target_id,payload_json)
		VALUES($1,'contest.remove_participant','contest_participant',$2,'{}') RETURNING id::text`, actor, contest).Scan(&auditID); err != nil {
		t.Fatal(err)
	}
	if _, err = env.db.Exec(`UPDATE audit_logs SET payload_json='{"changed":true}' WHERE id=$1`, auditID); err == nil {
		t.Fatal("financial lifecycle audit update unexpectedly succeeded")
	}
	if _, err = env.db.Exec(`DELETE FROM audit_logs WHERE id=$1`, auditID); err == nil {
		t.Fatal("financial lifecycle audit delete unexpectedly succeeded")
	}
}

func assertReversalCounts(t *testing.T, env *testEnv, contest, participant string, want int) {
	t.Helper()
	var walletCount, feeCount, poolCount, treasuryCount int
	queries := []struct {
		q    string
		dest *int
	}{
		{`SELECT COUNT(*) FROM wallet_ledger WHERE original_transaction_id IS NOT NULL AND ref_id=$1`, &walletCount},
		{`SELECT COUNT(*) FROM contest_fee_ledger WHERE original_entry_id IS NOT NULL AND contest_id=$1 AND participant_user_id=$2`, &feeCount},
		{`SELECT COUNT(*) FROM contest_prize_pool_ledger WHERE original_ledger_id IS NOT NULL AND contest_id=$1 AND participant_user_id=$2`, &poolCount},
		{`SELECT COUNT(*) FROM treasury_ledger WHERE original_ledger_id IS NOT NULL AND contest_id=$1 AND participant_user_id=$2`, &treasuryCount},
	}
	for i, x := range queries {
		if i == 0 {
			if err := env.db.QueryRow(x.q, contest).Scan(x.dest); err != nil {
				t.Fatal(err)
			}
		} else {
			if err := env.db.QueryRow(x.q, contest, participant).Scan(x.dest); err != nil {
				t.Fatal(err)
			}
		}
	}
	if walletCount != want || feeCount != want || poolCount != want || treasuryCount != 2*want {
		t.Fatalf("reversals wallet=%d fee=%d pool=%d treasury=%d", walletCount, feeCount, poolCount, treasuryCount)
	}
}
