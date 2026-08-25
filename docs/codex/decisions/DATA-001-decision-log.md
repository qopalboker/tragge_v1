# DATA-001 decision log

**Date:** 2026-08-25  
**Branch:** `codex/data-001-introduce-canonical-fixed-point-money-pric`

## Scale defaults (human-approved)

| Type | Representation | Default scale |
|---|---|---|
| Money | `int64` minor units | display scale 2 (USDT) |
| BPS | `int` | n/a (`platform_fee_bps=2000`) |
| Price / Rate / PnL | `int64` units + scale | 8 |
| Score | `int64` units + scale | 6 |
| Rational weight | num/den `int64` | exact |

Rounding: half_up (away from zero on .5). Overflow / excess precision fail closed.

Symbol-specific price scales may override defaults later via MD-001/ENG-002 registry metadata.

## Explicitly deferred

- Migrating all legacy `float64` call sites in Engine/Market Data (ENG-002 / MD-001).
- Replacing shopspring/decimal scoring internals (can adopt money.Score gradually).
- Full repository float ban across all apps (static check covers `packages/money` target path this PR).
