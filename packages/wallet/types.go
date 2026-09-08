// Package wallet provides wallet management for the tragge trading platform.
//
// Features:
//   - User wallet balance management
//   - Ledger entries for all transactions
//   - Contest entry fee deductions
//   - Prize credit operations
//
// Example usage:
//
//	svc := wallet.NewService(db)
//
//	// Get wallet balance
//	balance, err := svc.GetBalance(ctx, userID)
//
//	// Deduct entry fee for contest
//	err := svc.DeductContestEntryFee(ctx, tx, userID, contestID, entryFeeCents)
//
//	// Credit prize winnings
//	err := svc.CreditPrize(ctx, tx, userID, contestID, prizeCents)
package wallet

import (
	"time"
)

// SuperAdminTreasuryPurpose is the durable, system-owned custody account key.
// It is deliberately not a user ID and cannot be supplied by API callers.
const SuperAdminTreasuryPurpose = "super_admin_treasury"

// TreasuryReconciliationForwardOnly marks the account as containing only
// qualifying deposits posted after TREASURY-001. It is not a reconciled view of
// historical platform custody.
const TreasuryReconciliationForwardOnly = "forward_only_unreconciled"

// ContestFeeWalletPurpose is the stable system identity for contest-fee
// revenue. It is not a user ID and is never accepted from public input.
const ContestFeeWalletPurpose = "contest_fee_wallet"

// ContestFundsPolicyVersion records the economics policy used by fee postings.
const ContestFundsPolicyVersion = "2026-09-06.1"

// ContestPrizePoolPolicyV1 is the explicit forward-only custody boundary.
const ContestPrizePoolPolicyV1 = "contest_funds_v1"

type ContestPrizePoolEntry struct {
	ID                string    `json:"id"`
	AmountCents       int64     `json:"amount_cents"`
	Direction         string    `json:"direction"`
	Reason            string    `json:"reason"`
	ReferenceType     string    `json:"reference_type"`
	ReferenceID       string    `json:"reference_id"`
	ParticipantUserID string    `json:"participant_user_id"`
	IdempotencyKey    string    `json:"idempotency_key"`
	CreatedAt         time.Time `json:"created_at"`
}

type ContestPrizePoolView struct {
	ContestID     string                  `json:"contest_id"`
	PoolAccountID string                  `json:"pool_account_id"`
	BalanceCents  int64                   `json:"balance_cents"`
	Status        string                  `json:"status"`
	CreatedAt     time.Time               `json:"created_at"`
	Entries       []ContestPrizePoolEntry `json:"entries"`
}

type ContestReversal struct {
	WalletOriginalID string
	WalletReversalID string
	WalletCents      int64
	FeeCents         int64
	PrizePoolCents   int64
	TreasuryCents    int64
}

// ContestFeeKind is deliberately closed to canonical contest-fee classes.
type ContestFeeKind string

const (
	ContestFeeKindBase          ContestFeeKind = "contest_base_fee"
	ContestFeeKindLateSurcharge ContestFeeKind = "contest_late_surcharge"
)

type ContestFeeEntry struct {
	ID                string         `json:"id"`
	Kind              ContestFeeKind `json:"kind"`
	AmountCents       int64          `json:"amount_cents"`
	BalanceAfterCents int64          `json:"balance_after_cents"`
	ContestID         string         `json:"contest_id"`
	ParticipantUserID string         `json:"participant_user_id"`
	AdmissionID       string         `json:"admission_id"`
	PolicyVersion     string         `json:"policy_version"`
	PlatformFeeBps    int            `json:"platform_fee_bps"`
	OriginalEntryID   *string        `json:"original_entry_id,omitempty"`
	CreatedAt         time.Time      `json:"created_at"`
}

type ContestFeeWalletView struct {
	BalanceCents        int64             `json:"balance_cents"`
	BaseFeeTotalCents   int64             `json:"base_fee_total_cents"`
	SurchargeTotalCents int64             `json:"late_surcharge_total_cents"`
	ReversalTotalCents  int64             `json:"reversal_total_cents"`
	TotalEntries        int               `json:"total_entries"`
	Entries             []ContestFeeEntry `json:"entries"`
}

// WalletStatus represents the status of a wallet.
type WalletStatus string

const (
	WalletStatusActive WalletStatus = "active"
	WalletStatusFrozen WalletStatus = "frozen"
	WalletStatusClosed WalletStatus = "closed"
)

// LedgerType represents the type of ledger entry.
type LedgerType string

const (
	LedgerTypeDeposit             LedgerType = "deposit"
	LedgerTypeAdminFundedDeposit  LedgerType = "admin_funded_deposit" // FIN-006: Admin Panel top-ups (not gateway revenue)
	LedgerTypeWithdrawal          LedgerType = "withdrawal"
	LedgerTypeContestEntry        LedgerType = "contest_entry"
	LedgerTypeContestRefund       LedgerType = "contest_refund"
	LedgerTypePrizeCredit         LedgerType = "prize_credit"
	LedgerTypeAdjustment          LedgerType = "adjustment"
	LedgerTypeAffiliateCommission LedgerType = "affiliate_commission"
	LedgerTypeWithdrawFee         LedgerType = "withdraw_fee"
	LedgerTypeWithdrawalRefund    LedgerType = "withdrawal_refund"
	LedgerTypeWithdrawFeeRefund   LedgerType = "withdraw_fee_refund"
)

// GatewayDepositRevenueSQLPredicate is the SQL boolean predicate for user/gateway
// deposit revenue metrics. It includes only ledger type `deposit` and excludes
// residual misclassified admin top-ups (defense in depth after FIN-006 backfill).
const GatewayDepositRevenueSQLPredicate = `
type = 'deposit'
AND NOT (
  COALESCE(reason_code, '') = 'WALLET_TOPUP'
  AND COALESCE(ref_type::text, '') = 'admin_action'
)`

// ReasonCode represents a machine-readable reason for a ledger entry.
type ReasonCode string

const (
	ReasonCodeContestEntry        ReasonCode = "CONTEST_ENTRY"
	ReasonCodeContestEntryFree    ReasonCode = "CONTEST_ENTRY_FREE"
	ReasonCodeContestRefundQuorum ReasonCode = "CONTEST_REFUND_QUORUM"
	ReasonCodeContestRefundAdmin  ReasonCode = "CONTEST_REFUND_ADMIN"
	ReasonCodeContestRefundLeave  ReasonCode = "CONTEST_REFUND_LEAVE"
	ReasonCodeContestPrize        ReasonCode = "CONTEST_PRIZE"
	ReasonCodeWalletTopup         ReasonCode = "WALLET_TOPUP"
	ReasonCodeWalletWithdraw      ReasonCode = "WALLET_WITHDRAW"
)

// LedgerRefType represents the reference type for a ledger entry.
type LedgerRefType string

const (
	LedgerRefTypePaymentIntent LedgerRefType = "payment_intent"
	LedgerRefTypePayout        LedgerRefType = "payout"
	LedgerRefTypeContest       LedgerRefType = "contest"
	LedgerRefTypeAdminAction   LedgerRefType = "admin_action"
	LedgerRefTypeCommission    LedgerRefType = "commission"
)

// PaymentIntentStatus represents the status of a payment intent.
type PaymentIntentStatus string

const (
	PaymentIntentStatusPending    PaymentIntentStatus = "pending"
	PaymentIntentStatusProcessing PaymentIntentStatus = "processing"
	PaymentIntentStatusSucceeded  PaymentIntentStatus = "succeeded"
	PaymentIntentStatusFailed     PaymentIntentStatus = "failed"
	PaymentIntentStatusCancelled  PaymentIntentStatus = "cancelled"
	PaymentIntentStatusRefunded   PaymentIntentStatus = "refunded"
	PaymentIntentStatusExpired    PaymentIntentStatus = "expired"
)

// PayoutStatus represents the status of a payout.
type PayoutStatus string

const (
	PayoutStatusPending    PayoutStatus = "pending"
	PayoutStatusProcessing PayoutStatus = "processing"
	PayoutStatusSucceeded  PayoutStatus = "succeeded"
	PayoutStatusFailed     PayoutStatus = "failed"
	PayoutStatusCancelled  PayoutStatus = "cancelled"
)

// Wallet represents a user's wallet.
type Wallet struct {
	UserID       string       `json:"user_id"`
	BalanceCents int64        `json:"balance_cents"`
	Currency     string       `json:"currency"`
	Status       WalletStatus `json:"status"`
	CreatedAt    time.Time    `json:"created_at"`
	UpdatedAt    time.Time    `json:"updated_at"`
}

// LedgerEntry represents a single entry in the wallet ledger.
type LedgerEntry struct {
	ID                string         `json:"id"`
	UserID            string         `json:"user_id"`
	Type              LedgerType     `json:"type"`
	AmountCents       int64          `json:"amount_cents"`
	BalanceAfterCents int64          `json:"balance_after_cents"`
	RefType           *LedgerRefType `json:"ref_type,omitempty"`
	RefID             *string        `json:"ref_id,omitempty"`
	Description       *string        `json:"description,omitempty"`
	ReasonCode        *ReasonCode    `json:"reason_code,omitempty"`
	IdempotencyKey    *string        `json:"idempotency_key,omitempty"`
	CreatedAt         time.Time      `json:"created_at"`
}

// PaymentIntent represents a payment intent for deposits.
type PaymentIntent struct {
	ID                string              `json:"id"`
	UserID            string              `json:"user_id"`
	Provider          string              `json:"provider"`
	ProviderPaymentID *string             `json:"provider_payment_id,omitempty"`
	AmountCents       int64               `json:"amount_cents"`
	Currency          string              `json:"currency"`
	Status            PaymentIntentStatus `json:"status"`
	MetadataJSON      []byte              `json:"metadata_json,omitempty"`
	CreatedAt         time.Time           `json:"created_at"`
	UpdatedAt         time.Time           `json:"updated_at"`
	CompletedAt       *time.Time          `json:"completed_at,omitempty"`
}

// Payout represents a payout request for withdrawals.
type Payout struct {
	ID                  string       `json:"id"`
	UserID              string       `json:"user_id"`
	AmountCents         int64        `json:"amount_cents"`
	Currency            string       `json:"currency"`
	Status              PayoutStatus `json:"status"`
	Provider            *string      `json:"provider,omitempty"`
	ProviderPayoutID    *string      `json:"provider_payout_id,omitempty"`
	DestinationType     *string      `json:"destination_type,omitempty"`
	DestinationInfoJSON []byte       `json:"destination_info_json,omitempty"`
	MetadataJSON        []byte       `json:"metadata_json,omitempty"`
	CreatedAt           time.Time    `json:"created_at"`
	UpdatedAt           time.Time    `json:"updated_at"`
	CompletedAt         *time.Time   `json:"completed_at,omitempty"`
}

// InsufficientBalanceError is returned when a wallet has insufficient funds.
type InsufficientBalanceError struct {
	Required  int64
	Available int64
}

func (e *InsufficientBalanceError) Error() string {
	return "insufficient balance"
}

// WalletFrozenError is returned when attempting operations on a frozen wallet.
type WalletFrozenError struct {
	UserID string
}

func (e *WalletFrozenError) Error() string {
	return "wallet is frozen"
}

// WalletNotFoundError is returned when a wallet is not found.
type WalletNotFoundError struct {
	UserID string
}

func (e *WalletNotFoundError) Error() string {
	return "wallet not found"
}

// DuplicatePrizeCreditError is returned when a prize credit was already processed.
// This is not an error condition - it indicates idempotency worked correctly.
type DuplicatePrizeCreditError struct {
	IdempotencyKey string
	ExistingEntry  *LedgerEntry
}

func (e *DuplicatePrizeCreditError) Error() string {
	return "prize credit already processed"
}

// DuplicateCreditError is returned when a credit with the same idempotency key
// was already processed. This is not an error condition - it indicates
// idempotency protection worked correctly.
type DuplicateCreditError struct {
	IdempotencyKey string
	ExistingEntry  *LedgerEntry
}

func (e *DuplicateCreditError) Error() string {
	return "credit already processed"
}

// WithdrawalLimits holds the effective limits for a user (resolved from per-user override + system defaults).
type WithdrawalLimits struct {
	DailyAmountCents   int64
	MonthlyAmountCents int64
	DailyCount         int
	MonthlyCount       int
}

// WithdrawalUsage holds the current usage within the daily and monthly windows.
type WithdrawalUsage struct {
	DailyAmountCents   int64
	MonthlyAmountCents int64
	DailyCount         int
	MonthlyCount       int
}

// WithdrawalLimitExceededError is returned when a withdrawal would exceed a limit.
type WithdrawalLimitExceededError struct {
	LimitType      string // "daily_amount", "monthly_amount", "daily_count", "monthly_count"
	LimitValue     int64
	CurrentUsage   int64
	RequestedValue int64
}

func (e *WithdrawalLimitExceededError) Error() string {
	switch e.LimitType {
	case "daily_amount":
		return "daily withdrawal amount limit exceeded"
	case "monthly_amount":
		return "monthly withdrawal amount limit exceeded"
	case "daily_count":
		return "daily withdrawal count limit exceeded"
	case "monthly_count":
		return "monthly withdrawal count limit exceeded"
	default:
		return "withdrawal limit exceeded"
	}
}
