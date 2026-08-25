# FIN-006 decision log

## 2026-08-25 — Admin top-up ledger classification

**Question:** Admin Panel wallet credits today use ledger type `deposit` + `WALLET_TOPUP` + `admin_action`, so dashboard “deposits today” counts them as gateway/user deposit revenue.

**Answer (product decision `PRODUCT-2026-08-25-wallet-provider-tasks.md`):** Introduce distinct ledger type **`admin_funded_deposit`**. Gateway/user deposits remain `deposit`. Reports must exclude admin-funded from normal trading/user deposit revenue. Preserve full audit trail (ledger + `audit_logs`).

### Implementation choices

| Topic | Choice |
|---|---|
| New admin credits | `LedgerTypeAdminFundedDeposit` via `handleChargeUserWallet` |
| Gateway deposits | Unchanged `deposit` (payment-service paths) |
| Admin debits | Unchanged `adjustment` |
| Historical rows | **Backfill** `deposit`+`WALLET_TOPUP`+`admin_action` → `admin_funded_deposit` (amounts/balances/timestamps unchanged) |
| Metrics | `GatewayDepositRevenueSQLPredicate`: `type = 'deposit'` plus defense filter excluding residual `WALLET_TOPUP`+`admin_action` |
| Double-entry account mapping | **Deferred** — classification only; no new system-account postings in this PR (`FIN006-ACCOUNT-MAPPING`) |

### Policy note (§13.1 immutability)

§13.1 says existing ledger rows are immutable and admin corrections use compensating entries. FIN-006 applies a **one-time, human-approved classification correction** of the `type` label only for historical misclassified admin top-ups. Financial amounts and `balance_after_cents` are not rewritten. Tracked as an explicit exception in `discovered-issues.md` (`FIN006-LEDGER-TYPE-BACKFILL`).

### Sign-off

**Approved and merged to main** (PR #29, 2026-08-25). Gaps `FIN006-*` remain open.
