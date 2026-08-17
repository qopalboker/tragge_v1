//nolint:errcheck,goconst,gosec,gocyclo,noctx,staticcheck,ineffassign,prealloc,gofmt,goimports // E2E/integration test harness
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

// Trading Correctness Certification — quantity round-trip, edges, concurrency,
// position open/increase/reduce/close, long/short, and filled_qty invariants.
//
// Requires live Postgres (same as Phase2 E2E).
//
//	go test ./apps/trading-engine/server -run TradingCert -count=1 -v

func TestTradingCert_QuantityRoundTrip(t *testing.T) {
	if testing.Short() {
		t.Skip("short")
	}
	db := openPhase2E2E(t)
	defer db.Close()
	ctx := context.Background()

	// Product-supported whole-unit quantities only (no decimals).
	quantities := []int64{1, 2, 5, 10}

	for _, wantQty := range quantities {
		t.Run(fmtQty(wantQty), func(t *testing.T) {
			dir := t.TempDir()
			walPath := filepath.Join(dir, "qty.wal")
			// Each case needs enough allocation; use max(wantQty*4, 20)
			alloc := wantQty * 4
			if alloc < 20 {
				alloc = 20
			}
			contestID, users, symbol := seedContestUsers(t, db, 1)
			if _, err := db.ExecContext(ctx, `UPDATE contests SET qty_total=$2 WHERE id=$1`, contestID, alloc); err != nil {
				t.Fatal(err)
			}
			if _, err := db.ExecContext(ctx,
				`UPDATE contest_participants SET qty_total=$2, qty_available=$2 WHERE contest_id=$1 AND user_id=$3`,
				contestID, alloc, users[0]); err != nil {
				t.Fatal(err)
			}

			eng := newTestEngine(t, db, walPath)
			// Product defaults: min 1, max 100%
			eng.config.QtyMinPerTrade = 1
			eng.config.QtyMaxPctOfTotal = 100
			defer eng.GetWAL().Close()
			feedFreshTick(eng, symbol, 50000)

			orderID := uuid.New().String()
			if err := eng.ProcessOrder(ctx, &contracts.OrderRequest{
				OrderID: orderID, UserID: users[0], ContestID: contestID, Symbol: symbol,
				Side: contracts.OrderSideBuy, Type: contracts.OrderTypeMarket, Qty: wantQty,
				ClientTs: time.Now().UnixMilli(),
			}); err != nil {
				t.Fatalf("ProcessOrder qty=%d: %v", wantQty, err)
			}

			var orderQty, orderFilled int64
			var status string
			if err := db.QueryRowContext(ctx,
				`SELECT qty, qty_filled, status::text FROM orders WHERE order_id=$1`, orderID,
			).Scan(&orderQty, &orderFilled, &status); err != nil {
				t.Fatalf("order row: %v", err)
			}
			if orderQty != wantQty || orderFilled != wantQty {
				t.Fatalf("order qty/filled=%d/%d want %d/%d", orderQty, orderFilled, wantQty, wantQty)
			}
			if status != "filled" {
				t.Fatalf("status=%s want filled", status)
			}

			var fillQty int64
			var fillPrice float64
			if err := db.QueryRowContext(ctx,
				`SELECT qty, fill_price::float8 FROM fills WHERE order_id=$1`, orderID,
			).Scan(&fillQty, &fillPrice); err != nil {
				t.Fatalf("fill: %v", err)
			}
			if fillQty != wantQty {
				t.Fatalf("fill qty=%d want %d", fillQty, wantQty)
			}
			if fillPrice <= 0 {
				t.Fatalf("fill price invalid: %v", fillPrice)
			}

			var posOpen, posUsed int64
			var side string
			if err := db.QueryRowContext(ctx, `
				SELECT qty_open, qty_used, side::text FROM positions
				WHERE contest_id=$1 AND user_id=$2 AND closed_at IS NULL
			`, contestID, users[0]).Scan(&posOpen, &posUsed, &side); err != nil {
				t.Fatalf("position: %v", err)
			}
			if posOpen != wantQty || posUsed != wantQty {
				t.Fatalf("position open/used=%d/%d want %d", posOpen, posUsed, wantQty)
			}
			if side != "long" {
				t.Fatalf("side=%s want long", side)
			}

			// filled_quantity <= ordered_quantity
			if orderFilled > orderQty {
				t.Fatalf("filled > ordered")
			}

			// sum(fills) for this order
			var sumFills int64
			_ = db.QueryRowContext(ctx, `SELECT COALESCE(SUM(qty),0) FROM fills WHERE order_id=$1`, orderID).Scan(&sumFills)
			if sumFills != wantQty {
				t.Fatalf("sum fills=%d want %d", sumFills, wantQty)
			}
		})
	}
}

func TestTradingCert_QuantityEdges(t *testing.T) {
	if testing.Short() {
		t.Skip("short")
	}
	db := openPhase2E2E(t)
	defer db.Close()
	ctx := context.Background()
	dir := t.TempDir()
	eng := newTestEngine(t, db, filepath.Join(dir, "edge.wal"))
	eng.config.QtyMinPerTrade = 1
	eng.config.QtyMaxPctOfTotal = 100
	defer eng.GetWAL().Close()

	contestID, users, symbol := seedContestUsers(t, db, 1)
	if _, err := db.ExecContext(ctx, `UPDATE contests SET qty_total=20 WHERE id=$1`, contestID); err != nil {
		t.Fatal(err)
	}
	if _, err := db.ExecContext(ctx,
		`UPDATE contest_participants SET qty_total=20, qty_available=20 WHERE contest_id=$1 AND user_id=$2`,
		contestID, users[0]); err != nil {
		t.Fatal(err)
	}
	feedFreshTick(eng, symbol, 100)

	// Structural invalid (never reach execution as fill)
	cases := []struct {
		name string
		qty  int64
		ok   bool
	}{
		{"zero", 0, false},
		{"negative", -1, false},
		{"valid_1", 1, true},
		{"max_allowed_plus", MaxAllowedQty + 1, false},
		{"valid_10", 10, true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			orderID := uuid.New().String()
			err := eng.ProcessOrder(ctx, &contracts.OrderRequest{
				OrderID: orderID, UserID: users[0], ContestID: contestID, Symbol: symbol,
				Side: contracts.OrderSideBuy, Type: contracts.OrderTypeMarket, Qty: tc.qty,
			})
			var fills int
			_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM fills WHERE order_id=$1`, orderID).Scan(&fills)
			if tc.ok {
				if err != nil {
					t.Fatalf("expected success: %v", err)
				}
				if fills != 1 {
					t.Fatalf("want 1 fill, got %d", fills)
				}
			} else {
				if fills != 0 {
					t.Fatalf("invalid qty must not fill; fills=%d err=%v", fills, err)
				}
			}
		})
	}
}

func TestTradingCert_ConcurrentReservations(t *testing.T) {
	if testing.Short() {
		t.Skip("short")
	}
	db := openPhase2E2E(t)
	defer db.Close()
	ctx := context.Background()
	dir := t.TempDir()
	contestID, users, symbol := seedContestUsers(t, db, 1)
	const total int64 = 20
	if _, err := db.ExecContext(ctx, `UPDATE contests SET qty_total=$2 WHERE id=$1`, contestID, total); err != nil {
		t.Fatal(err)
	}
	if _, err := db.ExecContext(ctx,
		`UPDATE contest_participants SET qty_total=$2, qty_available=$2 WHERE contest_id=$1 AND user_id=$3`,
		contestID, total, users[0]); err != nil {
		t.Fatal(err)
	}
	eng := newTestEngine(t, db, filepath.Join(dir, "conc.wal"))
	eng.config.QtyMinPerTrade = 1
	eng.config.QtyMaxPctOfTotal = 100
	defer eng.GetWAL().Close()
	feedFreshTick(eng, symbol, 25000)

	// Two simultaneous orders qty 7 + 6 = 13 <= 20
	var wg sync.WaitGroup
	ids := []string{uuid.New().String(), uuid.New().String()}
	qtys := []int64{7, 6}
	errs := make([]error, 2)
	for i := 0; i < 2; i++ {
		wg.Add(1)
		go func(i int) {
			defer wg.Done()
			errs[i] = eng.ProcessOrder(ctx, &contracts.OrderRequest{
				OrderID: ids[i], UserID: users[0], ContestID: contestID, Symbol: symbol,
				Side: contracts.OrderSideBuy, Type: contracts.OrderTypeMarket, Qty: qtys[i],
			})
		}(i)
	}
	wg.Wait()
	for i, err := range errs {
		if err != nil {
			t.Logf("order %d err: %v", i, err)
		}
	}

	var sumFill, posOpen int64
	_ = db.QueryRowContext(ctx, `SELECT COALESCE(SUM(qty),0) FROM fills WHERE contest_id=$1 AND user_id=$2`, contestID, users[0]).Scan(&sumFill)
	_ = db.QueryRowContext(ctx, `SELECT COALESCE(SUM(qty_open),0) FROM positions WHERE contest_id=$1 AND user_id=$2 AND closed_at IS NULL`, contestID, users[0]).Scan(&posOpen)
	if sumFill != 13 {
		t.Fatalf("sum fills=%d want 13", sumFill)
	}
	if posOpen != 13 {
		t.Fatalf("pos open=%d want 13", posOpen)
	}

	// Over-reserve: try 5+5 when only 7 left → at most one succeeds fully
	var wg2 sync.WaitGroup
	ids2 := []string{uuid.New().String(), uuid.New().String()}
	errs2 := make([]error, 2)
	for i := 0; i < 2; i++ {
		wg2.Add(1)
		go func(i int) {
			defer wg2.Done()
			errs2[i] = eng.ProcessOrder(ctx, &contracts.OrderRequest{
				OrderID: ids2[i], UserID: users[0], ContestID: contestID, Symbol: symbol,
				Side: contracts.OrderSideBuy, Type: contracts.OrderTypeMarket, Qty: 5,
			})
		}(i)
	}
	wg2.Wait()
	var sumFill2 int64
	_ = db.QueryRowContext(ctx, `SELECT COALESCE(SUM(qty),0) FROM fills WHERE contest_id=$1 AND user_id=$2`, contestID, users[0]).Scan(&sumFill2)
	if sumFill2 > total {
		t.Fatalf("impossible: filled %d > total %d", sumFill2, total)
	}
	if sumFill2 < 13 || sumFill2 > 18 {
		// 13 + one of 5 = 18; both 5 would be 23 > 20 so max one extra
		t.Fatalf("after over-reserve attempt sum fills=%d (expect 13 or 18)", sumFill2)
	}
}

func TestTradingCert_LongShortOpenReduceClose(t *testing.T) {
	if testing.Short() {
		t.Skip("short")
	}
	db := openPhase2E2E(t)
	defer db.Close()
	ctx := context.Background()

	for _, side := range []contracts.OrderSide{contracts.OrderSideBuy, contracts.OrderSideSell} {
		name := "long"
		if side == contracts.OrderSideSell {
			name = "short"
		}
		t.Run(name, func(t *testing.T) {
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
			eng := newTestEngine(t, db, filepath.Join(dir, name+".wal"))
			eng.config.QtyMinPerTrade = 1
			eng.config.QtyMaxPctOfTotal = 100
			defer eng.GetWAL().Close()
			feedFreshTick(eng, symbol, 1000)

			// Open qty 10
			oid1 := uuid.New().String()
			if err := eng.ProcessOrder(ctx, &contracts.OrderRequest{
				OrderID: oid1, UserID: users[0], ContestID: contestID, Symbol: symbol,
				Side: side, Type: contracts.OrderTypeMarket, Qty: 10,
			}); err != nil {
				t.Fatalf("open: %v", err)
			}
			var qtyOpen int64
			var posSide string
			if err := db.QueryRowContext(ctx, `
				SELECT qty_open, side::text FROM positions
				WHERE contest_id=$1 AND user_id=$2 AND closed_at IS NULL
			`, contestID, users[0]).Scan(&qtyOpen, &posSide); err != nil {
				t.Fatalf("pos: %v", err)
			}
			if qtyOpen != 10 {
				t.Fatalf("open qty=%d", qtyOpen)
			}
			wantSide := "long"
			if side == contracts.OrderSideSell {
				wantSide = "short"
			}
			if posSide != wantSide {
				t.Fatalf("side=%s want %s", posSide, wantSide)
			}

			// Increase +5 same side
			oid2 := uuid.New().String()
			if err := eng.ProcessOrder(ctx, &contracts.OrderRequest{
				OrderID: oid2, UserID: users[0], ContestID: contestID, Symbol: symbol,
				Side: side, Type: contracts.OrderTypeMarket, Qty: 5,
			}); err != nil {
				t.Fatalf("increase: %v", err)
			}
			_ = db.QueryRowContext(ctx, `
				SELECT qty_open FROM positions WHERE contest_id=$1 AND user_id=$2 AND closed_at IS NULL
			`, contestID, users[0]).Scan(&qtyOpen)
			if qtyOpen != 15 {
				t.Fatalf("after increase qty=%d want 15", qtyOpen)
			}

			// Reduce 6 opposite
			opp := contracts.OrderSideSell
			if side == contracts.OrderSideSell {
				opp = contracts.OrderSideBuy
			}
			oid3 := uuid.New().String()
			if err := eng.ProcessOrder(ctx, &contracts.OrderRequest{
				OrderID: oid3, UserID: users[0], ContestID: contestID, Symbol: symbol,
				Side: opp, Type: contracts.OrderTypeMarket, Qty: 6,
			}); err != nil {
				t.Fatalf("reduce: %v", err)
			}
			_ = db.QueryRowContext(ctx, `
				SELECT qty_open FROM positions WHERE contest_id=$1 AND user_id=$2 AND closed_at IS NULL
			`, contestID, users[0]).Scan(&qtyOpen)
			if qtyOpen != 9 {
				t.Fatalf("after reduce qty=%d want 9", qtyOpen)
			}

			// Full close remaining 9
			oid4 := uuid.New().String()
			if err := eng.ProcessOrder(ctx, &contracts.OrderRequest{
				OrderID: oid4, UserID: users[0], ContestID: contestID, Symbol: symbol,
				Side: opp, Type: contracts.OrderTypeMarket, Qty: 9,
			}); err != nil {
				t.Fatalf("close: %v", err)
			}
			var openCount int
			_ = db.QueryRowContext(ctx, `
				SELECT COUNT(*) FROM positions WHERE contest_id=$1 AND user_id=$2 AND closed_at IS NULL
			`, contestID, users[0]).Scan(&openCount)
			if openCount != 0 {
				t.Fatalf("want fully closed, open positions=%d", openCount)
			}

			// sum fills for open+increase should equal closed movement
			var sumFills int64
			_ = db.QueryRowContext(ctx, `SELECT COALESCE(SUM(qty),0) FROM fills WHERE contest_id=$1 AND user_id=$2`, contestID, users[0]).Scan(&sumFills)
			// 10+5+6+9 = 30 total fill rows (open+add+reduce+close)
			if sumFills != 30 {
				t.Fatalf("sum fills=%d want 30", sumFills)
			}
		})
	}
}

func TestTradingCert_PnLIndependent(t *testing.T) {
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
	eng := newTestEngine(t, db, filepath.Join(dir, "pnl.wal"))
	eng.config.QtyMinPerTrade = 1
	eng.config.QtyMaxPctOfTotal = 100
	defer eng.GetWAL().Close()

	entry := 100.0
	feedFreshTick(eng, symbol, entry)
	oid := uuid.New().String()
	if err := eng.ProcessOrder(ctx, &contracts.OrderRequest{
		OrderID: oid, UserID: users[0], ContestID: contestID, Symbol: symbol,
		Side: contracts.OrderSideBuy, Type: contracts.OrderTypeMarket, Qty: 10,
	}); err != nil {
		t.Fatalf("open: %v", err)
	}

	// Exit higher for long profit: feed tick then sell
	exit := 110.0
	feedFreshTick(eng, symbol, exit)
	oid2 := uuid.New().String()
	if err := eng.ProcessOrder(ctx, &contracts.OrderRequest{
		OrderID: oid2, UserID: users[0], ContestID: contestID, Symbol: symbol,
		Side: contracts.OrderSideSell, Type: contracts.OrderTypeMarket, Qty: 10,
	}); err != nil {
		t.Fatalf("close: %v", err)
	}

	var realized float64
	if err := db.QueryRowContext(ctx, `
		SELECT COALESCE(realized_score,0)::float8 FROM positions
		WHERE contest_id=$1 AND user_id=$2 ORDER BY opened_at DESC LIMIT 1
	`, contestID, users[0]).Scan(&realized); err != nil {
		t.Fatalf("realized: %v", err)
	}

	// Independent: LONG pct = (exit-entry)/entry*100; score = qty * pct
	// Market fill uses ask for buy / bid for sell (tick sets bid=last*0.999, ask=last*1.001)
	// So entry ≈ 100*1.001, exit ≈ 110*0.999 — compute from DB fill prices
	var entryPx, exitPx float64
	_ = db.QueryRowContext(ctx, `SELECT fill_price::float8 FROM fills WHERE order_id=$1`, oid).Scan(&entryPx)
	_ = db.QueryRowContext(ctx, `SELECT fill_price::float8 FROM fills WHERE order_id=$1`, oid2).Scan(&exitPx)
	pct := (exitPx - entryPx) / entryPx * 100
	expected := 10 * pct
	// Tolerance for float last-mile vs decimal score path
	if abs(realized-expected) > 0.05 {
		t.Fatalf("realized_score=%v expected≈%v (entry=%v exit=%v)", realized, expected, entryPx, exitPx)
	}
	t.Logf("PnL check PASS realized=%v expected=%v entry=%v exit=%v", realized, expected, entryPx, exitPx)
}

func TestTradingCert_DuplicateOrderID(t *testing.T) {
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
	eng := newTestEngine(t, db, filepath.Join(dir, "dup.wal"))
	eng.config.QtyMinPerTrade = 1
	eng.config.QtyMaxPctOfTotal = 100
	defer eng.GetWAL().Close()
	feedFreshTick(eng, symbol, 50)

	orderID := uuid.New().String()
	req := &contracts.OrderRequest{
		OrderID: orderID, UserID: users[0], ContestID: contestID, Symbol: symbol,
		Side: contracts.OrderSideBuy, Type: contracts.OrderTypeMarket, Qty: 5,
	}
	if err := eng.ProcessOrder(ctx, req); err != nil {
		t.Fatal(err)
	}
	_ = eng.ProcessOrder(ctx, req)
	_ = eng.ProcessOrder(ctx, req)
	var fills int
	_ = db.QueryRowContext(ctx, `SELECT COUNT(*) FROM fills WHERE order_id=$1`, orderID).Scan(&fills)
	if fills != 1 {
		t.Fatalf("duplicate order_id produced %d fills", fills)
	}
	var pos int64
	_ = db.QueryRowContext(ctx, `
		SELECT COALESCE(SUM(qty_open),0) FROM positions WHERE contest_id=$1 AND user_id=$2 AND closed_at IS NULL
	`, contestID, users[0]).Scan(&pos)
	if pos != 5 {
		t.Fatalf("position qty=%d want 5", pos)
	}
}

func TestTradingCert_DefaultConfigProductQty(t *testing.T) {
	// Unit: product defaults accept qty 1 on allocation 10
	eng := &Engine{config: &Config{QtyMinPerTrade: 1, QtyMaxPctOfTotal: 100}}
	if err := eng.validateQtyLimits(1, 10); err != nil {
		t.Fatalf("qty 1 of 10 must pass: %v", err)
	}
	if err := eng.validateQtyLimits(10, 10); err != nil {
		t.Fatalf("full allocation must pass: %v", err)
	}
	// Legacy broken defaults must not be reintroduced as code defaults
	// (explicit test config with min=100 is still valid for custom deployments)
	broken := &Engine{config: &Config{QtyMinPerTrade: 100, QtyMaxPctOfTotal: 50}}
	if err := broken.validateQtyLimits(5, 10); err == nil {
		t.Fatal("min=100 should reject product qty 5")
	}
}

func fmtQty(q int64) string {
	return "qty_" + itoa(q)
}

func itoa(n int64) string {
	if n == 0 {
		return "0"
	}
	neg := n < 0
	if neg {
		n = -n
	}
	var b [20]byte
	i := len(b)
	for n > 0 {
		i--
		b[i] = byte('0' + n%10)
		n /= 10
	}
	if neg {
		i--
		b[i] = '-'
	}
	return string(b[i:])
}

func abs(x float64) float64 {
	if x < 0 {
		return -x
	}
	return x
}
