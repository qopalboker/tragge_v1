# ARCH-004 — Migrate wallet, payment, KYC, and withdrawal modules

**Date:** 2026-08-25  
**Branch:** `codex/arch-004-migrate-wallet-payment-kyc-and-withdrawal-`  
**Commit:** `refactor(platform): migrate financial modules`

## Boundary decision

DATA-003 (true double-entry) is not done. Approved approach: use **`packages/wallet` as the Platform ledger boundary** for ARCH-004. Defer account-journal rewrite to DATA-003.

**Out of scope:** FIN-006 (`admin_funded_deposit`), MD-005A (provider admin UI).

## What changed

| Module | Role |
|---|---|
| `wallet` | Sole ledger authority (`IsSoleLedgerAuthority`); credits/debits via ledger service |
| `payment` | Deposit/withdraw orchestration; replaceable `Provider` adapters; provider calls outside TX; inquiry/expiry jobs |
| `kyc` | Submit/approve/reject state machine + `RequireApproved` |
| Platform API | `/api/wallet|payments|kyc/v1/boundary` |
| `payment-service` | Remains compatibility host; documents Platform ledger boundary |

## Tests

```text
go test ./apps/platform/...
node --test scripts/sec-arch004-financial-modules.test.mjs
```

## Gaps (not runtime-verified)

- Live Postgres webhook E2E / dual-writer races
- Full HTTP cutover of all payment-service routes onto Platform only
- Prior open gaps: FIN003-*, FIN005-*, P0-FIN-06, LIFECYCLE*, ARCH001-DOCKER-IMAGE, ARCH003-*
- Track: `ARCH004-PAYMENT-HTTP-CUTOVER`, `ARCH004-WEBHOOK-POSTGRES-E2E`
