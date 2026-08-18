package server

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"runtime/debug"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
	"go.uber.org/zap"
)

const (
	// Public market-data socket (no auth). Live ticks with bid/ask verified here.
	derivPublicWSURL = "wss://api.derivws.com/trading/v1/options/ws/public"
	// Classic v3 host — used only as optional history fallback / override.
	derivClassicWSURL = "wss://ws.derivws.com/websockets/v3"
	derivDefaultAppID = "1089"
	derivPollInterval = 1500 * time.Millisecond
	derivSubscribeGrace = 2 * time.Second
	derivPingInterval   = 20 * time.Second
	derivReadDeadline   = 45 * time.Second
	derivActiveSymWait  = 3 * time.Second
)

// DerivProvider implements MarketProvider for Deriv public market-data WebSocket.
// Primary: wss://api.derivws.com/trading/v1/options/ws/public (live ticks + bid/ask).
// If live subscribe fails, polls ticks_history (real prices only — never invented).
type DerivProvider struct {
	appID     string
	wsURL     string
	conn      *websocket.Conn
	mu        sync.Mutex
	writeMu   sync.Mutex
	connected bool
	logger    *zap.Logger
	msgCh     chan []byte
	stopCh    chan struct{}
	wg        sync.WaitGroup

	reqID atomic.Int64

	// subscribed Deriv symbols (e.g. frxEURUSD)
	subsMu       sync.Mutex
	subscribed   map[string]*derivSubState
	subAt        time.Time
	fallbackOnce sync.Once

	pollFallback   atomic.Bool
	activeSymEmpty atomic.Bool
	activeSymCount atomic.Int64
	liveTickSeen   atomic.Bool
	lastTickAt     atomic.Int64 // unix seconds
	candleReady    atomic.Bool
	symbolsLoaded  atomic.Int64

	activeSymCh chan struct{}
}

type derivSubState struct {
	symbol      string
	liveOK      bool
	invalid     bool
	historyDead bool
	useCandles  bool
}

// NewDerivProvider creates a Deriv provider.
// appID is only appended when using the classic v3 host; public URL needs no app_id.
// Optional env DERIV_WS_URL overrides the socket (default: public market-data URL).
func NewDerivProvider(appID string, logger *zap.Logger) *DerivProvider {
	if strings.TrimSpace(appID) == "" {
		appID = derivDefaultAppID
	}
	wsURL := strings.TrimSpace(os.Getenv("DERIV_WS_URL"))
	if wsURL == "" {
		wsURL = derivPublicWSURL
	}
	return &DerivProvider{
		appID:       appID,
		wsURL:       wsURL,
		logger:      logger,
		msgCh:       make(chan []byte, 256),
		stopCh:      make(chan struct{}),
		subscribed:  make(map[string]*derivSubState),
		activeSymCh: make(chan struct{}, 1),
	}
}

func (p *DerivProvider) Name() ProviderType {
	return ProviderDeriv
}

func (p *DerivProvider) Connect(ctx context.Context) error {
	// Reset per-connection fallback so reconnect retries live subscribe first.
	p.pollFallback.Store(false)
	p.liveTickSeen.Store(false)
	p.activeSymEmpty.Store(false)
	p.activeSymCount.Store(0)
	p.fallbackOnce = sync.Once{}
	p.activeSymCh = make(chan struct{}, 1)

	wsURL := p.dialURL()
	p.logger.Info("Connecting",
		zap.String("url", wsURL),
		zap.String("app_id", p.appID))

	dialer := websocket.Dialer{
		HandshakeTimeout: 10 * time.Second,
	}
	conn, _, err := dialer.DialContext(ctx, wsURL, nil)
	if err != nil {
		return fmt.Errorf("Deriv dial failed: %w", err)
	}

	p.mu.Lock()
	p.conn = conn
	p.connected = true
	p.mu.Unlock()

	p.logger.Info("WebSocket connected")

	p.wg.Add(2)
	go p.readLoop()
	go p.pingLoop()

	// Probe active_symbols without product_type — public socket rejects that field.
	// Mapping still comes from DB/heuristics; empty active_symbols is non-fatal.
	if err := p.writeJSON(map[string]interface{}{
		"active_symbols": "brief",
		"req_id":         p.nextReqID(),
	}); err != nil {
		p.logger.Warn("active_symbols request failed", zap.Error(err))
		// Do not force poll fallback solely from this — public ticks often still work.
	} else {
		p.waitActiveSymbols(ctx)
	}

	return nil
}

func (p *DerivProvider) dialURL() string {
	u := strings.TrimSpace(p.wsURL)
	if u == "" {
		u = derivPublicWSURL
	}
	// Classic v3 hosts require app_id query param.
	if strings.Contains(u, "websockets/v3") && !strings.Contains(u, "app_id=") {
		sep := "?"
		if strings.Contains(u, "?") {
			sep = "&"
		}
		return u + sep + "app_id=" + p.appID
	}
	return u
}

func (p *DerivProvider) waitActiveSymbols(ctx context.Context) {
	timeout := derivActiveSymWait
	timer := time.NewTimer(timeout)
	defer timer.Stop()
	select {
	case <-p.activeSymCh:
	case <-timer.C:
		// Public socket may not populate active_symbols; live ticks can still work.
		p.logger.Warn("active_symbols timed out; continuing with DB/heuristic symbol map")
	case <-ctx.Done():
	case <-p.stopCh:
	}
}

func (p *DerivProvider) Subscribe(symbols []string) error {
	p.mu.Lock()
	conn := p.conn
	p.mu.Unlock()
	if conn == nil {
		return fmt.Errorf("not connected")
	}

	p.subsMu.Lock()
	for _, sym := range symbols {
		sym = strings.TrimSpace(sym)
		if sym == "" {
			continue
		}
		deriv := normalizeDerivSymbol(sym)
		if deriv == "" {
			continue
		}
		if _, ok := p.subscribed[deriv]; !ok {
			p.subscribed[deriv] = &derivSubState{symbol: deriv}
		}
	}
	p.subAt = time.Now()
	loaded := len(p.subscribed)
	p.subsMu.Unlock()
	p.symbolsLoaded.Store(int64(loaded))

	// Prefer live ticks subscribe when it works.
	for _, st := range p.snapshotSubs() {
		if err := p.writeJSON(map[string]interface{}{
			"ticks":     st.symbol,
			"subscribe": 1,
			"req_id":    p.nextReqID(),
		}); err != nil {
			return fmt.Errorf("Deriv subscribe failed for %s: %w", st.symbol, err)
		}
	}

	p.wg.Add(1)
	go p.pollLoop()

	p.logger.Info("Subscribed",
		zap.Int("symbol_count", loaded),
		zap.Bool("poll_fallback", p.pollFallback.Load()))
	return nil
}

// SubscribeSymbol adds a single canonical or Deriv symbol (dynamic manager).
func (p *DerivProvider) SubscribeSymbol(symbol string) error {
	deriv := normalizeDerivSymbol(symbol)
	if deriv == "" {
		return fmt.Errorf("cannot map symbol %q to Deriv", symbol)
	}
	p.subsMu.Lock()
	if _, ok := p.subscribed[deriv]; !ok {
		p.subscribed[deriv] = &derivSubState{symbol: deriv}
	}
	p.symbolsLoaded.Store(int64(len(p.subscribed)))
	p.subsMu.Unlock()

	if err := p.writeJSON(map[string]interface{}{
		"ticks":     deriv,
		"subscribe": 1,
		"req_id":    p.nextReqID(),
	}); err != nil {
		// Poller will still cover this symbol if we are in fallback.
		p.logger.Debug("SubscribeSymbol ticks send failed; poller will cover",
			zap.String("symbol", deriv), zap.Error(err))
	}
	return nil
}

// UnsubscribeSymbol removes a symbol from live subscribe + poll list.
func (p *DerivProvider) UnsubscribeSymbol(symbol string) error {
	deriv := normalizeDerivSymbol(symbol)
	if deriv == "" {
		return nil
	}
	p.subsMu.Lock()
	delete(p.subscribed, deriv)
	p.symbolsLoaded.Store(int64(len(p.subscribed)))
	p.subsMu.Unlock()
	return nil
}

func (p *DerivProvider) pollLoop() {
	defer p.wg.Done()
	defer func() {
		if r := recover(); r != nil {
			p.logger.Error("Deriv pollLoop panicked",
				zap.Any("panic", r),
				zap.String("stack", string(debug.Stack())))
		}
	}()

	ticker := time.NewTicker(derivPollInterval)
	defer ticker.Stop()

	for {
		select {
		case <-p.stopCh:
			return
		case <-ticker.C:
			p.maybePoll()
		}
	}
}

func (p *DerivProvider) maybePoll() {
	subs := p.snapshotSubs()
	needPoll := p.pollFallback.Load()
	if !needPoll {
		p.subsMu.Lock()
		graceOver := !p.subAt.IsZero() && time.Since(p.subAt) >= derivSubscribeGrace
		anyLive := false
		anyPending := false
		for _, st := range p.subscribed {
			if st.liveOK {
				anyLive = true
			} else if !st.historyDead {
				anyPending = true
			}
		}
		p.subsMu.Unlock()
		if anyLive && !anyPending {
			return
		}
		if !graceOver && !p.pollFallback.Load() {
			return
		}
		if anyPending {
			p.enablePollFallback("ticks subscribe produced no live ticks")
		}
	}

	for _, st := range subs {
		if st.liveOK || st.historyDead {
			continue
		}
		style := "ticks"
		if st.useCandles {
			style = "candles"
		}
		req := map[string]interface{}{
			"ticks_history":     st.symbol,
			"adjust_start_time": 1,
			"count":             1,
			"end":               "latest",
			"start":             1,
			"style":             style,
			"req_id":            p.nextReqID(),
		}
		if err := p.writeJSON(req); err != nil {
			p.logger.Debug("ticks_history poll write failed",
				zap.String("symbol", st.symbol), zap.Error(err))
			return
		}
	}
}

func (p *DerivProvider) enablePollFallback(reason string) {
	p.fallbackOnce.Do(func() {
		p.pollFallback.Store(true)
		p.logger.Warn("deriv using ticks_history poll fallback",
			zap.String("reason", reason),
			zap.Int("symbols", int(p.symbolsLoaded.Load())))
	})
	p.pollFallback.Store(true)
}

func (p *DerivProvider) pingLoop() {
	defer p.wg.Done()
	defer func() {
		if r := recover(); r != nil {
			p.logger.Error("Deriv pingLoop panicked",
				zap.Any("panic", r),
				zap.String("stack", string(debug.Stack())))
		}
	}()

	ticker := time.NewTicker(derivPingInterval)
	defer ticker.Stop()
	for {
		select {
		case <-p.stopCh:
			return
		case <-ticker.C:
			if err := p.writeJSON(map[string]interface{}{
				"ping":   1,
				"req_id": p.nextReqID(),
			}); err != nil {
				p.logger.Debug("ping failed", zap.Error(err))
			}
		}
	}
}

func (p *DerivProvider) readLoop() {
	defer p.wg.Done()
	defer func() {
		if r := recover(); r != nil {
			p.logger.Error("Deriv readLoop panicked",
				zap.Any("panic", r),
				zap.String("stack", string(debug.Stack())))
		}
	}()
	for {
		select {
		case <-p.stopCh:
			return
		default:
		}

		p.mu.Lock()
		conn := p.conn
		p.mu.Unlock()
		if conn == nil {
			return
		}

		conn.SetReadDeadline(time.Now().Add(derivReadDeadline))
		_, message, err := conn.ReadMessage()
		if err != nil {
			p.mu.Lock()
			p.connected = false
			p.mu.Unlock()
			p.logger.Error("Read error", zap.Error(err))
			select {
			case p.msgCh <- nil:
			default:
				p.logger.Warn("Failed to send disconnect sentinel: msgCh full, consumer may miss reconnect")
				wsSentinelDropsTotal.WithLabelValues("deriv").Inc()
			}
			return
		}

		p.observeMessage(message)

		select {
		case p.msgCh <- message:
		case <-p.stopCh:
			return
		}
	}
}

func (p *DerivProvider) observeMessage(data []byte) {
	res, err := ParseDerivMessage(data)
	if err != nil {
		return
	}
	switch res.MsgType {
	case "active_symbols":
		p.activeSymCount.Store(int64(len(res.ActiveSymbols)))
		if res.ActiveEmpty {
			p.activeSymEmpty.Store(true)
			// Empty catalog is OK on the public socket; rely on DB/heuristic maps + ticks.
			p.logger.Info("active_symbols empty; using registry/heuristic Deriv symbols")
		} else {
			p.activeSymEmpty.Store(false)
		}
		select {
		case p.activeSymCh <- struct{}{}:
		default:
		}
	case "error":
		if res.InvalidSymbol {
			// Per-symbol only — do not poison the whole feed when one exotic fails.
			p.markInvalid(res.EchoSymbol, res.EchoHistory)
			if res.EchoHistory {
				p.enablePollFallback("InvalidSymbol on ticks_history")
			}
		}
	case "tick":
		p.liveTickSeen.Store(true)
		for _, t := range res.Ticks {
			p.markLive(t.Symbol)
			if t.Quote > 0 {
				p.lastTickAt.Store(t.Epoch)
			}
		}
	case "history":
		for _, t := range res.Ticks {
			if t.Quote > 0 {
				p.lastTickAt.Store(t.Epoch)
				p.candleReady.Store(true)
			}
		}
	case "candles":
		if len(res.Ticks) > 0 && res.Ticks[0].Quote > 0 {
			p.candleReady.Store(true)
			p.lastTickAt.Store(res.Ticks[0].Epoch)
		}
	}
}

func (p *DerivProvider) markLive(symbol string) {
	if symbol == "" {
		return
	}
	p.subsMu.Lock()
	defer p.subsMu.Unlock()
	if st, ok := p.subscribed[symbol]; ok {
		st.liveOK = true
		st.invalid = false
	}
}

func (p *DerivProvider) markInvalid(symbol string, fromHistory bool) {
	if symbol == "" {
		return
	}
	p.subsMu.Lock()
	defer p.subsMu.Unlock()
	st, ok := p.subscribed[symbol]
	if !ok {
		st = &derivSubState{symbol: symbol}
		p.subscribed[symbol] = st
	}
	st.invalid = true
	if !fromHistory {
		// Live ticks subscribe failed; ticks_history (style=ticks) may still work.
		return
	}
	// ticks_history failed: try candles close next, then give up (never invent).
	if st.useCandles {
		st.historyDead = true
		p.logger.Warn("Deriv ticks_history also InvalidSymbol; not inventing price",
			zap.String("symbol", symbol))
		return
	}
	st.useCandles = true
}

func (p *DerivProvider) snapshotSubs() []*derivSubState {
	p.subsMu.Lock()
	defer p.subsMu.Unlock()
	out := make([]*derivSubState, 0, len(p.subscribed))
	for _, st := range p.subscribed {
		cp := *st
		out = append(out, &cp)
	}
	return out
}

func (p *DerivProvider) writeJSON(v interface{}) error {
	p.mu.Lock()
	conn := p.conn
	p.mu.Unlock()
	if conn == nil {
		return fmt.Errorf("not connected")
	}
	p.writeMu.Lock()
	defer p.writeMu.Unlock()
	return conn.WriteJSON(v)
}

func (p *DerivProvider) nextReqID() int64 {
	return p.reqID.Add(1)
}

func (p *DerivProvider) ReadMessage() ([]byte, error) {
	msg, ok := <-p.msgCh
	if !ok {
		return nil, fmt.Errorf("message channel closed")
	}
	if msg == nil {
		return nil, fmt.Errorf("connection lost")
	}
	return msg, nil
}

func (p *DerivProvider) Close() error {
	select {
	case <-p.stopCh:
	default:
		close(p.stopCh)
	}

	p.mu.Lock()
	var err error
	if p.conn != nil {
		err = p.conn.Close()
		p.conn = nil
		p.connected = false
	}
	p.mu.Unlock()

	p.wg.Wait()

	p.msgCh = make(chan []byte, 256)
	p.stopCh = make(chan struct{})
	return err
}

func (p *DerivProvider) IsConnected() bool {
	p.mu.Lock()
	defer p.mu.Unlock()
	return p.connected
}

func (p *DerivProvider) RotateKey() {
	// Deriv uses app_id, not rotating API keys.
}

func (p *DerivProvider) KeyCount() int {
	return 1
}

// LastTickAtUnix returns the unix-seconds timestamp of the last real Deriv price.
func (p *DerivProvider) LastTickAtUnix() int64 {
	return p.lastTickAt.Load()
}

// SymbolsLoaded returns how many symbols are currently subscribed.
func (p *DerivProvider) SymbolsLoaded() int {
	return int(p.symbolsLoaded.Load())
}

// CandleReady is true after a ticks_history candles response with a real close.
func (p *DerivProvider) CandleReady() bool {
	return p.candleReady.Load()
}

// UsingPollFallback reports whether ticks_history polling is active.
func (p *DerivProvider) UsingPollFallback() bool {
	return p.pollFallback.Load()
}

// --- mapping heuristics (canonical ↔ Deriv) ---

// CanonicalToDeriv maps EUR/USD→frxEURUSD, BTC/USD→cryBTCUSD, XAU/USD→frxXAUUSD.
func CanonicalToDeriv(canonical string) string {
	s := strings.TrimSpace(canonical)
	if s == "" {
		return ""
	}
	if strings.HasPrefix(s, "frx") || strings.HasPrefix(s, "cry") {
		return s
	}
	parts := strings.SplitN(s, "/", 2)
	if len(parts) != 2 {
		return ""
	}
	base := strings.ToUpper(parts[0])
	quote := strings.ToUpper(parts[1])
	if quote == "USDT" {
		quote = "USD"
	}
	if isForexSymbol(base + "/" + quote) {
		return "frx" + base + quote
	}
	return "cry" + base + quote
}

// DerivToCanonicalHeuristic maps frxEURUSD→EUR/USD, cryBTCUSD→BTC/USD.
func DerivToCanonicalHeuristic(deriv string) string {
	s := strings.TrimSpace(deriv)
	if s == "" {
		return ""
	}
	rest := s
	if strings.HasPrefix(s, "frx") || strings.HasPrefix(s, "cry") {
		rest = s[3:]
	} else if strings.Contains(s, "/") {
		return s
	}
	if len(rest) < 6 {
		return s
	}
	// Quote is the last 3 letters (USD, JPY, GBP, CHF, CAD, AUD, …).
	quote := rest[len(rest)-3:]
	base := rest[:len(rest)-3]
	if base == "" || quote == "" {
		return s
	}
	return base + "/" + quote
}

func normalizeDerivSymbol(symbol string) string {
	s := strings.TrimSpace(symbol)
	if s == "" {
		return ""
	}
	if strings.HasPrefix(s, "frx") || strings.HasPrefix(s, "cry") {
		return s
	}
	return CanonicalToDeriv(s)
}

// --- message parse ---

// DerivTick is a real Deriv price (live tick, history tick, or candle close).
type DerivTick struct {
	Symbol string
	Quote  float64
	Bid    float64
	Ask    float64
	Epoch  int64
}

// DerivParseResult is the structured outcome of ParseDerivMessage.
type DerivParseResult struct {
	Ticks         []DerivTick
	MsgType       string
	ErrCode       string
	ErrMsg        string
	ActiveSymbols []string
	ActiveEmpty   bool
	InvalidSymbol bool
	EchoSymbol    string
	EchoHistory   bool // echo_req was ticks_history (vs live ticks)
}

type derivEnvelope struct {
	MsgType string `json:"msg_type"`
	Error   *struct {
		Code    string `json:"code"`
		Message string `json:"message"`
	} `json:"error"`
	Tick *struct {
		Symbol string  `json:"symbol"`
		Quote  float64 `json:"quote"`
		Bid    float64 `json:"bid"`
		Ask    float64 `json:"ask"`
		Epoch  int64   `json:"epoch"`
	} `json:"tick"`
	History *struct {
		Prices []float64 `json:"prices"`
		Times  []int64   `json:"times"`
	} `json:"history"`
	Candles []struct {
		Close float64 `json:"close"`
		Epoch int64   `json:"epoch"`
		Open  float64 `json:"open"`
		High  float64 `json:"high"`
		Low   float64 `json:"low"`
	} `json:"candles"`
	ActiveSymbols []struct {
		Symbol string `json:"symbol"`
	} `json:"active_symbols"`
	EchoReq json.RawMessage `json:"echo_req"`
	Ping    string          `json:"ping"`
	Pong    int             `json:"pong"`
}

type derivEchoReq struct {
	Ticks        string `json:"ticks"`
	TicksHistory string `json:"ticks_history"`
}

// ParseDerivMessage parses a Deriv v3 WebSocket message.
// Never synthesizes prices: empty/error payloads yield no ticks.
func ParseDerivMessage(data []byte) (DerivParseResult, error) {
	var env derivEnvelope
	if err := json.Unmarshal(data, &env); err != nil {
		return DerivParseResult{}, fmt.Errorf("parse error: %w", err)
	}

	res := DerivParseResult{MsgType: env.MsgType}
	res.EchoSymbol, res.EchoHistory = echoSymbol(env.EchoReq)

	if env.Error != nil && (env.Error.Code != "" || env.Error.Message != "") {
		res.MsgType = "error"
		res.ErrCode = env.Error.Code
		res.ErrMsg = env.Error.Message
		if strings.EqualFold(env.Error.Code, "InvalidSymbol") ||
			strings.Contains(strings.ToLower(env.Error.Message), "invalid symbol") {
			res.InvalidSymbol = true
		}
		return res, nil
	}

	if env.MsgType == "" {
		if env.Tick != nil {
			res.MsgType = "tick"
		} else if env.History != nil {
			res.MsgType = "history"
		} else if env.Candles != nil {
			res.MsgType = "candles"
		} else if env.ActiveSymbols != nil {
			res.MsgType = "active_symbols"
		} else if env.Ping != "" || strings.Contains(string(data), `"ping"`) {
			res.MsgType = "ping"
		} else if env.Pong != 0 {
			res.MsgType = "pong"
		} else {
			res.MsgType = "other"
		}
	}

	switch res.MsgType {
	case "tick":
		if env.Tick != nil && env.Tick.Quote > 0 {
			sym := env.Tick.Symbol
			if sym == "" {
				sym = res.EchoSymbol
			}
			res.Ticks = []DerivTick{{
				Symbol: sym,
				Quote:  env.Tick.Quote,
				Bid:    env.Tick.Bid,
				Ask:    env.Tick.Ask,
				Epoch:  env.Tick.Epoch,
			}}
		}
	case "history":
		if env.History != nil && len(env.History.Prices) > 0 {
			idx := len(env.History.Prices) - 1
			price := env.History.Prices[idx]
			if price > 0 {
				var epoch int64
				if idx < len(env.History.Times) {
					epoch = env.History.Times[idx]
				}
				res.Ticks = []DerivTick{{
					Symbol: res.EchoSymbol,
					Quote:  price,
					Epoch:  epoch,
				}}
			}
		}
	case "candles", "ohlc":
		res.MsgType = "candles"
		if len(env.Candles) > 0 {
			c := env.Candles[len(env.Candles)-1]
			if c.Close > 0 {
				res.Ticks = []DerivTick{{
					Symbol: res.EchoSymbol,
					Quote:  c.Close,
					Epoch:  c.Epoch,
				}}
			}
		}
	case "active_symbols":
		for _, s := range env.ActiveSymbols {
			if s.Symbol != "" {
				res.ActiveSymbols = append(res.ActiveSymbols, s.Symbol)
			}
		}
		res.ActiveEmpty = len(res.ActiveSymbols) == 0
	case "ping", "pong":
		// keepalive — no ticks
	}

	return res, nil
}

func echoSymbol(raw json.RawMessage) (symbol string, history bool) {
	if len(raw) == 0 {
		return "", false
	}
	var echo derivEchoReq
	if err := json.Unmarshal(raw, &echo); err != nil {
		return "", false
	}
	if echo.TicksHistory != "" {
		return echo.TicksHistory, true
	}
	return echo.Ticks, false
}
