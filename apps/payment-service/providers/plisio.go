package providers

import (
	"context"
	"crypto/hmac"
	"crypto/sha1"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"math"
	"net/http"
	"net/url"
	"sort"
	"strconv"
	"strings"
	"time"
)

// Plisio implements the Provider interface for Plisio crypto invoices.
// Docs: https://plisio.net/documentation/endpoints/create-an-invoice
// Callback verification uses HMAC-SHA1 over compact sorted JSON of the payload
// with verify_hash removed (json=true callback mode for non-PHP backends).
type Plisio struct {
	secretKey  string
	baseURL    string
	httpClient *http.Client
	circuit    CircuitExecutor
}

// PlisioConfig holds configuration for the Plisio provider.
type PlisioConfig struct {
	SecretKey string
	BaseURL   string
	Circuit   CircuitExecutor
}

// NewPlisio creates a Plisio provider. SecretKey is required for production use.
func NewPlisio(cfg PlisioConfig) *Plisio {
	baseURL := strings.TrimRight(strings.TrimSpace(cfg.BaseURL), "/")
	if baseURL == "" {
		baseURL = "https://api.plisio.net/api/v1"
	}
	return &Plisio{
		secretKey: strings.TrimSpace(cfg.SecretKey),
		baseURL:   baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		circuit: cfg.Circuit,
	}
}

func (p *Plisio) doHTTP(ctx context.Context, req *http.Request) (*http.Response, error) {
	if p.circuit == nil {
		return p.httpClient.Do(req)
	}
	var resp *http.Response
	err := p.circuit.ExecuteWithContext(ctx, func(_ context.Context) error {
		var e error
		resp, e = p.httpClient.Do(req)
		return e
	})
	return resp, err
}

// Name returns the provider name.
func (p *Plisio) Name() ProviderType {
	return ProviderPlisio
}

// CreatePayment creates a Plisio invoice priced in USD (source_currency/source_amount).
func (p *Plisio) CreatePayment(ctx context.Context, req *CreatePaymentRequest) (*CreatePaymentResponse, error) {
	if p.secretKey == "" {
		return nil, ErrProviderUnavailable
	}
	if req.AmountCents < 1 {
		return nil, ErrInvalidAmount
	}
	payCurrency := strings.ToUpper(strings.TrimSpace(req.PayCurrency))
	if payCurrency == "" {
		payCurrency = "USDT_TRX" // USDT TRC20 on Plisio
	}
	// Map our internal codes onto Plisio currency IDs.
	switch strings.ToLower(req.PayCurrency) {
	case "usdttrc20", "usdt_trc20", "usdt-trc20":
		payCurrency = "USDT_TRX"
	case "trx":
		payCurrency = "TRX"
	case "btc":
		payCurrency = "BTC"
	case "eth":
		payCurrency = "ETH"
	}

	sourceAmount := fmt.Sprintf("%.2f", float64(req.AmountCents)/100.0)
	// order_number must be unique per merchant order — use server-side payment intent id.
	orderNumber := req.OrderID
	if orderNumber == "" {
		return nil, fmt.Errorf("order_id is required")
	}

	callbackURL := req.IPNCallbackURL
	if callbackURL != "" && !strings.Contains(callbackURL, "json=true") {
		if strings.Contains(callbackURL, "?") {
			callbackURL += "&json=true"
		} else {
			callbackURL += "?json=true"
		}
	}

	q := url.Values{}
	q.Set("api_key", p.secretKey)
	q.Set("order_name", "Tragge Deposit")
	q.Set("order_number", orderNumber)
	q.Set("source_currency", "USD")
	q.Set("source_amount", sourceAmount)
	q.Set("currency", payCurrency)
	q.Set("description", req.Description)
	if callbackURL != "" {
		q.Set("callback_url", callbackURL)
	}
	if req.CallbackURL != "" {
		q.Set("success_invoice_url", req.CallbackURL)
	}
	if req.CancelURL != "" {
		q.Set("fail_invoice_url", req.CancelURL)
	}
	// Skip Plisio email prompt with a non-delivery placeholder.
	q.Set("email", "deposit@users.tragge.internal")
	q.Set("expire_min", "60")

	endpoint := p.baseURL + "/invoices/new?" + q.Encode()
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("create plisio request: %w", err)
	}

	resp, err := p.doHTTP(ctx, httpReq)
	if err != nil {
		return nil, fmt.Errorf("plisio request failed: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read plisio response: %w", err)
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return nil, fmt.Errorf("plisio error: status=%d", resp.StatusCode)
	}

	var envelope struct {
		Status string `json:"status"`
		Data   struct {
			TxnID           string `json:"txn_id"`
			InvoiceURL      string `json:"invoice_url"`
			InvoiceTotalSum string `json:"invoice_total_sum"`
			Amount          string `json:"amount"`
			WalletHash      string `json:"wallet_hash"`
			Currency        string `json:"currency"`
			PsysCID         string `json:"psys_cid"`
			ExpireUTC       int64  `json:"expire_utc"`
			QRCode          string `json:"qr_code"`
			Status          string `json:"status"`
		} `json:"data"`
	}
	if err := json.Unmarshal(body, &envelope); err != nil {
		return nil, fmt.Errorf("parse plisio response: %w", err)
	}
	if !strings.EqualFold(envelope.Status, "success") || envelope.Data.TxnID == "" {
		return nil, fmt.Errorf("plisio invoice creation failed")
	}

	payAmount := 0.0
	if envelope.Data.InvoiceTotalSum != "" {
		payAmount, _ = strconv.ParseFloat(envelope.Data.InvoiceTotalSum, 64)
	} else if envelope.Data.Amount != "" {
		payAmount, _ = strconv.ParseFloat(envelope.Data.Amount, 64)
	}

	return &CreatePaymentResponse{
		ProviderPaymentID: envelope.Data.TxnID,
		PaymentURL:        envelope.Data.InvoiceURL,
		PayAddress:        envelope.Data.WalletHash,
		PayAmount:         payAmount,
		PayCurrency:       firstNonEmpty(envelope.Data.Currency, envelope.Data.PsysCID, payCurrency),
		QRCode:            envelope.Data.QRCode,
		ExpiresAt:         envelope.Data.ExpireUTC,
		Status:            PaymentStatusPending,
		Metadata: map[string]string{
			"provider":       string(ProviderPlisio),
			"source_amount":  sourceAmount,
			"source_currency": "USD",
			"order_number":   orderNumber,
		},
	}, nil
}

// GetPaymentStatus is not used for Plisio invoice reconciliation in MVP
// (callbacks are authoritative). Returns pending without external calls.
func (p *Plisio) GetPaymentStatus(ctx context.Context, providerPaymentID string) (*PaymentStatusResponse, error) {
	if providerPaymentID == "" {
		return nil, ErrPaymentNotFound
	}
	return &PaymentStatusResponse{
		ProviderPaymentID: providerPaymentID,
		Status:            PaymentStatusPending,
		Currency:          "USD",
	}, nil
}

// VerifyWebhook verifies Plisio callback HMAC and maps the event.
func (p *Plisio) VerifyWebhook(ctx context.Context, headers map[string]string, body []byte) (*WebhookEvent, error) {
	if p.secretKey == "" {
		return nil, ErrProviderUnavailable
	}
	if len(body) == 0 {
		return nil, ErrInvalidSignature
	}

	data, err := parsePlisioCallbackBody(body, headers)
	if err != nil {
		return nil, err
	}

	verifyHash, _ := data["verify_hash"].(string)
	verifyHash = strings.TrimSpace(verifyHash)
	if verifyHash == "" {
		return nil, ErrInvalidSignature
	}
	if !verifyPlisioHash(data, p.secretKey, verifyHash) {
		return nil, ErrInvalidSignature
	}

	statusRaw, _ := data["status"].(string)
	orderID := stringField(data, "order_number")
	txnID := stringField(data, "txn_id")
	if txnID == "" {
		txnID = stringField(data, "id")
	}

	// Prefer fiat source_amount when present — that is the USD invoice amount.
	amountCents := parseAmountToCents(data["source_amount"])
	if amountCents == 0 {
		// Fall back to source_amount as string in nested form.
		amountCents = parseAmountToCents(stringField(data, "source_amount"))
	}
	currency := strings.ToUpper(firstNonEmpty(stringField(data, "source_currency"), "USD"))

	// Paid crypto amount is informational only; credit uses intent USD amount.
	paidCrypto := parseFloatField(data, "amount")
	paidAmountCents := int64(math.Round(paidCrypto * 100))

	return &WebhookEvent{
		Provider:          ProviderPlisio,
		ProviderPaymentID: txnID,
		OrderID:           orderID,
		Status:            mapPlisioStatus(statusRaw),
		AmountCents:       amountCents,
		Currency:          currency,
		PaidAmountCents:   paidAmountCents,
		RawData:           data,
	}, nil
}

// CreatePayout is not implemented for Plisio in this MVP (manual withdrawals).
func (p *Plisio) CreatePayout(ctx context.Context, req *PayoutRequest) (*PayoutResponse, error) {
	return nil, fmt.Errorf("plisio payouts are not supported")
}

// GetPayoutStatus is not implemented for Plisio in this MVP.
func (p *Plisio) GetPayoutStatus(ctx context.Context, providerPayoutID string) (*PayoutResponse, error) {
	return nil, fmt.Errorf("plisio payouts are not supported")
}

// RefundPayment is not supported.
func (p *Plisio) RefundPayment(ctx context.Context, req *RefundRequest) (*RefundResponse, error) {
	return nil, fmt.Errorf("plisio refunds are not supported")
}

// ReversePayment is not supported.
func (p *Plisio) ReversePayment(ctx context.Context, purchaseID string) (*RefundResponse, error) {
	return nil, fmt.Errorf("plisio reverse is not supported")
}

// IsAvailable reports whether the secret key is configured.
func (p *Plisio) IsAvailable(ctx context.Context) bool {
	return p != nil && strings.TrimSpace(p.secretKey) != ""
}

// SupportedCurrencies returns fiat pricing currency for deposits.
func (p *Plisio) SupportedCurrencies() []string {
	return []string{"USD"}
}

func mapPlisioStatus(status string) PaymentStatus {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "new":
		return PaymentStatusPending
	case "pending", "pending internal", "pending_internal":
		return PaymentStatusConfirming
	case "completed":
		// Only full payment is auto-credit eligible. Under/overpayment ("mismatch")
		// must not credit the invoice amount — source_amount is the invoice total,
		// not necessarily what was received.
		return PaymentStatusFinished
	case "mismatch":
		// Fail closed for reconciliation: do not auto-credit partial/over payments.
		return PaymentStatusFailed
	case "expired":
		return PaymentStatusExpired
	case "error", "cancelled", "canceled", "cancelled duplicate", "canceled duplicate":
		return PaymentStatusFailed
	default:
		return PaymentStatusPending
	}
}

func parsePlisioCallbackBody(body []byte, headers map[string]string) (map[string]interface{}, error) {
	contentType := strings.ToLower(headers["content-type"])
	trimmed := bytesTrimSpace(body)

	// JSON body (json=true mode)
	if len(trimmed) > 0 && (trimmed[0] == '{' || strings.Contains(contentType, "application/json")) {
		var data map[string]interface{}
		if err := json.Unmarshal(trimmed, &data); err != nil {
			return nil, fmt.Errorf("%w: invalid json callback", ErrInvalidSignature)
		}
		return data, nil
	}

	// form-urlencoded / multipart-ish field body
	values, err := url.ParseQuery(string(body))
	if err != nil {
		return nil, fmt.Errorf("%w: invalid form callback", ErrInvalidSignature)
	}
	data := make(map[string]interface{}, len(values))
	for k, vs := range values {
		if len(vs) > 0 {
			data[k] = vs[0]
		}
	}
	if len(data) == 0 {
		return nil, fmt.Errorf("%w: empty callback", ErrInvalidSignature)
	}
	return data, nil
}

func verifyPlisioHash(data map[string]interface{}, secret, verifyHash string) bool {
	clone := make(map[string]interface{}, len(data))
	for k, v := range data {
		if k == "verify_hash" {
			continue
		}
		// Plisio docs: cast expire_utc to string when present.
		if k == "expire_utc" {
			clone[k] = fmt.Sprint(v)
			continue
		}
		clone[k] = v
	}

	// Compact sorted JSON (non-PHP backends with json=true).
	payload, err := marshalSortedCompactJSON(clone)
	if err != nil {
		return false
	}
	mac := hmac.New(sha1.New, []byte(secret))
	_, _ = mac.Write(payload)
	expected := hex.EncodeToString(mac.Sum(nil))
	return hmac.Equal([]byte(strings.ToLower(expected)), []byte(strings.ToLower(verifyHash)))
}

func marshalSortedCompactJSON(v interface{}) ([]byte, error) {
	switch val := v.(type) {
	case map[string]interface{}:
		keys := make([]string, 0, len(val))
		for k := range val {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		var b strings.Builder
		b.WriteByte('{')
		for i, k := range keys {
			if i > 0 {
				b.WriteByte(',')
			}
			kb, err := json.Marshal(k)
			if err != nil {
				return nil, err
			}
			b.Write(kb)
			b.WriteByte(':')
			vb, err := marshalSortedCompactJSON(val[k])
			if err != nil {
				return nil, err
			}
			b.Write(vb)
		}
		b.WriteByte('}')
		return []byte(b.String()), nil
	case []interface{}:
		var b strings.Builder
		b.WriteByte('[')
		for i, elem := range val {
			if i > 0 {
				b.WriteByte(',')
			}
			eb, err := marshalSortedCompactJSON(elem)
			if err != nil {
				return nil, err
			}
			b.Write(eb)
		}
		b.WriteByte(']')
		return []byte(b.String()), nil
	default:
		return json.Marshal(val)
	}
}

func stringField(data map[string]interface{}, key string) string {
	v, ok := data[key]
	if !ok || v == nil {
		return ""
	}
	switch t := v.(type) {
	case string:
		return t
	case float64:
		// avoid scientific notation for integer-looking IDs
		if t == math.Trunc(t) {
			return strconv.FormatInt(int64(t), 10)
		}
		return strconv.FormatFloat(t, 'f', -1, 64)
	case json.Number:
		return t.String()
	default:
		return fmt.Sprint(t)
	}
}

func parseFloatField(data map[string]interface{}, key string) float64 {
	v, ok := data[key]
	if !ok || v == nil {
		return 0
	}
	switch t := v.(type) {
	case float64:
		return t
	case string:
		f, _ := strconv.ParseFloat(t, 64)
		return f
	case json.Number:
		f, _ := t.Float64()
		return f
	default:
		return 0
	}
}

func parseAmountToCents(v interface{}) int64 {
	switch t := v.(type) {
	case nil:
		return 0
	case float64:
		return int64(math.Round(t * 100))
	case string:
		f, err := strconv.ParseFloat(strings.TrimSpace(t), 64)
		if err != nil {
			return 0
		}
		return int64(math.Round(f * 100))
	case json.Number:
		f, err := t.Float64()
		if err != nil {
			return 0
		}
		return int64(math.Round(f * 100))
	default:
		return 0
	}
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if strings.TrimSpace(v) != "" {
			return v
		}
	}
	return ""
}

func bytesTrimSpace(b []byte) []byte {
	return []byte(strings.TrimSpace(string(b)))
}
