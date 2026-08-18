package server

import (
	"testing"
)

func TestCanonicalToDeriv(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		{"EUR/USD", "frxEURUSD"},
		{"GBP/USD", "frxGBPUSD"},
		{"USD/JPY", "frxUSDJPY"},
		{"XAU/USD", "frxXAUUSD"},
		{"XAG/USD", "frxXAGUSD"},
		{"BTC/USD", "cryBTCUSD"},
		{"ETH/USD", "cryETHUSD"},
		{"SOL/USD", "crySOLUSD"},
		{"DOGE/USD", "cryDOGEUSD"},
		{"BTC/USDT", "cryBTCUSD"},
		{"frxEURUSD", "frxEURUSD"},
		{"cryBTCUSD", "cryBTCUSD"},
		{"", ""},
		{"AAPL", ""},
	}
	for _, tc := range cases {
		got := CanonicalToDeriv(tc.in)
		if got != tc.want {
			t.Errorf("CanonicalToDeriv(%q) = %q, want %q", tc.in, got, tc.want)
		}
	}
}

func TestDerivToCanonicalHeuristic(t *testing.T) {
	cases := []struct {
		in, want string
	}{
		{"frxEURUSD", "EUR/USD"},
		{"frxXAUUSD", "XAU/USD"},
		{"frxXAGUSD", "XAG/USD"},
		{"frxUSDJPY", "USD/JPY"},
		{"cryBTCUSD", "BTC/USD"},
		{"cryETHUSD", "ETH/USD"},
		{"cryDOGEUSD", "DOGE/USD"},
		{"EUR/USD", "EUR/USD"},
		{"", ""},
	}
	for _, tc := range cases {
		got := DerivToCanonicalHeuristic(tc.in)
		if got != tc.want {
			t.Errorf("DerivToCanonicalHeuristic(%q) = %q, want %q", tc.in, got, tc.want)
		}
	}
}

func TestParseDerivTick(t *testing.T) {
	raw := []byte(`{
		"echo_req": {"ticks": "frxEURUSD", "subscribe": 1},
		"msg_type": "tick",
		"tick": {
			"ask": 1.08523,
			"bid": 1.08503,
			"epoch": 1700000000,
			"quote": 1.08513,
			"symbol": "frxEURUSD"
		}
	}`)
	res, err := ParseDerivMessage(raw)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if res.MsgType != "tick" {
		t.Fatalf("msg_type=%s, want tick", res.MsgType)
	}
	if len(res.Ticks) != 1 {
		t.Fatalf("ticks=%d, want 1", len(res.Ticks))
	}
	tk := res.Ticks[0]
	if tk.Symbol != "frxEURUSD" {
		t.Errorf("symbol=%s", tk.Symbol)
	}
	if tk.Quote != 1.08513 {
		t.Errorf("quote=%v", tk.Quote)
	}
	if tk.Bid != 1.08503 || tk.Ask != 1.08523 {
		t.Errorf("bid/ask=%v/%v", tk.Bid, tk.Ask)
	}
	if tk.Epoch != 1700000000 {
		t.Errorf("epoch=%d", tk.Epoch)
	}
}

func TestParseDerivHistoryTicks(t *testing.T) {
	raw := []byte(`{
		"echo_req": {"ticks_history": "cryBTCUSD", "style": "ticks", "count": 1, "end": "latest"},
		"history": {"prices": [67421.5], "times": [1700000100]},
		"msg_type": "history"
	}`)
	res, err := ParseDerivMessage(raw)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if res.MsgType != "history" {
		t.Fatalf("msg_type=%s, want history", res.MsgType)
	}
	if res.EchoSymbol != "cryBTCUSD" {
		t.Errorf("echo symbol=%s", res.EchoSymbol)
	}
	if len(res.Ticks) != 1 || res.Ticks[0].Quote != 67421.5 {
		t.Fatalf("ticks=%v", res.Ticks)
	}
	if res.Ticks[0].Symbol != "cryBTCUSD" {
		t.Errorf("tick symbol=%s", res.Ticks[0].Symbol)
	}
	if res.Ticks[0].Epoch != 1700000100 {
		t.Errorf("epoch=%d", res.Ticks[0].Epoch)
	}
}

func TestParseDerivCandlesClose(t *testing.T) {
	raw := []byte(`{
		"echo_req": {"ticks_history": "frxXAUUSD", "style": "candles", "count": 1, "end": "latest"},
		"candles": [{"open": 2300.1, "high": 2301.0, "low": 2299.5, "close": 2300.75, "epoch": 1700000200}],
		"msg_type": "candles"
	}`)
	res, err := ParseDerivMessage(raw)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if res.MsgType != "candles" {
		t.Fatalf("msg_type=%s, want candles", res.MsgType)
	}
	if len(res.Ticks) != 1 || res.Ticks[0].Quote != 2300.75 {
		t.Fatalf("expected candle close 2300.75, got %v", res.Ticks)
	}
	if res.Ticks[0].Symbol != "frxXAUUSD" {
		t.Errorf("symbol=%s", res.Ticks[0].Symbol)
	}
}

func TestParseDerivInvalidSymbol(t *testing.T) {
	raw := []byte(`{
		"echo_req": {"ticks": "frxEURUSD", "subscribe": 1},
		"error": {"code": "InvalidSymbol", "message": "Invalid symbol."},
		"msg_type": "ticks"
	}`)
	res, err := ParseDerivMessage(raw)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if res.MsgType != "error" {
		t.Fatalf("msg_type=%s, want error", res.MsgType)
	}
	if !res.InvalidSymbol {
		t.Fatal("expected InvalidSymbol")
	}
	if res.EchoSymbol != "frxEURUSD" {
		t.Errorf("echo=%s", res.EchoSymbol)
	}
	if len(res.Ticks) != 0 {
		t.Fatal("must not invent prices on error")
	}
}

func TestParseDerivActiveSymbolsEmpty(t *testing.T) {
	raw := []byte(`{"echo_req": {"active_symbols": "brief"}, "active_symbols": [], "msg_type": "active_symbols"}`)
	res, err := ParseDerivMessage(raw)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if res.MsgType != "active_symbols" {
		t.Fatalf("msg_type=%s", res.MsgType)
	}
	if !res.ActiveEmpty {
		t.Fatal("expected ActiveEmpty")
	}
	if len(res.Ticks) != 0 {
		t.Fatal("empty active_symbols must not invent prices")
	}
}

func TestParseDerivActiveSymbolsPopulated(t *testing.T) {
	raw := []byte(`{
		"msg_type": "active_symbols",
		"active_symbols": [{"symbol": "frxEURUSD"}, {"symbol": "cryBTCUSD"}]
	}`)
	res, err := ParseDerivMessage(raw)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if res.ActiveEmpty {
		t.Fatal("expected non-empty")
	}
	if len(res.ActiveSymbols) != 2 {
		t.Fatalf("got %v", res.ActiveSymbols)
	}
}

func TestParseDerivHistoryUsesLastPriceOnly(t *testing.T) {
	raw := []byte(`{
		"echo_req": {"ticks_history": "frxEURUSD", "style": "ticks"},
		"history": {"prices": [1.08, 1.09, 1.10], "times": [1, 2, 3]},
		"msg_type": "history"
	}`)
	res, err := ParseDerivMessage(raw)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if len(res.Ticks) != 1 || res.Ticks[0].Quote != 1.10 || res.Ticks[0].Epoch != 3 {
		t.Fatalf("want last price 1.10 @ 3, got %+v", res.Ticks)
	}
}

func TestParseDerivZeroPriceNotEmitted(t *testing.T) {
	raw := []byte(`{"msg_type": "tick", "tick": {"symbol": "frxEURUSD", "quote": 0, "epoch": 1}}`)
	res, err := ParseDerivMessage(raw)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if len(res.Ticks) != 0 {
		t.Fatal("zero quote must not be emitted")
	}
}

func TestParseDerivMalformedJSON(t *testing.T) {
	_, err := ParseDerivMessage([]byte(`{not json`))
	if err == nil {
		t.Fatal("expected parse error")
	}
}

func TestRegistryDerivMappingAndSubscriptions(t *testing.T) {
	reg := buildRegistryFromEnv([]string{"EUR/USD", "BTC/USD", "XAU/USD", "AAPL"})
	if reg.ToDeriv["EUR/USD"] != "frxEURUSD" {
		t.Errorf("EUR/USD mapping=%s", reg.ToDeriv["EUR/USD"])
	}
	if reg.ToDeriv["BTC/USD"] != "cryBTCUSD" {
		t.Errorf("BTC/USD mapping=%s", reg.ToDeriv["BTC/USD"])
	}
	if reg.ToDeriv["XAU/USD"] != "frxXAUUSD" {
		t.Errorf("XAU/USD mapping=%s", reg.ToDeriv["XAU/USD"])
	}
	if _, ok := reg.ToDeriv["AAPL"]; ok {
		t.Error("stocks should not get a Deriv mapping")
	}

	subs := reg.DerivSubscriptions()
	want := map[string]bool{"frxEURUSD": true, "cryBTCUSD": true, "frxXAUUSD": true}
	if len(subs) != 3 {
		t.Fatalf("subs=%v", subs)
	}
	for _, s := range subs {
		if !want[s] {
			t.Errorf("unexpected sub %s", s)
		}
	}

	if got := reg.DerivToCanonical("frxEURUSD"); got != "EUR/USD" {
		t.Errorf("DerivToCanonical frxEURUSD=%s", got)
	}
	if got := reg.DerivToCanonical("cryBTCUSD"); got != "BTC/USD" {
		t.Errorf("DerivToCanonical cryBTCUSD=%s", got)
	}

	filtered := filterRegistry(reg, []string{"EUR/USD", "BTC/USD"})
	if len(filtered.ToDeriv) != 2 {
		t.Fatalf("filtered ToDeriv=%v", filtered.ToDeriv)
	}
	if filtered.FromDeriv["frxEURUSD"] != "EUR/USD" {
		t.Error("filter lost FromDeriv")
	}
}
