package db

import (
	"context"
	"database/sql"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"time"

	prizedistribution "github.com/Parsaeffatravesh/tragge/packages/scoring/distribution"
	"github.com/Parsaeffatravesh/tragge/packages/scoring/economics"
)

const (
	ContestSnapshotPolicyV1 = "contest_snapshot_v1"
	ContestFundsPolicyV1    = "2026-09-06.1"
	SnapshotConfirmed       = "contest_confirmed"
	SnapshotEconomicsCutoff = "economics_cutoff"
	SnapshotStarted         = "contest_started"
	SnapshotFinished        = "contest_finished"
)

var (
	ErrSnapshotNotReady  = errors.New("contest snapshot is not ready")
	ErrSnapshotConflict  = errors.New("contest snapshot conflicts with immutable history")
	ErrSnapshotIntegrity = errors.New("contest lifecycle snapshot integrity failure")
	ErrAdmissionEvidence = errors.New("contest admission financial evidence is incomplete or inconsistent")
)

type Snapshot struct {
	ID, ContestID, Type, Version, PolicyVersion                                string
	EventAt, CreatedAt, StartsAt, EndsAt                                       time.Time
	MinimumParticipants                                                        sql.NullInt64
	ParticipantCount                                                           int
	JoinedParticipantCount, EconomicParticipantCount, LeaderboardEligibleCount sql.NullInt64
	WinnerCapacityShortfall                                                    sql.NullBool
	EntryFeeCents, GrossBaseEntryCents                                         int64
	PlatformFeeBps                                                             int
	LateJoinEnabled                                                            bool
	PlatformFeeCents, LateSurchargeCents                                       int64
	PrizePoolCents                                                             int64
	PlannedWinnerCount                                                         int
	SettlementID                                                               sql.NullString
	Details                                                                    json.RawMessage
}

type SnapshotDB interface {
	ExecContext(context.Context, string, ...any) (sql.Result, error)
	QueryContext(context.Context, string, ...any) (*sql.Rows, error)
	QueryRowContext(context.Context, string, ...any) *sql.Row
}

const snapshotColumns = `id::text, contest_id::text, snapshot_type::text, snapshot_version,
 event_at, created_at, policy_version, minimum_participants, participant_count,
 starts_at, ends_at, entry_fee_cents, platform_fee_bps, late_join_enabled,
 COALESCE(gross_base_entry_cents,0), COALESCE(platform_fee_cents,0),
 COALESCE(late_surcharge_cents,0), COALESCE(prize_pool_cents,0),
 COALESCE(planned_winner_count,0), settlement_id::text, details,
 joined_participant_count, economic_participant_count, leaderboard_eligible_count,
 winner_capacity_shortfall`

func scanSnapshot(row interface{ Scan(...any) error }) (*Snapshot, error) {
	var s Snapshot
	err := row.Scan(&s.ID, &s.ContestID, &s.Type, &s.Version, &s.EventAt, &s.CreatedAt,
		&s.PolicyVersion, &s.MinimumParticipants, &s.ParticipantCount, &s.StartsAt, &s.EndsAt,
		&s.EntryFeeCents, &s.PlatformFeeBps, &s.LateJoinEnabled, &s.GrossBaseEntryCents,
		&s.PlatformFeeCents, &s.LateSurchargeCents, &s.PrizePoolCents,
		&s.PlannedWinnerCount, &s.SettlementID, &s.Details, &s.JoinedParticipantCount,
		&s.EconomicParticipantCount, &s.LeaderboardEligibleCount, &s.WinnerCapacityShortfall)
	return &s, err
}

// EnsureContestConfirmed creates the one-way confirmation fact inside the caller's admission transaction.
// The caller must already hold the contest row lock.
func EnsureContestConfirmed(ctx context.Context, tx SnapshotDB, contestID string) (*Snapshot, error) {
	var fundsPolicy string
	var poolAccounts int
	if err := tx.QueryRowContext(ctx, `SELECT c.funds_policy_version,
		(SELECT COUNT(*) FROM contest_prize_pool_accounts a WHERE a.contest_id=c.id)
		FROM contests c WHERE c.id=$1`, contestID).Scan(&fundsPolicy, &poolAccounts); err != nil {
		return nil, err
	}
	if fundsPolicy == "contest_funds_v1" && poolAccounts != 1 {
		return nil, fmt.Errorf("%w: modern contest %s has %d Prize Pool accounts", ErrSnapshotIntegrity, contestID, poolAccounts)
	}
	row := tx.QueryRowContext(ctx, `
WITH facts AS (
 SELECT c.id, c.min_participants,
   CASE WHEN COALESCE(c.is_free,FALSE) THEN 1 ELSE GREATEST(c.min_participants,2) END required,
   (SELECT COUNT(*) FROM contest_participants p WHERE p.contest_id=c.id AND NOT COALESCE(p.is_system,FALSE)) participants,
   c.starts_at,c.ends_at,COALESCE(c.locked_entry_fee_cents,c.entry_fee_cents) entry_fee,
   COALESCE(c.locked_platform_fee_bps,c.platform_fee_bps) fee_bps,
   COALESCE(c.late_join_enabled,TRUE) late_join_enabled,c.rules_json
 FROM contests c WHERE c.id=$1 AND c.lifecycle_policy_version=$2
), confirmed AS (
 UPDATE contests c SET confirmed_at=CURRENT_TIMESTAMP FROM facts f
 WHERE c.id=f.id AND c.confirmed_at IS NULL AND f.participants >= f.required
 RETURNING c.confirmed_at
), inserted AS (
 INSERT INTO contest_snapshots
 (contest_id,snapshot_type,snapshot_version,event_at,minimum_participants,participant_count,
  starts_at,ends_at,entry_fee_cents,platform_fee_bps,late_join_enabled,details)
 SELECT f.id,'contest_confirmed','contest_confirmed_v1',x.confirmed_at,f.required,f.participants,
        f.starts_at,f.ends_at,f.entry_fee,f.fee_bps,f.late_join_enabled,
        jsonb_build_object('rules',COALESCE(f.rules_json,'{}'::jsonb),'distribution_version','tralent_v1')
 FROM facts f CROSS JOIN confirmed x ON CONFLICT (contest_id,snapshot_type) DO NOTHING RETURNING `+snapshotColumns+`
)
SELECT `+snapshotColumns+` FROM inserted
UNION ALL SELECT `+snapshotColumns+` FROM contest_snapshots
 WHERE contest_id=$1 AND snapshot_type='contest_confirmed' LIMIT 1`, contestID, ContestSnapshotPolicyV1)
	s, err := scanSnapshot(row)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrSnapshotNotReady
	}
	return s, err
}

type cutoffContest struct {
	startsAt, endsAt time.Time
	startedAt        sql.NullTime
	entryFee         int64
	feeBps           int
	lateJoin         bool
	policy           string
	fundsPolicy      string
}

type cutoffParticipant struct {
	userID              string
	joinedAt            time.Time
	economic            bool
	leaderboardEligible bool
}

func cutoffPopulation(participants []cutoffParticipant) (economic, leaderboard int) {
	for _, participant := range participants {
		if participant.economic {
			economic++
		}
		if participant.leaderboardEligible {
			leaderboard++
		}
	}
	return economic, leaderboard
}

// EnsureEconomicsCutoff owns the entire serialized cutoff decision. The caller
// supplies only identity and transaction; participant count, winner planning,
// admission reconciliation, and snapshot values are derived while this method
// holds the contest row lock.
func EnsureEconomicsCutoff(ctx context.Context, tx SnapshotDB, contestID string) (*Snapshot, error) {
	var contest cutoffContest
	if err := tx.QueryRowContext(ctx, `
		SELECT c.starts_at,c.ends_at,s.event_at,
		       COALESCE(c.locked_entry_fee_cents,c.entry_fee_cents),
		       COALESCE(c.locked_platform_fee_bps,c.platform_fee_bps),
		       COALESCE(c.late_join_enabled,TRUE),c.lifecycle_policy_version,c.funds_policy_version
		FROM contests c
		LEFT JOIN contest_snapshots s ON s.contest_id=c.id AND s.snapshot_type='contest_started'
		WHERE c.id=$1 FOR UPDATE OF c`, contestID).Scan(
		&contest.startsAt, &contest.endsAt, &contest.startedAt, &contest.entryFee,
		&contest.feeBps, &contest.lateJoin, &contest.policy, &contest.fundsPolicy,
	); err != nil {
		return nil, err
	}
	if contest.policy != ContestSnapshotPolicyV1 {
		return nil, ErrSnapshotNotReady
	}
	if existing, err := SnapshotByType(ctx, tx, contestID, SnapshotEconomicsCutoff); err == nil {
		return existing, nil
	} else if !errors.Is(err, sql.ErrNoRows) {
		return nil, err
	}
	if !contest.startedAt.Valid {
		return nil, fmt.Errorf("%w: modern contest %s is missing contest_started", ErrSnapshotIntegrity, contestID)
	}
	cutoffAt := economics.LateJoinCutoff(contest.startsAt, contest.endsAt)
	var ready bool
	if err := tx.QueryRowContext(ctx, `SELECT CURRENT_TIMESTAMP >= $1`, cutoffAt).Scan(&ready); err != nil {
		return nil, err
	}
	if !ready {
		return nil, ErrSnapshotNotReady
	}

	rows, err := tx.QueryContext(ctx, `SELECT p.user_id::text,p.joined_at,
		CASE WHEN $2=0 THEN p.lifecycle_status NOT IN ('REFUNDED','CANCELLED')
		ELSE EXISTS (
			SELECT 1 FROM wallet_ledger admission
			WHERE admission.idempotency_key='contest_entry:'||p.contest_id::text||':'||p.user_id::text
			AND admission.type='contest_entry' AND admission.amount_cents < 0
			AND NOT EXISTS (SELECT 1 FROM wallet_ledger reversal WHERE reversal.original_transaction_id=admission.id)
		) END,
		p.lifecycle_status='ACTIVE' AND p.has_started_trading=TRUE
		FROM contest_participants p
		WHERE contest_id=$1 AND NOT COALESCE(is_system,FALSE) ORDER BY user_id`, contestID, contest.entryFee)
	if err != nil {
		return nil, err
	}
	var participants []cutoffParticipant
	for rows.Next() {
		var participant cutoffParticipant
		if err := rows.Scan(&participant.userID, &participant.joinedAt, &participant.economic,
			&participant.leaderboardEligible); err != nil {
			rows.Close()
			return nil, err
		}
		participants = append(participants, participant)
	}
	if err := rows.Err(); err != nil {
		rows.Close()
		return nil, err
	}
	if err := rows.Close(); err != nil {
		return nil, err
	}

	baseFee, surcharge := int64(0), int64(0)
	economicCount, leaderboardCount := cutoffPopulation(participants)
	for _, participant := range participants {
		if !participant.economic {
			continue
		}
		participantBaseFee, participantSurcharge, err := validateAdmissionEvidence(ctx, tx, contestID, contest, participant)
		if err != nil {
			return nil, err
		}
		if participantBaseFee > math.MaxInt64-baseFee || participantSurcharge > math.MaxInt64-surcharge {
			return nil, fmt.Errorf("%w: cutoff total overflow", ErrAdmissionEvidence)
		}
		baseFee += participantBaseFee
		surcharge += participantSurcharge
	}
	if contest.entryFee < 0 || (economicCount > 0 && contest.entryFee > math.MaxInt64/int64(economicCount)) {
		return nil, fmt.Errorf("%w: gross entry overflow", ErrAdmissionEvidence)
	}
	gross := int64(economicCount) * contest.entryFee
	pool := gross - baseFee
	if gross < 0 || baseFee < 0 || surcharge < 0 || pool < 0 || gross != baseFee+pool {
		return nil, fmt.Errorf("%w: impossible cutoff reconciliation", ErrAdmissionEvidence)
	}
	if contest.fundsPolicy == "contest_funds_v1" {
		var custodyBalance, ledgerBalance int64
		var entryCount int
		if err := tx.QueryRowContext(ctx, `SELECT a.balance_cents,
			(SELECT COALESCE(SUM(l.amount_cents),0) FROM contest_prize_pool_ledger l WHERE l.pool_account_id=a.id),
			(SELECT COUNT(*) FROM contest_prize_pool_ledger admission
			 WHERE admission.pool_account_id=a.id AND admission.direction='credit'
			 AND NOT EXISTS (SELECT 1 FROM contest_prize_pool_ledger reversal
			                 WHERE reversal.original_ledger_id=admission.id))
			FROM contest_prize_pool_accounts a WHERE a.contest_id=$1`, contestID).Scan(&custodyBalance, &ledgerBalance, &entryCount); err != nil {
			return nil, fmt.Errorf("%w: missing Prize Pool custody: %v", ErrSnapshotIntegrity, err)
		}
		if err := validatePrizePoolReconciliation(custodyBalance, ledgerBalance, entryCount, pool, economicCount); err != nil {
			return nil, err
		}
	}
	plannedWinners := prizedistribution.TralentV1PlannedWinners(economicCount)

	row := tx.QueryRowContext(ctx, `
WITH inserted AS (
 INSERT INTO contest_snapshots
 (contest_id,snapshot_type,snapshot_version,event_at,participant_count,starts_at,ends_at,
  entry_fee_cents,platform_fee_bps,late_join_enabled,gross_base_entry_cents,platform_fee_cents,
  late_surcharge_cents,prize_pool_cents,planned_winner_count,details,joined_participant_count,
  economic_participant_count,leaderboard_eligible_count,winner_capacity_shortfall)
 SELECT id,'economics_cutoff','economics_cutoff_v1',$2,$3,starts_at,ends_at,$4,$5,late_join_enabled,
  $6,$7,$8,$9,$10,jsonb_build_object('distribution_version','tralent_v1'),$3,$11,$12,$12<$10 FROM contests
 WHERE id=$1 AND lifecycle_policy_version=$13 AND CURRENT_TIMESTAMP >= $2
 ON CONFLICT (contest_id,snapshot_type) DO NOTHING RETURNING `+snapshotColumns+`
), event AS (
 INSERT INTO economic_adjustment_events(contest_id,event_type,previous_state,new_state,reason)
 SELECT contest_id,'ECONOMIC_SNAPSHOT_CREATED',NULL,'SNAPSHOT','ECONOMICS_CUTOFF' FROM inserted
 ON CONFLICT (contest_id,event_type) WHERE event_type='ECONOMIC_SNAPSHOT_CREATED' DO NOTHING
)
SELECT `+snapshotColumns+` FROM inserted UNION ALL SELECT `+snapshotColumns+` FROM contest_snapshots
	 WHERE contest_id=$1 AND snapshot_type='economics_cutoff' LIMIT 1`, contestID, cutoffAt,
		len(participants), contest.entryFee, contest.feeBps, gross, baseFee, surcharge, pool,
		plannedWinners, economicCount, leaderboardCount, ContestSnapshotPolicyV1)
	s, err := scanSnapshot(row)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrSnapshotNotReady
	}
	return s, err
}

func validatePrizePoolReconciliation(custodyBalance, ledgerBalance int64, entryCount int, expectedPool int64, expectedAdmissions int) error {
	if custodyBalance != expectedPool || ledgerBalance != expectedPool || entryCount != expectedAdmissions {
		return fmt.Errorf("%w: Prize Pool custody=%d ledger=%d entries=%d expected=%d/%d",
			ErrSnapshotIntegrity, custodyBalance, ledgerBalance, entryCount, expectedPool, expectedAdmissions)
	}
	return nil
}

func validateAdmissionEvidence(ctx context.Context, tx SnapshotDB, contestID string, contest cutoffContest, participant cutoffParticipant) (int64, int64, error) {
	admissionID := contestID + ":" + participant.userID
	expectedBaseFee, _ := economics.SplitEntryFee(contest.entryFee, contest.feeBps)
	isLate := !participant.joinedAt.Before(contest.startedAt.Time)
	if isLate && (!contest.lateJoin || !participant.joinedAt.Before(economics.LateJoinCutoff(contest.startsAt, contest.endsAt))) {
		return 0, 0, fmt.Errorf("%w: impossible late admission %s", ErrAdmissionEvidence, admissionID)
	}
	expectedSurcharge := int64(0)
	if isLate {
		expectedSurcharge = economics.LateJoinSurchargeCents(contest.entryFee)
	}

	if contest.entryFee > 0 {
		var count int
		var amount int64
		var userID, entryType, refType, refID, reasonCode, key string
		err := tx.QueryRowContext(ctx, `SELECT COUNT(*),COALESCE(MIN(amount_cents),0),
		 COALESCE(MIN(user_id::text),''),COALESCE(MIN(type::text),''),COALESCE(MIN(ref_type::text),''),
		 COALESCE(MIN(ref_id::text),''),COALESCE(MIN(reason_code),''),COALESCE(MIN(idempotency_key),'')
		 FROM wallet_ledger WHERE idempotency_key=$1`, "contest_entry:"+admissionID).Scan(
			&count, &amount, &userID, &entryType, &refType, &refID, &reasonCode, &key)
		if err != nil || count != 1 || amount != -(contest.entryFee+expectedSurcharge) ||
			userID != participant.userID || entryType != "contest_entry" || refType != "contest" ||
			refID != contestID || reasonCode != "CONTEST_ENTRY" || key != "contest_entry:"+admissionID {
			return 0, 0, fmt.Errorf("%w: wallet admission %s", ErrAdmissionEvidence, admissionID)
		}
	}

	type feeEvidence struct {
		kind, admissionID, contestID, userID, policy string
		amount                                       int64
		bps                                          int
		original                                     sql.NullString
	}
	feeRows, err := tx.QueryContext(ctx, `SELECT entry_kind,amount_cents,admission_id,
		contest_id::text,participant_user_id::text,policy_version,platform_fee_bps,original_entry_id::text
		FROM contest_fee_ledger WHERE admission_id=$1 OR (contest_id=$2 AND participant_user_id=$3)`,
		admissionID, contestID, participant.userID)
	if err != nil {
		return 0, 0, err
	}
	var evidence []feeEvidence
	for feeRows.Next() {
		var item feeEvidence
		if err := feeRows.Scan(&item.kind, &item.amount, &item.admissionID, &item.contestID,
			&item.userID, &item.policy, &item.bps, &item.original); err != nil {
			feeRows.Close()
			return 0, 0, err
		}
		evidence = append(evidence, item)
	}
	if err := feeRows.Err(); err != nil {
		feeRows.Close()
		return 0, 0, err
	}
	if err := feeRows.Close(); err != nil {
		return 0, 0, err
	}

	baseMatches, surchargeMatches := 0, 0
	for _, item := range evidence {
		contextMatches := item.admissionID == admissionID && item.contestID == contestID &&
			item.userID == participant.userID && item.policy == ContestFundsPolicyV1 && item.bps == contest.feeBps && !item.original.Valid
		switch item.kind {
		case "contest_base_fee":
			if contextMatches && item.amount == expectedBaseFee && expectedBaseFee > 0 {
				baseMatches++
			} else {
				return 0, 0, fmt.Errorf("%w: base fee %s", ErrAdmissionEvidence, admissionID)
			}
		case "contest_late_surcharge":
			if contextMatches && item.amount == expectedSurcharge && expectedSurcharge > 0 {
				surchargeMatches++
			} else {
				return 0, 0, fmt.Errorf("%w: surcharge %s", ErrAdmissionEvidence, admissionID)
			}
		default:
			return 0, 0, fmt.Errorf("%w: reversal or unknown fee %s", ErrAdmissionEvidence, admissionID)
		}
	}
	if (expectedBaseFee > 0 && baseMatches != 1) || (expectedBaseFee == 0 && baseMatches != 0) ||
		(expectedSurcharge > 0 && surchargeMatches != 1) || (expectedSurcharge == 0 && surchargeMatches != 0) {
		return 0, 0, fmt.Errorf("%w: fee row cardinality %s", ErrAdmissionEvidence, admissionID)
	}
	return expectedBaseFee, expectedSurcharge, nil
}

func SnapshotByType(ctx context.Context, q SnapshotDB, contestID, typ string) (*Snapshot, error) {
	return scanSnapshot(q.QueryRowContext(ctx, `SELECT `+snapshotColumns+` FROM contest_snapshots WHERE contest_id=$1 AND snapshot_type=$2::contest_snapshot_type`, contestID, typ))
}

func ListSnapshots(ctx context.Context, q SnapshotDB, contestID string) ([]Snapshot, error) {
	rows, err := q.QueryContext(ctx, `SELECT `+snapshotColumns+` FROM contest_snapshots WHERE contest_id=$1 ORDER BY event_at,created_at,id`, contestID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []Snapshot
	for rows.Next() {
		s, err := scanSnapshot(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *s)
	}
	return out, rows.Err()
}

func LatestSnapshot(ctx context.Context, q SnapshotDB, contestID string) (*Snapshot, error) {
	return scanSnapshot(q.QueryRowContext(ctx, `SELECT `+snapshotColumns+` FROM contest_snapshots WHERE contest_id=$1 ORDER BY event_at DESC,created_at DESC,id DESC LIMIT 1`, contestID))
}

func ensureSimple(ctx context.Context, tx SnapshotDB, contestID, typ, settlementID string, details any) (*Snapshot, error) {
	b, err := json.Marshal(details)
	if err != nil {
		return nil, err
	}
	row := tx.QueryRowContext(ctx, `
WITH c AS (SELECT * FROM contests WHERE id=$1 AND lifecycle_policy_version=$2 FOR UPDATE), inserted AS (
 INSERT INTO contest_snapshots(contest_id,snapshot_type,snapshot_version,event_at,participant_count,
 starts_at,ends_at,entry_fee_cents,platform_fee_bps,late_join_enabled,settlement_id,details)
 SELECT c.id,$3::contest_snapshot_type,$3||'_v1',
 CASE WHEN $3='contest_started' THEN c.started_at ELSE COALESCE(c.settled_at,CURRENT_TIMESTAMP) END,
 (SELECT COUNT(*) FROM contest_participants p WHERE p.contest_id=c.id AND NOT COALESCE(p.is_system,FALSE)),
 c.starts_at,c.ends_at,COALESCE(c.locked_entry_fee_cents,c.entry_fee_cents),
 COALESCE(c.locked_platform_fee_bps,c.platform_fee_bps),c.late_join_enabled,NULLIF($4,'')::uuid,$5::jsonb FROM c
 ON CONFLICT(contest_id,snapshot_type) DO NOTHING RETURNING `+snapshotColumns+`)
SELECT `+snapshotColumns+` FROM inserted UNION ALL SELECT `+snapshotColumns+` FROM contest_snapshots
WHERE contest_id=$1 AND snapshot_type=$3::contest_snapshot_type LIMIT 1`, contestID, ContestSnapshotPolicyV1, typ, settlementID, b)
	s, err := scanSnapshot(row)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrSnapshotNotReady
	}
	return s, err
}

func EnsureContestStarted(ctx context.Context, tx SnapshotDB, contestID string) (*Snapshot, error) {
	return ensureSimple(ctx, tx, contestID, SnapshotStarted, "", map[string]any{"trading_configuration_version": "contest_snapshot_v1"})
}

func EnsureContestFinished(ctx context.Context, tx SnapshotDB, contestID, settlementID string) (*Snapshot, error) {
	row := tx.QueryRowContext(ctx, `
WITH c AS (
 SELECT c.* FROM contests c
 JOIN contest_settlements cs ON cs.id=$3 AND cs.contest_id=c.id AND cs.status='completed'
 WHERE c.id=$1 AND c.lifecycle_policy_version=$2 FOR UPDATE OF c,cs
), inserted AS (
 INSERT INTO contest_snapshots(contest_id,snapshot_type,snapshot_version,event_at,participant_count,
 starts_at,ends_at,entry_fee_cents,platform_fee_bps,late_join_enabled,settlement_id,details)
 SELECT c.id,'contest_finished','contest_finished_v1',c.settled_at,
 (SELECT COUNT(*) FROM contest_participants p WHERE p.contest_id=c.id AND NOT COALESCE(p.is_system,FALSE)),
 c.starts_at,c.ends_at,COALESCE(c.locked_entry_fee_cents,c.entry_fee_cents),
 COALESCE(c.locked_platform_fee_bps,c.platform_fee_bps),c.late_join_enabled,$3::uuid,
 jsonb_build_object(
   'result_schema','contest_finished_v1','rank_zero_compatible',true,
   'settlement_status',(SELECT status::text FROM contest_settlements WHERE id=$3),
   'rankings',COALESCE((SELECT jsonb_agg(jsonb_build_object('user_id',user_id,'rank',rank,
      'final_score',final_score,'total_trades',total_trades) ORDER BY rank,user_id)
      FROM final_rankings WHERE contest_id=c.id AND settlement_id=$3),'[]'::jsonb),
   'winners',COALESCE((SELECT jsonb_agg(jsonb_build_object('user_id',user_id,'rank',rank,
      'amount_cents',prize_amount_cents,'status',status) ORDER BY rank,user_id)
      FROM prize_distributions WHERE contest_id=c.id AND settlement_id=$3),'[]'::jsonb))
 FROM c ON CONFLICT(contest_id,snapshot_type) DO NOTHING RETURNING `+snapshotColumns+`)
SELECT `+snapshotColumns+` FROM inserted UNION ALL SELECT `+snapshotColumns+` FROM contest_snapshots
WHERE contest_id=$1 AND snapshot_type='contest_finished' LIMIT 1`, contestID, ContestSnapshotPolicyV1, settlementID)
	s, err := scanSnapshot(row)
	if errors.Is(err, sql.ErrNoRows) {
		return nil, ErrSnapshotNotReady
	}
	if err != nil {
		return nil, err
	}
	var existing string
	if s.SettlementID.Valid {
		existing = s.SettlementID.String
	}
	if existing != settlementID {
		return nil, fmt.Errorf("%w: finished settlement %s != %s", ErrSnapshotConflict, existing, settlementID)
	}
	return s, nil
}
