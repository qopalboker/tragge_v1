# TREASURY-001 — Canonical Super Admin Wallet custody foundation

**Status:** Implemented for forward confirmed-deposit posting; real PostgreSQL
runtime certification and opening-balance cutover remain pending.

## Authority and identity

`packages/wallet.Service` remains the sole financial posting boundary. Migration
0115 adds exactly one `treasury_accounts` row with purpose
`super_admin_treasury`, kind `system_custody`, and no user ownership. Existing
`wallets.balance_cents` rows remain user entitlements.

`treasury_accounts.reconciliation_status` is fixed to
`forward_only_unreconciled`. No API or Admin UI exposes its balance as a globally
reconciled cash position.

## Confirmed deposits

`PostConfirmedDeposit` posts, in the payment intent transaction:

```text
confirmed external deposit X
  custody asset:   Super Admin Treasury +X
  user liability: beneficiary entitlement +X
```

The two amounts describe opposite balance-sheet perspectives of the same funds;
they are not summed as spendable money. `treasury_ledger.payment_intent_id` and
the existing `wallet_ledger.idempotency_key = deposit:<payment_intent_id>` tie
both durable entries to one operation and prevent repeat financial effects.

Webhook, inquiry, and expiry confirmation paths call this single posting API.
Admin-funded deposits are intentionally excluded because their external-custody
source is not proven.

## Activation and open evidence

- `TREASURY001-OPENING-BALANCE-CUTOVER`: reconcile actual external custody to
  ledger liabilities and record the controlled activation boundary. No existing
  user balances were used to fabricate an opening custody asset.
- `TREASURY001-ADMIN-FUNDED-CUSTODY-SEMANTICS`: classify whether each admin-funded
  entitlement is new external custody or assignment of already-held funds.
- Real PostgreSQL rollback and concurrency tests are retained in
  `packages/wallet/treasury_test.go`; Cloud execution requires Docker/testcontainers.

No Contest Fee Wallet, contest Prize Pool transfer, lifecycle, rank, settlement,
or withdrawal custody behavior is implemented here.
