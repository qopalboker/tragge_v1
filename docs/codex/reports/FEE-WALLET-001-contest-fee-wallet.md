# FEE-WALLET-001 — Dedicated Contest Fee Wallet

**Status:** Implemented for canonical forward paid-join fee allocation; real
PostgreSQL runtime certification remains pending. Production remains **NO-GO**.

## Authority and account design

`packages/scoring/economics.ComputeJoinCharge` remains the sole contest fee and
prize-contribution calculator. It consumes integer minor units and the locked
`platform_fee_bps`, floors integer division, and assigns the remainder to the
prize contribution. No calculator was added to the wallet or BFF.

Migration 0116 creates exactly one `contest_fee_accounts` row with purpose
`contest_fee_wallet` and kind `system_fee_revenue`. It has no `user_id`, cannot
authenticate or use user wallet APIs, and cannot be deleted. Its separate
`contest_fee_ledger` is append-only and accepts only `contest_base_fee`,
`contest_late_surcharge`, and the schema foundation for
`contest_fee_refund_reversal`. Deposits, prizes, withdrawals, forfeitures,
residuals, affiliate commissions, and generic adjustments are not valid kinds.

## Posting and transaction boundary

`wallet.Service.PostContestFee` is the narrow posting boundary. It accepts only
the two inflow kinds, positive `int64` amounts, server-owned contest/user IDs,
and canonical fee basis points. Each fee credit has an equal signed debit in
the existing Treasury journal. The paid-join transaction locks the contest,
computes `ComputeJoinCharge`, debits the user, inserts participation, preserves
the transitional Prize Pool/commission counters, posts base fee and optional
late surcharge, processes the existing affiliate record, and commits. Any
failure rolls all same-database effects back.

The canonical shared financial lock order is `Treasury -> user wallet ->
purpose account`. Paid join locks Treasury before its user debit; confirmed
deposit already locks Treasury before its user credit. The two flows therefore
cannot hold the user wallet while waiting for Treasury in opposite order.

Durable inflow idempotency is `(admission_id, entry_kind)`, where `admission_id`
is the server-derived `{contest UUID}:{participant user UUID}`. Both system rows
are locked before lookup/update. Replay succeeds only when matching Fee Wallet
and Treasury entries both exist with equal-and-opposite amounts and identical
contest, participant, admission, and fee-kind context. A missing or mismatched
counterpart fails closed and is never repaired automatically.

## Visibility and reversal boundary

The Admin BFF exposes a paginated read-only fee-wallet endpoint behind existing
Admin authentication/MFA, `financial.view`, and an explicit
`RequireSuperAdmin` check. The existing Financial page requests and renders the
balance, class totals, and ledger rows only for a Super Admin. There is no user
route and no mutation endpoint.

The inflow uniqueness index applies only to `contest_base_fee` and
`contest_late_surcharge`. Reversals are instead unique by `original_entry_id`,
so one late admission can append one exact reversal for its base fee and one for
its surcharge. The ledger schema validates the original amount and context. No
reversal API is exposed in this task: LIFECYCLE-004 must atomically pair the
exact fee reversal with the matching Treasury movement rather than minting a
refund or recalculating current config.

## Deliberate scope boundary

CONTEST-POOL-001 was not implemented. `prize_pool_net_cents` remains the current
transitional counter, and no Prize Pool account or transfer exists here. The
task debits Treasury only for the fee allocation; the later Prize Pool task must
debit the remaining contribution. Because Treasury remains forward-only and
unreconciled, a paid join fails closed if its fee portion lacks recorded custody.
