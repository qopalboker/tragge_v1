# FIN-002 decision log

## 2026-08-25 — Sole prize-math owner

**Question:** leaderboard payouts are labeled preview-only; `packages/scoring/prize` still used commission fractions; economics uses `platform_fee_bps`. Which path owns prize math?

**Answer (human):** **`packages/scoring/economics` + `prizedistribution` as the sole path.**

**Implication:**
- Fee/net pool math → `economics.CalculatePool` / `NetFromGross`
- Winner count + power-law shares → `prizedistribution`
- `packages/scoring/prize` becomes a thin compatibility layer (bps preferred)
- Settlement recalculation and leaderboard net helpers must call economics (no local formulas)

## Behavioral differences catalogued (pre-fix)

| Topic | leaderboard `payout.go` | settlement `calculatePrizes` | `packages/scoring/prize` |
|---|---|---|---|
| Pool fee input | `platform_fee_bps` | locked/`platform_fee_bps` | commission **fraction** |
| Net formula | floor gross×(10000-bps)/10000 | same (inline) | Floor(gross×fraction) |
| Distribution | `prizedistribution` | `prizedistribution` | `prizedistribution` |
| Authority | preview only | payout authority | preview helpers |

Post-fix: all three use economics net + prizedistribution shares.
