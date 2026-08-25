# DATA-001 — Canonical fixed-point financial primitives

**Branch:** `codex/data-001-introduce-canonical-fixed-point-money-pric`  
**Commit:** `feat(types): add fixed point financial primitives`

## What changed

| Area | Change |
|---|---|
| `packages/money` | Money, BPS, Price, Rate, PnL, Score, Rational + parse/format/overflow/half_up |
| `packages/scoring` | Canonical score scale bridge to `money.Score` |
| Target SQL | `0005_shared_financial_type_policy` schema comments |
| Workspace | `go.work` includes `packages/money` |
| CI | `scripts/sec-data001-fixed-point.test.mjs` |

## Tests run this session

```text
go test ./...   # packages/money
node --test scripts/sec-data001-fixed-point.test.mjs
```

## Gaps (not runtime-verified)

- Full float64 eradication in trading-engine/market-ingestor (`DATA001-FLOAT-CUTOVER`)
- Live Postgres storage of new types in domain tables (later DATA/ENG/MD migrations)
- Prior open gaps remain open
