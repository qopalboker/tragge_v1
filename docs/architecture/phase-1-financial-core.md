# Phase 1 — Contest Financial Core

**Status:** implementation in progress / see Phase 1 report  
**Date:** 2026-08-16

## Authority model (after Phase 1)

| Concern | Owner |
|---|---|
| Fee policy | `platform_fee_bps` only (canonical). `commission_rate` is deprecated read fallback |
| Economics math | `packages/scoring/economics` |
| Ranking | `leaderboard-worker` |
| Prize wallet credit + settlement rows | `settlement-service` only |
| Ledger truth | `packages/wallet` ledger entries |
| Wallet balance | projection of ledger |

## Join policy

- Free contests: `registration_open` only (no late join).
- Paid contests: `registration_open`, or `running` until  
  `starts_at + min(10% duration, 30m)` when `late_join_enabled`.
- Late join charges +10% platform surcharge; prize contribution remains 80% of base entry.
- Product-level `max_participants` is **not** enforced (policy §5.2).

## Economics lock

On first successful join, contest freezes:

- `locked_entry_fee_cents`
- `locked_platform_fee_bps`
- `economics_locked_at`

Admin updates to fees/timing are rejected after lock.

## Idempotency

- Settlement: `contest_settlements.contest_id` UNIQUE; prize credit via `CreditPrizeIdempotent`.
- Free generator: `schedule_idempotency_key` UNIQUE partial index.
- Join: unique `(contest_id, user_id)` on participants + wallet entry-fee ledger keys.

## Reconciliation

```bash
DATABASE_URL=postgres://... node scripts/contest-reconcile.mjs <contest_id>
```
