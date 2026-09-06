# POLICY-001 — Contest funds and participant lifecycle decision log

## 2026-09-06 — `contest_funds_v1`

**Status:** Approved; current policy; implementation may proceed according to the
ordered roadmap.
**Canonical source:** `docs/product/FIXED_PRODUCT_AND_TECHNICAL_POLICIES.md` §20.
**Effective boundary:** contests created after TREASURY-001 through
FIN-CLEAN-001 are deployed and a PostgreSQL boundary is recorded. Historical
ledger entries, settled contests, and existing P0-FIN-06 snapshots are not
rewritten.

### Decisions

- One stable system Super Admin Wallet owns platform custody; human Super Admins
  are permissioned actors, not the wallet identity.
- User balances are PostgreSQL ledger-backed entitlements. Contest Fee Wallet
  and each contest Prize Pool are separate financial accounts/allocations.
- Join, refund, Prize Pool lock-return, winner payout, and withdrawal movements
  follow §20 and require fixed-point, ledger-backed, idempotent effects.
- Users never self-leave. Only Super Admin may perform an audited, non-destructive
  participant removal using the exact reason/refund matrix.
- Cutoff snapshot is immutable; authorized later changes are append-only
  adjustments producing effective economics.
- Rank 0 persists until the first qualifying fill. Missing winner recipients do
  not cause share renormalization; their slots become unawarded residual.

### Current-code conflicts — implementation follow-ups only

These findings document current behavior. POLICY-001 does not change production
code.

| Area | Current evidence | Conflict / owning follow-up |
|---|---|---|
| User self-leave | `apps/user-bff/server/app.go` registers `POST /contests/{id}/leave`; `handleLeaveContest` in `apps/user-bff/server/contest_handlers.go` permits `registration_open`, refunds, and deletes the participant. | User leave is forbidden; LIFECYCLE-004. |
| Hard participant deletion | `handleLeaveContest` executes `DELETE FROM contest_participants`. `apps/contest-scheduler/internal/scheduler/cleanup.go` also deletes orphan participant rows. Test teardown contains further deletes but is not production behavior. | Joined history must be stateful/non-destructive. Assess orphan cleanup separately; LIFECYCLE-004/FIN-CLEAN-001. |
| Float refund calculation | `handleLeaveContest` uses `commission_rate`, `float64`, and `math.Round` to reconstruct fee/prize reversal. | Refund must use original ledger charge/split in integer units; LIFECYCLE-004/FIN-CLEAN-001. |
| Entry accounting | `handleJoinContest` calls `DeductContestEntryFeeWithName`, inserts participation, then increments `contests.prize_pool_net_cents` and `commission_amount`. | Debit is ledger-backed, but Prize Pool and fee destinations are counters rather than explicit account transfers; CONTEST-POOL-001/FEE-WALLET-001. |
| User balance authority | `packages/wallet/wallet.go` updates `wallets.balance_cents` and appends `wallet_ledger`; ARCH-004 records this package as the current Platform ledger boundary while true double-entry remains deferred. | No canonical custody/sub-ledger model yet; TREASURY-001. |
| Deposit destination | Deposit/admin-credit paths credit a user wallet/ledger classification; no stable Super Admin custody account is posted in the same journal. | TREASURY-001. |
| Prize Pool | `contests.prize_pool_net_cents` and P0-FIN-06 snapshot values identify amounts, but no per-contest ledger account or lock-return transfer to Super Admin Wallet exists. | CONTEST-POOL-001; preserve P0-FIN-06 snapshot evidence. |
| Fee revenue | Join adds base fee plus late surcharge to `contests.commission_amount`; no dedicated Contest Fee Wallet entry is posted. | FEE-WALLET-001. |
| Affiliate creation/reversal | `processAffiliateCommission` in `apps/user-bff/server/helpers.go` creates a pending commission inside the join transaction but treats lookup/insert/referral-update errors as warnings/returns. User leave calls `reverseAffiliateCommission`; the leaderboard worker retains an opt-in delayed credit job. | Refund-sensitive financial effects cannot be best effort; FIN-CLEAN-001. Cheating/Refund NO affiliate treatment is unresolved below. |
| Leaderboard initialization | `initializeLeaderboard` in `packages/domain/statemachine/contest_handlers.go` publishes every participant with `initial_score: 0`. | Rank-zero users must be absent until first qualifying fill; RANK-001. |
| Live leaderboard | `apps/leaderboard-worker/server/app.go` writes score updates to Redis sorted sets; Redis is already projection-only by ARCH-003 but current initialization admits no-trade participants. | RANK-001. |
| First-fill evidence | Durable `fills` and filled orders exist; settlement `getUserTradeStats` counts orders with `status='filled'`. | Use durable qualifying fill evidence, not score; RANK-001. |
| Final ranking | Settlement `calculateRankings` ranks every loaded participant before using trade counts; state-machine ranking also writes positive `final_rank` broadly. | No-trade/removed users can receive positive rank; RANK-001/SETTLE-001. |
| Fewer eligible winners | `TralentV1CalculatePrizeDistribution` in `packages/scoring/distribution/tralent_v1.go` explicitly renormalizes the remaining small-contest shares to 100%. | New policy preserves planned shares and residual; SETTLE-001. |
| Settlement/prize payout | FIN-003 names settlement sole finalization owner; `settlement.go` calls wallet prize-credit operations and contains a single-participant refund path. | Payout currently credits user accounting without a Super Admin Wallet debit; single-participant policy must align with new custody/refund rules; SETTLE-001/TREASURY-001. |
| Withdrawal | Admin withdrawal routes use existing permissions and sensitive-action reauthentication for completion; current flow reserves/deducts user accounting and records external completion without a canonical Super Admin custody debit. | WITHDRAW-001. |
| Super Admin controls | `apps/admin-bff/server/app.go`, SEC-004, and SEC-007 provide RBAC, sensitive-action grants, audit requirements, and TOTP policy. | Reuse these controls for Fee Wallet and removal; do not add weaker auth. |

### Genuine unresolved policy question

**Affiliate commission when removal reason is `cheating` and Refund NO:** current
approved policy does not say whether a pending/credited affiliate commission is
retained, cancelled, or reversed. The implementation must stop for a human
decision; it must not infer this from the no-refund treatment of contest fees or
forfeiture.

No other policy question was identified that prevents the ordered backlog from
starting.

### Runtime status

This is documentation-only. No runtime behavior is claimed. P0-FIN-06 real
PostgreSQL trigger/concurrency/parity verification remains open and is part of
the later Linux certification gate.
