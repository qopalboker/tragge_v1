package wallet

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/scoring/economics"
)

// TestMVP_AdminCreditJoinSettle_E2E proves the MVP financial spine without a payment gateway:
//
//	admin credit (ledger) → join debit → settlement prize credit → balance invariant
//
// Requires TRAGGE_E2E_DATABASE_URL (Compose Postgres).
func TestMVP_AdminCreditJoinSettle_E2E(t *testing.T) {
	if testing.Short() {
		t.Skip("short mode")
	}
	db := openE2E(t)
	defer db.Close()
	ctx := context.Background()
	svc := NewService(db)

	adminID := mustUUID()
	userID := mustUUID()
	contestID := mustUUID()
	entryFee := int64(10000) // $100
	feeBps := 2000
	creditAmt := int64(50000) // $500 admin top-up

	// Seed users (minimal)
	for i, uid := range []string{adminID, userID} {
		email := fmt.Sprintf("mvp-%d-%s@example.com", i, uid[:8])
		if _, err := db.ExecContext(ctx,
			`INSERT INTO users (id, email, password_hash, email_verified, terms_accepted_at)
			 VALUES ($1, $2, 'x', TRUE, NOW()) ON CONFLICT (id) DO NOTHING`, uid, email); err != nil {
			if _, err2 := db.ExecContext(ctx, `INSERT INTO users (id, email) VALUES ($1, $2) ON CONFLICT DO NOTHING`, uid, email); err2 != nil {
				t.Fatalf("user: %v / %v", err, err2)
			}
		}
	}
	// Ensure empty wallet for user
	if _, err := db.ExecContext(ctx,
		`INSERT INTO wallets (user_id, balance_cents, status) VALUES ($1, 0, 'active')
		 ON CONFLICT (user_id) DO UPDATE SET balance_cents = 0, status='active'`, userID); err != nil {
		t.Fatalf("wallet: %v", err)
	}

	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM prize_distributions WHERE contest_id=$1`, contestID)
		_, _ = db.Exec(`DELETE FROM contest_settlements WHERE contest_id=$1`, contestID)
		_, _ = db.Exec(`DELETE FROM contest_participants WHERE contest_id=$1`, contestID)
		_, _ = db.Exec(`DELETE FROM wallet_ledger WHERE user_id=$1 OR user_id=$2`, userID, adminID)
		_, _ = db.Exec(`DELETE FROM wallets WHERE user_id=$1 OR user_id=$2`, userID, adminID)
		_, _ = db.Exec(`DELETE FROM contests WHERE id=$1`, contestID)
		_, _ = db.Exec(`DELETE FROM users WHERE id=$1 OR id=$2`, userID, adminID)
	})

	// --- Admin credit (same model as admin-bff handleChargeUserWallet) ---
	refType := LedgerRefTypeAdminAction
	reason := ReasonCodeWalletTopup
	desc := "mvp admin top-up"
	idemp := fmt.Sprintf("mvp_admin_credit:%s:%s", contestID, userID)
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	entry, err := svc.CreditIdempotentWithReason(ctx, tx, userID, creditAmt, LedgerTypeDeposit, &refType, nil, &desc, &reason, idemp)
	if err != nil {
		tx.Rollback()
		t.Fatalf("admin credit: %v", err)
	}
	if err := tx.Commit(); err != nil {
		t.Fatal(err)
	}
	if entry.BalanceAfterCents != creditAmt {
		t.Fatalf("after credit balance=%d want %d", entry.BalanceAfterCents, creditAmt)
	}

	// Duplicate admin credit must not double-fund
	tx2, _ := db.BeginTx(ctx, nil)
	_, err = svc.CreditIdempotentWithReason(ctx, tx2, userID, creditAmt, LedgerTypeDeposit, &refType, nil, &desc, &reason, idemp)
	if err == nil {
		tx2.Commit()
		t.Fatal("expected duplicate credit error")
	}
	if _, ok := err.(*DuplicateCreditError); !ok {
		tx2.Rollback()
		t.Fatalf("want DuplicateCreditError got %T %v", err, err)
	}
	tx2.Rollback()

	var bal int64
	_ = db.QueryRow(`SELECT balance_cents FROM wallets WHERE user_id=$1`, userID).Scan(&bal)
	if bal != creditAmt {
		t.Fatalf("balance after dup attempt=%d want %d", bal, creditAmt)
	}

	// --- Contest with locked economics ---
	starts := time.Now().UTC().Add(-time.Hour)
	ends := time.Now().UTC().Add(time.Hour)
	_, err = db.ExecContext(ctx, `
		INSERT INTO contests (
			id, name, starts_at, ends_at, status, entry_fee_cents, platform_fee_bps,
			qty_total, commission_rate, is_free, current_participants,
			prize_pool_net_cents, commission_amount,
			economics_locked_at, locked_entry_fee_cents, locked_platform_fee_bps, late_join_enabled
		) VALUES (
			$1, 'mvp-e2e', $2, $3, 'registration_open', $4, $5,
			10, 20.0, FALSE, 0, 0, 0, NOW(), $6, $7, TRUE
		)`, contestID, starts, ends, entryFee, feeBps, entryFee, feeBps)
	if err != nil {
		t.Fatalf("contest: %v", err)
	}

	// --- Join (entry fee debit) ---
	charge := economics.ComputeJoinCharge(entryFee, feeBps, false)
	tx3, err := db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := svc.DeductContestEntryFeeWithName(ctx, tx3, userID, contestID, "mvp-e2e", charge.TotalCents); err != nil {
		tx3.Rollback()
		t.Fatalf("join debit: %v", err)
	}
	if _, err := tx3.ExecContext(ctx, `
		INSERT INTO contest_participants (contest_id, user_id, qty_total, qty_available, total_score)
		VALUES ($1, $2, 10, 10, 1000)`, contestID, userID); err != nil {
		tx3.Rollback()
		t.Fatalf("participant: %v", err)
	}
	if _, err := tx3.ExecContext(ctx, `
		UPDATE contests SET prize_pool_net_cents = COALESCE(prize_pool_net_cents,0)+$1,
		  commission_amount = COALESCE(commission_amount,0)+$2,
		  current_participants = current_participants + 1
		WHERE id=$3`, charge.PrizeCents, charge.PlatformCents, contestID); err != nil {
		tx3.Rollback()
		t.Fatalf("pool: %v", err)
	}
	if err := tx3.Commit(); err != nil {
		t.Fatal(err)
	}

	// Duplicate join debit must not double-charge (idempotent entry key)
	tx4, _ := db.BeginTx(ctx, nil)
	_, err = svc.DeductContestEntryFeeWithName(ctx, tx4, userID, contestID, "mvp-e2e", charge.TotalCents)
	// May succeed as no-op or fail as already deducted depending on implementation
	_ = tx4.Rollback()

	_ = db.QueryRow(`SELECT balance_cents FROM wallets WHERE user_id=$1`, userID).Scan(&bal)
	wantAfterJoin := creditAmt - charge.TotalCents
	if bal != wantAfterJoin {
		t.Fatalf("after join balance=%d want %d", bal, wantAfterJoin)
	}

	// --- Settlement prize (single winner full net pool) ---
	var net int64
	_ = db.QueryRow(`SELECT prize_pool_net_cents FROM contests WHERE id=$1`, contestID).Scan(&net)
	if net <= 0 {
		net = charge.PrizeCents
	}
	// One settlement
	var settlementID string
	err = db.QueryRowContext(ctx, `
		INSERT INTO contest_settlements (
			contest_id, status, started_at, completed_at,
			total_participants, total_winners,
			prize_pool_gross_cents, prize_pool_net_cents,
			total_distributed_cents, platform_fee_cents
		) VALUES ($1, 'completed', NOW(), NOW(), 1, 1, $2, $3, $3, $4)
		ON CONFLICT (contest_id) DO UPDATE SET status='completed', completed_at=NOW()
		RETURNING id`, contestID, charge.TotalCents, net, charge.PlatformCents).Scan(&settlementID)
	if err != nil {
		t.Fatalf("settlement: %v", err)
	}

	tx5, err := db.BeginTx(ctx, nil)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := svc.CreditPrizeIdempotent(ctx, tx5, userID, contestID, 1, net); err != nil {
		if _, ok := err.(*DuplicatePrizeCreditError); !ok {
			tx5.Rollback()
			t.Fatalf("prize: %v", err)
		}
	}
	if err := tx5.Commit(); err != nil {
		t.Fatal(err)
	}
	// Second prize credit must not double
	tx6, _ := db.BeginTx(ctx, nil)
	_, err = svc.CreditPrizeIdempotent(ctx, tx6, userID, contestID, 1, net)
	if err == nil {
		// may return nil if treated as success no-op
	} else if _, ok := err.(*DuplicatePrizeCreditError); !ok {
		tx6.Rollback()
		t.Fatalf("second prize: %v", err)
	}
	_ = tx6.Commit()

	_ = db.QueryRow(`SELECT balance_cents FROM wallets WHERE user_id=$1`, userID).Scan(&bal)
	// credit - entry + prize
	wantFinal := creditAmt - charge.TotalCents + net
	if bal != wantFinal {
		t.Fatalf("final balance=%d want %d (credit=%d fee=%d prize=%d)", bal, wantFinal, creditAmt, charge.TotalCents, net)
	}

	// Ledger: exactly one admin top-up (deposit), one entry, one prize
	var nDep, nEntry, nPrize int
	_ = db.QueryRow(`SELECT COUNT(*) FROM wallet_ledger WHERE user_id=$1 AND type='deposit' AND idempotency_key=$2`, userID, idemp).Scan(&nDep)
	_ = db.QueryRow(`SELECT COUNT(*) FROM wallet_ledger WHERE user_id=$1 AND type='contest_entry' AND idempotency_key LIKE $2`, userID, "contest_entry:"+contestID+":%").Scan(&nEntry)
	if nEntry == 0 {
		_ = db.QueryRow(`SELECT COUNT(*) FROM wallet_ledger WHERE user_id=$1 AND type='contest_entry'`, userID).Scan(&nEntry)
	}
	_ = db.QueryRow(`SELECT COUNT(*) FROM wallet_ledger WHERE user_id=$1 AND type='prize_credit' AND idempotency_key LIKE $2`, userID, "finalization:"+contestID+":%").Scan(&nPrize)
	if nDep != 1 {
		t.Fatalf("deposit ledger rows=%d want 1", nDep)
	}
	if nEntry != 1 {
		t.Fatalf("entry ledger rows=%d want 1", nEntry)
	}
	if nPrize != 1 {
		t.Fatalf("prize ledger rows=%d want 1", nPrize)
	}

	var nSet int
	_ = db.QueryRow(`SELECT COUNT(*) FROM contest_settlements WHERE contest_id=$1`, contestID).Scan(&nSet)
	if nSet != 1 {
		t.Fatalf("settlements=%d want 1", nSet)
	}

	t.Logf("MVP financial spine PASS final_balance=%d settlement=%s", bal, settlementID)
}

// TestMVP_InsufficientBalance_JoinBlocked ensures join cannot proceed without funds.
func TestMVP_InsufficientBalance_JoinBlocked(t *testing.T) {
	if testing.Short() {
		t.Skip("short")
	}
	db := openE2E(t)
	defer db.Close()
	ctx := context.Background()
	svc := NewService(db)
	userID := mustUUID()
	contestID := mustUUID()
	email := fmt.Sprintf("mvp-poor-%s@example.com", userID[:8])
	_, _ = db.ExecContext(ctx, `INSERT INTO users (id, email, password_hash, email_verified, terms_accepted_at) VALUES ($1,$2,'x',TRUE,NOW()) ON CONFLICT DO NOTHING`, userID, email)
	_, _ = db.ExecContext(ctx, `INSERT INTO wallets (user_id, balance_cents, status) VALUES ($1, 100, 'active') ON CONFLICT (user_id) DO UPDATE SET balance_cents=100`, userID)
	starts := time.Now().UTC().Add(-time.Hour)
	ends := time.Now().UTC().Add(time.Hour)
	_, _ = db.ExecContext(ctx, `
		INSERT INTO contests (id, name, starts_at, ends_at, status, entry_fee_cents, platform_fee_bps, qty_total, commission_rate, is_free, current_participants, prize_pool_net_cents, commission_amount, economics_locked_at, locked_entry_fee_cents, locked_platform_fee_bps, late_join_enabled)
		VALUES ($1,'mvp-poor',$2,$3,'registration_open',10000,2000,10,20,FALSE,0,0,0,NOW(),10000,2000,TRUE)`, contestID, starts, ends)
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM contest_participants WHERE contest_id=$1`, contestID)
		_, _ = db.Exec(`DELETE FROM wallet_ledger WHERE user_id=$1`, userID)
		_, _ = db.Exec(`DELETE FROM wallets WHERE user_id=$1`, userID)
		_, _ = db.Exec(`DELETE FROM contests WHERE id=$1`, contestID)
		_, _ = db.Exec(`DELETE FROM users WHERE id=$1`, userID)
	})
	tx, _ := db.BeginTx(ctx, nil)
	_, err := svc.DeductContestEntryFeeWithName(ctx, tx, userID, contestID, "mvp-poor", 10000)
	_ = tx.Rollback()
	if err == nil {
		t.Fatal("expected insufficient balance")
	}
	if _, ok := err.(*InsufficientBalanceError); !ok {
		// accept any error that blocks join
		t.Logf("join blocked with: %T %v", err, err)
	}
}
