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

---

## LIFECYCLE003-POSTGRES-E2E

| Field | Value |
|---|---|
| **ID** | LIFECYCLE003-POSTGRES-E2E |
| **Severity** | P1 (verification gap) |
| **Found during** | LIFECYCLE-003 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

LIFECYCLE-003 soft-delete + archive copies are locked via static/unit tests. A full Postgres integration run (archive completed contest → absent from hot listings → present in `tournaments_archive` / audit query until `retain_until`) was **not** reproduced this session. Do **not** mark archival as runtime-verified until that E2E passes.

---

## ARCH001-DOCKER-IMAGE

| Field | Value |
|---|---|
| **ID** | ARCH001-DOCKER-IMAGE |
| **Severity** | P2 (verification gap) |
| **Found during** | ARCH-001 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

ARCH-001 added `apps/platform/Dockerfile` (one image, three modes) and `infra/docker/docker-compose.platform.yml`. The Docker image build / multi-mode container smoke was **not** run this session. Local `go test ./apps/platform/...` and binary build passed. Do **not** claim the versioned image acceptance criterion as runtime-verified until `docker build` succeeds and each mode responds on `/healthz` + `/readyz` in a container.

---

## ARCH003-OUTBOX-SCHEMA

| Field | Value |
|---|---|
| **ID** | ARCH003-OUTBOX-SCHEMA |
| **Severity** | P2 (verification gap) |
| **Found during** | ARCH-003 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

ARCH-003 adds an in-process outbox port for notification/ticket. ARCH-006 added target SQL + durable store ports; live Postgres permission/crash E2E remains open (`ARCH006-POSTGRES-PERMISSIONS-E2E`).

---

## ARCH003-AFFILIATE-JOB

| Field | Value |
|---|---|
| **ID** | ARCH003-AFFILIATE-JOB |
| **Severity** | P2 (verification gap) |
| **Found during** | ARCH-003 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Affiliate commission crediting still lives in `apps/leaderboard-worker`. ARCH-003 gated wallet-credit *flags* on projection finalize but did not relocate the affiliate job. Track until wallet/settlement ownership absorbs it.

---

## ARCH004-PAYMENT-HTTP-CUTOVER

| Field | Value |
|---|---|
| **ID** | ARCH004-PAYMENT-HTTP-CUTOVER |
| **Severity** | P2 (verification gap) |
| **Found during** | ARCH-004 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Platform mounts payment/wallet/kyc boundary APIs and owns orchestration modules. Full cutover of every `payment-service` HTTP route onto Platform-only serving was not completed. Do not claim all payment/withdrawal traffic runs exclusively on Platform until route cutover is verified.

---

## ARCH004-WEBHOOK-POSTGRES-E2E

| Field | Value |
|---|---|
| **ID** | ARCH004-WEBHOOK-POSTGRES-E2E |
| **Severity** | P1 (verification gap) |
| **Found during** | ARCH-004 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Webhook idempotency + ledger credit paths are unit/contract tested in Platform memory backends. Live Postgres webhook E2E against real provider fixtures was not reproduced this session.

---

## ARCH005-SETTLEMENT-HTTP-CUTOVER

| Field | Value |
|---|---|
| **ID** | ARCH005-SETTLEMENT-HTTP-CUTOVER |
| **Severity** | P2 (verification gap) |
| **Found during** | ARCH-005 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Platform settlement module owns finalization authority in-process. Full cutover of `settlement-service` Kafka/HTTP serving onto Platform-only was not completed this session.

---

## ARCH006-POSTGRES-PERMISSIONS-E2E

| Field | Value |
|---|---|
| **ID** | ARCH006-POSTGRES-PERMISSIONS-E2E |
| **Severity** | P1 (verification gap) |
| **Found during** | ARCH-006 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Target SQL defines per-owner outbox/inbox and schema grants. Live PostgreSQL tests that runtime roles cannot SELECT/DML other schemas, and crash-window outbox durability after process kill, were not reproduced this session.

---

## ARCH006-BROKER-RELAY

| Field | Value |
|---|---|
| **ID** | ARCH006-BROKER-RELAY |
| **Severity** | P2 (verification gap) |
| **Found during** | ARCH-006 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Outbox relay jobs exist as Platform worker ports. Publishing committed outbox rows to the broker with retry/dead-letter evidence was not runtime-verified.

---

## ENG001-TRADING-CORE-CUTOVER

| Field | Value |
|---|---|
| **ID** | ENG001-TRADING-CORE-CUTOVER |
| **Severity** | P2 (verification gap) |
| **Found during** | ENG-001 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Standalone Engine image/entrypoint exists. Default Compose still serves Engine via `trading-core` merged wrapper. Do not claim production traffic runs exclusively on the standalone Engine image until cutover is verified.

---

## ENG001-COMPOSE-RESTART-E2E

| Field | Value |
|---|---|
| **ID** | ENG001-COMPOSE-RESTART-E2E |
| **Severity** | P2 (verification gap) |
| **Found during** | ENG-001 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

`docker-compose.engine-standalone.yml` documents independent restart. Live Compose build/up/restart of `trading-engine` without Market Data provider credentials was not reproduced this session.

---

## DATA001-FLOAT-CUTOVER

| Field | Value |
|---|---|
| **ID** | DATA001-FLOAT-CUTOVER |
| **Severity** | P1 (verification gap) |
| **Found during** | DATA-001 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

`packages/money` primitives exist and ban float64 internally. Legacy Engine/Market Data/contracts `float64` call sites remain until ENG-002/MD-001 cutover. Do not claim financial boundaries are float-free repo-wide.

---

## MD001-KAFKA-V2-CUTOVER

| Field | Value |
|---|---|
| **ID** | MD001-KAFKA-V2-CUTOVER |
| **Severity** | P1 (verification gap) |
| **Found during** | MD-001 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Tick contract v2 and Engine admission helpers exist. Production Kafka still defaults to `ticks.v1` float snapshots. Do not claim live market data is fixed-point end-to-end until topic/producer/consumer cutover is verified.

---

## MD001-FRONTEND-CUTOVER

| Field | Value |
|---|---|
| **ID** | MD001-FRONTEND-CUTOVER |
| **Severity** | P2 (verification gap) |
| **Found during** | MD-001 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

TypeScript v2 types are exported for frontends. Chart/trading websocket handlers still consume legacy float tick payloads.

---

## ARCH007-WRAPPER-DELETE

| Field | Value |
|---|---|
| **ID** | ARCH007-WRAPPER-DELETE |
| **Severity** | P1 (verification gap) |
| **Found during** | ARCH-007 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Wrappers are deprecated and inventoried as `DELETE_AFTER_CUTOVER`, but source/images for `api-server`, `trading-core`, and `worker` remain for rollback. Physical deletion waits on payment/settlement/trading-core/Kafka cutover evidence.

---

## ARCH007-TARGET-COMPOSE-E2E

| Field | Value |
|---|---|
| **ID** | ARCH007-TARGET-COMPOSE-E2E |
| **Severity** | P2 (verification gap) |
| **Found during** | ARCH-007 (2026-08-25) |
| **Status** | Open — **not runtime-verified** |

Compose profile `target` defines Platform + Engine + Market Data. Live up/smoke against public routes was not reproduced this session.

---

## ARCH008-NO-SAFE-DELETE

| Field | Value |
|---|---|
| **ID** | ARCH008-NO-SAFE-DELETE |
| **Severity** | P2 (inventory outcome) |
| **Found during** | ARCH-008 (2026-08-25) |
| **Status** | Open — **no service proven safe to delete** |

ARCH-008 documented KEEP/REPLACE/DELETE_AFTER_CUTOVER for all listed standalones. Zero services met SAFE_TO_DELETE (proven zero callers/traffic/refs). Wrapper imports and/or ingress/gateway names remain. Do not delete `apps/*` trees without closing cutover gaps and producing traffic evidence.
