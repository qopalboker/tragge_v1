# CONTEST-POOL-001 Lock and Deployment Review

## Canonical lock order

Paid admission owns one PostgreSQL transaction and acquires locks in this order:

```text
contest row -> Super Admin Treasury -> user wallet -> Contest Fee Wallet -> contest Prize Pool
```

`PostContestFee` and `PostContestPrizeContribution` defensively lock Treasury
before their purpose account. During admission these calls re-enter the Treasury
row lock already held by the same transaction; they do not acquire it after a
purpose-account lock. Cutoff reconciliation first locks the contest and then
performs read-only ledger/account aggregation. It does not lock the Prize Pool.

No production caller acquires the Prize Pool or Contest Fee Wallet before
Treasury, and no paid-admission caller locks a user wallet before its contest.
The static regression test in `packages/wallet/contest_fee_static_test.go`
protects these source-level boundaries.

## Deployment order

Migration `0118_contest_prize_pool` is a hard prerequisite for this application
version:

1. Apply migration `0118`.
2. Existing contests are explicitly stamped `legacy`.
3. After the account table and provisioning trigger exist, the migration
   changes the default to `contest_funds_v1`; creation of each new contest then
   provisions its empty Prize Pool account. This statement order is safe even
   if a migration runner does not wrap the file in one transaction.
4. Deploy the application version that posts admission Prize Pool movements.

The admission path reads `funds_policy_version` in its authoritative locked
contest query and fails closed if that query fails. It has no fallback that can
reinterpret a missing `0118` schema as a legacy contest. This makes an
application-before-migration deployment unavailable for paid admission rather
than allowing unledgered money movement.

The migration performs no participant scan, historical balance derivation,
synthetic ledger insert, or destructive data rewrite. Legacy contests do not
require Prize Pool ledger evidence; modern contests do, based only on the
explicit policy column.

## Runtime certification

Real PostgreSQL tests exist for concurrent contributions, duplicate retries,
transaction rollback, ledger/account constraints, and balance reconciliation.
They remain certification-pending until executed in an environment with a real
PostgreSQL runtime.
