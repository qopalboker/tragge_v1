package wallet

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
)

// TxExecutor is an interface for executing database operations.
// It can be either a *sql.DB or *sql.Tx.
type TxExecutor interface {
	ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error)
	QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row
	QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error)
}

// TxAdapter wraps a *sql.Tx to satisfy the TxExecutor interface.
type TxAdapter struct {
	Tx *sql.Tx
}

func (a *TxAdapter) ExecContext(ctx context.Context, query string, args ...interface{}) (sql.Result, error) {
	return a.Tx.ExecContext(ctx, query, args...)
}

func (a *TxAdapter) QueryRowContext(ctx context.Context, query string, args ...interface{}) *sql.Row {
	return a.Tx.QueryRowContext(ctx, query, args...)
}

func (a *TxAdapter) QueryContext(ctx context.Context, query string, args ...interface{}) (*sql.Rows, error) {
	return a.Tx.QueryContext(ctx, query, args...)
}

// Service provides wallet operations.
type Service struct {
	db *sql.DB
}

// NewService creates a new wallet service.
func NewService(db *sql.DB) *Service {
	return &Service{db: db}
}

// GetWallet retrieves a wallet by user ID.
func (s *Service) GetWallet(ctx context.Context, userID string) (*Wallet, error) {
	return s.getWallet(ctx, s.db, userID)
}

// GetWalletTx retrieves a wallet by user ID within a transaction.
func (s *Service) GetWalletTx(ctx context.Context, tx TxExecutor, userID string) (*Wallet, error) {
	return s.getWallet(ctx, tx, userID)
}

func (s *Service) getWallet(ctx context.Context, exec TxExecutor, userID string) (*Wallet, error) {
	var w Wallet
	err := exec.QueryRowContext(ctx,
		`SELECT user_id, balance_cents, currency, status, created_at, updated_at
		 FROM wallets WHERE user_id = $1`,
		userID,
	).Scan(&w.UserID, &w.BalanceCents, &w.Currency, &w.Status, &w.CreatedAt, &w.UpdatedAt)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, &WalletNotFoundError{UserID: userID}
		}
		return nil, fmt.Errorf("failed to get wallet: %w", err)
	}

	return &w, nil
}

// GetBalance retrieves the balance for a user.
func (s *Service) GetBalance(ctx context.Context, userID string) (int64, error) {
	wallet, err := s.GetWallet(ctx, userID)
	if err != nil {
		return 0, err
	}
	return wallet.BalanceCents, nil
}

// GetBalanceTx retrieves the balance for a user within a transaction.
// It uses SELECT FOR UPDATE to lock the row.
func (s *Service) GetBalanceTx(ctx context.Context, tx TxExecutor, userID string) (int64, error) {
	var balanceCents int64
	var status WalletStatus
	err := tx.QueryRowContext(ctx,
		`SELECT balance_cents, status FROM wallets WHERE user_id = $1 FOR UPDATE`,
		userID,
	).Scan(&balanceCents, &status)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return 0, &WalletNotFoundError{UserID: userID}
		}
		return 0, fmt.Errorf("failed to get balance: %w", err)
	}

	if status == WalletStatusFrozen {
		return 0, &WalletFrozenError{UserID: userID}
	}

	return balanceCents, nil
}

// CreateWallet creates or retrieves a wallet for a user (idempotent get-or-create).
// If the wallet already exists, the existing wallet is returned unchanged.
// This is typically handled by a database trigger, but can be called manually.
func (s *Service) CreateWallet(ctx context.Context, userID string) (*Wallet, error) {
	// Attempt insert; do nothing if wallet already exists.
	_, err := s.db.ExecContext(ctx,
		`INSERT INTO wallets (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`,
		userID,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create wallet: %w", err)
	}

	// Fetch the wallet (whether just created or pre-existing).
	var w Wallet
	err = s.db.QueryRowContext(ctx,
		`SELECT user_id, balance_cents, currency, status, created_at, updated_at
		 FROM wallets WHERE user_id = $1`,
		userID,
	).Scan(&w.UserID, &w.BalanceCents, &w.Currency, &w.Status, &w.CreatedAt, &w.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch wallet: %w", err)
	}

	return &w, nil
}

// CreateWalletTx creates or retrieves a wallet for a user within an existing transaction (idempotent get-or-create).
// If the wallet already exists, the existing wallet is returned unchanged.
func (s *Service) CreateWalletTx(ctx context.Context, tx TxExecutor, userID string) (*Wallet, error) {
	_, err := tx.ExecContext(ctx,
		`INSERT INTO wallets (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`,
		userID,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create wallet: %w", err)
	}

	var w Wallet
	err = tx.QueryRowContext(ctx,
		`SELECT user_id, balance_cents, currency, status, created_at, updated_at
		 FROM wallets WHERE user_id = $1`,
		userID,
	).Scan(&w.UserID, &w.BalanceCents, &w.Currency, &w.Status, &w.CreatedAt, &w.UpdatedAt)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch wallet: %w", err)
	}

	return &w, nil
}

// Debit deducts an amount from a wallet and creates a ledger entry.
// Must be called within a transaction.
func (s *Service) Debit(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	amountCents int64,
	ledgerType LedgerType,
	refType *LedgerRefType,
	refID *string,
	description *string,
) (*LedgerEntry, error) {
	return s.DebitWithReason(ctx, tx, userID, amountCents, ledgerType, refType, refID, description, nil)
}

// DebitWithReason deducts an amount from a wallet and creates a ledger entry with a reason code.
// Must be called within a transaction.
func (s *Service) DebitWithReason(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	amountCents int64,
	ledgerType LedgerType,
	refType *LedgerRefType,
	refID *string,
	description *string,
	reasonCode *ReasonCode,
) (*LedgerEntry, error) {
	if amountCents <= 0 {
		return nil, errors.New("debit amount must be positive")
	}

	// Get current balance with lock
	balance, err := s.GetBalanceTx(ctx, tx, userID)
	if err != nil {
		return nil, err
	}

	// Check sufficient balance
	if balance < amountCents {
		return nil, &InsufficientBalanceError{Required: amountCents, Available: balance}
	}

	// Calculate new balance
	newBalance := balance - amountCents

	// Update wallet balance
	_, err = tx.ExecContext(ctx,
		`UPDATE wallets SET balance_cents = $1, updated_at = NOW() WHERE user_id = $2`,
		newBalance, userID,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to update wallet balance: %w", err)
	}

	// Create ledger entry (negative amount for debit)
	entry, err := s.createLedgerEntry(ctx, tx, userID, -amountCents, newBalance, ledgerType, refType, refID, description, reasonCode)
	if err != nil {
		return nil, err
	}

	return entry, nil
}

// Credit adds an amount to a wallet and creates a ledger entry.
// Must be called within a transaction.
func (s *Service) Credit(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	amountCents int64,
	ledgerType LedgerType,
	refType *LedgerRefType,
	refID *string,
	description *string,
) (*LedgerEntry, error) {
	return s.CreditWithReason(ctx, tx, userID, amountCents, ledgerType, refType, refID, description, nil)
}

// CreditWithReason adds an amount to a wallet and creates a ledger entry with a reason code.
// Must be called within a transaction.
func (s *Service) CreditWithReason(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	amountCents int64,
	ledgerType LedgerType,
	refType *LedgerRefType,
	refID *string,
	description *string,
	reasonCode *ReasonCode,
) (*LedgerEntry, error) {
	if amountCents <= 0 {
		return nil, errors.New("credit amount must be positive")
	}

	// Get current balance with lock
	balance, err := s.GetBalanceTx(ctx, tx, userID)
	if err != nil {
		// If wallet is frozen, still allow prize credits and refunds
		if _, ok := err.(*WalletFrozenError); ok && (ledgerType == LedgerTypePrizeCredit || ledgerType == LedgerTypeContestRefund) {
			// Get balance without status check
			err = tx.QueryRowContext(ctx,
				`SELECT balance_cents FROM wallets WHERE user_id = $1 FOR UPDATE`,
				userID,
			).Scan(&balance)
			if err != nil {
				return nil, fmt.Errorf("failed to get balance: %w", err)
			}
		} else {
			return nil, err
		}
	}

	// Calculate new balance
	newBalance := balance + amountCents

	// Update wallet balance
	_, err = tx.ExecContext(ctx,
		`UPDATE wallets SET balance_cents = $1, updated_at = NOW() WHERE user_id = $2`,
		newBalance, userID,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to update wallet balance: %w", err)
	}

	// Create ledger entry (positive amount for credit)
	entry, err := s.createLedgerEntry(ctx, tx, userID, amountCents, newBalance, ledgerType, refType, refID, description, reasonCode)
	if err != nil {
		return nil, err
	}

	return entry, nil
}

// CreditIdempotent adds an amount to a wallet with idempotency protection.
// If a ledger entry with the given idempotency key already exists, it returns
// the existing entry and a *DuplicateCreditError (not a real error — idempotent success).
// Must be called within a transaction.
func (s *Service) CreditIdempotent(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	amountCents int64,
	ledgerType LedgerType,
	refType *LedgerRefType,
	refID *string,
	description *string,
	idempotencyKey string,
) (*LedgerEntry, error) {
	return s.CreditIdempotentWithReason(ctx, tx, userID, amountCents, ledgerType, refType, refID, description, nil, idempotencyKey)
}

// CreditIdempotentWithReason adds an amount to a wallet with idempotency protection and a reason code.
// Must be called within a transaction.
func (s *Service) CreditIdempotentWithReason(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	amountCents int64,
	ledgerType LedgerType,
	refType *LedgerRefType,
	refID *string,
	description *string,
	reasonCode *ReasonCode,
	idempotencyKey string,
) (*LedgerEntry, error) {
	if amountCents <= 0 {
		return nil, errors.New("credit amount must be positive")
	}

	// Check if a ledger entry with this idempotency key already exists.
	// Done within the same transaction to prevent TOCTOU race conditions.
	var existingEntry LedgerEntry
	var existingRefType, existingRefID, existingDesc, existingIdempKey, existingReasonCode sql.NullString
	err := tx.QueryRowContext(ctx,
		`SELECT id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, description, reason_code, idempotency_key, created_at
		 FROM wallet_ledger
		 WHERE idempotency_key = $1
		 FOR UPDATE`,
		idempotencyKey,
	).Scan(
		&existingEntry.ID,
		&existingEntry.UserID,
		&existingEntry.Type,
		&existingEntry.AmountCents,
		&existingEntry.BalanceAfterCents,
		&existingRefType,
		&existingRefID,
		&existingDesc,
		&existingReasonCode,
		&existingIdempKey,
		&existingEntry.CreatedAt,
	)

	if err == nil {
		// Entry already exists — idempotent success
		if existingRefType.Valid {
			rt := LedgerRefType(existingRefType.String)
			existingEntry.RefType = &rt
		}
		if existingRefID.Valid {
			existingEntry.RefID = &existingRefID.String
		}
		if existingDesc.Valid {
			existingEntry.Description = &existingDesc.String
		}
		if existingReasonCode.Valid {
			rc := ReasonCode(existingReasonCode.String)
			existingEntry.ReasonCode = &rc
		}
		if existingIdempKey.Valid {
			existingEntry.IdempotencyKey = &existingIdempKey.String
		}

		return &existingEntry, &DuplicateCreditError{
			IdempotencyKey: idempotencyKey,
			ExistingEntry:  &existingEntry,
		}
	}

	if !errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("failed to check for existing credit: %w", err)
	}

	// No existing entry — proceed with credit
	balance, err := s.GetBalanceTx(ctx, tx, userID)
	if err != nil {
		// If wallet is frozen, still allow refunds and prize credits
		if _, ok := err.(*WalletFrozenError); ok && (ledgerType == LedgerTypePrizeCredit || ledgerType == LedgerTypeContestRefund) {
			err = tx.QueryRowContext(ctx,
				`SELECT balance_cents FROM wallets WHERE user_id = $1 FOR UPDATE`,
				userID,
			).Scan(&balance)
			if err != nil {
				return nil, fmt.Errorf("failed to get balance: %w", err)
			}
		} else {
			return nil, err
		}
	}

	newBalance := balance + amountCents

	_, err = tx.ExecContext(ctx,
		`UPDATE wallets SET balance_cents = $1, updated_at = NOW() WHERE user_id = $2`,
		newBalance, userID,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to update wallet balance: %w", err)
	}

	entry, err := s.createLedgerEntryWithIdempotency(
		ctx, tx, userID, amountCents, newBalance, ledgerType,
		refType, refID, description, reasonCode, &idempotencyKey,
	)
	if err != nil {
		return nil, err
	}

	return entry, nil
}

// PostConfirmedDeposit atomically records a qualifying external deposit as a
// custody asset in the system-owned Super Admin Treasury and as an entitlement
// in the beneficiary's user wallet. The caller owns the PostgreSQL transaction
// and must commit it together with the payment-intent status transition.
//
// The payment intent is the shared operation identity. Replays return
// alreadyPosted=true without an additional financial effect. The Treasury row
// is locked first, serializing custody balance updates and concurrent replays;
// the user wallet lock then composes with reservations and withdrawals.
func (s *Service) PostConfirmedDeposit(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	amountCents int64,
	paymentIntentID string,
) (alreadyPosted bool, err error) {
	if amountCents <= 0 {
		return false, errors.New("confirmed deposit amount must be positive")
	}
	if userID == "" {
		return false, errors.New("confirmed deposit user ID is required")
	}
	if paymentIntentID == "" {
		return false, errors.New("confirmed deposit payment intent ID is required")
	}

	treasuryBalance, err := s.LockTreasuryForFinancialOperation(ctx, tx)
	if err != nil {
		return false, err
	}

	var existingUserID string
	var existingAmount int64
	err = tx.QueryRowContext(ctx,
		`SELECT beneficiary_user_id, amount_cents
		 FROM treasury_ledger
		 WHERE payment_intent_id = $1`,
		paymentIntentID,
	).Scan(&existingUserID, &existingAmount)
	if err == nil {
		if existingUserID != userID || existingAmount != amountCents {
			return false, errors.New("confirmed deposit replay does not match original custody posting")
		}
		idempotencyKey := "deposit:" + paymentIntentID
		var entitlementExists bool
		if err := tx.QueryRowContext(ctx,
			`SELECT EXISTS (
				SELECT 1 FROM wallet_ledger
				WHERE idempotency_key = $1
				  AND user_id = $2
				  AND type = 'deposit'
				  AND amount_cents = $3
				  AND ref_type = 'payment_intent'
				  AND ref_id = $4
			)`,
			idempotencyKey, userID, amountCents, paymentIntentID,
		).Scan(&entitlementExists); err != nil {
			return false, fmt.Errorf("failed to verify existing deposit entitlement: %w", err)
		}
		if !entitlementExists {
			return false, errors.New("custody posting exists without matching user entitlement")
		}
		return true, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return false, fmt.Errorf("failed to check existing custody posting: %w", err)
	}

	newTreasuryBalance := treasuryBalance + amountCents
	if newTreasuryBalance < treasuryBalance {
		return false, errors.New("Super Admin Treasury balance overflow")
	}
	if _, err := tx.ExecContext(ctx,
		`UPDATE treasury_accounts
		 SET balance_cents = $1, updated_at = NOW()
		 WHERE purpose = $2`,
		newTreasuryBalance, SuperAdminTreasuryPurpose,
	); err != nil {
		return false, fmt.Errorf("failed to update Super Admin Treasury: %w", err)
	}
	if _, err := tx.ExecContext(ctx,
		`INSERT INTO treasury_ledger (
			treasury_purpose, entry_kind, amount_cents,
			balance_after_cents, payment_intent_id, beneficiary_user_id
		) VALUES ($1, 'external_deposit', $2, $3, $4, $5)`,
		SuperAdminTreasuryPurpose, amountCents, newTreasuryBalance, paymentIntentID, userID,
	); err != nil {
		return false, fmt.Errorf("failed to create Treasury custody entry: %w", err)
	}

	refType := LedgerRefTypePaymentIntent
	idempotencyKey := "deposit:" + paymentIntentID
	if _, err := s.CreditIdempotent(
		ctx, tx, userID, amountCents, LedgerTypeDeposit,
		&refType, &paymentIntentID, nil, idempotencyKey,
	); err != nil {
		if _, duplicate := err.(*DuplicateCreditError); duplicate {
			return false, errors.New("user entitlement exists without matching Treasury custody posting")
		}
		return false, fmt.Errorf("failed to post deposit user entitlement: %w", err)
	}

	return false, nil
}

// LockTreasuryForFinancialOperation starts the financial-account portion of the
// canonical order. Callers first lock contest and participant(s), then hold
// Treasury before user wallet, Fee Wallet, and contest Prize Pool.
func (s *Service) LockTreasuryForFinancialOperation(ctx context.Context, tx TxExecutor) (int64, error) {
	var treasuryBalance int64
	var reconciliationStatus string
	err := tx.QueryRowContext(ctx,
		`SELECT balance_cents, reconciliation_status
		 FROM treasury_accounts
		 WHERE purpose = $1
		 FOR UPDATE`,
		SuperAdminTreasuryPurpose,
	).Scan(&treasuryBalance, &reconciliationStatus)
	if err != nil {
		return 0, fmt.Errorf("failed to lock Super Admin Treasury: %w", err)
	}
	if reconciliationStatus != TreasuryReconciliationForwardOnly {
		return 0, fmt.Errorf("unexpected Super Admin Treasury reconciliation status %q", reconciliationStatus)
	}
	return treasuryBalance, nil
}

// PostContestFee records one canonical fee allocation inside the caller's paid
// admission transaction. The account row lock serializes balance changes; the
// durable inflow (admission_id, entry_kind) index makes retries exactly-once.
// alreadyPosted is true only when the existing entry exactly matches the retry.
func (s *Service) PostContestFee(
	ctx context.Context,
	tx TxExecutor,
	contestID, participantUserID string,
	kind ContestFeeKind,
	amountCents int64,
	platformFeeBps int,
) (alreadyPosted bool, err error) {
	if kind != ContestFeeKindBase && kind != ContestFeeKindLateSurcharge {
		return false, fmt.Errorf("unsupported contest fee kind %q", kind)
	}
	if amountCents <= 0 {
		return false, errors.New("contest fee amount must be positive")
	}
	if platformFeeBps <= 0 || platformFeeBps > 10000 {
		return false, errors.New("contest fee basis points out of range")
	}
	if _, err := uuid.Parse(contestID); err != nil {
		return false, errors.New("invalid contest ID")
	}
	if _, err := uuid.Parse(participantUserID); err != nil {
		return false, errors.New("invalid participant user ID")
	}

	admissionID := contestID + ":" + participantUserID
	treasuryBalance, err := s.LockTreasuryForFinancialOperation(ctx, tx)
	if err != nil {
		return false, err
	}
	var balance int64
	if err := tx.QueryRowContext(ctx, `
		SELECT balance_cents FROM contest_fee_accounts
		WHERE purpose = $1 FOR UPDATE`, ContestFeeWalletPurpose).Scan(&balance); err != nil {
		return false, fmt.Errorf("failed to lock Contest Fee Wallet: %w", err)
	}

	var existingAmount int64
	var existingContest, existingUser, existingPolicy string
	var existingBps int
	feeErr := tx.QueryRowContext(ctx, `
		SELECT amount_cents, contest_id::text, participant_user_id::text,
		       policy_version, platform_fee_bps
		FROM contest_fee_ledger
		WHERE admission_id = $1 AND entry_kind = $2`, admissionID, kind).Scan(
		&existingAmount, &existingContest, &existingUser, &existingPolicy, &existingBps,
	)
	var treasuryAmount int64
	var treasuryContest, treasuryUser string
	treasuryErr := tx.QueryRowContext(ctx, `
		SELECT amount_cents, contest_id::text, participant_user_id::text
		FROM treasury_ledger
		WHERE entry_kind = 'contest_fee_allocation' AND admission_id = $1 AND fee_kind = $2`,
		admissionID, kind,
	).Scan(&treasuryAmount, &treasuryContest, &treasuryUser)
	if feeErr != nil && !errors.Is(feeErr, sql.ErrNoRows) {
		return false, fmt.Errorf("failed to check contest fee idempotency: %w", feeErr)
	}
	if treasuryErr != nil && !errors.Is(treasuryErr, sql.ErrNoRows) {
		return false, fmt.Errorf("failed to check Treasury fee allocation: %w", treasuryErr)
	}
	if feeErr == nil && treasuryErr == nil {
		if existingAmount != amountCents || existingContest != contestID ||
			existingUser != participantUserID || existingPolicy != ContestFundsPolicyVersion ||
			existingBps != platformFeeBps || treasuryAmount != -amountCents ||
			treasuryContest != contestID || treasuryUser != participantUserID {
			return false, errors.New("contest fee idempotency conflict")
		}
		return true, nil
	}
	if feeErr == nil || treasuryErr == nil {
		return false, errors.New("contest fee posting has no matching financial counterpart")
	}
	if treasuryBalance < amountCents {
		return false, &InsufficientBalanceError{Required: amountCents, Available: treasuryBalance}
	}

	newBalance := balance + amountCents
	if newBalance < balance {
		return false, errors.New("Contest Fee Wallet balance overflow")
	}
	if _, err := tx.ExecContext(ctx, `
		UPDATE treasury_accounts SET balance_cents = $1, updated_at = NOW()
		WHERE purpose = $2`, treasuryBalance-amountCents, SuperAdminTreasuryPurpose); err != nil {
		return false, fmt.Errorf("failed to allocate Treasury custody to Contest Fee Wallet: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `
		UPDATE contest_fee_accounts SET balance_cents = $1, updated_at = NOW()
		WHERE purpose = $2`, newBalance, ContestFeeWalletPurpose); err != nil {
		return false, fmt.Errorf("failed to update Contest Fee Wallet: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO treasury_ledger (
			treasury_purpose, entry_kind, amount_cents, balance_after_cents,
			contest_id, participant_user_id, admission_id, fee_kind
		) VALUES ($1,'contest_fee_allocation',$2,$3,$4,$5,$6,$7)`,
		SuperAdminTreasuryPurpose, -amountCents, treasuryBalance-amountCents,
		contestID, participantUserID, admissionID, kind,
	); err != nil {
		return false, fmt.Errorf("failed to append Treasury fee allocation: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `
		INSERT INTO contest_fee_ledger (
			fee_wallet_purpose, entry_kind, amount_cents, balance_after_cents,
			contest_id, participant_user_id, admission_id, policy_version, platform_fee_bps
		) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)`,
		ContestFeeWalletPurpose, kind, amountCents, newBalance, contestID,
		participantUserID, admissionID, ContestFundsPolicyVersion, platformFeeBps,
	); err != nil {
		return false, fmt.Errorf("failed to append contest fee ledger: %w", err)
	}
	return false, nil
}

// PostContestPrizeContribution moves one admission's validated PrizeCents from
// Treasury into the contest's pre-provisioned pool. Callers must already hold
// locks in contest -> Treasury -> user -> Fee Wallet order; this method takes
// the final Prize Pool lock. Re-locking Treasury here is harmless for the
// admission transaction and makes the controlled operation safe for retries.
func (s *Service) PostContestPrizeContribution(ctx context.Context, tx TxExecutor, contestID, participantUserID string, amountCents int64) (bool, error) {
	if amountCents <= 0 {
		return false, errors.New("contest Prize Pool contribution must be positive")
	}
	if _, err := uuid.Parse(contestID); err != nil {
		return false, errors.New("invalid contest ID")
	}
	if _, err := uuid.Parse(participantUserID); err != nil {
		return false, errors.New("invalid participant user ID")
	}
	admissionID := contestID + ":" + participantUserID
	key := "contest_pool:" + admissionID + ":v1"
	treasuryBalance, err := s.LockTreasuryForFinancialOperation(ctx, tx)
	if err != nil {
		return false, err
	}

	var accountID, policy string
	var poolBalance int64
	if err := tx.QueryRowContext(ctx, `SELECT a.id::text,a.balance_cents,c.funds_policy_version
		FROM contests c JOIN contest_prize_pool_accounts a ON a.contest_id=c.id
		WHERE c.id=$1 FOR UPDATE OF a`, contestID).Scan(&accountID, &poolBalance, &policy); err != nil {
		return false, fmt.Errorf("failed to lock contest Prize Pool: %w", err)
	}
	if policy != ContestPrizePoolPolicyV1 {
		return false, errors.New("contest is not on contest_funds_v1")
	}

	var existingAmount int64
	var existingContest, existingAccount, existingUser, existingReference string
	poolErr := tx.QueryRowContext(ctx, `SELECT amount_cents,contest_id::text,pool_account_id::text,
		participant_user_id::text,reference_id FROM contest_prize_pool_ledger WHERE idempotency_key=$1`, key).
		Scan(&existingAmount, &existingContest, &existingAccount, &existingUser, &existingReference)
	var treasuryAmount int64
	var treasuryContest, treasuryUser string
	treasuryErr := tx.QueryRowContext(ctx, `SELECT amount_cents,contest_id::text,participant_user_id::text
		FROM treasury_ledger WHERE entry_kind='contest_pool_allocation' AND admission_id=$1`, admissionID).
		Scan(&treasuryAmount, &treasuryContest, &treasuryUser)
	if poolErr != nil && !errors.Is(poolErr, sql.ErrNoRows) {
		return false, fmt.Errorf("failed to check Prize Pool idempotency: %w", poolErr)
	}
	if treasuryErr != nil && !errors.Is(treasuryErr, sql.ErrNoRows) {
		return false, fmt.Errorf("failed to check Treasury pool allocation: %w", treasuryErr)
	}
	if poolErr == nil && treasuryErr == nil {
		if existingAmount != amountCents || existingContest != contestID || existingAccount != accountID ||
			existingUser != participantUserID || existingReference != admissionID || treasuryAmount != -amountCents ||
			treasuryContest != contestID || treasuryUser != participantUserID {
			return false, errors.New("contest Prize Pool idempotency conflict")
		}
		return true, nil
	}
	if poolErr == nil || treasuryErr == nil {
		return false, errors.New("contest Prize Pool posting has no matching financial counterpart")
	}

	if treasuryBalance < amountCents {
		return false, &InsufficientBalanceError{Required: amountCents, Available: treasuryBalance}
	}
	if amountCents > math.MaxInt64-poolBalance {
		return false, errors.New("contest Prize Pool balance overflow")
	}
	newPoolBalance := poolBalance + amountCents
	if _, err := tx.ExecContext(ctx, `UPDATE treasury_accounts SET balance_cents=$1,updated_at=NOW() WHERE purpose=$2`, treasuryBalance-amountCents, SuperAdminTreasuryPurpose); err != nil {
		return false, fmt.Errorf("failed to allocate Treasury custody to Prize Pool: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO treasury_ledger(treasury_purpose,entry_kind,amount_cents,balance_after_cents,
		contest_id,participant_user_id,admission_id) VALUES($1,'contest_pool_allocation',$2,$3,$4,$5,$6)`,
		SuperAdminTreasuryPurpose, -amountCents, treasuryBalance-amountCents, contestID, participantUserID, admissionID); err != nil {
		return false, fmt.Errorf("failed to append Treasury pool allocation: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO contest_prize_pool_ledger(contest_id,pool_account_id,amount_cents,direction,
		reason,reference_type,reference_id,participant_user_id,policy_version,balance_after_cents,idempotency_key)
		VALUES($1,$2,$3,'credit','contest_admission','contest_admission',$4,$5,$6,$7,$8)`, contestID, accountID,
		amountCents, admissionID, participantUserID, ContestPrizePoolPolicyV1, newPoolBalance, key); err != nil {
		return false, fmt.Errorf("failed to append contest Prize Pool ledger: %w", err)
	}
	if _, err := tx.ExecContext(ctx, `UPDATE contest_prize_pool_accounts SET balance_cents=$1,updated_at=NOW() WHERE id=$2`, newPoolBalance, accountID); err != nil {
		return false, fmt.Errorf("failed to update contest Prize Pool: %w", err)
	}
	return false, nil
}

// ReverseContestAdmission appends an exact reversal of every canonical money
// movement created by one paid admission. The caller owns the surrounding
// transaction and must have already locked contest and participant rows.
func (s *Service) ReverseContestAdmission(ctx context.Context, tx TxExecutor, contestID, participantUserID, actorID, lifecycleEventID, reason string) (*ContestReversal, error) {
	for name, value := range map[string]string{"contest": contestID, "participant": participantUserID, "actor": actorID, "event": lifecycleEventID} {
		if _, err := uuid.Parse(value); err != nil {
			return nil, fmt.Errorf("invalid %s ID", name)
		}
	}
	admissionID := contestID + ":" + participantUserID
	result := &ContestReversal{}
	var walletAmount int64
	if err := tx.QueryRowContext(ctx, `SELECT id::text,amount_cents FROM wallet_ledger
		WHERE user_id=$1 AND type='contest_entry' AND ref_type='contest' AND ref_id=$2
		ORDER BY created_at DESC,id DESC LIMIT 1`, participantUserID, contestID).
		Scan(&result.WalletOriginalID, &walletAmount); err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return result, nil
		}
		return nil, fmt.Errorf("find original contest entry: %w", err)
	}
	if walletAmount >= 0 {
		return nil, errors.New("original contest entry has invalid sign")
	}

	treasuryBalance, err := s.LockTreasuryForFinancialOperation(ctx, tx)
	if err != nil {
		return nil, err
	}
	var walletBalance int64
	if err := tx.QueryRowContext(ctx, `SELECT balance_cents FROM wallets WHERE user_id=$1 FOR UPDATE`, participantUserID).Scan(&walletBalance); err != nil {
		return nil, fmt.Errorf("lock participant wallet: %w", err)
	}
	var feeBalance int64
	if err := tx.QueryRowContext(ctx, `SELECT balance_cents FROM contest_fee_accounts WHERE purpose=$1 FOR UPDATE`, ContestFeeWalletPurpose).Scan(&feeBalance); err != nil {
		return nil, fmt.Errorf("lock Contest Fee Wallet: %w", err)
	}
	var poolID string
	var poolBalance int64
	if err := tx.QueryRowContext(ctx, `SELECT id::text,balance_cents FROM contest_prize_pool_accounts WHERE contest_id=$1 FOR UPDATE`, contestID).Scan(&poolID, &poolBalance); err != nil {
		return nil, fmt.Errorf("lock contest Prize Pool: %w", err)
	}

	refund := -walletAmount
	newWalletBalance := walletBalance + refund
	if newWalletBalance < walletBalance {
		return nil, errors.New("wallet balance overflow")
	}
	result.WalletReversalID = uuid.NewString()
	idempotencyKey := "contest_admission_reversal:" + admissionID
	desc := "Reversal: " + reason
	if _, err := tx.ExecContext(ctx, `UPDATE wallets SET balance_cents=$1,updated_at=NOW() WHERE user_id=$2`, newWalletBalance, participantUserID); err != nil {
		return nil, err
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO wallet_ledger(id,user_id,type,amount_cents,balance_after_cents,ref_type,ref_id,
		description,reason_code,idempotency_key,original_transaction_id,lifecycle_event_id,reversal_actor_id)
		VALUES($1,$2,'contest_refund',$3,$4,'contest',$5,$6,'CONTEST_REFUND_ADMIN',$7,$8,$9,$10)`,
		result.WalletReversalID, participantUserID, refund, newWalletBalance, contestID, desc, idempotencyKey,
		result.WalletOriginalID, lifecycleEventID, actorID); err != nil {
		return nil, fmt.Errorf("append wallet reversal: %w", err)
	}
	result.WalletCents = refund

	feeRows, err := tx.QueryContext(ctx, `SELECT f.id::text,f.amount_cents,f.entry_kind,f.policy_version,f.platform_fee_bps,
		t.id::text FROM contest_fee_ledger f JOIN treasury_ledger t ON t.entry_kind='contest_fee_allocation'
		AND t.admission_id=f.admission_id AND t.fee_kind=f.entry_kind
		WHERE f.admission_id=$1 AND f.entry_kind IN ('contest_base_fee','contest_late_surcharge') ORDER BY f.entry_kind`, admissionID)
	if err != nil {
		return nil, fmt.Errorf("load original fee movements: %w", err)
	}
	type feeOriginal struct {
		id           string
		amount       int64
		kind, policy string
		bps          int
		treasuryID   string
	}
	var fees []feeOriginal
	for feeRows.Next() {
		var f feeOriginal
		if err := feeRows.Scan(&f.id, &f.amount, &f.kind, &f.policy, &f.bps, &f.treasuryID); err != nil {
			feeRows.Close()
			return nil, err
		}
		fees = append(fees, f)
	}
	if err := feeRows.Close(); err != nil {
		return nil, err
	}
	for _, f := range fees {
		if feeBalance < f.amount {
			return nil, errors.New("Contest Fee Wallet reversal would be negative")
		}
		feeBalance -= f.amount
		treasuryBalance += f.amount
		if _, err := tx.ExecContext(ctx, `INSERT INTO contest_fee_ledger(fee_wallet_purpose,entry_kind,amount_cents,balance_after_cents,
			contest_id,participant_user_id,admission_id,policy_version,platform_fee_bps,original_entry_id,lifecycle_event_id,reversal_actor_id)
			VALUES($1,'contest_fee_refund_reversal',$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)`, ContestFeeWalletPurpose, -f.amount, feeBalance,
			contestID, participantUserID, admissionID, f.policy, f.bps, f.id, lifecycleEventID, actorID); err != nil {
			return nil, fmt.Errorf("append fee reversal: %w", err)
		}
		if _, err := tx.ExecContext(ctx, `INSERT INTO treasury_ledger(treasury_purpose,entry_kind,amount_cents,balance_after_cents,
			contest_id,participant_user_id,admission_id,fee_kind,original_ledger_id,lifecycle_event_id,reversal_actor_id)
			VALUES($1,'treasury_reversal',$2,$3,$4,$5,$6,$7,$8,$9,$10)`, SuperAdminTreasuryPurpose, f.amount, treasuryBalance,
			contestID, participantUserID, admissionID, f.kind, f.treasuryID, lifecycleEventID, actorID); err != nil {
			return nil, fmt.Errorf("append Treasury fee reversal: %w", err)
		}
		result.FeeCents += f.amount
		result.TreasuryCents += f.amount
	}

	var poolLedgerID, treasuryPoolID string
	var poolAmount int64
	poolErr := tx.QueryRowContext(ctx, `SELECT p.id::text,p.amount_cents,t.id::text FROM contest_prize_pool_ledger p
		JOIN treasury_ledger t ON t.entry_kind='contest_pool_allocation' AND t.admission_id=p.reference_id
		WHERE p.contest_id=$1 AND p.participant_user_id=$2 AND p.direction='credit'`, contestID, participantUserID).
		Scan(&poolLedgerID, &poolAmount, &treasuryPoolID)
	if poolErr != nil && !errors.Is(poolErr, sql.ErrNoRows) {
		return nil, poolErr
	}
	if poolErr == nil {
		if poolBalance < poolAmount {
			return nil, errors.New("Prize Pool reversal would be negative")
		}
		poolBalance -= poolAmount
		treasuryBalance += poolAmount
		if _, err := tx.ExecContext(ctx, `INSERT INTO contest_prize_pool_ledger(contest_id,pool_account_id,amount_cents,direction,reason,
			reference_type,reference_id,participant_user_id,policy_version,balance_after_cents,idempotency_key,original_ledger_id,lifecycle_event_id,reversal_actor_id)
			VALUES($1,$2,$3,'debit','participant_refund','lifecycle_event',$4,$5,$6,$7,$8,$9,$4,$10)`, contestID, poolID, -poolAmount,
			lifecycleEventID, participantUserID, ContestPrizePoolPolicyV1, poolBalance, "contest_pool_reversal:"+admissionID, poolLedgerID, actorID); err != nil {
			return nil, fmt.Errorf("append Prize Pool reversal: %w", err)
		}
		if _, err := tx.ExecContext(ctx, `INSERT INTO treasury_ledger(treasury_purpose,entry_kind,amount_cents,balance_after_cents,
			contest_id,participant_user_id,admission_id,original_ledger_id,lifecycle_event_id,reversal_actor_id)
			VALUES($1,'treasury_reversal',$2,$3,$4,$5,$6,$7,$8,$9)`, SuperAdminTreasuryPurpose, poolAmount, treasuryBalance,
			contestID, participantUserID, admissionID, treasuryPoolID, lifecycleEventID, actorID); err != nil {
			return nil, fmt.Errorf("append Treasury pool reversal: %w", err)
		}
		result.PrizePoolCents = poolAmount
		result.TreasuryCents += poolAmount
	}
	if result.FeeCents+result.PrizePoolCents != refund {
		return nil, errors.New("contest admission does not reconcile to canonical allocations")
	}
	if _, err := tx.ExecContext(ctx, `UPDATE contest_fee_accounts SET balance_cents=$1,updated_at=NOW() WHERE purpose=$2`, feeBalance, ContestFeeWalletPurpose); err != nil {
		return nil, err
	}
	if _, err := tx.ExecContext(ctx, `UPDATE contest_prize_pool_accounts SET balance_cents=$1,updated_at=NOW() WHERE id=$2`, poolBalance, poolID); err != nil {
		return nil, err
	}
	if _, err := tx.ExecContext(ctx, `UPDATE treasury_accounts SET balance_cents=$1,updated_at=NOW() WHERE purpose=$2`, treasuryBalance, SuperAdminTreasuryPurpose); err != nil {
		return nil, err
	}
	return result, nil
}

func (s *Service) GetContestPrizePool(ctx context.Context, contestID string, limit, offset int) (*ContestPrizePoolView, error) {
	if _, err := uuid.Parse(contestID); err != nil || limit < 1 || limit > 100 || offset < 0 {
		return nil, errors.New("invalid contest Prize Pool request")
	}
	view := &ContestPrizePoolView{ContestID: contestID}
	if err := s.db.QueryRowContext(ctx, `SELECT id::text,balance_cents,status,created_at FROM contest_prize_pool_accounts WHERE contest_id=$1`, contestID).
		Scan(&view.PoolAccountID, &view.BalanceCents, &view.Status, &view.CreatedAt); err != nil {
		return nil, fmt.Errorf("failed to read contest Prize Pool: %w", err)
	}
	rows, err := s.db.QueryContext(ctx, `SELECT id::text,amount_cents,direction,reason,reference_type,reference_id,
		participant_user_id::text,idempotency_key,created_at FROM contest_prize_pool_ledger WHERE contest_id=$1
		ORDER BY created_at DESC,id DESC LIMIT $2 OFFSET $3`, contestID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to list contest Prize Pool ledger: %w", err)
	}
	defer rows.Close()
	view.Entries = make([]ContestPrizePoolEntry, 0)
	for rows.Next() {
		var entry ContestPrizePoolEntry
		if err := rows.Scan(&entry.ID, &entry.AmountCents, &entry.Direction, &entry.Reason, &entry.ReferenceType,
			&entry.ReferenceID, &entry.ParticipantUserID, &entry.IdempotencyKey, &entry.CreatedAt); err != nil {
			return nil, err
		}
		view.Entries = append(view.Entries, entry)
	}
	return view, rows.Err()
}

// GetContestFeeWallet returns the balance and paginated append-only history.
// Authorization belongs to the Admin BFF; this method accepts no account key.
func (s *Service) GetContestFeeWallet(ctx context.Context, limit, offset int) (*ContestFeeWalletView, error) {
	if limit < 1 || limit > 100 || offset < 0 {
		return nil, errors.New("invalid contest fee wallet pagination")
	}
	view := &ContestFeeWalletView{}
	if err := s.db.QueryRowContext(ctx, `
		SELECT a.balance_cents,
		       COALESCE(SUM(l.amount_cents) FILTER (WHERE l.entry_kind = 'contest_base_fee'), 0),
		       COALESCE(SUM(l.amount_cents) FILTER (WHERE l.entry_kind = 'contest_late_surcharge'), 0),
		       COALESCE(SUM(l.amount_cents) FILTER (WHERE l.entry_kind = 'contest_fee_refund_reversal'), 0),
		       COUNT(l.id)
		FROM contest_fee_accounts a
		LEFT JOIN contest_fee_ledger l ON l.fee_wallet_purpose = a.purpose
		WHERE a.purpose = $1 GROUP BY a.purpose, a.balance_cents`, ContestFeeWalletPurpose,
	).Scan(&view.BalanceCents, &view.BaseFeeTotalCents, &view.SurchargeTotalCents,
		&view.ReversalTotalCents, &view.TotalEntries); err != nil {
		return nil, fmt.Errorf("failed to read Contest Fee Wallet: %w", err)
	}
	rows, err := s.db.QueryContext(ctx, `
		SELECT id::text, entry_kind, amount_cents, balance_after_cents,
		       contest_id::text, participant_user_id::text, admission_id,
		       policy_version, platform_fee_bps, original_entry_id::text, created_at
		FROM contest_fee_ledger ORDER BY created_at DESC, id DESC LIMIT $1 OFFSET $2`, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to list contest fee ledger: %w", err)
	}
	defer rows.Close()
	view.Entries = make([]ContestFeeEntry, 0)
	for rows.Next() {
		var entry ContestFeeEntry
		var original sql.NullString
		if err := rows.Scan(&entry.ID, &entry.Kind, &entry.AmountCents, &entry.BalanceAfterCents,
			&entry.ContestID, &entry.ParticipantUserID, &entry.AdmissionID,
			&entry.PolicyVersion, &entry.PlatformFeeBps, &original, &entry.CreatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan contest fee ledger: %w", err)
		}
		if original.Valid {
			entry.OriginalEntryID = &original.String
		}
		view.Entries = append(view.Entries, entry)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("failed to iterate contest fee ledger: %w", err)
	}
	return view, nil
}

// createLedgerEntry creates a new ledger entry.
func (s *Service) createLedgerEntry(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	amountCents int64,
	balanceAfterCents int64,
	ledgerType LedgerType,
	refType *LedgerRefType,
	refID *string,
	description *string,
	reasonCode *ReasonCode,
) (*LedgerEntry, error) {
	return s.createLedgerEntryWithIdempotency(ctx, tx, userID, amountCents, balanceAfterCents, ledgerType, refType, refID, description, reasonCode, nil)
}

// createLedgerEntryWithIdempotency creates a new ledger entry with an optional idempotency key.
func (s *Service) createLedgerEntryWithIdempotency(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	amountCents int64,
	balanceAfterCents int64,
	ledgerType LedgerType,
	refType *LedgerRefType,
	refID *string,
	description *string,
	reasonCode *ReasonCode,
	idempotencyKey *string,
) (*LedgerEntry, error) {
	entryID := uuid.New().String()

	_, err := tx.ExecContext(ctx,
		`INSERT INTO wallet_ledger (id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, description, reason_code, idempotency_key)
		 VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
		entryID, userID, ledgerType, amountCents, balanceAfterCents, refType, refID, description, reasonCode, idempotencyKey,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to create ledger entry: %w", err)
	}

	return &LedgerEntry{
		ID:                entryID,
		UserID:            userID,
		Type:              ledgerType,
		AmountCents:       amountCents,
		BalanceAfterCents: balanceAfterCents,
		RefType:           refType,
		RefID:             refID,
		Description:       description,
		ReasonCode:        reasonCode,
		IdempotencyKey:    idempotencyKey,
	}, nil
}

// DeductContestEntryFee deducts the entry fee from a user's wallet for joining a contest.
// Must be called within a transaction.
func (s *Service) DeductContestEntryFee(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	contestID string,
	entryFeeCents int64,
) (*LedgerEntry, error) {
	return s.DeductContestEntryFeeWithName(ctx, tx, userID, contestID, "", entryFeeCents)
}

// DeductContestEntryFeeWithName deducts the entry fee with a human-readable contest name in the description.
// Must be called within a transaction.
//
// Idempotency: uses key contest_entry:{contest_id}:{user_id}. A repeated join
// attempt that reaches debit after a prior successful debit will not double-charge
// (unique ledger idempotency_key). Callers should still prevent duplicate
// participant rows via PRIMARY KEY (contest_id, user_id).
func (s *Service) DeductContestEntryFeeWithName(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	contestID string,
	contestName string,
	entryFeeCents int64,
) (*LedgerEntry, error) {
	if entryFeeCents <= 0 {
		return nil, nil // No fee to deduct
	}

	refType := LedgerRefTypeContest
	reasonCode := ReasonCodeContestEntry
	var desc string
	if contestName != "" {
		desc = fmt.Sprintf("Entry fee for contest %s (ID: %s)", contestName, contestID)
	} else {
		desc = fmt.Sprintf("Entry fee for contest %s", contestID)
	}
	idempotencyKey := fmt.Sprintf("contest_entry:%s:%s", contestID, userID)

	// Check for existing debit with same key (idempotent success).
	var existing LedgerEntry
	var existingRefType, existingRefID, existingDesc, existingReason, existingKey sql.NullString
	err := tx.QueryRowContext(ctx,
		`SELECT id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, description, reason_code, idempotency_key, created_at
		 FROM wallet_ledger WHERE idempotency_key = $1 FOR UPDATE`,
		idempotencyKey,
	).Scan(
		&existing.ID, &existing.UserID, &existing.Type, &existing.AmountCents, &existing.BalanceAfterCents,
		&existingRefType, &existingRefID, &existingDesc, &existingReason, &existingKey, &existing.CreatedAt,
	)
	if err == nil {
		if existingRefType.Valid {
			rt := LedgerRefType(existingRefType.String)
			existing.RefType = &rt
		}
		if existingRefID.Valid {
			existing.RefID = &existingRefID.String
		}
		if existingDesc.Valid {
			existing.Description = &existingDesc.String
		}
		if existingReason.Valid {
			rc := ReasonCode(existingReason.String)
			existing.ReasonCode = &rc
		}
		if existingKey.Valid {
			existing.IdempotencyKey = &existingKey.String
		}
		return &existing, nil
	}
	if !errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("failed to check contest entry debit: %w", err)
	}

	// Debit then attach idempotency key via dedicated insert path.
	balance, balErr := s.GetBalanceTx(ctx, tx, userID)
	if balErr != nil {
		return nil, balErr
	}
	if balance < entryFeeCents {
		return nil, &InsufficientBalanceError{Required: entryFeeCents, Available: balance}
	}
	newBalance := balance - entryFeeCents
	if _, err := tx.ExecContext(ctx,
		`UPDATE wallets SET balance_cents = $1, updated_at = NOW() WHERE user_id = $2`,
		newBalance, userID,
	); err != nil {
		return nil, fmt.Errorf("failed to update wallet balance: %w", err)
	}
	return s.createLedgerEntryWithIdempotency(
		ctx, tx, userID, -entryFeeCents, newBalance, LedgerTypeContestEntry,
		&refType, &contestID, &desc, &reasonCode, &idempotencyKey,
	)
}

// RecordFreeContestEntry records a zero-cost entry for a free contest (for history/audit).
// Must be called within a transaction. Creates a ledger entry with amount 0 is not allowed,
// so this records the participation without a monetary transaction.
// Returns nil, nil (no ledger entry created for free contests).
func (s *Service) RecordFreeContestEntry(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	contestID string,
	contestName string,
) (*LedgerEntry, error) {
	// Free contests don't create wallet transactions (amount must be non-zero per DB constraint)
	// The participation is recorded in contest_participants table
	return nil, nil
}

// RefundContestEntryFee refunds the entry fee to a user's wallet.
// Must be called within a transaction.
func (s *Service) RefundContestEntryFee(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	contestID string,
	entryFeeCents int64,
) (*LedgerEntry, error) {
	return s.RefundContestEntryFeeWithReason(ctx, tx, userID, contestID, "", entryFeeCents, ReasonCodeContestRefundQuorum)
}

// RefundContestEntryFeeWithReason refunds the entry fee with a specific reason code.
// Must be called within a transaction.
func (s *Service) RefundContestEntryFeeWithReason(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	contestID string,
	contestName string,
	entryFeeCents int64,
	reasonCode ReasonCode,
) (*LedgerEntry, error) {
	if entryFeeCents <= 0 {
		return nil, nil // No fee to refund
	}

	refType := LedgerRefTypeContest
	var desc string
	label := contestID
	if contestName != "" {
		label = contestName
	}
	switch reasonCode {
	case ReasonCodeContestRefundAdmin:
		desc = fmt.Sprintf("Refund: Contest %s cancelled by admin", label)
	case ReasonCodeContestRefundLeave:
		desc = fmt.Sprintf("Refund: Left contest %s", label)
	default:
		desc = fmt.Sprintf("Refund: Contest %s cancelled (minimum participants not reached)", label)
	}

	return s.CreditWithReason(ctx, tx, userID, entryFeeCents, LedgerTypeContestRefund, &refType, &contestID, &desc, &reasonCode)
}

// GenerateRefundIdempotencyKey generates a deterministic idempotency key for refunds.
// Format: refund:{contest_id}:{user_id}
func GenerateRefundIdempotencyKey(contestID, userID string) string {
	return fmt.Sprintf("refund:%s:%s", contestID, userID)
}

// RefundContestEntryFeeIdempotent refunds the entry fee with idempotency protection.
// Prevents double-refunds if called multiple times for the same contest+user.
// Must be called within a transaction.
func (s *Service) RefundContestEntryFeeIdempotent(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	contestID string,
	contestName string,
	entryFeeCents int64,
	reasonCode ReasonCode,
) (*LedgerEntry, error) {
	if entryFeeCents <= 0 {
		return nil, nil
	}

	idempotencyKey := GenerateRefundIdempotencyKey(contestID, userID)

	refType := LedgerRefTypeContest
	var desc string
	label := contestID
	if contestName != "" {
		label = contestName
	}
	switch reasonCode {
	case ReasonCodeContestRefundAdmin:
		desc = fmt.Sprintf("Refund: Contest %s cancelled by admin", label)
	case ReasonCodeContestRefundLeave:
		desc = fmt.Sprintf("Refund: Left contest %s", label)
	default:
		desc = fmt.Sprintf("Refund: Contest %s cancelled (minimum participants not reached)", label)
	}

	return s.CreditIdempotentWithReason(ctx, tx, userID, entryFeeCents, LedgerTypeContestRefund, &refType, &contestID, &desc, &reasonCode, idempotencyKey)
}

// CreditPrize credits prize money to a user's wallet.
// Must be called within a transaction.
// DEPRECATED: Use CreditPrizeIdempotent for idempotent prize credits.
func (s *Service) CreditPrize(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	contestID string,
	prizeCents int64,
) (*LedgerEntry, error) {
	if prizeCents <= 0 {
		return nil, nil // No prize to credit
	}

	refType := LedgerRefTypeContest
	reasonCode := ReasonCodeContestPrize
	desc := fmt.Sprintf("Prize for contest %s", contestID)

	return s.CreditWithReason(ctx, tx, userID, prizeCents, LedgerTypePrizeCredit, &refType, &contestID, &desc, &reasonCode)
}

// GeneratePrizeIdempotencyKey generates a deterministic idempotency key for prize credits.
// Format: finalization:{contest_id}:{user_id}:{rank}
func GeneratePrizeIdempotencyKey(contestID, userID string, rank int) string {
	return fmt.Sprintf("finalization:%s:%s:%d", contestID, userID, rank)
}

// CheckPrizeCreditExists checks if a prize credit with the given idempotency key
// already exists in the wallet_ledger table. This provides a DB-level fallback
// for idempotency checking that is independent of error type detection.
func (s *Service) CheckPrizeCreditExists(ctx context.Context, idempotencyKey string) (bool, error) {
	var exists bool
	err := s.db.QueryRowContext(ctx,
		`SELECT EXISTS(SELECT 1 FROM wallet_ledger WHERE idempotency_key = $1)`,
		idempotencyKey,
	).Scan(&exists)
	if err != nil {
		return false, fmt.Errorf("failed to check prize credit existence: %w", err)
	}
	return exists, nil
}

// CreditPrizeIdempotent credits prize money to a user's wallet with idempotency protection.
// Must be called within a transaction.
//
// This function:
// 1. Generates a deterministic idempotency key: finalization:{contest_id}:{user_id}:{rank}
// 2. Checks if a wallet_ledger entry with this idempotency key already exists
// 3. If the entry exists, returns the existing entry and a DuplicatePrizeCreditError
// 4. If not, proceeds with the credit operation atomically
//
// The existence check and insert are wrapped in the same transaction to prevent TOCTOU race conditions.
//
// Returns:
//   - (*LedgerEntry, nil) on successful new credit
//   - (*LedgerEntry, *DuplicatePrizeCreditError) if credit was already processed (idempotent success)
//   - (nil, error) on actual errors
func (s *Service) CreditPrizeIdempotent(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	contestID string,
	rank int,
	prizeCents int64,
) (*LedgerEntry, error) {
	if prizeCents <= 0 {
		return nil, nil // No prize to credit
	}

	// Generate deterministic idempotency key
	idempotencyKey := GeneratePrizeIdempotencyKey(contestID, userID, rank)

	// Check if a ledger entry with this idempotency key already exists
	// This is done within the same transaction to prevent TOCTOU race conditions
	var existingEntry LedgerEntry
	var existingRefType, existingRefID, existingDesc, existingIdempKey, existingReasonCode sql.NullString
	err := tx.QueryRowContext(ctx,
		`SELECT id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, description, reason_code, idempotency_key, created_at
		 FROM wallet_ledger
		 WHERE idempotency_key = $1
		 FOR UPDATE`,
		idempotencyKey,
	).Scan(
		&existingEntry.ID,
		&existingEntry.UserID,
		&existingEntry.Type,
		&existingEntry.AmountCents,
		&existingEntry.BalanceAfterCents,
		&existingRefType,
		&existingRefID,
		&existingDesc,
		&existingReasonCode,
		&existingIdempKey,
		&existingEntry.CreatedAt,
	)

	if err == nil {
		// Entry already exists - this is idempotent success, not an error
		if existingRefType.Valid {
			refType := LedgerRefType(existingRefType.String)
			existingEntry.RefType = &refType
		}
		if existingRefID.Valid {
			existingEntry.RefID = &existingRefID.String
		}
		if existingDesc.Valid {
			existingEntry.Description = &existingDesc.String
		}
		if existingReasonCode.Valid {
			rc := ReasonCode(existingReasonCode.String)
			existingEntry.ReasonCode = &rc
		}
		if existingIdempKey.Valid {
			existingEntry.IdempotencyKey = &existingIdempKey.String
		}

		return &existingEntry, &DuplicatePrizeCreditError{
			IdempotencyKey: idempotencyKey,
			ExistingEntry:  &existingEntry,
		}
	}

	if !errors.Is(err, sql.ErrNoRows) {
		return nil, fmt.Errorf("failed to check for existing prize credit: %w", err)
	}

	// No existing entry - proceed with credit
	// Get current balance with lock
	balance, err := s.GetBalanceTx(ctx, tx, userID)
	if err != nil {
		// If wallet is frozen, still allow prize credits
		if _, ok := err.(*WalletFrozenError); ok {
			// Get balance without status check
			err = tx.QueryRowContext(ctx,
				`SELECT balance_cents FROM wallets WHERE user_id = $1 FOR UPDATE`,
				userID,
			).Scan(&balance)
			if err != nil {
				return nil, fmt.Errorf("failed to get balance: %w", err)
			}
		} else {
			return nil, err
		}
	}

	// Calculate new balance
	newBalance := balance + prizeCents

	// Update wallet balance
	_, err = tx.ExecContext(ctx,
		`UPDATE wallets SET balance_cents = $1, updated_at = NOW() WHERE user_id = $2`,
		newBalance, userID,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to update wallet balance: %w", err)
	}

	// Create ledger entry with idempotency key and reason code
	refType := LedgerRefTypeContest
	reasonCode := ReasonCodeContestPrize
	desc := fmt.Sprintf("Prize for contest %s (rank %d)", contestID, rank)

	entry, err := s.createLedgerEntryWithIdempotency(
		ctx, tx, userID, prizeCents, newBalance, LedgerTypePrizeCredit,
		&refType, &contestID, &desc, &reasonCode, &idempotencyKey,
	)
	if err != nil {
		return nil, err
	}

	return entry, nil
}

// CreditAffiliateCommission credits an affiliate commission to a referrer's wallet.
// commissionID is the UUID of the affiliate_commissions record.
func (s *Service) CreditAffiliateCommission(
	ctx context.Context,
	tx TxExecutor,
	userID string,
	commissionID string,
	commissionCents int64,
) (*LedgerEntry, error) {
	if commissionCents <= 0 {
		return nil, nil // No commission to credit
	}

	refType := LedgerRefTypeCommission
	desc := fmt.Sprintf("Affiliate commission %s", commissionID)

	return s.Credit(ctx, tx, userID, commissionCents, LedgerTypeAffiliateCommission, &refType, &commissionID, &desc)
}

// GetLedgerEntries retrieves ledger entries for a user with pagination.
func (s *Service) GetLedgerEntries(ctx context.Context, userID string, limit, offset int) ([]LedgerEntry, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	rows, err := s.db.QueryContext(ctx,
		`SELECT id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, description, reason_code, idempotency_key, created_at
		 FROM wallet_ledger
		 WHERE user_id = $1
		 ORDER BY created_at DESC
		 LIMIT $2 OFFSET $3`,
		userID, limit, offset,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to query ledger entries: %w", err)
	}
	defer rows.Close()

	var entries []LedgerEntry
	for rows.Next() {
		var e LedgerEntry
		if err := rows.Scan(&e.ID, &e.UserID, &e.Type, &e.AmountCents, &e.BalanceAfterCents,
			&e.RefType, &e.RefID, &e.Description, &e.ReasonCode, &e.IdempotencyKey, &e.CreatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan ledger entry: %w", err)
		}
		entries = append(entries, e)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("failed to iterate ledger entries: %w", err)
	}

	return entries, nil
}

// GetLedgerEntriesByType retrieves ledger entries for a user with optional type filtering and pagination.
// If ledgerType is empty, all types are returned.
func (s *Service) GetLedgerEntriesByType(ctx context.Context, userID string, ledgerType string, limit, offset int) ([]LedgerEntry, error) {
	if limit <= 0 {
		limit = 50
	}
	if limit > 100 {
		limit = 100
	}

	var rows *sql.Rows
	var err error

	if ledgerType != "" {
		rows, err = s.db.QueryContext(ctx,
			`SELECT id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, description, reason_code, idempotency_key, created_at
			 FROM wallet_ledger
			 WHERE user_id = $1 AND type = $2
			 ORDER BY created_at DESC
			 LIMIT $3 OFFSET $4`,
			userID, ledgerType, limit, offset,
		)
	} else {
		rows, err = s.db.QueryContext(ctx,
			`SELECT id, user_id, type, amount_cents, balance_after_cents, ref_type, ref_id, description, reason_code, idempotency_key, created_at
			 FROM wallet_ledger
			 WHERE user_id = $1
			 ORDER BY created_at DESC
			 LIMIT $2 OFFSET $3`,
			userID, limit, offset,
		)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to query ledger entries: %w", err)
	}
	defer rows.Close()

	var entries []LedgerEntry
	for rows.Next() {
		var e LedgerEntry
		if err := rows.Scan(&e.ID, &e.UserID, &e.Type, &e.AmountCents, &e.BalanceAfterCents,
			&e.RefType, &e.RefID, &e.Description, &e.ReasonCode, &e.IdempotencyKey, &e.CreatedAt); err != nil {
			return nil, fmt.Errorf("failed to scan ledger entry: %w", err)
		}
		entries = append(entries, e)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("failed to iterate ledger entries: %w", err)
	}

	return entries, nil
}

// CountLedgerEntriesByType returns the total number of ledger entries for a user, optionally filtered by type.
// If ledgerType is empty, all types are counted.
func (s *Service) CountLedgerEntriesByType(ctx context.Context, userID string, ledgerType string) (int, error) {
	var count int
	var err error

	if ledgerType != "" {
		err = s.db.QueryRowContext(ctx,
			`SELECT COUNT(*) FROM wallet_ledger WHERE user_id = $1 AND type = $2`,
			userID, ledgerType,
		).Scan(&count)
	} else {
		err = s.db.QueryRowContext(ctx,
			`SELECT COUNT(*) FROM wallet_ledger WHERE user_id = $1`,
			userID,
		).Scan(&count)
	}

	if err != nil {
		return 0, fmt.Errorf("failed to count ledger entries: %w", err)
	}
	return count, nil
}

// CountLedgerEntries returns the total number of ledger entries for a user.
func (s *Service) CountLedgerEntries(ctx context.Context, userID string) (int, error) {
	var count int
	err := s.db.QueryRowContext(ctx,
		`SELECT COUNT(*) FROM wallet_ledger WHERE user_id = $1`,
		userID,
	).Scan(&count)
	if err != nil {
		return 0, fmt.Errorf("failed to count ledger entries: %w", err)
	}
	return count, nil
}

// HasSufficientBalance checks if a user has sufficient balance for an operation.
func (s *Service) HasSufficientBalance(ctx context.Context, userID string, requiredCents int64) (bool, error) {
	wallet, err := s.GetWallet(ctx, userID)
	if err != nil {
		return false, err
	}

	if wallet.Status == WalletStatusFrozen {
		return false, &WalletFrozenError{UserID: userID}
	}

	return wallet.BalanceCents >= requiredCents, nil
}

// FreezeWallet freezes a user's wallet.
func (s *Service) FreezeWallet(ctx context.Context, userID string) error {
	_, err := s.db.ExecContext(ctx,
		`UPDATE wallets SET status = $1, updated_at = NOW() WHERE user_id = $2`,
		WalletStatusFrozen, userID,
	)
	if err != nil {
		return fmt.Errorf("failed to freeze wallet: %w", err)
	}
	return nil
}

// UnfreezeWallet unfreezes a user's wallet.
func (s *Service) UnfreezeWallet(ctx context.Context, userID string) error {
	_, err := s.db.ExecContext(ctx,
		`UPDATE wallets SET status = $1, updated_at = NOW() WHERE user_id = $2`,
		WalletStatusActive, userID,
	)
	if err != nil {
		return fmt.Errorf("failed to unfreeze wallet: %w", err)
	}
	return nil
}

// CheckWithdrawalLimits checks whether a withdrawal of the given amount would
// exceed the user's daily or monthly limits. Returns nil if within limits,
// or a *WithdrawalLimitExceededError describing which limit would be exceeded.
//
// defaultLimits provides the system-wide defaults. Per-user overrides (from the
// withdrawal_limits table) take precedence on a per-field basis.
func (s *Service) CheckWithdrawalLimits(
	ctx context.Context,
	userID string,
	amountCents int64,
	defaultLimits WithdrawalLimits,
) error {
	// Resolve effective limits (per-user override merged with defaults)
	limits, err := s.resolveWithdrawalLimits(ctx, userID, defaultLimits)
	if err != nil {
		return fmt.Errorf("failed to resolve withdrawal limits: %w", err)
	}

	// Query current usage from payouts table
	usage, err := s.getWithdrawalUsage(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get withdrawal usage: %w", err)
	}

	// Check daily count
	if limits.DailyCount > 0 && usage.DailyCount+1 > limits.DailyCount {
		return &WithdrawalLimitExceededError{
			LimitType:      "daily_count",
			LimitValue:     int64(limits.DailyCount),
			CurrentUsage:   int64(usage.DailyCount),
			RequestedValue: 1,
		}
	}

	// Check monthly count
	if limits.MonthlyCount > 0 && usage.MonthlyCount+1 > limits.MonthlyCount {
		return &WithdrawalLimitExceededError{
			LimitType:      "monthly_count",
			LimitValue:     int64(limits.MonthlyCount),
			CurrentUsage:   int64(usage.MonthlyCount),
			RequestedValue: 1,
		}
	}

	// Check daily amount
	if limits.DailyAmountCents > 0 && usage.DailyAmountCents+amountCents > limits.DailyAmountCents {
		return &WithdrawalLimitExceededError{
			LimitType:      "daily_amount",
			LimitValue:     limits.DailyAmountCents,
			CurrentUsage:   usage.DailyAmountCents,
			RequestedValue: amountCents,
		}
	}

	// Check monthly amount
	if limits.MonthlyAmountCents > 0 && usage.MonthlyAmountCents+amountCents > limits.MonthlyAmountCents {
		return &WithdrawalLimitExceededError{
			LimitType:      "monthly_amount",
			LimitValue:     limits.MonthlyAmountCents,
			CurrentUsage:   usage.MonthlyAmountCents,
			RequestedValue: amountCents,
		}
	}

	return nil
}

// resolveWithdrawalLimits fetches per-user overrides and merges with defaults.
func (s *Service) resolveWithdrawalLimits(
	ctx context.Context,
	userID string,
	defaults WithdrawalLimits,
) (WithdrawalLimits, error) {
	var dailyAmount, monthlyAmount sql.NullInt64
	var dailyCount, monthlyCount sql.NullInt32

	err := s.db.QueryRowContext(ctx,
		`SELECT daily_amount_cents, monthly_amount_cents, daily_count, monthly_count
		 FROM withdrawal_limits WHERE user_id = $1`,
		userID,
	).Scan(&dailyAmount, &monthlyAmount, &dailyCount, &monthlyCount)

	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return defaults, nil
		}
		return defaults, fmt.Errorf("failed to query withdrawal limits: %w", err)
	}

	// Merge: per-user overrides take precedence (non-NULL wins)
	result := defaults
	if dailyAmount.Valid {
		result.DailyAmountCents = dailyAmount.Int64
	}
	if monthlyAmount.Valid {
		result.MonthlyAmountCents = monthlyAmount.Int64
	}
	if dailyCount.Valid {
		result.DailyCount = int(dailyCount.Int32)
	}
	if monthlyCount.Valid {
		result.MonthlyCount = int(monthlyCount.Int32)
	}

	return result, nil
}

// getWithdrawalUsage queries the payouts table for current daily and monthly usage.
// Only counts payouts that are not cancelled or failed.
func (s *Service) getWithdrawalUsage(ctx context.Context, userID string) (WithdrawalUsage, error) {
	now := time.Now().UTC()
	startOfDay := time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, time.UTC)
	startOfMonth := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)

	var usage WithdrawalUsage

	err := s.db.QueryRowContext(ctx, `
		SELECT
			COALESCE(SUM(CASE WHEN created_at >= $2 THEN amount_cents ELSE 0 END), 0),
			COALESCE(SUM(amount_cents), 0),
			COALESCE(SUM(CASE WHEN created_at >= $2 THEN 1 ELSE 0 END), 0),
			COUNT(*)
		FROM payouts
		WHERE user_id = $1
		  AND created_at >= $3
		  AND status NOT IN ('cancelled', 'failed')
	`, userID, startOfDay, startOfMonth).Scan(
		&usage.DailyAmountCents,
		&usage.MonthlyAmountCents,
		&usage.DailyCount,
		&usage.MonthlyCount,
	)

	if err != nil {
		return usage, fmt.Errorf("failed to query withdrawal usage: %w", err)
	}

	return usage, nil
}
