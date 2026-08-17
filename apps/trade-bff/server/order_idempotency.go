package server

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"github.com/google/uuid"
)

// ErrClientOrderOwnership is returned when a client_order_id exists for another user/contest.
var ErrClientOrderOwnership = errors.New("client_order_id belongs to another user or contest")

// claimClientOrderID registers a durable logical submission identity.
// Policy: order_id == client_order_id (UUID). Concurrent claims with the same
// client_order_id return the existing mapping (isNew=false) without inserting.
func (a *App) claimClientOrderID(ctx context.Context, userID, contestID, clientOrderID string) (orderID string, isNew bool, err error) {
	if _, err := uuid.Parse(clientOrderID); err != nil {
		return "", false, fmt.Errorf("client_order_id must be a UUID: %w", err)
	}
	if a.pool == nil || a.pool.Primary() == nil {
		// No DB: fall through with client id as order id (dev-only safety net)
		return clientOrderID, true, nil
	}

	// Atomic claim: insert or no-op on conflict
	_, err = a.pool.Primary().ExecContext(ctx, `
		INSERT INTO order_client_submissions (client_order_id, user_id, contest_id, order_id)
		VALUES ($1::uuid, $2::uuid, $3::uuid, $1::uuid)
		ON CONFLICT (client_order_id) DO NOTHING
	`, clientOrderID, userID, contestID)
	if err != nil {
		// Table missing mid-migration: still use client id as order id
		if strings.Contains(err.Error(), "order_client_submissions") &&
			(strings.Contains(err.Error(), "does not exist") || strings.Contains(err.Error(), "undefined_table")) {
			return clientOrderID, true, nil
		}
		return "", false, fmt.Errorf("claim client_order_id: %w", err)
	}

	var ownerUser, ownerContest, mappedOrder string
	err = a.pool.Primary().QueryRowContext(ctx, `
		SELECT user_id::text, contest_id::text, order_id::text
		FROM order_client_submissions
		WHERE client_order_id = $1::uuid
	`, clientOrderID).Scan(&ownerUser, &ownerContest, &mappedOrder)
	if err == sql.ErrNoRows {
		return "", false, fmt.Errorf("client_order_id claim vanished")
	}
	if err != nil {
		return "", false, fmt.Errorf("load client_order_id claim: %w", err)
	}
	if ownerUser != userID || ownerContest != contestID {
		return "", false, ErrClientOrderOwnership
	}

	// Detect whether this claim created the row: use INSERT ... RETURNING pattern via
	// xmax=0 is not portable; instead re-run insert with DO NOTHING and check rows.
	// First insert already done; isNew is best-effort for logging only.
	// Concurrent first claims both publish the same order_id; engine PK is financial truth.
	var ageMs float64
	_ = a.pool.Primary().QueryRowContext(ctx, `
		SELECT EXTRACT(EPOCH FROM (NOW() - created_at)) * 1000
		FROM order_client_submissions WHERE client_order_id = $1::uuid
	`, clientOrderID).Scan(&ageMs)
	isNew = ageMs < 50 // same-request window; duplicates after this still share order_id
	return mappedOrder, isNew, nil
}

// resolveClientOrderID validates optional client-supplied identity or generates a new UUID.
// Empty client_order_id → new server UUID (backward compatible; not retry-safe).
func resolveClientOrderID(raw string) (string, error) {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return uuid.New().String(), nil
	}
	id, err := uuid.Parse(raw)
	if err != nil {
		return "", fmt.Errorf("client_order_id must be a UUID")
	}
	return id.String(), nil
}
