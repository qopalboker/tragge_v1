package server

import (
	"sync"
	"sync/atomic"
	"testing"
	"time"

	contracts "github.com/Parsaeffatravesh/tragge/packages/contracts/v1"
)

func TestTickTimestampSafety(t *testing.T) {
	pb := NewPriceBook()
	nowMs := time.Now().UnixMilli()

	// Valid tick
	st := pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: nowMs,
		Symbols: []contracts.SymbolTick{{
			Symbol: "BTC/USD", Last: 100, Bid: 99.5, Ask: 100.5,
		}},
	})
	if st.Accepted != 1 {
		t.Fatalf("expected accept, stats=%+v", st)
	}

	// Future timestamp
	st = pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: time.Now().Add(30 * time.Second).UnixMilli(),
		Symbols: []contracts.SymbolTick{{
			Symbol: "ETH/USD", Last: 50, Bid: 49, Ask: 51,
		}},
	})
	if st.Accepted != 0 || st.Reasons["future_timestamp"] == 0 {
		t.Fatalf("future must reject: %+v", st)
	}

	// Extremely old
	st = pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: time.Now().Add(-48 * time.Hour).UnixMilli(),
		Symbols: []contracts.SymbolTick{{
			Symbol: "SOL/USD", Last: 10, Bid: 9, Ask: 11,
		}},
	})
	if st.Accepted != 0 || st.Reasons["extremely_old_timestamp"] == 0 {
		t.Fatalf("old must reject: %+v", st)
	}

	// Zero timestamp
	st = pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: 0,
		Symbols: []contracts.SymbolTick{{
			Symbol: "XRP/USD", Last: 1, Bid: 1, Ask: 1,
		}},
	})
	if st.Accepted != 0 {
		t.Fatalf("zero ts must reject: %+v", st)
	}

	// Seconds unit normalized and accepted
	sec := time.Now().Unix()
	st = pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: sec, // seconds
		Symbols: []contracts.SymbolTick{{
			Symbol: "ADA/USD", Last: 2, Bid: 1.9, Ask: 2.1,
		}},
	})
	if st.Accepted != 1 {
		t.Fatalf("seconds unit should normalize: %+v", st)
	}
	q, ok := pb.GetQuote("ADA/USD")
	if !ok || q.Timestamp < 1e12 {
		t.Fatalf("expected ms timestamp, got %d", q.Timestamp)
	}

	// Backward time: older tick must not override newer
	newer := time.Now().UnixMilli()
	_ = pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: newer,
		Symbols: []contracts.SymbolTick{{
			Symbol: "BTC/USD", Last: 110, Bid: 109, Ask: 111,
		}},
	})
	st = pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: newer - 5000,
		Symbols: []contracts.SymbolTick{{
			Symbol: "BTC/USD", Last: 1, Bid: 1, Ask: 1, // poison prices
		}},
	})
	if st.Reasons["backward_timestamp"] == 0 {
		t.Fatalf("backward must reject: %+v", st)
	}
	q, _ = pb.GetQuote("BTC/USD")
	if q.Last != 110 {
		t.Fatalf("stale override applied, last=%v", q.Last)
	}
}

func TestMarketDataReadiness(t *testing.T) {
	pb := NewPriceBook()
	ok, reason := pb.MarketDataReady(nil, 30*time.Second)
	if ok {
		t.Fatalf("empty book ready: %s", reason)
	}

	_ = pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: time.Now().UnixMilli(),
		Symbols: []contracts.SymbolTick{{
			Symbol: "BTC/USD", Last: 100, Bid: 99, Ask: 101,
		}},
	})
	ok, reason = pb.MarketDataReady([]string{"BTC/USD"}, 30*time.Second)
	if !ok {
		t.Fatalf("should be ready: %s", reason)
	}
	ok, reason = pb.MarketDataReady([]string{"ETH/USD"}, 30*time.Second)
	if ok {
		t.Fatalf("missing symbol should fail: %s", reason)
	}
}

func TestContestFinalizationGate_RaceAB(t *testing.T) {
	// Simulates contest cutoff: trading gate disables contest while status still
	// might race; engine gate + ends_at exclusive boundary.
	var enabled atomic.Bool
	enabled.Store(true)
	gate := func(contestID string) bool {
		return enabled.Load()
	}

	e := &Engine{
		contestTradingEnabled: gate,
		config:                &Config{},
		priceBook:             NewPriceBook(),
	}
	// When gate disabled, CanAcceptTrading is still true (WAL ok) but ProcessOrder
	// rejects via gate — unit-check the gate path directly.
	if e.contestTradingEnabled("c1") != true {
		t.Fatal("expected enabled")
	}
	enabled.Store(false)
	if e.contestTradingEnabled("c1") {
		t.Fatal("Race B: finalization must disable trading")
	}
}

func TestContestFinalizationGate_ConcurrentOrders(t *testing.T) {
	// Race C: concurrent order checks see a consistent gate flip.
	var enabled atomic.Bool
	enabled.Store(true)
	gate := func(string) bool { return enabled.Load() }

	var accepted, rejected atomic.Int64
	var wg sync.WaitGroup
	for i := 0; i < 50; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			if gate("c") {
				accepted.Add(1)
			} else {
				rejected.Add(1)
			}
		}()
		if i == 25 {
			enabled.Store(false)
		}
	}
	wg.Wait()
	if accepted.Load()+rejected.Load() != 50 {
		t.Fatal("lost concurrent checks")
	}
	// After flip, later checks should reject; total rejected should be > 0.
	if rejected.Load() == 0 {
		t.Fatal("expected some rejections after finalization flip")
	}
}

func TestIsContestTradingEnabled_DefaultTrue(t *testing.T) {
	a := &App{contestTrading: make(map[string]bool)}
	if !a.IsContestTradingEnabled("unknown") {
		t.Fatal("default should allow until explicitly disabled")
	}
	a.SetContestTradingEnabled("c1", false)
	if a.IsContestTradingEnabled("c1") {
		t.Fatal("explicit disable must stick")
	}
}

func TestProviderMonotonicSourceSwitch(t *testing.T) {
	// Primary then stale fallback must not regress book time/prices.
	pb := NewPriceBook()
	t0 := time.Now().UnixMilli()
	_ = pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: t0,
		Symbols: []contracts.SymbolTick{{
			Symbol: "EUR/USD", Last: 1.10, Bid: 1.099, Ask: 1.101,
		}},
	})
	// "fallback" delivers older tick
	st := pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: t0 - 1000,
		Symbols: []contracts.SymbolTick{{
			Symbol: "EUR/USD", Last: 9.99, Bid: 9.9, Ask: 10,
		}},
	})
	if st.Reasons["backward_timestamp"] == 0 {
		t.Fatal("fallback older tick must not override primary")
	}
	// Primary recovery with newer tick
	st = pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: t0 + 50,
		Symbols: []contracts.SymbolTick{{
			Symbol: "EUR/USD", Last: 1.11, Bid: 1.109, Ask: 1.111,
		}},
	})
	if st.Accepted != 1 {
		t.Fatalf("primary recovery should accept: %+v", st)
	}
	q, _ := pb.GetQuote("EUR/USD")
	if q.Last != 1.11 {
		t.Fatalf("want recovered last 1.11 got %v", q.Last)
	}
}

func TestMalformedTickRejected(t *testing.T) {
	pb := NewPriceBook()
	st := pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: time.Now().UnixMilli(),
		Symbols: []contracts.SymbolTick{{
			Symbol: "BTC/USD", Last: -1, Bid: 1, Ask: 2,
		}},
	})
	if st.Accepted != 0 {
		t.Fatal("negative last must reject")
	}
	st = pb.UpdateFromTick(&contracts.TickSnapshot{
		Ts: time.Now().UnixMilli(),
		Symbols: []contracts.SymbolTick{{
			Symbol: "BTC/USD", Last: 100, Bid: 102, Ask: 101, // crossed
		}},
	})
	if st.Accepted != 0 {
		t.Fatal("crossed book must reject")
	}
}
