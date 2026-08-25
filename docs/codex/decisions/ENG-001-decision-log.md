# ENG-001 decision log

**Date:** 2026-08-25  
**Branch:** `codex/eng-001-separate-trading-engine-runtime-and-define`

## Boundary

ENG-001 establishes:

1. Standalone Engine binary/image (`cmd/trading-engine`, `Dockerfile`).
2. Compose profile `engine-standalone` for independent restart.
3. Startup guards rejecting Market Data provider credentials and Platform JWT/session secrets.
4. Target Platform↔Engine contracts under `packages/contracts/engine/v1` (configuration, activation, order, freeze, close, snapshot, result) without banned product fields.

## Explicitly deferred

- Full cutover away from `trading-core` merged wrapper (`ENG001-TRADING-CORE-CUTOVER`).
- Wiring every Kafka consumer to the new engine/v1 contracts (compatibility remains on legacy `contracts/v1` until cutover).
- Fixed-point price/score conversion (ENG-002).
- Live Postgres engine-role permission E2E (inherits ARCH006 gap).
