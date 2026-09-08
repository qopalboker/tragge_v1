# Canonical Financial Lock Order

All contest admission, participant removal/refund, contest cancellation, and
settlement-preparation transactions acquire every applicable lock in this order:

1. **Contest** — serializes lifecycle and economics decisions.
2. **Participant(s)** — one participant row, or multiple rows ordered by user ID.
3. **Treasury** — canonical system custody account.
4. **User Wallet** — participant entitlement account; multiple users use user-ID order.
5. **Fee Wallet** — canonical contest fee account.
6. **Contest Prize Pool** — the contest-owned custody account.

Admission creates and thereby locks the new participant row after locking the
contest and before taking any financial-account lock. Removal locks the existing
participant row. Cancellation locks all active participants in user-ID order.

## Why this order is mandatory

A single order prevents admission, cancellation, removal, refund, and settlement
preparation from waiting on the same durable authorities in opposite directions.
It also makes the transaction boundary reviewable: lifecycle authority is fixed
before custody or entitlement changes begin.

## Forbidden patterns

- Never lock Treasury and then attempt to lock a contest or participant.
- Never lock a Fee Wallet or Prize Pool and then attempt to lock Treasury or a user wallet.
- Never lock multiple participants or wallets in nondeterministic order.
- Never correct a lifecycle reversal through `contests.prize_pool_net_cents` or
  `contests.commission_amount`; append exact linked ledger reversals instead.
- Never update an account balance unless the same transaction appends its
  authoritative ledger movement and validates the resulting reconciliation.

Workflows that acquire only a subset preserve the relative order above. A new
financial workflow must extend the regression tests before introducing locks.

