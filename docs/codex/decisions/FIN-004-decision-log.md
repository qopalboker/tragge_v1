# FIN-004 decision log

## 2026-08-25 — Authoritative spec

**Source:** `docs/product/FIXED_PRODUCT_AND_TECHNICAL_POLICIES.md` §11 (`tralent_v1`).

**Not authoritative:** `packages/contracts/prize_distribution/tralent_like_v1.json` (different bracket tables; legacy name only).

## 2026-08-25 — Divergence evidence (Power Law vs tralent_v1)

Net pool **$800** (80000 cents):

| Participants | PL 1st $ | TV 1st $ | 1st Δ$ |
|---:|---:|---:|---:|
| 4 | 544.91 | 640.00 | −95.09 |
| 7 | 452.38 | 520.00 | −67.62 |
| 10 | 452.38 | 400.00 | +52.38 |
| 12 | 402.50 | 271.01 | +131.49 |
| 100 | 228.50 | 167.36 | +61.14 |

## 2026-08-25 — Direction

**Question:** Implement `tralent_v1` or keep Power Law and amend policy?

**Answer (human):** **Implement tralent_v1 as production path.**

**Implemented:** `CalculateForContest` / `TralentV1*` become production; Power Law retained as `*PowerLaw` for divergence tests only. Settlement, leaderboard, economics, prize package call `CalculateForContest`.
