# Product decisions — admin top-ups & provider admin UI (2026-08-25)

## FIN-006 — Admin wallet top-ups

**Question:** Admin charges today use ledger type `deposit` + `WALLET_TOPUP` + `admin_action`, and dashboard “deposits today” counts all `deposit` rows.

**Decision:** Introduce a distinct ledger type **`admin_funded_deposit`**. Gateway/user deposits remain `deposit`. Reports must exclude admin-funded from normal trading/user deposit revenue. Preserve full audit trail (ledger + `audit_logs`).

**Task:** `FIN-006` in `PRODUCTION_ROADMAP_AND_CODEX_TASKS.md`.

## MD-005A — Provider selection in Admin Panel

**Context:** Policy §9.2 defaults active Crypto/Forex providers independently; §9.4 defines AUTO / FORCE_PROVIDER / PAUSE_SYMBOL. Code already defaults Forex=Deriv, Crypto=Nobitex and has partial control APIs.

**Decision (near-term):** Implement **defaults + auditable Admin selection UI** (Forex=Deriv, Crypto=Nobitex; validated switch; clear active state; audit). Full AUTO/FORCE/PAUSE with 1h review remains **MD-005 / MD-006**, not this task.

**Task:** `MD-005A` in `PRODUCTION_ROADMAP_AND_CODEX_TASKS.md`.

## Explicitly not decided here

- Double-entry account mapping details for `admin_funded_deposit` (clearing vs revenue) — resolve in FIN-006 decision log at implementation time if still ambiguous.
- Full §9.4 automatic health selection / force review timers — MD-005.
