package server

import (
	"bufio"
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"sync"
	"sync/atomic"
	"time"

	"github.com/Parsaeffatravesh/tragge/packages/infra"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"go.uber.org/zap"
)

// WAL operation types
type WALOperationType string

const (
	WALOpUpdatePosition      WALOperationType = "update_position"
	WALOpClosePosition       WALOperationType = "close_position"
	WALOpCreatePosition      WALOperationType = "create_position"
	WALOpUpdateQtyAvailable  WALOperationType = "update_qty_available"
	WALOpUpdateRealizedScore WALOperationType = "update_realized_score"
	WALOpAddPendingOrder     WALOperationType = "add_pending_order"
	WALOpRemovePendingOrder  WALOperationType = "remove_pending_order"
)

// WAL entry status
type WALEntryStatus string

const (
	WALStatusPending    WALEntryStatus = "pending"
	WALStatusCommitted  WALEntryStatus = "committed"
	WALStatusRolledBack WALEntryStatus = "rolled_back"
)

// WALEntry represents a single entry in the Write-Ahead Log.
type WALEntry struct {
	SeqNum    uint64           `json:"seq_num"`
	Operation WALOperationType `json:"operation"`
	Status    WALEntryStatus   `json:"status"`
	Timestamp time.Time        `json:"timestamp"`

	// Context for the operation
	ContestID string `json:"contest_id"`
	UserID    string `json:"user_id"`
	Symbol    string `json:"symbol,omitempty"`

	// Operation-specific data (JSON-encoded)
	Data []byte `json:"data"`

	// For replay verification
	DBTxID string `json:"db_tx_id,omitempty"` // Unique ID for DB verification
}

// PositionUpdateData holds data for position update operations.
type PositionUpdateData struct {
	PositionID    string  `json:"position_id"`
	Symbol        string  `json:"symbol"`
	Side          string  `json:"side"`
	QtyOpen       int64   `json:"qty_open"`
	EntryPrice    float64 `json:"entry_price"`
	QtyUsed       int64   `json:"qty_used"`
	RealizedScore float64 `json:"realized_score"`
}

// QtyScoreUpdateData holds data for quantity and score updates.
type QtyScoreUpdateData struct {
	NewQtyAvailable  int64   `json:"new_qty_available"`
	NewRealizedScore float64 `json:"new_realized_score"`
	DeltaScore       float64 `json:"delta_score"`
}

// PendingOrderData holds data for pending order operations.
type PendingOrderData struct {
	OrderID    string   `json:"order_id"`
	Symbol     string   `json:"symbol"`
	Side       string   `json:"side"`
	Type       string   `json:"type"`
	Qty        int64    `json:"qty"`
	LimitPrice *float64 `json:"limit_price,omitempty"`
	StopPrice  *float64 `json:"stop_price,omitempty"`
}

// WALConfig holds configuration for the WAL.
type WALConfig struct {
	MaxEntries  int    // Maximum entries in ring buffer (default: 10000)
	PersistPath string // Path to WAL file for crash recovery; empty = in-memory only
	// SyncOnWrite when true (default if PersistPath set) fsyncs each entry before Write returns.
	// This is required so crash recovery can observe every acknowledged durable event.
	SyncOnWrite bool
	// FailClosedLoad when true (default) refuses to start if the WAL file is corrupt/unreadable.
	FailClosedLoad bool
}

// DefaultWALConfig returns default WAL configuration.
func DefaultWALConfig() WALConfig {
	return WALConfig{
		MaxEntries:     10000,
		SyncOnWrite:    true,
		FailClosedLoad: true,
	}
}

// ErrWALNotDurable is returned when a durable write is required but persistence failed.
var ErrWALNotDurable = fmt.Errorf("WAL durable write failed")

// ErrWALReplayFailed is returned when startup replay cannot complete safely.
var ErrWALReplayFailed = fmt.Errorf("WAL replay failed")

// WAL file record types for JSON Lines persistence.
const (
	walFileRecordEntry  = "entry"
	walFileRecordStatus = "status"
)

// WALFileRecord is a single line in the WAL file (JSON Lines format).
type WALFileRecord struct {
	Type   string         `json:"type"`
	Entry  *WALEntry      `json:"entry,omitempty"`
	SeqNum uint64         `json:"seq_num,omitempty"`
	Status WALEntryStatus `json:"status,omitempty"`
}

// Prometheus metrics for WAL
var (
	walEntriesTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "trading_engine_wal_entries_total",
			Help: "Total number of WAL entries created",
		},
		[]string{"operation", "status"},
	)

	walDivergenceEvents = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "trading_engine_wal_divergence_events_total",
			Help: "Total number of state divergence events detected",
		},
	)

	walReplayedEntries = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "trading_engine_wal_replayed_entries_total",
			Help: "Total number of WAL entries replayed on startup",
		},
	)

	walBufferUsage = promauto.NewGauge(
		prometheus.GaugeOpts{
			Name: "trading_engine_wal_buffer_usage",
			Help: "Current number of entries in WAL buffer",
		},
	)
)

// WriteAheadLog is an in-memory ring buffer for tracking state operations,
// with optional file-based persistence for crash recovery.
type WriteAheadLog struct {
	entries    []WALEntry
	head       int // Next write position
	tail       int // Oldest entry position
	size       int // Current number of entries
	maxEntries int

	seqCounter atomic.Uint64
	mu         sync.RWMutex

	// seqIndex maps sequence numbers to ring buffer indices for O(1) lookup.
	// Maintained by Write() and cleaned up when ring buffer overwrites entries.
	seqIndex map[uint64]int

	// State divergence tracking
	stateDiverged atomic.Bool
	divergedAt    time.Time
	divergenceMu  sync.RWMutex

	// Fail-closed health: once set, trading must remain NOT READY.
	unhealthy   atomic.Bool
	lastFailure atomic.Value // string

	// File persistence
	persistPath    string
	syncOnWrite    bool
	failClosedLoad bool
	file           *os.File
	fileMu         sync.Mutex

	// Async file persistence for non-critical status marks (committed/rolled_back).
	// Entry Write() always uses synchronous durable path when persistPath is set.
	flushCh   chan WALFileRecord
	flushDone chan struct{}

	logger *zap.Logger
}

const (
	// walFlushBufferSize is the channel buffer size for async WAL persistence.
	walFlushBufferSize = 4096
	// walFlushInterval is how often the flusher goroutine syncs to disk.
	walFlushInterval = 10 * time.Millisecond
	// walFlushBatchSize is the max records to write per fsync batch.
	walFlushBatchSize = 256
)

// NewWriteAheadLog creates a new Write-Ahead Log.
// If config.PersistPath is set, pending entries are recovered from the file on startup.
// Fail-closed: load or open errors return an error (never silently disable persistence).
// Durable path always fsyncs entry records on Write before returning.
func NewWriteAheadLog(config WALConfig, logger *zap.Logger) (*WriteAheadLog, error) {
	if config.MaxEntries <= 0 {
		config.MaxEntries = 10000
	}

	// Durable backend always uses fail-closed load + sync-on-write for launch safety.
	syncOnWrite := true
	failClosedLoad := true
	if config.PersistPath == "" {
		syncOnWrite = false
		failClosedLoad = false
	}

	w := &WriteAheadLog{
		entries:        make([]WALEntry, config.MaxEntries),
		maxEntries:     config.MaxEntries,
		seqIndex:       make(map[uint64]int, config.MaxEntries),
		logger:         logger,
		persistPath:    config.PersistPath,
		syncOnWrite:    syncOnWrite,
		failClosedLoad: failClosedLoad,
	}

	if config.PersistPath != "" {
		if err := w.loadFromFile(); err != nil {
			w.markUnhealthy(fmt.Sprintf("WAL load failed: %v", err))
			return nil, fmt.Errorf("%w: load %s: %v", ErrWALReplayFailed, config.PersistPath, err)
		}

		// Open file for appending — never silently disable persistence.
		f, err := os.OpenFile(config.PersistPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0640)
		if err != nil {
			w.markUnhealthy(fmt.Sprintf("WAL open failed: %v", err))
			return nil, fmt.Errorf("%w: open %s: %v", ErrWALNotDurable, config.PersistPath, err)
		}
		w.file = f
		// Start async flusher for status records only (entries use sync path).
		w.flushCh = make(chan WALFileRecord, walFlushBufferSize)
		w.flushDone = make(chan struct{})
		infra.SafeGo(w.logger, "wal-flusher", func() { w.flusherLoop() })
	}

	return w, nil
}

// MustNewWriteAheadLog is a test helper that panics on error.
func MustNewWriteAheadLog(config WALConfig, logger *zap.Logger) *WriteAheadLog {
	w, err := NewWriteAheadLog(config, logger)
	if err != nil {
		panic(err)
	}
	return w
}

// markUnhealthy records a critical WAL failure (fail-closed).
func (w *WriteAheadLog) markUnhealthy(reason string) {
	w.unhealthy.Store(true)
	w.lastFailure.Store(reason)
	if w.logger != nil {
		w.logger.Error("CRITICAL: WAL marked unhealthy (fail-closed)",
			zap.String("reason", reason))
	}
}

// IsHealthy returns false when the WAL cannot safely support trading.
func (w *WriteAheadLog) IsHealthy() bool {
	if w == nil {
		return false
	}
	return !w.unhealthy.Load() && !w.stateDiverged.Load()
}

// UnhealthyReason returns the last failure reason, if any.
func (w *WriteAheadLog) UnhealthyReason() string {
	if v := w.lastFailure.Load(); v != nil {
		if s, ok := v.(string); ok {
			return s
		}
	}
	if w.stateDiverged.Load() {
		return "state divergence detected"
	}
	return ""
}

// IsPersistent reports whether this WAL has a durable file backend.
func (w *WriteAheadLog) IsPersistent() bool {
	return w != nil && w.persistPath != "" && w.file != nil
}

// loadFromFile reads the WAL file and loads pending entries into the ring buffer.
func (w *WriteAheadLog) loadFromFile() error {
	data, err := os.ReadFile(w.persistPath)
	if os.IsNotExist(err) {
		return nil // No file yet, nothing to load
	}
	if err != nil {
		return fmt.Errorf("read WAL file: %w", err)
	}

	// Parse all records: build map of entries, then apply status updates
	entries := make(map[uint64]*WALEntry)
	var maxSeq uint64

	scanner := bufio.NewScanner(bytes.NewReader(data))
	scanner.Buffer(make([]byte, 1024*1024), 1024*1024) // 1MB line limit
	lineNo := 0
	for scanner.Scan() {
		lineNo++
		line := scanner.Bytes()
		if len(line) == 0 {
			continue
		}

		var record WALFileRecord
		if err := json.Unmarshal(line, &record); err != nil {
			if w.failClosedLoad {
				return fmt.Errorf("corrupt WAL record at line %d: %w", lineNo, err)
			}
			continue
		}
		if record.Type != walFileRecordEntry && record.Type != walFileRecordStatus {
			if w.failClosedLoad {
				return fmt.Errorf("unknown WAL record type %q at line %d", record.Type, lineNo)
			}
			continue
		}

		switch record.Type {
		case walFileRecordEntry:
			if record.Entry != nil {
				entryCopy := *record.Entry
				entries[entryCopy.SeqNum] = &entryCopy
				if entryCopy.SeqNum > maxSeq {
					maxSeq = entryCopy.SeqNum
				}
			}
		case walFileRecordStatus:
			if e, ok := entries[record.SeqNum]; ok {
				e.Status = record.Status
			}
		}
	}
	if err := scanner.Err(); err != nil {
		return fmt.Errorf("scan WAL file: %w", err)
	}

	// Load only pending entries into the ring buffer in deterministic seq order.
	pendingList := make([]*WALEntry, 0, len(entries))
	for _, entry := range entries {
		if entry.Status == WALStatusPending {
			pendingList = append(pendingList, entry)
		}
	}
	sort.Slice(pendingList, func(i, j int) bool {
		return pendingList[i].SeqNum < pendingList[j].SeqNum
	})

	var pendingCount int
	for _, entry := range pendingList {
		if w.size >= w.maxEntries {
			// Ring buffer full — shouldn't happen normally, but be safe
			break
		}
		w.entries[w.head] = *entry
		w.seqIndex[entry.SeqNum] = w.head
		w.head = (w.head + 1) % w.maxEntries
		w.size++
		pendingCount++
	}

	// Set sequence counter to continue from the highest seen
	w.seqCounter.Store(maxSeq)

	if w.logger != nil {
		w.logger.Info("WAL loaded from file",
			zap.Int("pending_entries", pendingCount),
			zap.Uint64("max_seq_num", maxSeq),
			zap.String("path", w.persistPath))
	}

	return nil
}

// appendToFile enqueues a record for async batch persistence.
// If async flushing is not available, falls back to synchronous write.
func (w *WriteAheadLog) appendToFile(record WALFileRecord) {
	if w.flushCh != nil {
		select {
		case w.flushCh <- record:
			return
		default:
			// Channel full — fall through to synchronous write
			if w.logger != nil {
				w.logger.Warn("WAL flush channel full, falling back to synchronous write")
			}
		}
	}

	// Synchronous fallback (also used when persistence is not configured)
	if err := w.syncWriteRecord(record); err != nil {
		w.markUnhealthy(fmt.Sprintf("syncWriteRecord failed: %v", err))
	}
}

// syncWriteRecord writes a single record synchronously with fsync.
// Returns an error if the durable write cannot be completed.
func (w *WriteAheadLog) syncWriteRecord(record WALFileRecord) error {
	if w.file == nil {
		return nil
	}

	w.fileMu.Lock()
	defer w.fileMu.Unlock()

	data, err := json.Marshal(record)
	if err != nil {
		if w.logger != nil {
			w.logger.Error("Failed to marshal WAL file record", zap.Error(err))
		}
		return fmt.Errorf("marshal WAL record: %w", err)
	}

	data = append(data, '\n')
	if _, err := w.file.Write(data); err != nil {
		if w.logger != nil {
			w.logger.Error("Failed to write WAL file record", zap.Error(err))
		}
		return fmt.Errorf("write WAL record: %w", err)
	}

	if err := w.file.Sync(); err != nil {
		if w.logger != nil {
			w.logger.Error("Failed to fsync WAL file", zap.Error(err))
		}
		return fmt.Errorf("fsync WAL: %w", err)
	}
	return nil
}

// flusherLoop is the async batch flusher goroutine.
// It drains the flush channel, batches writes, and does a single fsync per batch.
// Captures the channel locally so Close can nil w.flushCh without hanging the select.
func (w *WriteAheadLog) flusherLoop() {
	defer close(w.flushDone)

	ch := w.flushCh
	if ch == nil {
		return
	}

	ticker := time.NewTicker(walFlushInterval)
	defer ticker.Stop()

	batch := make([]WALFileRecord, 0, walFlushBatchSize)

	for {
		select {
		case record, ok := <-ch:
			if !ok {
				// Channel closed — flush remaining and exit
				w.flushBatch(batch)
				return
			}
			batch = append(batch, record)
			// Drain up to batch size without blocking
			for len(batch) < walFlushBatchSize {
				select {
				case r, ok2 := <-ch:
					if !ok2 {
						w.flushBatch(batch)
						return
					}
					batch = append(batch, r)
				default:
					goto flush
				}
			}
		flush:
			w.flushBatch(batch)
			batch = batch[:0]

		case <-ticker.C:
			if len(batch) > 0 {
				w.flushBatch(batch)
				batch = batch[:0]
			}
		}
	}
}

// flushBatch writes a batch of records and fsyncs once.
func (w *WriteAheadLog) flushBatch(records []WALFileRecord) {
	if len(records) == 0 || w.file == nil {
		return
	}

	w.fileMu.Lock()
	defer w.fileMu.Unlock()

	for i := range records {
		data, err := json.Marshal(&records[i])
		if err != nil {
			if w.logger != nil {
				w.logger.Error("Failed to marshal WAL file record", zap.Error(err))
			}
			continue
		}
		data = append(data, '\n')
		if _, err := w.file.Write(data); err != nil {
			if w.logger != nil {
				w.logger.Error("Failed to write WAL file record", zap.Error(err))
			}
			return // Stop on write error
		}
	}

	if err := w.file.Sync(); err != nil {
		if w.logger != nil {
			w.logger.Error("Failed to fsync WAL file", zap.Error(err))
		}
	}
}

// Write creates a new WAL entry and returns its sequence number.
// When a persist path is configured, the entry is fsynced before Write returns
// (durable-before-mutate contract for ExecuteWithWAL).
// On durable write failure the entry is not retained and the WAL is marked unhealthy.
func (w *WriteAheadLog) Write(op WALOperationType, contestID, userID, symbol string, data []byte) (uint64, error) {
	if w.unhealthy.Load() {
		return 0, fmt.Errorf("%w: %s", ErrWALNotDurable, w.UnhealthyReason())
	}

	w.mu.Lock()

	seqNum := w.seqCounter.Add(1)

	entry := WALEntry{
		SeqNum:    seqNum,
		Operation: op,
		Status:    WALStatusPending,
		Timestamp: time.Now().UTC(),
		ContestID: contestID,
		UserID:    userID,
		Symbol:    symbol,
		Data:      data,
		DBTxID:    fmt.Sprintf("wal-%d", seqNum),
	}

	// If ring buffer is full, remove the overwritten entry from the index
	if w.size >= w.maxEntries {
		overwrittenSeq := w.entries[w.head].SeqNum
		if overwrittenSeq > 0 {
			delete(w.seqIndex, overwrittenSeq)
		}
	}

	slot := w.head
	w.entries[slot] = entry
	w.seqIndex[seqNum] = slot
	w.head = (w.head + 1) % w.maxEntries

	if w.size < w.maxEntries {
		w.size++
	} else {
		// Ring buffer full, move tail
		w.tail = (w.tail + 1) % w.maxEntries
	}

	walEntriesTotal.WithLabelValues(string(op), string(WALStatusPending)).Inc()
	walBufferUsage.Set(float64(w.size))

	// Copy entry for file persistence (before releasing lock)
	entryCopy := entry
	w.mu.Unlock()

	// Durable path: fsync before caller may mutate DB / acknowledge.
	if w.file != nil && w.syncOnWrite {
		if err := w.syncWriteRecord(WALFileRecord{
			Type:  walFileRecordEntry,
			Entry: &entryCopy,
		}); err != nil {
			// Roll back ring buffer entry so we never treat non-durable events as pending.
			w.mu.Lock()
			if idx, ok := w.seqIndex[seqNum]; ok && w.entries[idx].SeqNum == seqNum {
				w.entries[idx].Status = WALStatusRolledBack
				delete(w.seqIndex, seqNum)
			}
			w.mu.Unlock()
			w.markUnhealthy(fmt.Sprintf("durable Write failed seq=%d: %v", seqNum, err))
			return 0, fmt.Errorf("%w: %v", ErrWALNotDurable, err)
		}
		return seqNum, nil
	}

	// In-memory or async path (dev/test without persist file).
	if w.file != nil {
		w.appendToFile(WALFileRecord{
			Type:  walFileRecordEntry,
			Entry: &entryCopy,
		})
	}

	return seqNum, nil
}

// MarkCommitted marks a WAL entry as committed after successful DB and in-memory update.
// Status is durably fsynced when a persist file is configured so restart does not re-apply.
func (w *WriteAheadLog) MarkCommitted(seqNum uint64) bool {
	w.mu.Lock()

	idx, ok := w.seqIndex[seqNum]
	if !ok {
		w.mu.Unlock()
		return false
	}
	if w.entries[idx].SeqNum != seqNum {
		// Defensive: index is stale (should not happen with correct maintenance)
		delete(w.seqIndex, seqNum)
		w.mu.Unlock()
		return false
	}
	w.entries[idx].Status = WALStatusCommitted
	walEntriesTotal.WithLabelValues(string(w.entries[idx].Operation), string(WALStatusCommitted)).Inc()
	w.mu.Unlock()

	// Persist status change durably (sync) so recovery never re-applies committed work.
	if err := w.syncWriteRecord(WALFileRecord{
		Type:   walFileRecordStatus,
		SeqNum: seqNum,
		Status: WALStatusCommitted,
	}); err != nil {
		w.markUnhealthy(fmt.Sprintf("MarkCommitted fsync failed seq=%d: %v", seqNum, err))
		return false
	}

	return true
}

// MarkRolledBack marks a WAL entry as rolled back after DB transaction failure.
func (w *WriteAheadLog) MarkRolledBack(seqNum uint64) bool {
	w.mu.Lock()

	idx, ok := w.seqIndex[seqNum]
	if !ok {
		w.mu.Unlock()
		return false
	}
	if w.entries[idx].SeqNum != seqNum {
		// Defensive: index is stale (should not happen with correct maintenance)
		delete(w.seqIndex, seqNum)
		w.mu.Unlock()
		return false
	}
	w.entries[idx].Status = WALStatusRolledBack
	walEntriesTotal.WithLabelValues(string(w.entries[idx].Operation), string(WALStatusRolledBack)).Inc()
	w.mu.Unlock()

	if err := w.syncWriteRecord(WALFileRecord{
		Type:   walFileRecordStatus,
		SeqNum: seqNum,
		Status: WALStatusRolledBack,
	}); err != nil {
		w.markUnhealthy(fmt.Sprintf("MarkRolledBack fsync failed seq=%d: %v", seqNum, err))
		return false
	}

	return true
}

// GetPendingEntries returns all entries with pending status.
func (w *WriteAheadLog) GetPendingEntries() []WALEntry {
	w.mu.RLock()
	defer w.mu.RUnlock()

	var pending []WALEntry
	for i := 0; i < w.size; i++ {
		idx := (w.tail + i) % w.maxEntries
		if w.entries[idx].Status == WALStatusPending {
			// Make a copy
			entryCopy := w.entries[idx]
			dataCopy := make([]byte, len(w.entries[idx].Data))
			copy(dataCopy, w.entries[idx].Data)
			entryCopy.Data = dataCopy
			pending = append(pending, entryCopy)
		}
	}
	return pending
}

// SetDiverged marks the state as diverged.
func (w *WriteAheadLog) SetDiverged() {
	w.divergenceMu.Lock()
	defer w.divergenceMu.Unlock()

	if !w.stateDiverged.Load() {
		w.stateDiverged.Store(true)
		w.divergedAt = time.Now()
		walDivergenceEvents.Inc()

		if w.logger != nil {
			w.logger.Error("CRITICAL: State divergence detected - in-memory state differs from database",
				zap.Time("diverged_at", w.divergedAt))
		}
	}
}

// ClearDiverged clears the divergence flag after successful reload.
func (w *WriteAheadLog) ClearDiverged() {
	w.divergenceMu.Lock()
	defer w.divergenceMu.Unlock()

	w.stateDiverged.Store(false)
	w.divergedAt = time.Time{}
}

// IsDiverged returns whether state divergence has been detected.
func (w *WriteAheadLog) IsDiverged() bool {
	return w.stateDiverged.Load()
}

// GetDivergenceInfo returns information about state divergence.
func (w *WriteAheadLog) GetDivergenceInfo() (bool, time.Time) {
	w.divergenceMu.RLock()
	defer w.divergenceMu.RUnlock()

	return w.stateDiverged.Load(), w.divergedAt
}

// GetStats returns statistics about the WAL.
func (w *WriteAheadLog) GetStats() WALStats {
	w.mu.RLock()
	defer w.mu.RUnlock()

	stats := WALStats{
		TotalEntries:  w.size,
		MaxEntries:    w.maxEntries,
		CurrentSeqNum: w.seqCounter.Load(),
		IsDiverged:    w.stateDiverged.Load(),
	}

	for i := 0; i < w.size; i++ {
		idx := (w.tail + i) % w.maxEntries
		switch w.entries[idx].Status {
		case WALStatusPending:
			stats.PendingCount++
		case WALStatusCommitted:
			stats.CommittedCount++
		case WALStatusRolledBack:
			stats.RolledBackCount++
		}
	}

	w.divergenceMu.RLock()
	stats.DivergedAt = w.divergedAt
	w.divergenceMu.RUnlock()

	return stats
}

// WALStats holds statistics about the WAL.
type WALStats struct {
	TotalEntries    int       `json:"total_entries"`
	MaxEntries      int       `json:"max_entries"`
	PendingCount    int       `json:"pending_count"`
	CommittedCount  int       `json:"committed_count"`
	RolledBackCount int       `json:"rolled_back_count"`
	CurrentSeqNum   uint64    `json:"current_seq_num"`
	IsDiverged      bool      `json:"is_diverged"`
	DivergedAt      time.Time `json:"diverged_at,omitempty"`
}

// Compact rewrites the WAL file to contain only pending entries.
// This reduces file size and speeds up future recovery.
func (w *WriteAheadLog) Compact() error {
	if w.persistPath == "" {
		return nil
	}

	// Drain async flush channel before compacting to ensure all writes are on disk
	if w.flushCh != nil {
		// Close the flusher channel and wait for it to drain
		close(w.flushCh)
		<-w.flushDone
		w.flushCh = nil
	}

	pending := w.GetPendingEntries()

	w.fileMu.Lock()
	defer w.fileMu.Unlock()

	// Close current file
	if w.file != nil {
		w.file.Close()
		w.file = nil
	}

	// Write pending entries to a temp file
	tmpPath := w.persistPath + ".tmp"
	tmpFile, err := os.Create(tmpPath)
	if err != nil {
		return fmt.Errorf("create temp WAL file: %w", err)
	}

	for i := range pending {
		record := WALFileRecord{Type: walFileRecordEntry, Entry: &pending[i]}
		data, marshalErr := json.Marshal(record)
		if marshalErr != nil {
			tmpFile.Close()
			os.Remove(tmpPath)
			return fmt.Errorf("marshal WAL entry during compaction: %w", marshalErr)
		}
		data = append(data, '\n')
		if _, writeErr := tmpFile.Write(data); writeErr != nil {
			tmpFile.Close()
			os.Remove(tmpPath)
			return fmt.Errorf("write WAL entry during compaction: %w", writeErr)
		}
	}

	if err := tmpFile.Sync(); err != nil {
		tmpFile.Close()
		os.Remove(tmpPath)
		return fmt.Errorf("fsync temp WAL file: %w", err)
	}
	tmpFile.Close()

	// Atomic rename
	if err := os.Rename(tmpPath, w.persistPath); err != nil {
		return fmt.Errorf("rename temp WAL file: %w", err)
	}

	// Reopen for appending
	f, err := os.OpenFile(w.persistPath, os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("reopen WAL file after compaction: %w", err)
	}
	w.file = f

	// Restart async flusher goroutine
	w.flushCh = make(chan WALFileRecord, walFlushBufferSize)
	w.flushDone = make(chan struct{})
	go w.flusherLoop()

	if w.logger != nil {
		w.logger.Info("WAL file compacted",
			zap.Int("pending_entries", len(pending)),
			zap.String("path", w.persistPath))
	}

	return nil
}

// Close drains any pending async writes and closes the WAL file handle.
// Safe to call multiple times.
func (w *WriteAheadLog) Close() error {
	// Stop the flusher goroutine and wait for it to drain (once).
	w.fileMu.Lock()
	ch := w.flushCh
	w.flushCh = nil
	w.fileMu.Unlock()

	if ch != nil {
		close(ch)
		<-w.flushDone
	}

	w.fileMu.Lock()
	defer w.fileMu.Unlock()
	if w.file != nil {
		err := w.file.Close()
		w.file = nil
		return err
	}
	return nil
}

// StateOperator wraps state operations with WAL protection.
type StateOperator struct {
	wal    *WriteAheadLog
	db     *sql.DB
	logger *zap.Logger

	// Callback for state reload on divergence
	onDivergence func(ctx context.Context) error
}

// NewStateOperator creates a new state operator with WAL protection.
func NewStateOperator(wal *WriteAheadLog, db *sql.DB, logger *zap.Logger) *StateOperator {
	return &StateOperator{
		wal:    wal,
		db:     db,
		logger: logger,
	}
}

// SetDivergenceCallback sets the callback function for handling state divergence.
func (so *StateOperator) SetDivergenceCallback(callback func(ctx context.Context) error) {
	so.onDivergence = callback
}

// ExecuteWithWAL executes a state change with WAL protection.
// Durability ordering (launch contract):
//
//	1. validate/serialize
//	2. append WAL entry + fsync (durable intent)
//	3. execute DB transaction + commit
//	4. mutate in-memory state
//	5. mark WAL committed
//	6. caller may acknowledge
//
// Never acknowledge an economically meaningful event that cannot be recovered:
// a durable Write failure aborts before DB mutation.
func (so *StateOperator) ExecuteWithWAL(
	ctx context.Context,
	op WALOperationType,
	contestID, userID, symbol string,
	data interface{},
	dbTxFunc func(ctx context.Context, tx *sql.Tx) error,
	memoryFunc func() error,
) error {
	// 1. Serialize operation data
	dataBytes, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("marshal WAL data: %w", err)
	}

	// 2. Durable Write to WAL (fsync when persist path configured)
	seqNum, err := so.wal.Write(op, contestID, userID, symbol, dataBytes)
	if err != nil {
		return fmt.Errorf("WAL durable write: %w", err)
	}

	so.logger.Debug("WAL entry created",
		zap.Uint64("seq_num", seqNum),
		zap.String("operation", string(op)),
		zap.String("contest_id", contestID),
		zap.String("user_id", userID))

	// 3. Execute database transaction
	tx, err := so.db.BeginTx(ctx, nil)
	if err != nil {
		so.wal.MarkRolledBack(seqNum)
		return fmt.Errorf("begin transaction: %w", err)
	}

	if err := dbTxFunc(ctx, tx); err != nil {
		if rbErr := tx.Rollback(); rbErr != nil {
			so.logger.Error("Failed to rollback transaction",
				zap.Uint64("seq_num", seqNum),
				zap.Error(rbErr))
		}
		so.wal.MarkRolledBack(seqNum)
		return fmt.Errorf("execute db transaction: %w", err)
	}

	if err := tx.Commit(); err != nil {
		so.wal.MarkRolledBack(seqNum)
		return fmt.Errorf("commit transaction: %w", err)
	}

	// 4. DB transaction succeeded - now update in-memory state
	if err := memoryFunc(); err != nil {
		// CRITICAL: DB committed but in-memory update failed
		so.logger.Error("CRITICAL: In-memory state update failed after DB commit - STATE DIVERGENCE",
			zap.Uint64("seq_num", seqNum),
			zap.String("operation", string(op)),
			zap.String("contest_id", contestID),
			zap.String("user_id", userID),
			zap.Error(err))

		so.wal.SetDiverged()

		// Trigger state reload if callback is set
		if so.onDivergence != nil {
			infra.SafeGo(so.logger, "wal-divergence-reload", func() {
				reloadCtx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
				defer cancel()

				if reloadErr := so.onDivergence(reloadCtx); reloadErr != nil {
					so.logger.Error("Failed to reload state after divergence",
						zap.Error(reloadErr))
				} else {
					so.wal.ClearDiverged()
					so.logger.Info("State successfully reloaded after divergence")
				}
			})
		}

		// Still mark as committed since DB has the change
		so.wal.MarkCommitted(seqNum)
		return fmt.Errorf("in-memory update failed (DB committed): %w", err)
	}

	// 5. Mark WAL entry as committed
	so.wal.MarkCommitted(seqNum)

	so.logger.Debug("WAL entry committed",
		zap.Uint64("seq_num", seqNum),
		zap.String("operation", string(op)))

	return nil
}

// ReplayPendingEntries replays pending WAL entries on startup.
// For each pending entry:
// - Check if the change exists in DB
// - If yes: apply to in-memory state, mark committed
// - If no: discard (mark rolled_back)
//
// Fail-closed: any DB check error or apply error aborts replay and returns
// ErrWALReplayFailed. The engine must remain NOT READY.
func (so *StateOperator) ReplayPendingEntries(ctx context.Context, applyFunc func(entry WALEntry) error) error {
	if so.wal == nil {
		return fmt.Errorf("%w: WAL is nil", ErrWALReplayFailed)
	}
	if !so.wal.IsHealthy() {
		return fmt.Errorf("%w: WAL unhealthy before replay: %s", ErrWALReplayFailed, so.wal.UnhealthyReason())
	}

	pending := so.wal.GetPendingEntries()
	if len(pending) == 0 {
		so.logger.Info("No pending WAL entries to replay")
		return nil
	}

	so.logger.Info("Replaying pending WAL entries",
		zap.Int("count", len(pending)))

	for _, entry := range pending {
		// Check if change exists in DB (based on operation type)
		exists, err := so.checkDBForChange(ctx, entry)
		if err != nil {
			reason := fmt.Sprintf("DB check failed for WAL seq=%d: %v", entry.SeqNum, err)
			so.logger.Error("CRITICAL: WAL replay aborted (fail-closed)",
				zap.Uint64("seq_num", entry.SeqNum),
				zap.Error(err))
			so.wal.markUnhealthy(reason)
			return fmt.Errorf("%w: %s", ErrWALReplayFailed, reason)
		}

		if exists {
			// Apply to in-memory state
			if err := applyFunc(entry); err != nil {
				reason := fmt.Sprintf("apply failed for WAL seq=%d: %v", entry.SeqNum, err)
				so.logger.Error("CRITICAL: WAL replay apply failed (fail-closed)",
					zap.Uint64("seq_num", entry.SeqNum),
					zap.Error(err))
				so.wal.markUnhealthy(reason)
				return fmt.Errorf("%w: %s", ErrWALReplayFailed, reason)
			}
			so.wal.MarkCommitted(entry.SeqNum)
			walReplayedEntries.Inc()
			so.logger.Debug("Replayed WAL entry",
				zap.Uint64("seq_num", entry.SeqNum),
				zap.String("operation", string(entry.Operation)))
		} else {
			// DB doesn't have the change - discard (crash before commit)
			so.wal.MarkRolledBack(entry.SeqNum)
			so.logger.Info("Discarded WAL entry (not in DB — crash before commit)",
				zap.Uint64("seq_num", entry.SeqNum),
				zap.String("operation", string(entry.Operation)))
		}
	}

	return nil
}

// checkDBForChange verifies if a WAL entry's change exists in the database.
func (so *StateOperator) checkDBForChange(ctx context.Context, entry WALEntry) (bool, error) {
	if so.db == nil {
		return false, fmt.Errorf("database is nil")
	}
	switch entry.Operation {
	case WALOpCreatePosition, WALOpUpdatePosition:
		var data PositionUpdateData
		if err := json.Unmarshal(entry.Data, &data); err != nil {
			return false, fmt.Errorf("unmarshal position data: %w", err)
		}
		return so.checkPositionExists(ctx, data.PositionID)

	case WALOpClosePosition:
		var data PositionUpdateData
		if err := json.Unmarshal(entry.Data, &data); err != nil {
			return false, fmt.Errorf("unmarshal position data: %w", err)
		}
		return so.checkPositionClosed(ctx, data.PositionID)

	case WALOpUpdateQtyAvailable, WALOpUpdateRealizedScore:
		// For participant updates, check the current values match
		var data QtyScoreUpdateData
		if err := json.Unmarshal(entry.Data, &data); err != nil {
			return false, fmt.Errorf("unmarshal qty/score data: %w", err)
		}
		return so.checkParticipantState(ctx, entry.ContestID, entry.UserID, data)

	case WALOpAddPendingOrder:
		var data PendingOrderData
		if err := json.Unmarshal(entry.Data, &data); err != nil {
			return false, fmt.Errorf("unmarshal pending order data: %w", err)
		}
		return so.checkPendingOrderExists(ctx, data.OrderID)

	case WALOpRemovePendingOrder:
		var data PendingOrderData
		if err := json.Unmarshal(entry.Data, &data); err != nil {
			return false, fmt.Errorf("unmarshal pending order data: %w", err)
		}
		exists, err := so.checkPendingOrderExists(ctx, data.OrderID)
		return !exists, err // Order should NOT exist if it was removed

	default:
		// Unknown operation - assume exists to be safe
		return true, nil
	}
}

func (so *StateOperator) checkPositionExists(ctx context.Context, positionID string) (bool, error) {
	var count int
	err := so.db.QueryRowContext(ctx, `
		SELECT COUNT(*) FROM positions WHERE position_id = $1
	`, positionID).Scan(&count)
	if err != nil {
		return false, err
	}
	return count > 0, nil
}

func (so *StateOperator) checkPositionClosed(ctx context.Context, positionID string) (bool, error) {
	var closedAt sql.NullTime
	err := so.db.QueryRowContext(ctx, `
		SELECT closed_at FROM positions WHERE position_id = $1
	`, positionID).Scan(&closedAt)
	if err == sql.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return closedAt.Valid, nil
}

func (so *StateOperator) checkParticipantState(ctx context.Context, contestID, userID string, data QtyScoreUpdateData) (bool, error) {
	var qtyAvailable int64
	var totalScore float64
	err := so.db.QueryRowContext(ctx, `
		SELECT qty_available, total_score
		FROM contest_participants
		WHERE contest_id = $1 AND user_id = $2
	`, contestID, userID).Scan(&qtyAvailable, &totalScore)
	if err == sql.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	// Check if values match (with small tolerance for floats)
	return qtyAvailable == data.NewQtyAvailable, nil
}

func (so *StateOperator) checkPendingOrderExists(ctx context.Context, orderID string) (bool, error) {
	var status string
	err := so.db.QueryRowContext(ctx, `
		SELECT status FROM orders WHERE order_id = $1
	`, orderID).Scan(&status)
	if err == sql.ErrNoRows {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	return status == "open" || status == "pending", nil
}

// GetWAL returns the underlying WAL for stats/monitoring.
func (so *StateOperator) GetWAL() *WriteAheadLog {
	return so.wal
}
