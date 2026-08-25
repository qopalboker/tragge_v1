# ARCH-006 — Schema ownership and transactional outbox/inbox

**Branch:** `codex/arch-006-implement-schema-ownership-and-transaction`  
**Commit:** `feat(events): add owned schemas and outbox inbox`

## What changed

| Area | Change |
|---|---|
| Target SQL | `0002`/`0003`/`0004` per-owner outbox, inbox, dead_letter, schema_migrations |
| Contracts | `packages/contracts/envelope/v1` + `schemas/envelope.v1.json` |
| Store | `packages/db/events` memory store (commit-durable, rollback-discard, inbox dedupe, ordering) |
| Platform | `internal/modules/events` wired into compose + worker jobs |
| Engine / Market Data | schema ownership markers + forbid cross-schema SQL helper |
| CI | `scripts/sec-arch006-schema-outbox.test.mjs` |

## Tests run this session

```text
go test ./events/...                 # packages/db
go test ./envelope/...               # packages/contracts
go test ./internal/modules/events/... ./internal/compose/...  # apps/platform
go test ./server -run TestEngineSchemaOwnerBoundary           # trading-engine
go test ./server -run TestMarketDataSchemaOwnerBoundary       # market-ingestor
node --test scripts/sec-arch006-schema-outbox.test.mjs
node --test scripts/database-migration-reset.test.mjs
```

## Gaps (not runtime-verified)

- Live Postgres permission tests (runtime roles cannot SELECT other schemas)
- Live crash-window integration against PostgreSQL
- Full domain table move out of legacy `public`
- Pre-existing: `scripts/database-migration-reset.test.mjs` still expects 100 legacy ups while tree has 111 (0101–0111 from earlier FIN/LIFECYCLE work); not introduced by ARCH-006
- Prior open gaps remain open: FIN003-*, FIN005-*, P0-FIN-06, LIFECYCLE*, ARCH001-DOCKER-IMAGE, ARCH003-*, ARCH004-*, ARCH005-SETTLEMENT-HTTP-CUTOVER
- Track: `ARCH006-POSTGRES-PERMISSIONS-E2E`, `ARCH006-BROKER-RELAY`
