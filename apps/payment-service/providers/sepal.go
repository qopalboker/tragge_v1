package providers

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

// Sepal implements the Provider interface for Sepal.ir online payment gateway (IRR).
// Official docs: https://sepal.ir/static/api-pay
//
// Sandbox (staging):
//
//	apiKey = "test" (or configured key)
//	POST https://sepal.ir/api/sandbox/request.json
//	GET  https://sepal.ir/sandbox/payment/{paymentNumber}
//	POST https://sepal.ir/api/sandbox/verify.json
//
// Production:
//
//	POST https://sepal.ir/api/request.json
//	GET  https://sepal.ir/payment/{paymentNumber}
//	POST https://sepal.ir/api/verify.json
//
// Amounts on CreatePayment are Iranian Rials (integer). Callers convert USD→IRR.
type Sepal struct {
	apiKey     string
	baseURL    string
	sandbox    bool
	httpClient *http.Client
	circuit    CircuitExecutor
}

// SepalConfig configures the Sepal provider.
type SepalConfig struct {
	APIKey  string
	BaseURL string
	Sandbox bool
	Circuit CircuitExecutor
}

// NewSepal creates a Sepal provider.
func NewSepal(cfg SepalConfig) *Sepal {
	base := strings.TrimRight(strings.TrimSpace(cfg.BaseURL), "/")
	if base == "" {
		base = "https://sepal.ir"
	}
	return &Sepal{
		apiKey:  strings.TrimSpace(cfg.APIKey),
		baseURL: base,
		sandbox: cfg.Sandbox,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
		circuit: cfg.Circuit,
	}
}

func (s *Sepal) doHTTP(ctx context.Context, req *http.Request) (*http.Response, error) {
	if s.circuit == nil {
		return s.httpClient.Do(req)
	}
	var resp *http.Response
	err := s.circuit.ExecuteWithContext(ctx, func(_ context.Context) error {
		var e error
		resp, e = s.httpClient.Do(req)
		return e
	})
	return resp, err
}

func (s *Sepal) Name() ProviderType { return ProviderSepal }

// IsSandbox reports whether Sepal is in sandbox/test mode.
func (s *Sepal) IsSandbox() bool { return s != nil && s.sandbox }

func (s *Sepal) IsAvailable(ctx context.Context) bool {
	if s == nil || s.apiKey == "" {
		return false
	}
	// Production must not use the public sandbox key.
	if !s.sandbox && strings.EqualFold(s.apiKey, "test") {
		return false
	}
	return true
}

func (s *Sepal) SupportedCurrencies() []string { return []string{"IRR"} }

func (s *Sepal) requestURL() string {
	if s.sandbox {
		return s.baseURL + "/api/sandbox/request.json"
	}
	return s.baseURL + "/api/request.json"
}

func (s *Sepal) verifyURL() string {
	if s.sandbox {
		return s.baseURL + "/api/sandbox/verify.json"
	}
	return s.baseURL + "/api/verify.json"
}

func (s *Sepal) paymentPageURL(paymentNumber string) string {
	if s.sandbox {
		return s.baseURL + "/sandbox/payment/" + paymentNumber
	}
	return s.baseURL + "/payment/" + paymentNumber
}

// CreatePayment creates a Sepal invoice. AmountCents is IRR rials (integer).
func (s *Sepal) CreatePayment(ctx context.Context, req *CreatePaymentRequest) (*CreatePaymentResponse, error) {
	if !s.IsAvailable(ctx) {
		return nil, ErrProviderUnavailable
	}
	if req.AmountCents < 1 {
		return nil, ErrInvalidAmount
	}
	if req.OrderID == "" {
		return nil, fmt.Errorf("order_id is required")
	}
	callbackURL := req.IPNCallbackURL
	if callbackURL == "" {
		callbackURL = req.CallbackURL
	}
	if callbackURL == "" {
		return nil, fmt.Errorf("callback_url is required")
	}

	payload := map[string]interface{}{
		"apiKey":        s.apiKey,
		"amount":        req.AmountCents,
		"callbackUrl":   callbackURL,
		"invoiceNumber": req.OrderID,
		"description":   firstNonEmpty(req.Description, "Tragge Wallet Deposit"),
	}
	if req.CustomerPhone != "" {
		payload["payerMobile"] = req.CustomerPhone
	}
	if req.CustomerEmail != "" {
		payload["payerEmail"] = req.CustomerEmail
	}

	body, err := json.Marshal(payload)
	if err != nil {
		return nil, err
	}
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, s.requestURL(), bytes.NewReader(body))
	if err != nil {
		return nil, fmt.Errorf("create sepal request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")

	resp, err := s.doHTTP(ctx, httpReq)
	if err != nil {
		return nil, fmt.Errorf("sepal request failed: %w", err)
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("read sepal response: %w", err)
	}

	var envelope struct {
		Status        interface{} `json:"status"`
		Message       string      `json:"message"`
		PaymentNumber interface{} `json:"paymentNumber"`
	}
	if err := json.Unmarshal(raw, &envelope); err != nil {
		return nil, fmt.Errorf("parse sepal response: %w", err)
	}
	if !sepalStatusOK(envelope.Status) {
		msg := strings.TrimSpace(envelope.Message)
		if msg == "" {
			msg = "sepal request failed"
		}
		return nil, fmt.Errorf("sepal error: %s", msg)
	}
	paymentNumber := sepalPaymentNumberString(envelope.PaymentNumber)
	if paymentNumber == "" {
		return nil, fmt.Errorf("sepal missing paymentNumber")
	}

	return &CreatePaymentResponse{
		ProviderPaymentID: paymentNumber,
		PaymentURL:        s.paymentPageURL(paymentNumber),
		PayAmount:         float64(req.AmountCents),
		PayCurrency:       "IRR",
		Status:            PaymentStatusPending,
		Metadata: map[string]string{
			"provider":       string(ProviderSepal),
			"invoice_number": req.OrderID,
			"amount_irr":     strconv.FormatInt(req.AmountCents, 10),
			"sandbox":        strconv.FormatBool(s.sandbox),
		},
	}, nil
}

// GetPaymentStatus returns pending without external polling (callback+verify is authoritative).
func (s *Sepal) GetPaymentStatus(ctx context.Context, providerPaymentID string) (*PaymentStatusResponse, error) {
	if providerPaymentID == "" {
		return nil, ErrPaymentNotFound
	}
	return &PaymentStatusResponse{
		ProviderPaymentID: providerPaymentID,
		Status:            PaymentStatusPending,
		Currency:          "IRR",
	}, nil
}

// VerifyWebhook validates Sepal callback via server-side verify.json.
// Never credit based on browser redirect alone.
func (s *Sepal) VerifyWebhook(ctx context.Context, headers map[string]string, body []byte) (*WebhookEvent, error) {
	if !s.IsAvailable(ctx) {
		return nil, ErrProviderUnavailable
	}
	data, err := parseSepalCallbackBody(body, headers)
	if err != nil {
		return nil, err
	}

	paymentNumber := firstNonEmpty(stringField(data, "paymentNumber"), stringField(data, "payment_number"))
	invoiceNumber := firstNonEmpty(
		stringField(data, "invoiceNumber"),
		stringField(data, "invoice_number"),
		stringField(data, "order_id"),
	)
	statusRaw := firstNonEmpty(stringField(data, "status"), stringField(data, "Status"))
	if paymentNumber == "" {
		return nil, fmt.Errorf("%w: missing paymentNumber", ErrInvalidSignature)
	}

	mapped := mapSepalCallbackStatus(statusRaw)
	if mapped == PaymentStatusFinished {
		if err := s.verifyWithProvider(ctx, paymentNumber, invoiceNumber); err != nil {
			return nil, err
		}
	}

	amountIRR := parseAmountToCents(data["amount"])
	if amountIRR == 0 {
		amountIRR = parseAmountToCents(stringField(data, "amount"))
	}

	return &WebhookEvent{
		Provider:          ProviderSepal,
		ProviderPaymentID: paymentNumber,
		OrderID:           invoiceNumber,
		Status:            mapped,
		AmountCents:       amountIRR,
		Currency:          "IRR",
		RawData:           data,
	}, nil
}

func (s *Sepal) verifyWithProvider(ctx context.Context, paymentNumber, invoiceNumber string) error {
	payload := map[string]interface{}{
		"apiKey":        s.apiKey,
		"paymentNumber": paymentNumber,
	}
	if invoiceNumber != "" {
		payload["invoiceNumber"] = invoiceNumber
	}
	body, _ := json.Marshal(payload)
	httpReq, err := http.NewRequestWithContext(ctx, http.MethodPost, s.verifyURL(), bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("sepal verify request: %w", err)
	}
	httpReq.Header.Set("Content-Type", "application/json")
	resp, err := s.doHTTP(ctx, httpReq)
	if err != nil {
		return fmt.Errorf("sepal verify failed: %w", err)
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("read sepal verify: %w", err)
	}
	var envelope struct {
		Status  interface{} `json:"status"`
		Message string      `json:"message"`
	}
	if err := json.Unmarshal(raw, &envelope); err != nil {
		return fmt.Errorf("%w: invalid verify response", ErrInvalidSignature)
	}
	if !sepalStatusOK(envelope.Status) {
		return fmt.Errorf("%w: sepal verify rejected", ErrInvalidSignature)
	}
	return nil
}

func (s *Sepal) CreatePayout(ctx context.Context, req *PayoutRequest) (*PayoutResponse, error) {
	return nil, fmt.Errorf("sepal payouts are not supported")
}
func (s *Sepal) GetPayoutStatus(ctx context.Context, providerPayoutID string) (*PayoutResponse, error) {
	return nil, fmt.Errorf("sepal payouts are not supported")
}
func (s *Sepal) RefundPayment(ctx context.Context, req *RefundRequest) (*RefundResponse, error) {
	return nil, fmt.Errorf("sepal refunds are not supported")
}
func (s *Sepal) ReversePayment(ctx context.Context, purchaseID string) (*RefundResponse, error) {
	return nil, fmt.Errorf("sepal reverse is not supported")
}

func sepalPaymentNumberString(v interface{}) string {
	switch t := v.(type) {
	case nil:
		return ""
	case string:
		return strings.TrimSpace(t)
	case float64:
		// JSON numbers decode as float64 — avoid scientific notation for IDs.
		return strconv.FormatInt(int64(t), 10)
	case json.Number:
		return t.String()
	case int64:
		return strconv.FormatInt(t, 10)
	case int:
		return strconv.Itoa(t)
	default:
		s := strings.TrimSpace(fmt.Sprint(t))
		if s == "<nil>" {
			return ""
		}
		return s
	}
}

func sepalStatusOK(v interface{}) bool {
	switch t := v.(type) {
	case bool:
		return t
	case float64:
		return t == 1
	case string:
		s := strings.ToLower(strings.TrimSpace(t))
		return s == "1" || s == "true" || s == "success" || s == "ok"
	case json.Number:
		n, _ := t.Int64()
		return n == 1
	default:
		return false
	}
}

func mapSepalCallbackStatus(status string) PaymentStatus {
	s := strings.ToLower(strings.TrimSpace(status))
	switch s {
	case "1", "true", "success", "ok", "paid", "completed":
		return PaymentStatusFinished
	case "0", "false", "failed", "error", "canceled", "cancelled":
		return PaymentStatusFailed
	default:
		if sepalStatusOK(status) {
			return PaymentStatusFinished
		}
		return PaymentStatusPending
	}
}

func parseSepalCallbackBody(body []byte, headers map[string]string) (map[string]interface{}, error) {
	contentType := strings.ToLower(headers["content-type"])
	trimmed := bytesTrimSpace(body)
	if len(trimmed) == 0 {
		return nil, fmt.Errorf("%w: empty callback", ErrInvalidSignature)
	}
	if trimmed[0] == '{' || strings.Contains(contentType, "application/json") {
		var data map[string]interface{}
		if err := json.Unmarshal(trimmed, &data); err != nil {
			return nil, fmt.Errorf("%w: invalid json callback", ErrInvalidSignature)
		}
		return data, nil
	}
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
