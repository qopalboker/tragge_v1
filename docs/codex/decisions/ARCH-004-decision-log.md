# ARCH-004 decision log

**Date:** 2026-08-25  
**Branch:** `codex/arch-004-migrate-wallet-payment-kyc-and-withdrawal-`

## DATA-003 dependency

**Question:** ARCH-004 lists DATA-003, but double-entry ledger is incomplete.

**Answer (human):** Proceed with `packages/wallet` as the Platform ledger boundary. Defer true double-entry to DATA-003.

## Explicitly excluded

- **FIN-006** — `admin_funded_deposit` classification (separate PR)
- **MD-005A** — Admin Forex/Crypto provider selection UI (separate PR)
