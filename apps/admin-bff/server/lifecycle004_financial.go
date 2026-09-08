package server

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/domain/statemachine"
	"github.com/Parsaeffatravesh/tragge/packages/wallet"
	"github.com/google/uuid"
)

var errEconomicsCutoff = errors.New("participant removal is blocked after economics cutoff")
var errParticipantInactive = errors.New("participant is no longer active")

type removalResult struct {
	Refunded bool
	EventID  string
}

func (a *App) removeParticipantAtomic(ctx context.Context, contestID, participantID, actorID string, req participantRemovalRequest) (*removalResult, error) {
	refund, valid := req.refundDecision()
	if !valid {
		return nil, errors.New("invalid reason/refund decision")
	}
	tx, err := a.pool.Primary().BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	var contestName string
	if err := tx.QueryRowContext(ctx, `SELECT name FROM contests WHERE id=$1 FOR UPDATE`, contestID).Scan(&contestName); err != nil {
		return nil, err
	}
	var cutoff bool
	if err := tx.QueryRowContext(ctx, `SELECT EXISTS(SELECT 1 FROM contest_snapshots WHERE contest_id=$1 AND snapshot_type='economics_cutoff')`, contestID).Scan(&cutoff); err != nil {
		return nil, err
	}
	if cutoff {
		return nil, errEconomicsCutoff
	}
	var status string
	if err := tx.QueryRowContext(ctx, `SELECT lifecycle_status FROM contest_participants WHERE contest_id=$1 AND user_id=$2 FOR UPDATE`, contestID, participantID).Scan(&status); err != nil {
		return nil, err
	}
	if status != "ACTIVE" {
		return nil, errParticipantInactive
	}
	metadata, _ := json.Marshal(map[string]any{"admin_note": req.AdminNote})
	eventID := uuid.NewString()
	if _, err := tx.ExecContext(ctx, `INSERT INTO contest_participant_lifecycle_events(id,contest_id,participant_id,actor_id,event_type,reason,refund_decision,metadata)
		VALUES($1,$2,$3,$4,'PARTICIPANT_REMOVED',$5,$6,$7)`, eventID, contestID, participantID, actorID, req.Reason, refund, metadata); err != nil {
		return nil, err
	}
	result := &removalResult{Refunded: refund, EventID: eventID}
	if refund {
		reversal, err := wallet.NewService(a.pool.Primary()).ReverseContestAdmission(ctx, tx, contestID, participantID, actorID, eventID, req.Reason)
		if err != nil {
			return nil, err
		}
		if reversal.WalletOriginalID != "" {
			if _, err := tx.ExecContext(ctx, `INSERT INTO contest_participant_lifecycle_events(contest_id,participant_id,actor_id,event_type,reason,refund_decision,metadata)
				VALUES($1,$2,$3,'PARTICIPANT_REFUNDED',$4,true,$5)`, contestID, participantID, actorID, req.Reason, mustJSON(reversal)); err != nil {
				return nil, err
			}
		}
	}
	newStatus := "DISQUALIFIED"
	if refund {
		newStatus = "REFUNDED"
	}
	if _, err := tx.ExecContext(ctx, `UPDATE contest_participants SET lifecycle_status=$1,lifecycle_changed_at=NOW() WHERE contest_id=$2 AND user_id=$3`, newStatus, contestID, participantID); err != nil {
		return nil, err
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO audit_logs(actor_user_id,action,target_type,target_id,payload_json)
		VALUES($1,'contest.remove_participant','contest_participant',$2,$3)`, actorID, contestID, mustJSON(map[string]any{"participant_id": participantID, "reason": req.Reason, "refund": refund, "event_id": eventID, "contest_name": contestName})); err != nil {
		return nil, err
	}
	if err := tx.Commit(); err != nil {
		return nil, err
	}
	return result, nil
}

func mustJSON(v any) []byte { b, _ := json.Marshal(v); return b }

type cancellationResult struct {
	Participants     int
	Refunds          int
	AlreadyCancelled bool
}

func (a *App) cancelContestAtomic(ctx context.Context, contestID, actorID, reason string) (*cancellationResult, error) {
	if reason == "" {
		reason = "Cancelled by Super Admin"
	}
	tx, err := a.pool.Primary().BeginTx(ctx, nil)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback()
	var current string
	if err := tx.QueryRowContext(ctx, `SELECT status FROM contests WHERE id=$1 FOR UPDATE`, contestID).Scan(&current); err != nil {
		return nil, err
	}
	if current == string(statemachine.StatusCancelled) {
		return &cancellationResult{AlreadyCancelled: true}, nil
	}
	if !statemachine.CanTransition(statemachine.ContestStatus(current), statemachine.StatusCancelled) {
		return nil, fmt.Errorf("contest status %s cannot be cancelled", current)
	}
	rows, err := tx.QueryContext(ctx, `SELECT user_id::text FROM contest_participants WHERE contest_id=$1 AND lifecycle_status='ACTIVE' ORDER BY user_id FOR UPDATE`, contestID)
	if err != nil {
		return nil, err
	}
	var participantIDs []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			rows.Close()
			return nil, err
		}
		participantIDs = append(participantIDs, id)
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}
	result := &cancellationResult{Participants: len(participantIDs)}
	for _, participantID := range participantIDs {
		eventID := uuid.NewString()
		if _, err := tx.ExecContext(ctx, `INSERT INTO contest_participant_lifecycle_events(id,contest_id,participant_id,actor_id,event_type,reason,refund_decision)
			VALUES($1,$2,$3,$4,'CONTEST_CANCELLED',$5,true)`, eventID, contestID, participantID, actorID, reason); err != nil {
			return nil, err
		}
		reversal, err := wallet.NewService(a.pool.Primary()).ReverseContestAdmission(ctx, tx, contestID, participantID, actorID, eventID, reason)
		if err != nil {
			return nil, err
		}
		if reversal.WalletOriginalID != "" {
			result.Refunds++
			if _, err := tx.ExecContext(ctx, `INSERT INTO contest_participant_lifecycle_events(contest_id,participant_id,actor_id,event_type,reason,refund_decision,metadata)
			VALUES($1,$2,$3,'CONTEST_REFUND_COMPLETED',$4,true,$5)`, contestID, participantID, actorID, reason, mustJSON(reversal)); err != nil {
				return nil, err
			}
		}
		if _, err := tx.ExecContext(ctx, `UPDATE contest_participants SET lifecycle_status='CANCELLED',lifecycle_changed_at=NOW() WHERE contest_id=$1 AND user_id=$2`, contestID, participantID); err != nil {
			return nil, err
		}
	}
	now := time.Now().UTC()
	if _, err := tx.ExecContext(ctx, `UPDATE contests SET status='cancelled',cancelled_at=$1,cancellation_reason=$2 WHERE id=$3`, now, reason, contestID); err != nil {
		return nil, err
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO contest_status_history(contest_id,from_status,to_status,changed_by,reason,metadata) VALUES($1,$2,'cancelled',$3,$4,'{}')`, contestID, current, actorID, reason); err != nil {
		return nil, err
	}
	if _, err := tx.ExecContext(ctx, `INSERT INTO audit_logs(actor_user_id,action,target_type,target_id,payload_json) VALUES($1,'contest.cancelled','contest',$2,$3)`, actorID, contestID, mustJSON(map[string]any{"reason": reason, "participants": result.Participants, "refunds": result.Refunds})); err != nil {
		return nil, err
	}
	if err := tx.Commit(); err != nil {
		return nil, err
	}
	return result, nil
}
