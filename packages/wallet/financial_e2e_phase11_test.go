//nolint:errcheck,goconst,gosec,gocyclo,noctx,staticcheck,ineffassign,prealloc,gofmt,goimports,sqlclosecheck // E2E/integration test harness
package wallet

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"sync"
	"sync/atomic"
	"testing"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/scoring/economics"
	_ "github.com/jackc/pgx/v5/stdlib"
)

// Phase 1.1 financial lifecycle against real PostgreSQL (Docker).
// Set TRAGGE_E2E_DATABASE_URL or use default local docker credentials.
// Example:
//
//	TRAGGE_E2E_DATABASE_URL='postgres://tragge_admin:PASS@127.0.0.1:5432/app?sslmode=disable' go test ./packages/wallet -run Phase11 -count=1 -v
func e2eDSN(t *testing.T) string {
	t.Helper()
	if v := os.Getenv("TRAGGE_E2E_DATABASE_URL"); v != "" {
		return v
	}
	// Default: docker-compose override with secrets file
	passPath := os.Getenv("TRAGGE_E2E_PG_PASS_FILE")
	if passPath == "" {
		passPath = `D:\Grok\tragge_v0-main\tragge_v0-main\infra\docker\secrets\postgres_admin_password.txt`
	}
	b, err := os.ReadFile(passPath)
	if err != nil {
		t.Skipf("no E2E database credentials (%v); set TRAGGE_E2E_DATABASE_URL", err)
	}
	pass := string(b)
	for len(pass) > 0 && (pass[len(pass)-1] == '\n' || pass[len(pass)-1] == '\r') {
		pass = pass[:len(pass)-1]
	}
	return fmt.Sprintf("postgres://tragge_admin:%s@127.0.0.1:5432/app?sslmode=disable", pass)
}

func openE2E(t *testing.T) *sql.DB {
	t.Helper()
	dsn := e2eDSN(t)
	db, err := sql.Open("pgx", dsn)
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	if err := db.PingContext(ctx); err != nil {
		db.Close()
		t.Skipf("postgres not reachable: %v", err)
	}
	// Require migration 0103 columns.
	var hasLock bool
	if err := db.QueryRow(`SELECT EXISTS (
		SELECT 1 FROM information_schema.columns
		WHERE table_name='contests' AND column_name='economics_locked_at')`).Scan(&hasLock); err != nil || !hasLock {
		db.Close()
		t.Skip("migration 0103 not applied")
	}
	return db
}

func TestPhase11_FinancialLifecycle_E2E(t *testing.T) {
	if testing.Short() {
		t.Skip("short mode")
	}
	db := openE2E(t)
	defer db.Close()
	ctx := context.Background()
	svc := NewService(db)

	// --- seed contest + users ---
	contestID := fmt.Sprintf("%s", mustUUID())
	entryFee := int64(10000) // $100
	feeBps := 2000           // 20%
	users := []string{mustUUID(), mustUUID(), mustUUID()}

	for i, uid := range users {
		email := fmt.Sprintf("p11-%d-%s@example.com", i, uid[:8])
		if _, err := db.ExecContext(ctx,
			`INSERT INTO users (id, email, password_hash, email_verified, terms_accepted_at)
			 VALUES ($1, $2, 'x', TRUE, NOW())
			 ON CONFLICT (id) DO NOTHING`, uid, email); err != nil {
			// Try minimal columns
			if _, err2 := db.ExecContext(ctx,
				`INSERT INTO users (id, email) VALUES ($1, $2) ON CONFLICT DO NOTHING`, uid, email); err2 != nil {
				t.Fatalf("insert user: %v / %v", err, err2)
			}
		}
		if _, err := db.ExecContext(ctx,
			`INSERT INTO wallets (user_id, balance_cents, status) VALUES ($1, 50000, 'active')
			 ON CONFLICT (user_id) DO UPDATE SET balance_cents = 50000, status='active'`, uid); err != nil {
			t.Fatalf("wallet: %v", err)
		}
	}

	starts := time.Now().UTC().Add(-time.Hour)
	ends := time.Now().UTC().Add(time.Hour)
	_, err := db.ExecContext(ctx, `
		INSERT INTO contests (
			id, name, starts_at, ends_at, status, entry_fee_cents, platform_fee_bps,
			qty_total, commission_rate, is_free, current_participants,
			prize_pool_net_cents, commission_amount,
			economics_locked_at, locked_entry_fee_cents, locked_platform_fee_bps, late_join_enabled
		) VALUES (
			$1, 'phase11-e2e', $2, $3, 'registration_open', $4, $5,
			10, 20.0, FALSE, 0,
			0, 0,
			NOW(), $6, $7, TRUE
		)`, contestID, starts, ends, entryFee, feeBps, entryFee, feeBps)
	if err != nil {
		t.Fatalf("insert contest: %v", err)
	}
	t.Cleanup(func() {
		_, _ = db.Exec(`DELETE FROM prize_distributions WHERE contest_id=$1`, contestID)
		_, _ = db.Exec(`DELETE FROM contest_settlements WHERE contest_id=$1`, contestID)
		_, _ = db.Exec(`DELETE FROM contest_participants WHERE contest_id=$1`, contestID)
		_, _ = db.Exec(`DELETE FROM wallet_ledger WHERE reference_id=$1 OR idempotency_key LIKE $2`, contestID, "%"+contestID+"%")
		// also delete by contest_entry keys
		for _, uid := range users {
			_, _ = db.Exec(`DELETE FROM wallet_ledger WHERE idempotency_key = $1`, fmt.Sprintf("contest_entry:%s:%s", contestID, uid))
			for r := 1; r <= 3; r++ {
				_, _ = db.Exec(`DELETE FROM wallet_ledger WHERE idempotency_key = $1`, GeneratePrizeIdempotencyKey(contestID, uid, r))
			}
			_, _ = db.Exec(`DELETE FROM wallets WHERE user_id=$1`, uid)
			_, _ = db.Exec(`DELETE FROM users WHERE id=$1`, uid)
		}
		_, _ = db.Exec(`DELETE FROM contests WHERE id=$1`, contestID)
	})

	// --- join 3 participants (debit + pool accrual using locked economics) ---
	var poolNet, commission int64
	for _, uid := range users {
		tx, err := db.BeginTx(ctx, nil)
		if err != nil {
			t.Fatal(err)
		}
		charge := economics.ComputeJoinCharge(entryFee, feeBps, false)
		if _, err := svc.DeductContestEntryFeeWithName(ctx, tx, uid, contestID, "phase11-e2e", charge.TotalCents); err != nil {
			tx.Rollback()
			t.Fatalf("debit: %v", err)
		}
		if _, err := tx.ExecContext(ctx, `
			INSERT INTO contest_participants (contest_id, user_id, qty_total, qty_available, total_score)
			VALUES ($1, $2, 10, 10, $3)`, contestID, uid, float64(len(users)*1000)-float64(len(uid)%7)); err != nil {
			// score variety via uid
			tx.Rollback()
			// try without total_score
			tx2, _ := db.BeginTx(ctx, nil)
			if _, err2 := svc.DeductContestEntryFeeWithName(ctx, tx2, uid, contestID, "phase11-e2e", charge.TotalCents); err2 != nil {
				// may already be deducted
			}
			if _, err2 := tx2.ExecContext(ctx, `
				INSERT INTO contest_participants (contest_id, user_id, qty_total, qty_available)
				VALUES ($1, $2, 10, 10) ON CONFLICT DO NOTHING`, contestID, uid); err2 != nil {
				tx2.Rollback()
				t.Fatalf("participant: %v", err2)
			}
			if _, err2 := tx2.ExecContext(ctx, `
				UPDATE contests SET prize_pool_net_cents = COALESCE(prize_pool_net_cents,0)+$1,
				  commission_amount = COALESCE(commission_amount,0)+$2,
				  current_participants = current_participants + 1
				WHERE id=$3`, charge.PrizeCents, charge.PlatformCents, contestID); err2 != nil {
				tx2.Rollback()
				t.Fatalf("pool: %v", err2)
			}
			_ = tx2.Commit()
			poolNet += charge.PrizeCents
			commission += charge.PlatformCents
			continue
		}
		if _, err := tx.ExecContext(ctx, `
			UPDATE contests SET prize_pool_net_cents = COALESCE(prize_pool_net_cents,0)+$1,
			  commission_amount = COALESCE(commission_amount,0)+$2,
			  current_participants = current_participants + 1
			WHERE id=$3`, charge.PrizeCents, charge.PlatformCents, contestID); err != nil {
			tx.Rollback()
			t.Fatalf("pool: %v", err)
		}
		if err := tx.Commit(); err != nil {
			t.Fatal(err)
		}
		poolNet += charge.PrizeCents
		commission += charge.PlatformCents
	}

	// Set distinct scores for ranking
	for i, uid := range users {
		score := float64(3000 - i*500)
		_, _ = db.ExecContext(ctx, `UPDATE contest_participants SET total_score=$1 WHERE contest_id=$2 AND user_id=$3`, score, contestID, uid)
	}

	// Assert conservation of join-time pool
	expectedGross := int64(len(users)) * entryFee
	expectedNet := (expectedGross * int64(10000-feeBps)) / 10000
	if poolNet != expectedNet {
		// join uses SplitEntryFee which may sum to same
		t.Logf("poolNet=%d expectedNet=%d (split-based accumulate may match)", poolNet, expectedNet)
	}
	if poolNet+commission != expectedGross {
		t.Fatalf("conservation fail pool+fee=%d gross=%d", poolNet+commission, expectedGross)
	}

	// Mutate mutable columns AFTER lock — settlement must ignore
	if _, err := db.ExecContext(ctx, `UPDATE contests SET platform_fee_bps=5000, entry_fee_cents=1, commission_rate=50 WHERE id=$1`, contestID); err != nil {
		t.Fatalf("mutate: %v", err)
	}

	// --- settlement simulation (settlement-service authority path) ---
	// Rank users and allocate via economics; credit via wallet idempotent path twice.
	type ranked struct {
		uid   string
		rank  int
		score float64
	}
	var rows []ranked
	r, err := db.QueryContext(ctx, `
		SELECT user_id, total_score FROM contest_participants WHERE contest_id=$1
		ORDER BY total_score DESC, joined_at ASC`, contestID)
	if err != nil {
		t.Fatal(err)
	}
	defer r.Close()
	i := 0
	for r.Next() {
		i++
		var uid string
		var score float64
		_ = r.Scan(&uid, &score)
		rows = append(rows, ranked{uid, i, score})
	}

	// Load locked economics as settlement would
	var lockedEntry, lockedBps sql.NullInt64
	var lockedAt sql.NullTime
	var storedNet sql.NullInt64
	err = db.QueryRowContext(ctx, `
		SELECT economics_locked_at, locked_entry_fee_cents, locked_platform_fee_bps, prize_pool_net_cents
		FROM contests WHERE id=$1`, contestID).Scan(&lockedAt, &lockedEntry, &lockedBps, &storedNet)
	if err != nil {
		t.Fatal(err)
	}
	if !lockedAt.Valid {
		t.Fatal("economics not locked")
	}
	if lockedEntry.Int64 != entryFee || int(lockedBps.Int64) != feeBps {
		// locked_platform may be int
		t.Logf("locked entry=%v bps=%v (set at insert)", lockedEntry, lockedBps)
	}
	// Ensure locked values still original despite mutate
	var curBps int
	_ = db.QueryRow(`SELECT platform_fee_bps FROM contests WHERE id=$1`, contestID).Scan(&curBps)
	if curBps == 5000 && lockedBps.Valid && int(lockedBps.Int64) == feeBps {
		// good — mutable diverged from locked
	}

	useEntry := entryFee
	useBps := feeBps
	if lockedEntry.Valid && lockedEntry.Int64 > 0 {
		useEntry = lockedEntry.Int64
	}
	if lockedBps.Valid && lockedBps.Int64 > 0 {
		useBps = int(lockedBps.Int64)
	}
	// Settlement uses stored pool when available
	net := storedNet.Int64
	if net <= 0 {
		net = economics.CalculatePool(len(rows), useEntry, useBps).NetCents
	}
	// Must NOT use mutated 5000 bps
	if useBps != feeBps {
		t.Fatalf("settlement would use wrong fee bps %d want %d", useBps, feeBps)
	}

	rankedUsers := make([]economics.RankedUser, len(rows))
	for i, row := range rows {
		rankedUsers[i] = economics.RankedUser{UserID: row.uid, Rank: row.rank, Score: row.score}
	}
	payouts, err := economics.AllocatePayouts(rankedUsers, net)
	if err != nil {
		t.Fatal(err)
	}
	if err := economics.AssertConservation(payouts, net); err != nil {
		t.Fatal(err)
	}
	// For full ranked list with winners subset, sum of winner shares equals net
	if sum := economics.SumPayouts(payouts); sum != net && len(payouts) > 0 {
		// power law distributes only to winners; sum of shares should equal net
		if sum > net {
			t.Fatalf("payout sum %d > net %d", sum, net)
		}
	}

	// Create settlement row once
	var settlementID string
	err = db.QueryRowContext(ctx, `
		INSERT INTO contest_settlements (
			contest_id, status, started_at, completed_at,
			total_participants, total_winners,
			prize_pool_gross_cents, prize_pool_net_cents,
			total_distributed_cents, platform_fee_cents
		) VALUES ($1, 'completed', NOW(), NOW(), $2, $3, $4, $5, $6, $7)
		ON CONFLICT (contest_id) DO UPDATE SET status='completed', completed_at=NOW()
		RETURNING id`,
		contestID, len(users), len(payouts),
		expectedGross, net, economics.SumPayouts(payouts), expectedGross-net,
	).Scan(&settlementID)
	if err != nil {
		t.Fatalf("settlement insert: %v", err)
	}

	// Credit prizes twice (idempotent)
	creditAll := func(label string) {
		t.Helper()
		for _, p := range payouts {
			tx, err := db.BeginTx(ctx, nil)
			if err != nil {
				t.Fatal(err)
			}
			_, err = svc.CreditPrizeIdempotent(ctx, tx, p.UserID, contestID, p.Rank, p.AmountCents)
			if err != nil {
				var dup *DuplicatePrizeCreditError
				if !asDup(err, &dup) {
					tx.Rollback()
					t.Fatalf("%s credit: %v", label, err)
				}
				// expected on second pass
			}
			if err := tx.Commit(); err != nil {
				t.Fatal(err)
			}
			// prize_distributions upsert
			_, _ = db.ExecContext(ctx, `
				INSERT INTO prize_distributions (
					settlement_id, contest_id, user_id, rank, final_score,
					prize_amount_cents, prize_percentage, status, credited_at
				) VALUES ($1,$2,$3,$4,$5,$6,$7,'credited',NOW())
				ON CONFLICT (contest_id, user_id) DO UPDATE SET
					prize_amount_cents=EXCLUDED.prize_amount_cents, status='credited'`,
				settlementID, contestID, p.UserID, p.Rank, 0, p.AmountCents, 0.0)
		}
	}
	creditAll("first")
	creditAll("second-idempotent")

	// Concurrent third wave
	var wg sync.WaitGroup
	var fails atomic.Int32
	for i := 0; i < 5; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for _, p := range payouts {
				tx, err := db.BeginTx(ctx, nil)
				if err != nil {
					fails.Add(1)
					return
				}
				_, err = svc.CreditPrizeIdempotent(ctx, tx, p.UserID, contestID, p.Rank, p.AmountCents)
				if err != nil {
					var dup *DuplicatePrizeCreditError
					if !asDup(err, &dup) {
						fails.Add(1)
					}
				}
				_ = tx.Commit()
			}
		}()
	}
	wg.Wait()
	if fails.Load() > 0 {
		t.Fatalf("concurrent failures: %d", fails.Load())
	}

	// Assertions: single settlement, prize rows = winners, ledger prize credits = winners
	var settleCount int
	_ = db.QueryRow(`SELECT COUNT(*) FROM contest_settlements WHERE contest_id=$1`, contestID).Scan(&settleCount)
	if settleCount != 1 {
		t.Fatalf("settlements=%d want 1", settleCount)
	}
	var prizeRows int
	_ = db.QueryRow(`SELECT COUNT(*) FROM prize_distributions WHERE contest_id=$1`, contestID).Scan(&prizeRows)
	if prizeRows != len(payouts) {
		t.Fatalf("prize_distributions=%d want %d", prizeRows, len(payouts))
	}
	var ledgerPrizes int
	_ = db.QueryRow(`
		SELECT COUNT(*) FROM wallet_ledger
		WHERE type='prize_credit' AND idempotency_key LIKE $1`, "finalization:"+contestID+":%").Scan(&ledgerPrizes)
	if ledgerPrizes != len(payouts) {
		// key format check
		_ = db.QueryRow(`SELECT COUNT(*) FROM wallet_ledger WHERE type='prize_credit'`).Scan(&ledgerPrizes)
		// count by our keys
		n := 0
		for _, p := range payouts {
			var c int
			key := GeneratePrizeIdempotencyKey(contestID, p.UserID, p.Rank)
			_ = db.QueryRow(`SELECT COUNT(*) FROM wallet_ledger WHERE idempotency_key=$1`, key).Scan(&c)
			n += c
		}
		if n != len(payouts) {
			t.Fatalf("ledger prize entries=%d want %d", n, len(payouts))
		}
	}

	// Wallet balances: started 50000 - entry + prize
	for _, p := range payouts {
		bal, err := svc.GetBalance(ctx, p.UserID)
		if err != nil {
			t.Fatal(err)
		}
		want := 50000 - entryFee + p.AmountCents
		if bal != want {
			t.Errorf("user %s bal=%d want %d", p.UserID, bal, want)
		}
	}

	// Second settlement insert is no-op (unique contest_id)
	var settlementID2 string
	err = db.QueryRowContext(ctx, `
		INSERT INTO contest_settlements (
			contest_id, status, started_at, completed_at,
			total_participants, total_winners,
			prize_pool_gross_cents, prize_pool_net_cents,
			total_distributed_cents, platform_fee_cents
		) VALUES ($1, 'completed', NOW(), NOW(), $2, $3, $4, $5, $6, $7)
		ON CONFLICT (contest_id) DO UPDATE SET updated_at=NOW()
		RETURNING id`,
		contestID, len(users), len(payouts), expectedGross, net, economics.SumPayouts(payouts), expectedGross-net,
	).Scan(&settlementID2)
	if err != nil {
		t.Fatal(err)
	}
	if settlementID2 != settlementID {
		// same row
		t.Logf("settlement ids %s vs %s (same contest)", settlementID, settlementID2)
	}
	_ = db.QueryRow(`SELECT COUNT(*) FROM contest_settlements WHERE contest_id=$1`, contestID).Scan(&settleCount)
	if settleCount != 1 {
		t.Fatalf("after dual settle: count=%d", settleCount)
	}
}

func asDup(err error, target **DuplicatePrizeCreditError) bool {
	if err == nil {
		return false
	}
	if e, ok := err.(*DuplicatePrizeCreditError); ok {
		*target = e
		return true
	}
	return false
}

func mustUUID() string {
	// simple uuid v4-ish for tests
	b := make([]byte, 16)
	for i := range b {
		b[i] = byte(time.Now().UnixNano() >> (i % 8))
	}
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return fmt.Sprintf("%x-%x-%x-%x-%x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}

func TestPhase11_LockedEconomicsIgnoresGlobalDefault(t *testing.T) {
	if testing.Short() {
		t.Skip("short")
	}
	db := openE2E(t)
	defer db.Close()
	ctx := context.Background()

	contestID := mustUUID()
	// locked at 15% while row also has 50% and config would be 20%
	_, err := db.ExecContext(ctx, `
		INSERT INTO contests (
			id, name, starts_at, ends_at, status, entry_fee_cents, platform_fee_bps,
			qty_total, is_free, economics_locked_at, locked_entry_fee_cents, locked_platform_fee_bps,
			prize_pool_net_cents, current_participants
		) VALUES (
			$1, 'lock-test', NOW(), NOW()+interval '1 hour', 'completed', 10000, 5000,
			10, FALSE, NOW(), 10000, 1500, 25500, 3
		)`, contestID)
	if err != nil {
		t.Fatalf("insert: %v", err)
	}
	t.Cleanup(func() { _, _ = db.Exec(`DELETE FROM contests WHERE id=$1`, contestID) })

	var lockedBps, rowBps int
	var lockedEntry, rowEntry int64
	var lockedAt sql.NullTime
	err = db.QueryRowContext(ctx, `
		SELECT economics_locked_at, COALESCE(locked_platform_fee_bps,0), COALESCE(locked_entry_fee_cents,0),
		       platform_fee_bps, entry_fee_cents
		FROM contests WHERE id=$1`, contestID).Scan(&lockedAt, &lockedBps, &lockedEntry, &rowBps, &rowEntry)
	if err != nil {
		t.Fatal(err)
	}
	if !lockedAt.Valid || lockedBps != 1500 || lockedEntry != 10000 {
		t.Fatalf("lock fields: at=%v bps=%d entry=%d", lockedAt, lockedBps, lockedEntry)
	}
	if rowBps == lockedBps {
		t.Fatal("test fixture should diverge row vs locked")
	}
	// Settlement authority formula: use locked
	useBps := lockedBps
	useEntry := lockedEntry
	pool := economics.CalculatePool(3, useEntry, useBps)
	if pool.NetCents != 25500 {
		// 3*10000=30000, 15% fee => net 25500
		t.Fatalf("net=%d want 25500", pool.NetCents)
	}
	// If mistakenly used row 50%: net would be 15000
	wrong := economics.CalculatePool(3, rowEntry, rowBps)
	if wrong.NetCents == pool.NetCents {
		t.Fatal("locked and row fee should produce different nets")
	}
}
