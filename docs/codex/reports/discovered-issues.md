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

---

## FIN003-POSTGRES-DUAL-RACE

| Field | Value |
|---|---|
| **ID** | FIN003-POSTGRES-DUAL-RACE |
| **Severity** | P1 (verification gap) |
| **Found during** | FIN-003 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

FIN-003 ownership/idempotency is locked via static guards + wallet idempotency-key concurrency tests. A full dual-consumer race (leaderboard finalize + settlement settle) against **real PostgreSQL** was not reproduced (host linker OOM / no integration env in session).

**Do not mark FIN-003 fully runtime-verified until this gap is closed** with a Postgres integration test that fires both paths concurrently and asserts exactly one payout / one settlement completion.

---

## FIN004-TRALENT-LIKE-JSON

| Field | Value |
|---|---|
| **ID** | FIN004-TRALENT-LIKE-JSON |
| **Severity** | P2 (legacy fixture drift) |
| **Found during** | FIN-004 (2026-08-25) |
| **Status** | Open |

`packages/contracts/prize_distribution/tralent_like_v1.json` is **not** the policy `tralent_v1` algorithm (different fixed brackets). Production now uses policy §11 via `CalculateForContest`. Retire or rewrite this JSON in a docs/contracts cleanup PR.

---

## FIN005-COMPOSE-LIFECYCLE

| Field | Value |
|---|---|
| **ID** | FIN005-COMPOSE-LIFECYCLE |
| **Severity** | P1 (verification gap) |
| **Found during** | FIN-005 (2026-08-25) |
| **Status** | Open |

In-process economics/tralent_v1/ledger conservation harness is green. Full multi-service join/trade/finalize/settle against Compose Postgres/Redis was not run this session.

---

## FIN005-STAGING-SCHEDULE

| Field | Value |
|---|---|
| **ID** | FIN005-STAGING-SCHEDULE |
| **Severity** | P2 |
| **Found during** | FIN-005 (2026-08-25) |
| **Status** | Open |

Scheduled staging-like reconciliation guard not configured (no staging environment / cron in this session).

---

## FIN005-BRANCH-PROTECTION

| Field | Value |
|---|---|
| **ID** | FIN005-BRANCH-PROTECTION |
| **Severity** | P2 |
| **Found during** | FIN-005 (2026-08-25) |
| **Status** | Open |

`fin-005-reconciliation-harness` CI job exists (always-on). Making it a GitHub required check (optionally path-filtered) is owned by CI-003.

---

## P0-FIN-06-ECONOMICS-LOCK-AT-CUTOFF

| Field | Value |
|---|---|
| **ID** | P0-FIN-06-ECONOMICS-LOCK-AT-CUTOFF |
| **Severity** | P0 (audit) / deferred from LIFECYCLE-001 |
| **Found during** | LIFECYCLE-001 (2026-08-25) |
| **Status** | Open — **not implemented in LIFECYCLE-001** |

Policy §4.4 requires economics immutability when the **late-entry window closes**. Current code locks fee fields on first join and still allows late joiners to increment `prize_pool_net_cents` until cutoff. A dedicated cutoff-time economics snapshot freeze remains outstanding (audit P0-FIN-06).

---

## LIFECYCLE001-USERBFF-COMPILE

| Field | Value |
|---|---|
| **ID** | LIFECYCLE001-USERBFF-COMPILE |
| **Severity** | P2 (verification gap) |
| **Found during** | LIFECYCLE-001 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Full `go test ./apps/user-bff/server` was not run (host OOM). Policy tests execute in `packages/scoring/economics`. Do not claim user-bff package compile/runtime verification until reproduced.

---

## LIFECYCLE002-LOAD-TEST

| Field | Value |
|---|---|
| **ID** | LIFECYCLE002-LOAD-TEST |
| **Severity** | P1 (verification gap) |
| **Found during** | LIFECYCLE-002 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

LIFECYCLE-002 removed product capacity enforcement (constraint, ValidateRegistration, create-path NULL, UI). A large synthetic participant join/load test against real Postgres (or Compose at target scale) was **not** run this session. Do **not** mark the load-test verify item as runtime-verified until reproduced at the agreed scale.

---

## LIFECYCLE002-STATEMACHINE-COMPILE

| Field | Value |
|---|---|
| **ID** | LIFECYCLE002-STATEMACHINE-COMPILE |
| **Severity** | P2 (verification gap) |
| **Found during** | LIFECYCLE-002 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

`go test ./packages/domain/statemachine -run TestLIFECYCLE002` failed to link on this host (OOM). CI job still runs the suite; local/static locks cover source invariants. Do not claim domain package compile/runtime verification on constrained hosts until reproduced.
