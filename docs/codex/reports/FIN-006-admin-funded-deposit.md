# FIN-006 — Classify admin wallet top-ups as admin-funded deposits

**Date:** 2026-08-25  
**Branch:** `codex/fin-006-admin-funded-deposit-classification`  
**Status:** Implemented — **requires financial sign-off before merge**

## What changed

| Area | Change |
|---|---|
| `packages/db/migrations/0112_*` | Add enum value `admin_funded_deposit` |
| `packages/db/migrations/0113_*` | Backfill historical admin top-ups (`deposit`+`WALLET_TOPUP`+`admin_action`) |
| `packages/wallet/types.go` | `LedgerTypeAdminFundedDeposit` + `GatewayDepositRevenueSQLPredicate` |
| `apps/admin-bff/.../handlers_withdrawal.go` | Admin credits use `admin_funded_deposit`; audit payload includes `ledger_type` |
| `apps/admin-bff/.../handlers_user_management.go` | Deposits-today metric uses gateway revenue predicate |
| Admin i18n | Label clarifies “Gateway Deposits Today” |

## Exact tests

```text
node --test scripts/sec-fin006-admin-funded-deposit.test.mjs
```

## NOT verified (do not claim)

- Live Postgres migration apply + backfill row counts on production/staging data
- End-to-end Admin UI charge → dashboard metric against a real DB
- Double-entry clearing/revenue account mapping for `admin_funded_deposit` (`FIN006-ACCOUNT-MAPPING`)

## Sign-off request

Approve FIN-006 (admin top-ups = `admin_funded_deposit`; gateway revenue excludes them). Next after merge: **MD-005A** (separate PR).
