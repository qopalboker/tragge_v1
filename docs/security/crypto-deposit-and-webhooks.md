# Crypto Deposits and Webhooks (MVP-002)

## Providers

| Provider | Config | Create | Callback |
| --- | --- | --- | --- |
| NOWPayments | `NOWPAYMENTS_API_KEY`, `NOWPAYMENTS_IPN_SECRET` | Invoice API | HMAC-SHA512 `x-nowpayments-sig` |
| Plisio | `PLISIO_SECRET_KEY` (+ optional `PLISIO_BASE_URL`) | `GET /api/v1/invoices/new` | HMAC-SHA1 `verify_hash` (json=true) |

Secrets load via the repository secrets helper (`*_FILE` mounts supported). Secrets are never returned to clients, logged, or embedded in frontend bundles.

## Canonical payment statuses

Provider statuses map into payment_intent rows:

| Canonical | Meaning |
| --- | --- |
| `pending` | Intent created / awaiting provider |
| `processing` | Provider accepted / confirming |
| `succeeded` | Verified paid; wallet credited once |
| `failed` | Failed, cancelled, or amount mismatch |
| `expired` | Timed out |
| `refunded` | Refunded |

## Credit rules

1. Authenticated user creates deposit; `user_id` and `amount_cents` are server-authoritative.
2. Minimum deposit: **$4** (`MIN_DEPOSIT_CENTS`, default 400; MVP-004).
3. Webhook signature/hash verified first.
4. Replay store (Redis SetNX) rejects duplicate event identities. Plisio callbacks may omit timestamps (provider design); freshness is enforced when a timestamp is present, and production still requires timestamps for NOWPayments.
5. Row lock (`SELECT FOR UPDATE`) + terminal-status short circuit + ledger idempotency key `deposit:{payment_intent_id}`.
6. Completed callbacks must present amount matching intent (1% / $10 cap tolerance). Mismatch → fail closed, no credit.
7. Wallet is credited the **intent** USD amount (not untrusted client figures).

## Plisio mapping

| Plisio status | Internal |
| --- | --- |
| new | pending |
| pending / pending internal | processing |
| completed | finished → credit path |
| mismatch | failed (no auto-credit; under/overpayment requires reconciliation) |
| expired | expired |
| error / cancelled / cancelled duplicate | failed |

Only `completed` is eligible for automatic wallet credit. `mismatch` fails closed because `source_amount` is the invoice total, not necessarily the amount received.

## Mini App

- `GET /api/payments/deposit/providers` — available providers only
- `POST /api/payments/deposit/crypto/create` — create invoice
- `GET /api/payments/deposit/{id}/status` — ownership-checked status
- Mini App route `/miniapp/deposit` polls status; success only after backend `succeeded`
