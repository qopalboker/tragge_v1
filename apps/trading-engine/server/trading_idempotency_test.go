package server

import (
	"context"
	"path/filepath"
	"sync"
	"testing"
	"time"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
	"github.com/google/uuid"
)

// Concurrent ProcessOrder with the SAME order_id (client_order_id identity)
// must yield exactly one fill and one position delta.
func TestTradingCert_ConcurrentSameOrderID(t *testing.T) {
	if testing.Short() {
		t.Skip("short")
	}
	db := openPhase2E2E(t)
	defer db.Close()
	ctx := context.Background()
	dir := t.TempDir()
	contestID, users, symbol := seedContestUsers(t, db, 1)
	if _, err := db.ExecContext(ctx, `UPDATE contests SET qty_total=20 WHERE id=$1`, contestID); err != nil {
		t.Fatal(err)
	}
	if _, err := db.ExecContext(ctx,
		`UPDATE contest_participants SET qty_total=20, qty_available=20 WHERE contest_id=$1 AND user_id=$2`,
		contestID, users[0]); err != nil {
		t.Fatal(err)
	}
	eng := newTestEngine(t, db, filepath.Join(dir, "idem.wal"))
	eng.config.QtyMinPerTrade = 1
	eng.config.QtyMaxPctOfTotal = 100
	defer eng.GetWAL().Close()
	feedFreshTick(eng, symbol, 1000)

	// Same logical order identity (as BFF maps client_order_id → order_id)
	orderID := uuid.New().String()
	req := &contracts.OrderRequest{
		OrderID: orderID, UserID: users[0], ContestID: contestID, Symbol: symbol,
		Side: contracts.OrderSideBuy, Type: contracts.OrderTypeMarket, Qty: 5,
		ClientTs: time.Now().UnixMilli(),
	}

	var wg sync.WaitGroup
	const n = 8
	errs := make([]error, n)
	for i := 0; i < n; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			// Clone request (same OrderID)
			r := *req
			errs[i] = eng.ProcessOrder(ctx, &r)
		}(i)
	}
	wg.Wait()

	var fills, orders int
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM fills WHERE order_id=$1`, orderID).Scan(&fills)
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM orders WHERE order_id=$1`, orderID).Scan(&orders)
	if fills != 1 {
		t.Fatalf("want exactly 1 fill for concurrent same order_id, got %d", fills)
	}
	if orders != 1 {
		t.Fatalf("want exactly 1 order row, got %d", orders)
	}
	var posQty int64
	_ = db.QueryRowContext(ctx, `
		SELECT COALESCE(SUM(qty_open),0) FROM positions
		WHERE contest_id=$1 AND user_id=$2 AND closed_at IS NULL
	`, contestID, users[0]).Scan(&posQty)
	if posQty != 5 {
		t.Fatalf("position qty=%d want 5", posQty)
	}
}

// Distinct client identities must still create distinct orders.
func TestTradingCert_DistinctOrderIDsStillWork(t *testing.T) {
	if testing.Short() {
		t.Skip("short")
	}
	db := openPhase2E2E(t)
	defer db.Close()
	ctx := context.Background()
	dir := t.TempDir()
	contestID, users, symbol := seedContestUsers(t, db, 1)
	if _, err := db.ExecContext(ctx, `UPDATE contests SET qty_total=20 WHERE id=$1`, contestID); err != nil {
		t.Fatal(err)
	}
	if _, err := db.ExecContext(ctx,
		`UPDATE contest_participants SET qty_total=20, qty_available=20 WHERE contest_id=$1 AND user_id=$2`,
		contestID, users[0]); err != nil {
		t.Fatal(err)
	}
	eng := newTestEngine(t, db, filepath.Join(dir, "distinct.wal"))
	eng.config.QtyMinPerTrade = 1
	eng.config.QtyMaxPctOfTotal = 100
	defer eng.GetWAL().Close()
	feedFreshTick(eng, symbol, 2000)

	id1, id2 := uuid.New().String(), uuid.New().String()
	for _, id := range []string{id1, id2} {
		if err := eng.ProcessOrder(ctx, &contracts.OrderRequest{
			OrderID: id, UserID: users[0], ContestID: contestID, Symbol: symbol,
			Side: contracts.OrderSideBuy, Type: contracts.OrderTypeMarket, Qty: 3,
		}); err != nil {
			t.Fatalf("order %s: %v", id, err)
		}
	}
	var fills int
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM fills WHERE contest_id=$1 AND user_id=$2`, contestID, users[0]).Scan(&fills)
	if fills != 2 {
		t.Fatalf("want 2 fills for distinct orders, got %d", fills)
	}
}
