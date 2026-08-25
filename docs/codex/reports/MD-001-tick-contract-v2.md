# MD-001 — Fixed-point market-data contract v2

**Branch:** `codex/md-001-create-versioned-fixed-point-market-data-c`  
**Commit:** `feat(marketdata): add tick contract v2`

## What changed

| Area | Change |
|---|---|
| Go contract | `packages/contracts/marketdata/v2` TickEvent + FeedControl + Engine accept + v1 compat |
| JSON schema | `packages/contracts/schemas/tick_event.v2.json` |
| TypeScript | `packages/contracts/ts/v2` + frontend-shared / user / admin type exports |
| Engine | `AcceptTickV2` stale/incompatible reject helper |
| Ingestor | legacy snapshot translator + explicit gap event builder |
| CI | `scripts/sec-md001-tick-v2.test.mjs` |

## Tests run this session

```text
go test ./marketdata/v2 -bench=BenchmarkTickEventMarshal -benchtime=10x
go test ./server -run TestAcceptTickV2RejectsStale          # trading-engine
go test ./server -run 'TestTranslateLegacySnapshot|TestNewGapEventRequiresMissing'  # market-ingestor
node --test scripts/sec-md001-tick-v2.test.mjs
```

## Gaps (not runtime-verified)

- Live Kafka publish/consume of tick v2
- Frontend WS/chart path still on float v1 snapshots
- Prior open gaps remain open
- Track: `MD001-KAFKA-V2-CUTOVER`, `MD001-FRONTEND-CUTOVER`
