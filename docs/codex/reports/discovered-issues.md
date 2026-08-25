# Discovered issues

Issues found while executing the AI agent roadmap that are out of the current task scope.

---

## SEC001-REMOTE-URL-ASSERTION

| Field | Value |
|---|---|
| **ID** | SEC001-REMOTE-URL-ASSERTION |
| **Severity** | P2 (doc/script drift) |
| **Found during** | SEC-008 (2026-08-25) |
| **Status** | Open |

`scripts/sec001-auth-isolation.test.mjs` asserts `.git/config` contains `tragge_v0.git`, but origin is `https://github.com/qopalboker/tragge_v1.git`. Nine of ten isolation tests pass; this metadata assertion fails. Update the script when convenient — not a runtime auth regression.



---

## SEC004-STALE-STRING

| Field | Value |
|---|---|
| **ID** | SEC004-STALE-STRING |
| **Severity** | P2 (script drift) |
| **Found during** | SEC-009 (2026-08-25) |
| **Status** | Open — intentionally not fixed in SEC-009 |

`scripts/sec-004-sensitive-action-check.mjs` requires the exact comment fragment `Super Admin password verification establishes only the first factor` in `handlers_helpers.go`. Current helpers document policy-gated MFA instead. Behavioral reauth/MFA locks are covered by SEC-009; update the SEC-004 script separately.
# Discovered issues / verification gaps
This ledger tracks open verification gaps. Entries from the stacked architecture
branches (ARCH-001…009, ENG/DATA/MD) remain open until those PRs merge and
runtime evidence exists. **Do not treat documentation as gap closure.**
## INFRA002-POSTGRES-HA-OVERLAY
| **ID** | INFRA002-POSTGRES-HA-OVERLAY |
| **Severity** | P2 (desired-state gap) |
| **Found during** | INFRA-002 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |
`base/postgres-ha` cannot be merged into the production overlay alongside base
postgres/pgbouncer objects without ConfigMap ID conflicts (`pgbouncer-config`).
Production overlay remains on single-instance postgres from base until a
conflict-free HA composition is designed. This is **desired-state** tracking
only — not live-cluster evidence.

---

## FIN001-TEMPLATE-COMMISSION-UI

| Field | Value |
|---|---|
| **ID** | FIN001-TEMPLATE-COMMISSION-UI |
| **Severity** | P2 (non-authoritative leftover) |
| **Found during** | FIN-001 (2026-08-25) |
| **Status** | Open |

Admin template handlers still accept/store `commission_rate` on `tournament_templates`. Contest materialization no longer derives `platform_fee_bps` from that field (always 2000 for paid). Remove template UI/API field in a follow-up cleanup PR.
