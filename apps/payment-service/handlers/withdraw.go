package handlers

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"net/http"
	"regexp"
	"strings"
	"time"
	"unicode"

	"github.com/go-chi/chi/v5"

	"github.com/Parsaeffatravesh/tragge/packages/auth"
	"github.com/Parsaeffatravesh/tragge/packages/kyc"
	"github.com/Parsaeffatravesh/tragge/packages/validation"
	"github.com/Parsaeffatravesh/tragge/packages/wallet"
	"github.com/google/uuid"
	"go.uber.org/zap"
)

// Manual crypto withdrawals are reviewed and paid by admins outside payment providers.
const manualPayoutProvider = "manual"

// WithdrawHandler handles withdrawal-related requests
type WithdrawHandler struct {
	db            *sql.DB
	walletService *wallet.Service
	kycService    *kyc.Service
	logger        *zap.Logger
	config        *WithdrawConfig
	circuits      DatabaseCircuitExecutor
}

// WithdrawConfig holds configuration for withdrawal operations
type WithdrawConfig struct {
	MinWithdrawCents   int64
	MaxWithdrawCents   int64
	WithdrawFeeCents   int64
	WithdrawFeePercent float64
	// AML withdrawal limits (defaults, per-user overrides in DB)
	DailyWithdrawAmountCents   int64
	MonthlyWithdrawAmountCents int64
	DailyWithdrawCount         int
	MonthlyWithdrawCount       int
}

// NewWithdrawHandler creates a new withdrawal handler.
// registry is accepted for API compatibility with existing call sites but is unused:
// MVP-003 withdrawals are manual and never call payout providers.
func NewWithdrawHandler(db *sql.DB, walletService *wallet.Service, kycService *kyc.Service, _ interface{}, logger *zap.Logger, config *WithdrawConfig, circuits DatabaseCircuitExecutor) *WithdrawHandler {
	return &WithdrawHandler{
		db:            db,
		walletService: walletService,
		kycService:    kycService,
		logger:        logger,
		config:        config,
		circuits:      circuits,
	}
}

// nestedCryptoDetails matches the Mini App / desktop client payload shape.
type nestedCryptoDetails struct {
	Address  string `json:"address"`
	Network  string `json:"network"`
	Currency string `json:"currency"`
}

type nestedBankDetails struct {
	AccountHolder string `json:"account_holder"`
	IBAN          string `json:"iban"`
	BankAccount   string `json:"bank_account"`
	BankName      string `json:"bank_name"`
}

// WithdrawRequest represents the request body for creating a withdrawal
type WithdrawRequest struct {
	AmountCents     int64  `json:"amount_cents"`
	Currency        string `json:"currency,omitempty"`
	DestinationType string `json:"destination_type"` // bank, crypto

	// Bank transfer fields (flat)
	BankAccount   string `json:"bank_account,omitempty"`
	BankName      string `json:"bank_name,omitempty"`
	AccountHolder string `json:"account_holder,omitempty"`

	// Crypto payout fields (flat)
	WalletAddress  string `json:"wallet_address,omitempty"`
	CryptoCurrency string `json:"crypto_currency,omitempty"`
	Network        string `json:"network,omitempty"`

	// Nested shapes used by frontend clients
	CryptoDetails *nestedCryptoDetails `json:"crypto_details,omitempty"`
	BankDetails   *nestedBankDetails   `json:"bank_details,omitempty"`
}

// WithdrawResponse represents the response for creating a withdrawal
type WithdrawResponse struct {
	PayoutID         string `json:"payout_id"`
	AmountCents      int64  `json:"amount_cents"`
	FeeCents         int64  `json:"fee_cents"`
	NetAmountCents   int64  `json:"net_amount_cents"`
	Currency         string `json:"currency"`
	Status           string `json:"status"`
	UserFacingStatus string `json:"user_facing_status"`
	EstimatedTime    string `json:"estimated_time,omitempty"`
	KYCStatus        string `json:"kyc_status,omitempty"`
	KYCMessage       string `json:"kyc_message,omitempty"`
	BalanceCents     int64  `json:"balance_cents,omitempty"`
}

// WithdrawErrorResponse represents an error response for withdrawal requests
type WithdrawErrorResponse struct {
	Error          string `json:"error"`
	Message        string `json:"message,omitempty"`
	KYCStatus      string `json:"kyc_status,omitempty"`
	KYCMessage     string `json:"kyc_message,omitempty"`
	MinimumCents   int64  `json:"minimum_cents,omitempty"`
	AvailableCents int64  `json:"available_cents,omitempty"`
	RequestedCents int64  `json:"requested_cents,omitempty"`
	LimitType      string `json:"limit_type,omitempty"`
	LimitCents     int64  `json:"limit_cents,omitempty"`
	UsedCents      int64  `json:"used_cents,omitempty"`
	LimitCount     int64  `json:"limit_count,omitempty"`
	UsedCount      int64  `json:"used_count,omitempty"`
}

var (
	// TRON base58 address (USDT TRC20)
	trc20AddressPattern = regexp.MustCompile(`^T[1-9A-HJ-NP-Za-km-z]{33}$`)
)

func (req *WithdrawRequest) normalize() {
	req.DestinationType = strings.ToLower(strings.TrimSpace(req.DestinationType))
	req.Currency = strings.ToUpper(strings.TrimSpace(req.Currency))
	req.WalletAddress = strings.TrimSpace(req.WalletAddress)
	req.CryptoCurrency = strings.TrimSpace(req.CryptoCurrency)
	req.Network = strings.TrimSpace(req.Network)
	req.BankAccount = strings.TrimSpace(req.BankAccount)
	req.BankName = strings.TrimSpace(req.BankName)
	req.AccountHolder = strings.TrimSpace(req.AccountHolder)

	if req.CryptoDetails != nil {
		if req.WalletAddress == "" {
			req.WalletAddress = strings.TrimSpace(req.CryptoDetails.Address)
		}
		if req.Network == "" {
			req.Network = strings.TrimSpace(req.CryptoDetails.Network)
		}
		if req.CryptoCurrency == "" {
			req.CryptoCurrency = strings.TrimSpace(req.CryptoDetails.Currency)
		}
	}
	if req.BankDetails != nil {
		if req.AccountHolder == "" {
			req.AccountHolder = strings.TrimSpace(req.BankDetails.AccountHolder)
		}
		if req.BankName == "" {
			req.BankName = strings.TrimSpace(req.BankDetails.BankName)
		}
		if req.BankAccount == "" {
			if req.BankDetails.IBAN != "" {
				req.BankAccount = strings.TrimSpace(req.BankDetails.IBAN)
			} else {
				req.BankAccount = strings.TrimSpace(req.BankDetails.BankAccount)
			}
		}
	}

	// Default crypto asset for Mini App: USDT on TRC20.
	if req.DestinationType == "crypto" {
		if req.Network == "" {
			req.Network = "TRC20"
		}
		if req.CryptoCurrency == "" {
			req.CryptoCurrency = "USDT"
		}
		// Normalize common aliases
		cur := strings.ToUpper(req.CryptoCurrency)
		net := strings.ToUpper(req.Network)
		switch {
		case strings.Contains(cur, "USDT") && (net == "TRC20" || net == "TRON" || net == "TRX"):
			req.CryptoCurrency = "USDT"
			req.Network = "TRC20"
		}
	}
}

// MapPayoutStatusToUserFacing maps internal payout status to product language.
func MapPayoutStatusToUserFacing(status string) string {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "pending":
		return "pending_review"
	case "processing":
		return "processing"
	case "succeeded":
		return "paid"
	case "rejected", "failed", "cancelled":
		return "rejected"
	default:
		return status
	}
}

// HandleCreateWithdraw handles POST /api/payments/withdraw/request
//
// Financial model (MVP manual withdrawals):
//   - Available balance is debited atomically (funds leave spendable balance).
//   - Payout row holds the locked claim until paid or rejected.
//   - Paid: status only (no second debit).
//   - Rejected: single idempotent refund credit.
//
// No automatic provider payout is performed.
func (h *WithdrawHandler) HandleCreateWithdraw(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	userID := auth.GetUserID(ctx)
	if userID == "" {
		writeErrorJSON(w, http.StatusUnauthorized, "authentication required")
		return
	}

	var req WithdrawRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeErrorJSON(w, http.StatusBadRequest, "invalid request body")
		return
	}
	req.normalize()

	idempotencyKey := strings.TrimSpace(r.Header.Get("Idempotency-Key"))
	if len(idempotencyKey) > 128 {
		writeErrorJSON(w, http.StatusBadRequest, "idempotency key too long")
		return
	}

	// Check KYC verification status before processing withdrawal
	kycResult, err := h.kycService.CheckVerification(ctx, userID)
	if err != nil {
		h.logger.Error("Failed to check KYC status", zap.Error(err), zap.String("user_id", userID))
		writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
		return
	}

	if !kycResult.Verified {
		h.logger.Info("Withdrawal blocked: KYC not verified",
			zap.String("user_id", userID),
			zap.String("kyc_status", string(kycResult.Status)))

		writeJSON(w, http.StatusForbidden, WithdrawErrorResponse{
			Error:      "kyc_required",
			Message:    "KYC verification is required for withdrawals",
			KYCStatus:  string(kycResult.Status),
			KYCMessage: kycResult.Message,
		})
		return
	}

	// Check minimum amount first (specific error format)
	if req.AmountCents < h.config.MinWithdrawCents {
		h.logger.Info("Withdrawal blocked: below minimum amount",
			zap.String("user_id", userID),
			zap.Int64("amount_cents", req.AmountCents),
			zap.Int64("minimum_cents", h.config.MinWithdrawCents))

		minDollars := float64(h.config.MinWithdrawCents) / 100.0
		writeJSON(w, http.StatusBadRequest, WithdrawErrorResponse{
			Error:        "minimum_amount",
			Message:      fmt.Sprintf("Minimum withdrawal is $%.2f", minDollars),
			MinimumCents: h.config.MinWithdrawCents,
		})
		return
	}

	// Check withdrawal limits (AML compliance)
	limitErr := h.walletService.CheckWithdrawalLimits(ctx, userID, req.AmountCents, wallet.WithdrawalLimits{
		DailyAmountCents:   h.config.DailyWithdrawAmountCents,
		MonthlyAmountCents: h.config.MonthlyWithdrawAmountCents,
		DailyCount:         h.config.DailyWithdrawCount,
		MonthlyCount:       h.config.MonthlyWithdrawCount,
	})
	if limitErr != nil {
		if limitExceeded, ok := limitErr.(*wallet.WithdrawalLimitExceededError); ok {
			h.logger.Info("Withdrawal blocked: limit exceeded",
				zap.String("user_id", userID),
				zap.String("limit_type", limitExceeded.LimitType),
				zap.Int64("limit_value", limitExceeded.LimitValue),
				zap.Int64("current_usage", limitExceeded.CurrentUsage),
				zap.Int64("requested", limitExceeded.RequestedValue))

			resp := WithdrawErrorResponse{
				Error:   "withdrawal_limit_exceeded",
				Message: limitExceeded.Error(),
			}
			switch limitExceeded.LimitType {
			case "daily_amount", "monthly_amount":
				resp.LimitType = limitExceeded.LimitType
				resp.LimitCents = limitExceeded.LimitValue
				resp.UsedCents = limitExceeded.CurrentUsage
				resp.RequestedCents = limitExceeded.RequestedValue
			case "daily_count", "monthly_count":
				resp.LimitType = limitExceeded.LimitType
				resp.LimitCount = limitExceeded.LimitValue
				resp.UsedCount = limitExceeded.CurrentUsage
			}
			writeJSON(w, http.StatusTooManyRequests, resp)
			return
		}
		h.logger.Error("Failed to check withdrawal limits", zap.Error(limitErr))
		writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
		return
	}

	// Validate request
	v := validation.New()

	if req.AmountCents > h.config.MaxWithdrawCents {
		v.AddError("amount_cents", "max_withdraw", "amount exceeds maximum")
	}

	if req.DestinationType != "bank" && req.DestinationType != "crypto" {
		v.AddError("destination_type", "invalid_destination", "must be 'bank' or 'crypto'")
	}

	if req.DestinationType == "bank" {
		v.Required("bank_account", req.BankAccount)
		v.Required("account_holder", req.AccountHolder)
	}

	if req.DestinationType == "crypto" {
		v.Required("wallet_address", req.WalletAddress)
		v.Required("crypto_currency", req.CryptoCurrency)
		if req.Network == "TRC20" || strings.EqualFold(req.CryptoCurrency, "USDT") {
			if !trc20AddressPattern.MatchString(req.WalletAddress) {
				v.AddError("wallet_address", "invalid_address", "invalid USDT TRC20 wallet address")
			}
		} else if len(req.WalletAddress) < 10 || len(req.WalletAddress) > 128 {
			v.AddError("wallet_address", "invalid_address", "invalid wallet address length")
		}
	}

	if v.HasErrors() {
		validation.WriteValidationError(w, v.Errors())
		return
	}

	// Calculate fee using integer arithmetic to avoid float precision issues.
	feeCents := h.config.WithdrawFeeCents
	if h.config.WithdrawFeePercent > 0 {
		feeBasisPoints := int64(math.Round(h.config.WithdrawFeePercent * 100))
		feeCents += req.AmountCents * feeBasisPoints / 10000
	}
	totalDeductCents := req.AmountCents + feeCents
	netAmountCents := req.AmountCents

	payoutID := uuid.New().String()

	currency := req.Currency
	if currency == "" {
		currency = "USD"
	}

	// Begin transaction (protected by circuit breaker)
	var tx *sql.Tx
	err = h.circuits.ExecuteDatabase(ctx, func(ctx context.Context) error {
		var e error
		tx, e = h.db.BeginTx(ctx, nil)
		return e
	})
	if err != nil {
		h.logger.Error("Failed to begin transaction", zap.Error(err))
		writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
		return
	}
	defer tx.Rollback()

	// Idempotent replay: return existing payout if same key already succeeded.
	if idempotencyKey != "" {
		var existingID, existingStatus string
		var existingAmount, existingFee int64
		var existingCurrency string
		var existingBalance int64
		scanErr := tx.QueryRowContext(ctx, `
			SELECT p.id, p.status, p.amount_cents, p.currency,
			       COALESCE((p.metadata_json->>'fee_cents')::bigint, 0),
			       COALESCE(w.balance_cents, 0)
			FROM payouts p
			LEFT JOIN wallets w ON w.user_id = p.user_id
			WHERE p.user_id = $1 AND p.idempotency_key = $2
			FOR UPDATE OF p
		`, userID, idempotencyKey).Scan(&existingID, &existingStatus, &existingAmount, &existingCurrency, &existingFee, &existingBalance)
		if scanErr == nil {
			_ = tx.Commit()
			writeJSON(w, http.StatusOK, WithdrawResponse{
				PayoutID:         existingID,
				AmountCents:      existingAmount + existingFee,
				FeeCents:         existingFee,
				NetAmountCents:   existingAmount,
				Currency:         existingCurrency,
				Status:           existingStatus,
				UserFacingStatus: MapPayoutStatusToUserFacing(existingStatus),
				EstimatedTime:    "manual review",
				BalanceCents:     existingBalance,
			})
			return
		}
		if !errors.Is(scanErr, sql.ErrNoRows) {
			h.logger.Error("Failed to check withdrawal idempotency", zap.Error(scanErr))
			writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
			return
		}
	}

	txWrapper := &wallet.TxAdapter{Tx: tx}

	// Lock wallet and verify balance for amount + fee before any debits.
	balance, balErr := h.walletService.GetBalanceTx(ctx, txWrapper, userID)
	if balErr != nil {
		if _, ok := balErr.(*wallet.WalletFrozenError); ok {
			writeJSON(w, http.StatusForbidden, WithdrawErrorResponse{
				Error:   "wallet_frozen",
				Message: "Your wallet is frozen and cannot process withdrawals",
			})
			return
		}
		if _, ok := balErr.(*wallet.WalletNotFoundError); ok {
			writeJSON(w, http.StatusBadRequest, WithdrawErrorResponse{
				Error:   "insufficient_balance",
				Message: "Wallet not found",
			})
			return
		}
		h.logger.Error("Failed to check balance", zap.Error(balErr))
		writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
		return
	}
	if balance < totalDeductCents {
		writeJSON(w, http.StatusBadRequest, WithdrawErrorResponse{
			Error:          "insufficient_balance",
			Message:        "Insufficient balance for this withdrawal including fees",
			AvailableCents: balance,
			RequestedCents: totalDeductCents,
		})
		return
	}

	// Debit withdrawal amount from wallet (available → locked claim)
	refType := wallet.LedgerRefTypePayout
	withdrawDesc := "Withdrawal request (funds held for review)"
	_, err = h.walletService.Debit(ctx, txWrapper, userID, req.AmountCents, wallet.LedgerTypeWithdrawal, &refType, &payoutID, &withdrawDesc)
	if err != nil {
		if insufficientErr, ok := err.(*wallet.InsufficientBalanceError); ok {
			writeJSON(w, http.StatusBadRequest, WithdrawErrorResponse{
				Error:          "insufficient_balance",
				Message:        "Insufficient balance for this withdrawal",
				AvailableCents: insufficientErr.Available,
				RequestedCents: totalDeductCents,
			})
			return
		}
		if _, ok := err.(*wallet.WalletFrozenError); ok {
			writeJSON(w, http.StatusForbidden, WithdrawErrorResponse{
				Error:   "wallet_frozen",
				Message: "Your wallet is frozen and cannot process withdrawals",
			})
			return
		}
		h.logger.Error("Failed to debit wallet", zap.Error(err))
		writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
		return
	}

	if feeCents > 0 {
		feeDesc := "Withdrawal fee"
		_, err = h.walletService.Debit(ctx, txWrapper, userID, feeCents, wallet.LedgerTypeWithdrawFee, &refType, &payoutID, &feeDesc)
		if err != nil {
			if insufficientErr, ok := err.(*wallet.InsufficientBalanceError); ok {
				writeJSON(w, http.StatusBadRequest, WithdrawErrorResponse{
					Error:          "insufficient_balance",
					Message:        "Insufficient balance for withdrawal fee",
					AvailableCents: insufficientErr.Available,
					RequestedCents: totalDeductCents,
				})
				return
			}
			h.logger.Error("Failed to debit withdrawal fee", zap.Error(err))
			writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
			return
		}
	}

	now := time.Now()

	destinationInfo := map[string]string{
		"destination_type": req.DestinationType,
	}
	if req.DestinationType == "bank" {
		destinationInfo["bank_account"] = req.BankAccount
		destinationInfo["bank_name"] = req.BankName
		destinationInfo["account_holder"] = req.AccountHolder
	} else {
		destinationInfo["wallet_address"] = req.WalletAddress
		destinationInfo["crypto_currency"] = req.CryptoCurrency
		destinationInfo["network"] = req.Network
	}
	destinationJSON, _ := json.Marshal(destinationInfo)

	metadataJSON, _ := json.Marshal(map[string]interface{}{
		"fee_cents":        feeCents,
		"gross_amount":     req.AmountCents,
		"net_amount":       netAmountCents,
		"manual_payout":    true,
		"payout_mode":      "manual_admin_review",
		"idempotency_key":  idempotencyKey,
	})

	var idempArg interface{}
	if idempotencyKey != "" {
		idempArg = idempotencyKey
	}

	_, err = tx.ExecContext(ctx, `
		INSERT INTO payouts (
			id, user_id, amount_cents, currency, status, provider,
			destination_type, destination_info_json, metadata_json,
			idempotency_key, created_at, updated_at
		)
		VALUES ($1, $2, $3, $4, 'pending', $5, $6, $7, $8, $9, $10, $10)
	`, payoutID, userID, netAmountCents, currency, manualPayoutProvider, req.DestinationType, destinationJSON, metadataJSON, idempArg, now)
	if err != nil {
		// Unique violation on idempotency key: concurrent duplicate.
		if strings.Contains(strings.ToLower(err.Error()), "idx_payouts_user_idempotency") ||
			strings.Contains(strings.ToLower(err.Error()), "duplicate key") {
			writeErrorJSON(w, http.StatusConflict, "duplicate withdrawal request")
			return
		}
		h.logger.Error("Failed to create payout record", zap.Error(err))
		writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
		return
	}

	// Best-effort audit (same transaction when table exists)
	auditPayload, _ := json.Marshal(map[string]interface{}{
		"payout_id":        payoutID,
		"amount_cents":     req.AmountCents,
		"fee_cents":        feeCents,
		"destination_type": req.DestinationType,
		"provider":         manualPayoutProvider,
	})
	_, _ = tx.ExecContext(ctx, `
		INSERT INTO audit_logs (actor_user_id, action, target_type, target_id, payload_json)
		VALUES ($1, $2, $3, $4, $5)
	`, userID, "withdrawal.created", "payout", payoutID, auditPayload)

	newBalance, _ := h.walletService.GetBalanceTx(ctx, txWrapper, userID)

	if err := tx.Commit(); err != nil {
		h.logger.Error("Failed to commit transaction", zap.Error(err))
		writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
		return
	}

	h.logger.Info("Withdrawal request created",
		zap.String("payout_id", payoutID),
		zap.String("user_id", userID),
		zap.Int64("amount_cents", req.AmountCents),
		zap.Int64("fee_cents", feeCents),
		zap.String("destination_type", req.DestinationType),
		zap.String("provider", manualPayoutProvider))

	writeJSON(w, http.StatusCreated, WithdrawResponse{
		PayoutID:         payoutID,
		AmountCents:      req.AmountCents,
		FeeCents:         feeCents,
		NetAmountCents:   netAmountCents,
		Currency:         currency,
		Status:           "pending",
		UserFacingStatus: MapPayoutStatusToUserFacing("pending"),
		EstimatedTime:    "manual admin review",
		KYCStatus:        string(kycResult.Status),
		KYCMessage:       "KYC verified",
		BalanceCents:     newBalance,
	})
}

// HandleListWithdrawals handles GET /api/payments/withdraw/list
// Returns the authenticated user's withdrawals only.
func (h *WithdrawHandler) HandleListWithdrawals(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	userID := auth.GetUserID(ctx)
	if userID == "" {
		writeErrorJSON(w, http.StatusUnauthorized, "authentication required")
		return
	}

	limit := 50
	offset := 0
	if v := r.URL.Query().Get("limit"); v != "" {
		if n, err := fmt.Sscanf(v, "%d", &limit); n == 1 && err == nil {
			if limit <= 0 {
				limit = 50
			}
			if limit > 100 {
				limit = 100
			}
		}
	}
	if v := r.URL.Query().Get("offset"); v != "" {
		if n, err := fmt.Sscanf(v, "%d", &offset); n == 1 && err == nil && offset < 0 {
			offset = 0
		}
	}

	type item struct {
		PayoutID         string  `json:"payout_id"`
		AmountCents      int64   `json:"amount_cents"`
		Currency         string  `json:"currency"`
		Status           string  `json:"status"`
		UserFacingStatus string  `json:"user_facing_status"`
		DestinationType  string  `json:"destination_type,omitempty"`
		Network          string  `json:"network,omitempty"`
		WalletAddress    string  `json:"wallet_address,omitempty"`
		AdminNote        string  `json:"admin_note,omitempty"`
		TransactionID    string  `json:"transaction_id,omitempty"`
		CreatedAt        string  `json:"created_at"`
		CompletedAt      *string `json:"completed_at,omitempty"`
	}

	rows, err := h.db.QueryContext(ctx, `
		SELECT id, amount_cents, currency, status, COALESCE(destination_type, ''),
		       destination_info_json, admin_comment, transaction_id, created_at, completed_at
		FROM payouts
		WHERE user_id = $1
		ORDER BY created_at DESC
		LIMIT $2 OFFSET $3
	`, userID, limit, offset)
	if err != nil {
		h.logger.Error("Failed to list withdrawals", zap.Error(err))
		writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
		return
	}
	defer rows.Close()

	out := make([]item, 0, limit)
	for rows.Next() {
		var (
			id, currency, status, destType string
			amount                         int64
			destJSON                       []byte
			adminComment, txID             sql.NullString
			createdAt                      time.Time
			completedAt                    sql.NullTime
		)
		if err := rows.Scan(&id, &amount, &currency, &status, &destType, &destJSON, &adminComment, &txID, &createdAt, &completedAt); err != nil {
			h.logger.Error("Failed to scan withdrawal", zap.Error(err))
			continue
		}
		it := item{
			PayoutID:         id,
			AmountCents:      amount,
			Currency:         currency,
			Status:           status,
			UserFacingStatus: MapPayoutStatusToUserFacing(status),
			DestinationType:  destType,
			CreatedAt:        createdAt.UTC().Format(time.RFC3339),
		}
		if len(destJSON) > 0 {
			var dest map[string]string
			if json.Unmarshal(destJSON, &dest) == nil {
				it.Network = dest["network"]
				it.WalletAddress = dest["wallet_address"]
			}
		}
		// User-visible notes only for terminal outcomes.
		if adminComment.Valid && (status == "rejected" || status == "failed" || status == "succeeded") {
			it.AdminNote = sanitizeUserVisibleNote(adminComment.String)
		}
		if txID.Valid {
			it.TransactionID = txID.String
		}
		if completedAt.Valid {
			s := completedAt.Time.UTC().Format(time.RFC3339)
			it.CompletedAt = &s
		}
		out = append(out, it)
	}

	writeJSON(w, http.StatusOK, map[string]interface{}{
		"withdrawals": out,
		"limit":       limit,
		"offset":      offset,
	})
}

// HandleGetWithdrawStatus handles GET /api/payments/withdraw/{id}/status
func (h *WithdrawHandler) HandleGetWithdrawStatus(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	userID := auth.GetUserID(ctx)
	if userID == "" {
		writeErrorJSON(w, http.StatusUnauthorized, "authentication required")
		return
	}

	payoutID := chi.URLParam(r, "id")
	if payoutID == "" {
		writeErrorJSON(w, http.StatusBadRequest, "payout id is required")
		return
	}

	var payout struct {
		ID              string
		UserID          string
		AmountCents     int64
		Currency        string
		Status          string
		DestinationType string
		DestJSON        []byte
		CompletedAt     sql.NullTime
		MetadataJSON    sql.NullString
		AdminComment    sql.NullString
		TransactionID   sql.NullString
		CreatedAt       time.Time
	}

	err := h.circuits.ExecuteDatabase(ctx, func(ctx context.Context) error {
		return h.db.QueryRowContext(ctx, `
			SELECT id, user_id, amount_cents, currency, status,
			       COALESCE(destination_type, ''), COALESCE(destination_info_json, '{}'::jsonb),
			       completed_at, metadata_json, admin_comment, transaction_id, created_at
			FROM payouts
			WHERE id = $1
		`, payoutID).Scan(
			&payout.ID, &payout.UserID, &payout.AmountCents,
			&payout.Currency, &payout.Status, &payout.DestinationType, &payout.DestJSON,
			&payout.CompletedAt, &payout.MetadataJSON, &payout.AdminComment, &payout.TransactionID, &payout.CreatedAt,
		)
	})
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			writeErrorJSON(w, http.StatusNotFound, "payout not found")
			return
		}
		h.logger.Error("Failed to get payout", zap.Error(err))
		writeErrorJSON(w, http.StatusInternalServerError, "internal server error")
		return
	}

	// Ownership — never leak other users' withdrawals.
	if payout.UserID != userID {
		writeErrorJSON(w, http.StatusForbidden, "access denied")
		return
	}

	response := map[string]interface{}{
		"payout_id":          payout.ID,
		"amount_cents":       payout.AmountCents,
		"currency":           payout.Currency,
		"status":             payout.Status,
		"user_facing_status": MapPayoutStatusToUserFacing(payout.Status),
		"destination_type":   payout.DestinationType,
		"created_at":         payout.CreatedAt.UTC().Format(time.RFC3339),
	}

	if len(payout.DestJSON) > 0 {
		var dest map[string]string
		if json.Unmarshal(payout.DestJSON, &dest) == nil {
			if dest["network"] != "" {
				response["network"] = dest["network"]
			}
			if dest["wallet_address"] != "" {
				response["wallet_address"] = dest["wallet_address"]
			}
			if dest["crypto_currency"] != "" {
				response["crypto_currency"] = dest["crypto_currency"]
			}
		}
	}

	if payout.CompletedAt.Valid {
		response["completed_at"] = payout.CompletedAt.Time.Format(time.RFC3339)
	}

	if payout.MetadataJSON.Valid {
		var metadata map[string]interface{}
		if err := json.Unmarshal([]byte(payout.MetadataJSON.String), &metadata); err == nil {
			if feeCents, ok := metadata["fee_cents"].(float64); ok {
				response["fee_cents"] = int64(feeCents)
			}
		}
	}

	// User-visible admin note on terminal states only.
	if payout.AdminComment.Valid && (payout.Status == "rejected" || payout.Status == "failed" || payout.Status == "succeeded") {
		response["admin_note"] = sanitizeUserVisibleNote(payout.AdminComment.String)
		// legacy alias
		response["failure_reason"] = response["admin_note"]
	}

	if payout.TransactionID.Valid && payout.TransactionID.String != "" {
		response["transaction_id"] = payout.TransactionID.String
		// Product wording: recorded payout reference (not chain-verified).
		response["payout_reference"] = payout.TransactionID.String
	}

	writeJSON(w, http.StatusOK, response)
}

func sanitizeUserVisibleNote(note string) string {
	// Strip any " | Tx: ..." suffix used historically so users see the admin note cleanly.
	if idx := strings.Index(note, " | Tx: "); idx >= 0 {
		note = note[:idx]
	}
	note = strings.TrimSpace(note)
	// Prevent control characters from leaking into UI.
	return strings.Map(func(r rune) rune {
		if unicode.IsControl(r) && r != '\n' && r != '\t' {
			return -1
		}
		return r
	}, note)
}
