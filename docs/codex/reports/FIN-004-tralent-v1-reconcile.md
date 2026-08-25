# FIN-004 — Reconcile prize distribution vs `tralent_v1`

**Date:** 2026-08-25  
**Branch:** `codex/FIN-004-tralent-v1-reconcile`  
**Status:** Implemented — **requires financial sign-off before merge**

## Also tracked this turn

- FIN-003 human sign-off recorded.
- `FIN003-POSTGRES-DUAL-RACE` added to `discovered-issues.md` — **not runtime-verified** until dual-path race is reproduced on real PostgreSQL.

## Spec

Policy §11 `tralent_v1`: winner_ratio 0.30, decay 0.80, small-contest fixtures, rank bands, half_up residual to top individual ranks.

## What changed

| File | Change |
|---|---|
| `packages/scoring/distribution/tralent_v1.go` | Policy-faithful implementation |
| `packages/scoring/distribution/distribution.go` | Production API → tralent; Power Law renamed `*PowerLaw` |
| `packages/scoring/distribution/fin004_divergence_test.go` | Quantified PL vs TV divergence |
| Settlement / leaderboard / economics / prize | Call `CalculateForContest` |
| CI `fin-004-tralent-v1` / `test:fin004` | Regression lock |

## Numeric before/after (example: 4 participants, $800 net pool)

| | Before (Power Law) | After (`tralent_v1`) |
|---|---|---|
| Ranks | 2 winners ~68%/32% | **80% / 20%** fixture |
| 1st place | ~$544.91 | **$640.00** |

## Exact tests

```text
go test ./packages/scoring/distribution/ ./packages/scoring/economics/ ./packages/scoring/prize/
ok

node --test scripts/sec-fin004-tralent-v1-check.test.mjs
# pass 3
```

## Explicitly NOT done

- Rewriting `tralent_like_v1.json` contract fixture (legacy/non-policy).
- Full tie-pooling edge cases from §11.6 beyond equal band split.
- Live settlement E2E with new shares against Postgres.

## Sign-off request

Approve FIN-004 (`tralent_v1` production prize shares). Next: **FIN-005**.
