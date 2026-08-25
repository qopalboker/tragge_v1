# MD-001 decision log

**Date:** 2026-08-25  
**Branch:** `codex/md-001-create-versioned-fixed-point-market-data-c`

## Boundary

- Canonical tick is per-symbol `TickEvent` schema_version=2 with fixed-point bid/ask/last (units+scale), not float.
- Default price scale = DATA-001 `DefaultPriceScale` (8).
- Legacy `contracts/v1.TickSnapshot` remains for rollout; `FromV1Snapshot` marks quality=`degraded`.
- Continuity events: gap / stale / pause / resume / source_switch (`FeedControlEvent`). Silent sequence drops are rejected/detected.

## Explicitly deferred

- Kafka topic rename/cutover from `ticks.v1` (`MD001-KAFKA-V2-CUTOVER`)
- Full frontend chart/WS consumer migration (`MD001-FRONTEND-CUTOVER`)
- MD-005A admin provider selection UI (separate task)
- FIN-006 (separate)
