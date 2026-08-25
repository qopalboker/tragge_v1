package events

import (
	"context"
	"encoding/json"
	"fmt"
	"sort"
	"sync"
	"time"

	envelopev1 "github.com/Parsaeffatravesh/tragge/packages/contracts/envelope/v1"
)

// Status values for outbox rows.
const (
	StatusPending   = "pending"
	StatusPublished = "published"
	StatusFailed    = "failed"
)

// OutboxRecord is a durable pending/published outbox row.
type OutboxRecord struct {
	Envelope     envelopev1.Envelope
	Status       string
	AttemptCount int
	NextAttempt  time.Time
	LastError    string
	PublishedAt  time.Time
	CreatedAt    time.Time
}

// DeadLetterRecord quarantines permanently failed envelopes.
type DeadLetterRecord struct {
	EventID      string
	ConsumerName string
	Direction    string
	Reason       string
	Envelope     envelopev1.Envelope
	FailedAt     time.Time
}

// MigrationRecord is one applied owner-schema migration checksum.
type MigrationRecord struct {
	MigrationID    string
	ChecksumSHA256 string
	AppliedAt      time.Time
	AppliedBy      string
	DurationMS     int
}

// Store is the transactional outbox/inbox port for one schema owner.
type Store interface {
	Owner() SchemaOwner
	Begin(ctx context.Context) (Tx, error)
	PendingOutbox(ctx context.Context, limit int) ([]OutboxRecord, error)
	DeadLetters(ctx context.Context) ([]DeadLetterRecord, error)
	HasInbox(ctx context.Context, consumer, eventID string) (bool, error)
	RecordMigration(ctx context.Context, rec MigrationRecord) error
	GetMigration(ctx context.Context, migrationID string) (MigrationRecord, bool, error)
}

// Tx is an owner-local unit of work. Outbox inserts are invisible until Commit.
type Tx interface {
	InsertOutbox(ctx context.Context, env envelopev1.Envelope) error
	RecordInbox(ctx context.Context, consumer string, env envelopev1.Envelope) (inserted bool, err error)
	MarkPublished(ctx context.Context, eventID string) error
	MarkFailed(ctx context.Context, eventID string, attempt int, next time.Time, lastErr string) error
	DeadLetter(ctx context.Context, direction, consumer, reason string, env envelopev1.Envelope) error
	Commit(ctx context.Context) error
	Rollback(ctx context.Context) error
}

type memoryStore struct {
	owner SchemaOwner
	mu    sync.Mutex

	outbox      map[string]OutboxRecord
	inbox       map[string]struct{} // consumer\x00eventID
	dead        []DeadLetterRecord
	migrations  map[string]MigrationRecord
	openTxCount int
}

// NewMemoryStore returns an in-process store for one schema owner.
// Crash-window semantics: uncommitted inserts are discarded on Rollback;
// Commit makes them durable for subsequent PendingOutbox reads.
func NewMemoryStore(owner SchemaOwner) (Store, error) {
	if err := owner.Validate(); err != nil {
		return nil, err
	}
	return &memoryStore{
		owner:      owner,
		outbox:     make(map[string]OutboxRecord),
		inbox:      make(map[string]struct{}),
		migrations: make(map[string]MigrationRecord),
	}, nil
}

func (s *memoryStore) Owner() SchemaOwner { return s.owner }

func (s *memoryStore) Begin(context.Context) (Tx, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.openTxCount++
	return &memoryTx{
		store:   s,
		outbox:  make(map[string]OutboxRecord),
		inbox:   make(map[string]struct{}),
		dead:    nil,
		publish: make(map[string]struct{}),
		fail:    make(map[string]failPatch),
	}, nil
}

type failPatch struct {
	attempt int
	next    time.Time
	err     string
}

type memoryTx struct {
	store    *memoryStore
	mu       sync.Mutex
	outbox   map[string]OutboxRecord
	inbox    map[string]struct{}
	dead     []DeadLetterRecord
	publish  map[string]struct{}
	fail     map[string]failPatch
	done     bool
}

func inboxKey(consumer, eventID string) string {
	return consumer + "\x00" + eventID
}

func (t *memoryTx) InsertOutbox(_ context.Context, env envelopev1.Envelope) error {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.done {
		return fmt.Errorf("events: tx closed")
	}
	if err := env.Validate(); err != nil {
		return err
	}
	if _, exists := t.outbox[env.EventID]; exists {
		return fmt.Errorf("events: duplicate outbox event_id %s", env.EventID)
	}
	now := time.Now().UTC()
	t.outbox[env.EventID] = OutboxRecord{
		Envelope:     env,
		Status:       StatusPending,
		AttemptCount: 0,
		NextAttempt:  now,
		CreatedAt:    now,
	}
	return nil
}

func (t *memoryTx) RecordInbox(_ context.Context, consumer string, env envelopev1.Envelope) (bool, error) {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.done {
		return false, fmt.Errorf("events: tx closed")
	}
	if consumer == "" {
		return false, fmt.Errorf("events: consumer_name is required")
	}
	if err := env.Validate(); err != nil {
		return false, err
	}
	key := inboxKey(consumer, env.EventID)
	t.store.mu.Lock()
	_, exists := t.store.inbox[key]
	t.store.mu.Unlock()
	if exists {
		return false, nil
	}
	if _, staged := t.inbox[key]; staged {
		return false, nil
	}
	t.inbox[key] = struct{}{}
	return true, nil
}

func (t *memoryTx) MarkPublished(_ context.Context, eventID string) error {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.done {
		return fmt.Errorf("events: tx closed")
	}
	t.publish[eventID] = struct{}{}
	return nil
}

func (t *memoryTx) MarkFailed(_ context.Context, eventID string, attempt int, next time.Time, lastErr string) error {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.done {
		return fmt.Errorf("events: tx closed")
	}
	t.fail[eventID] = failPatch{attempt: attempt, next: next, err: lastErr}
	return nil
}

func (t *memoryTx) DeadLetter(_ context.Context, direction, consumer, reason string, env envelopev1.Envelope) error {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.done {
		return fmt.Errorf("events: tx closed")
	}
	if direction != "outbox" && direction != "inbox" {
		return fmt.Errorf("events: invalid dead-letter direction %q", direction)
	}
	t.dead = append(t.dead, DeadLetterRecord{
		EventID:      env.EventID,
		ConsumerName: consumer,
		Direction:    direction,
		Reason:       reason,
		Envelope:     env,
		FailedAt:     time.Now().UTC(),
	})
	return nil
}

func (t *memoryTx) Commit(context.Context) error {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.done {
		return fmt.Errorf("events: tx closed")
	}
	t.store.mu.Lock()
	defer t.store.mu.Unlock()

	for id, rec := range t.outbox {
		if _, exists := t.store.outbox[id]; exists {
			t.done = true
			t.store.openTxCount--
			return fmt.Errorf("events: duplicate durable outbox event_id %s", id)
		}
		t.store.outbox[id] = rec
	}
	for key := range t.inbox {
		t.store.inbox[key] = struct{}{}
	}
	for id := range t.publish {
		rec, ok := t.store.outbox[id]
		if !ok {
			continue
		}
		rec.Status = StatusPublished
		rec.PublishedAt = time.Now().UTC()
		t.store.outbox[id] = rec
	}
	for id, patch := range t.fail {
		rec, ok := t.store.outbox[id]
		if !ok {
			continue
		}
		rec.AttemptCount = patch.attempt
		rec.NextAttempt = patch.next
		rec.LastError = patch.err
		if patch.attempt >= 5 {
			rec.Status = StatusFailed
		}
		t.store.outbox[id] = rec
	}
	t.store.dead = append(t.store.dead, t.dead...)
	t.done = true
	t.store.openTxCount--
	return nil
}

func (t *memoryTx) Rollback(context.Context) error {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.done {
		return nil
	}
	t.done = true
	t.store.mu.Lock()
	t.store.openTxCount--
	t.store.mu.Unlock()
	return nil
}

func (s *memoryStore) PendingOutbox(_ context.Context, limit int) ([]OutboxRecord, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	now := time.Now().UTC()
	out := make([]OutboxRecord, 0)
	for _, rec := range s.outbox {
		if rec.Status == StatusPending && !rec.NextAttempt.After(now) {
			out = append(out, rec)
		}
	}
	sort.Slice(out, func(i, j int) bool {
		if out[i].Envelope.OrderingKey == out[j].Envelope.OrderingKey {
			return out[i].Envelope.AggregateVersion < out[j].Envelope.AggregateVersion
		}
		return out[i].CreatedAt.Before(out[j].CreatedAt)
	})
	if limit > 0 && len(out) > limit {
		out = out[:limit]
	}
	return out, nil
}

func (s *memoryStore) DeadLetters(context.Context) ([]DeadLetterRecord, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	out := make([]DeadLetterRecord, len(s.dead))
	copy(out, s.dead)
	return out, nil
}

func (s *memoryStore) HasInbox(_ context.Context, consumer, eventID string) (bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	_, ok := s.inbox[inboxKey(consumer, eventID)]
	return ok, nil
}

func (s *memoryStore) RecordMigration(_ context.Context, rec MigrationRecord) error {
	if rec.MigrationID == "" || rec.ChecksumSHA256 == "" || rec.AppliedBy == "" {
		return fmt.Errorf("events: migration record incomplete")
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if existing, ok := s.migrations[rec.MigrationID]; ok {
		if existing.ChecksumSHA256 != rec.ChecksumSHA256 {
			return fmt.Errorf("events: checksum mismatch for %s", rec.MigrationID)
		}
		return nil
	}
	if rec.AppliedAt.IsZero() {
		rec.AppliedAt = time.Now().UTC()
	}
	s.migrations[rec.MigrationID] = rec
	return nil
}

func (s *memoryStore) GetMigration(_ context.Context, migrationID string) (MigrationRecord, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	rec, ok := s.migrations[migrationID]
	return rec, ok, nil
}

// MustJSON is a test helper for payload literals.
func MustJSON(v any) json.RawMessage {
	b, err := json.Marshal(v)
	if err != nil {
		panic(err)
	}
	return b
}
