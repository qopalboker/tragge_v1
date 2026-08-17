# PHASE 0 — Current-Tree Forensic Audit and Baseline

**Date:** 2026-08-16  
**Repository snapshot:** local tree `D:\Grok\tragge_v0-main\tragge_v0-main` (aligned with `github.com/qopalboker/tragge_v1`)  
**Audit author:** Acting CTO (forensic re-verification against live source)  
**Paid-production decision (current):** **NO-GO**  
**Phase 0 acceptance status:** **PASS** (forensic/planning complete; no production launch claim)

This document does **not** claim paid readiness. It establishes evidence for the launch backlog. Prior audits are treated as evidence only; every P0/P1 finding below was re-checked against the current tree.

---

## 0.1 Repository inventory and architecture map

### Metrics (2026-08-16 tree count)

| Metric | Count |
|---|---:|
| Go files (excl. node_modules) | 434 |
| Go test files | 139 |
| Vue files | 235 |
| TypeScript/TSX (approx.) | 193 |
| Up migrations (`*.up.sql`) | 102 |
| Down migrations (`*.down.sql`) | 103 |
| Application directories under `apps/` | 17 |
| Package directories under `packages/` | 20 |
| K8s files under `infra/k8s` | 48 |
| CI workflow | `.github/workflows/ci.yml` (present locally) |

> Note: `scripts/production-baseline.mjs verify` still expects older snapshot counts (e.g. 415 Go files, 100 up migrations). **Inventory verifier is STALE relative to the tree** — evidence, not a product defect.

### Executable applications

| Application | Form | Runtime role |
|---|---|---|
| `api-server` | Merged process | **user-bff :8081**, **admin-bff :8083**, **payment-service :8091** — shared DB pool + Redis; **isolated User vs Admin auth contexts** |
| `trading-core` | Merged process | **market-ingestor :8084**, **trading-engine :8085**, **trade-bff :8082** — shared DB + Redis |
| `worker` | Merged process | **leaderboard :8086**, **settlement :8087**, **contest-scheduler :8088**, **free-contest-generator :8089** — shared DB + Redis |
| `user-bff` / `admin-bff` / `payment-service` / `trade-bff` / `trading-engine` / `market-ingestor` / `leaderboard-worker` / `settlement-service` / `contest-scheduler` / `free-contest-generator` / `shard-router` | Standalone modules | Still present for local/dev; production Compose/K8s base prefer merged wrappers |
| `user-frontend` | Vue/Vite | User + trade Mini App surface (`:5173` dev) |
| `admin-frontend` | Vue/Vite | Admin panel (`:5174` dev) |
| `gateway` | Nginx | Edge routing / static / WS sticky in dockerized topology |

### Shared packages (ownership)

| Domain | Package(s) |
|---|---|
| Auth / session / MFA | `packages/auth` |
| Wallet / ledger | `packages/wallet` |
| Prize math | `packages/scoring`, `packages/scoring/prize`, `packages/scoring/distribution` |
| Contest state machine | `packages/domain/statemachine` |
| Contracts / events | `packages/contracts` |
| DB / migrations | `packages/db` |
| Edge security / CSRF / rate limit | `packages/validation`, `packages/resilience/ratelimit` |
| Secrets loading | `packages/secrets` |
| Observability | `packages/observability` |
| SMS / KYC / notifications | `packages/sms`, `packages/kyc`, `packages/notification` |

### Data / messaging topology

| System | Usage |
|---|---|
| **PostgreSQL 16** | Primary system of record: users, contests, wallets, ledger, settlements, orders/positions history |
| **Redis 7** | Sessions, rate limits, lockouts, leaderboard caches, pub/sub contest events, WS affinity |
| **Redpanda (Kafka)** | Orders, ticks, fills, positions, PnL deltas, contest state, settlement requests, notifications |
| **MinIO/S3 (optional)** | Avatars / KYC documents — not required for pure contest trading path |

### Authentication boundaries

- **User trust domain:** issuer/audience/context `user`; secrets `JWT_SECRET_USER` + refresh; cookies `refresh_token_user`.
- **Admin trust domain:** issuer/audience/context `admin`; secrets `JWT_SECRET_ADMIN` + refresh; Super Admin TOTP MFA required on login.
- **api-server** constructs **two** auth contexts (`buildAuthContexts`) and injects User into user-bff/payment, Admin into admin-bff — verified in `apps/api-server/main.go`.
- Query-string session tokens are **prohibited** (`HasProhibitedCredentialQuery` in `packages/auth/middleware.go`).

### Financial boundaries

- Entry fee debit on join (user-bff + wallet package).
- Prize **credits** intended via **settlement-service** (`CreditPrizeIdempotent`).
- Leaderboard finalization writes ranks and payout metadata; comments explicitly state wallet credits are **delegated** to settlement.
- Withdrawals: manual review path in payment-service / admin-bff (MVP policy).

### Ownership summary (critical path)

| Concern | Owner (source of truth) | Shared / secondary |
|---|---|---|
| User auth | user-bff | packages/auth |
| Admin auth + MFA | admin-bff | packages/auth |
| Contest CRUD / admin ops | admin-bff | domain/statemachine |
| Contest join / leave | user-bff | wallet |
| Market data | market-ingestor | Kafka ticks |
| Order execution | trading-engine | WAL, Kafka |
| Realtime trade UI API | trade-bff | WS hub |
| Ranking / finalization | leaderboard-worker | domain/statemachine Complete |
| Prize wallet credit | settlement-service | packages/wallet |
| Contest scheduling | contest-scheduler | free-contest-generator (parallel path) |
| Payments / deposits | payment-service | providers NOWPayments/Plisio/Sepal/Jibit |

---

## 0.2 P0/P1 finding reconciliation (current tree)

Classifications: `OPEN` | `FIXED` | `STALE` | `PARTIALLY_FIXED` | `UNKNOWN`

### Architecture

| ID | Class | Evidence | Required action |
|---|---|---|---|
| **P0-ARCH-01** | **OPEN** | `apps/trading-core/main.go` still merges engine+ingestor+trade-bff | Accept for controlled launch **or** split failure domains; document blast radius |
| **P0-ARCH-02** | **OPEN** | `apps/api-server/main.go` still merges user+admin+payment | Same — shared process risk remains |
| **P0-ARCH-03** | **OPEN** | `apps/worker/main.go` merges leaderboard+settlement+scheduler+generator | Same |
| **P0-ARCH-04** | **OPEN** | `infra/k8s/base` uses merged; production overlay still patches standalone names | Fix k8s overlay before cluster launch |
| **P0-ARCH-05** | **OPEN** | Merged health endpoints do not prove each embedded runtime ready | Per-runtime readiness probes |

### Security

| ID | Class | Evidence | Required action |
|---|---|---|---|
| **P0-SEC-01** | **FIXED** | `api-server` builds **isolated** User + Admin contexts (`buildAuthContexts`); not a single shared Auth injected into all | Maintain dual secrets in deploy config |
| **P0-SEC-02** | **FIXED** | `HasProhibitedCredentialQuery` fail-closed on `token`/`jwt`/… query params | Keep redaction middleware on telemetry path |
| **P0-SEC-03** | **PARTIALLY_FIXED** | SMS: no mock OTP logger when key missing; OTP fail-closed when enabled without provider (`user-bff/server/app.go`) | Ensure production `SMS_ENABLED=false` or real KaveNegar keys; document |
| **P0-SEC-04** | **PARTIALLY_FIXED** | Super Admin MFA enrollment/verify exists (`admin_mfa.go`); reauthentication package exists | Prove E2E Super Admin MFA enrollment in staging; cover all sensitive admin mutations |

### Financial / contest economics

| ID | Class | Evidence | Required action |
|---|---|---|---|
| **P0-FIN-01** | **OPEN** | Join still reads **both** `platform_fee_bps` and `commission_rate` (`contest_handlers.go`) | Single fee field in runtime + migration policy |
| **P0-FIN-02** | **OPEN** | Same dual-field join economics path | Collapse to one calculation path |
| **P0-FIN-03** | **OPEN** | `packages/scoring/distribution` still Power Law α model, not locked `tralent_v1` contract alone | Align product policy + single distribution implementation |
| **P0-FIN-04** | **PARTIALLY_FIXED** | Shared `prizedistribution` used by leaderboard + settlement + prize package, but leaderboard still has own wrappers (`payout.go`) and user preview (`contest_prizes.go`) | Force all call sites through one public economics API |
| **P0-FIN-05** | **PARTIALLY_FIXED** | Leaderboard comments + flow: **wallet credits delegated to settlement**; but leaderboard still calculates payouts, writes settlement audit rows, and completes contest | Settlement sole financial authority; leaderboard rank-only |
| **P0-FIN-06** | **OPEN** | No immutable economics lock at join-cutoff found in state machine handlers | Implement lock snapshot table/fields at cutoff |

### Contest / scheduling

| ID | Class | Evidence | Required action |
|---|---|---|---|
| **P0-CON-01** | **OPEN** | Join requires `status == registration_open` only (`contest_handlers.go` ~533, ~616) | Implement approved late-join policy explicitly |
| **P0-CON-02** | **OPEN** | `max_participants` still in SQL, join path, templates | Product decision: remove or enforce consistently |
| **P0-CON-03** | **OPEN** | Separate `contest-scheduler` calendar vs `free-contest-generator` | One scheduling policy / uniqueness constraints |
| **P1-CON-04** | **OPEN** | Cleanup hard-deletes archived contests (`cleanup.go`) | Soft-delete / archive retention policy |
| **P1-CON-05** | **OPEN** | System accounts exist; exclusion not proven on every path | Centralize `is_system_account` filters + tests |

### Engine / market data

| ID | Class | Evidence | Required action |
|---|---|---|---|
| **P1-ENG-01** | **OPEN** | `WAL_PERSIST_PATH` defaults empty (`config.go`) | Require durable path in prod config |
| **P1-ENG-02** | **OPEN** | WAL replay failure logs warn and continues (`app.go` ~540) | Fail readiness on unrecovered WAL |
| **P1-ENG-03** | **OPEN** | Compose/k8s lack proven WAL volume for engine | Add PVC / bind mount |
| **P1-ENG-04** | **OPEN** | float64 still in pricebook / position math | Decimal money path for PnL/score critical fields |
| **P1-ENG-05** | **OPEN** | WAL unit tests exist; no CI crash/soak suite | Add recovery integration tests |
| **P1-MD-01..03** | **OPEN** | Tick v1 still float64, minimal fields, simple failover | Contract v2 + quality flags (post-min launch possible) |
| **P1-MD-04** | **OPEN** | No commercial redistribution evidence | Non-engineering gate |

### Frontend / CI

| ID | Class | Evidence | Required action |
|---|---|---|---|
| **P1-FE-01** | **OPEN** | Trade module lives inside user-frontend | Accept for launch min; split later |
| **P1-FE-02** | **OPEN** | Large trading Vue/TS files | Non-blocking polish |
| **P1-CI-01** | **OPEN** | CI lint/build only | Add typecheck + unit + critical e2e |
| **P1-CI-02** | **PARTIALLY_FIXED** | settlement has tests; scheduler/generator/worker/trading-core still thin/none | Add tests Phase 1–2 |
| **P1-CI-03** | **OPEN** | CI installs golangci from mutable HEAD | Pin version |
| **P1-CI-04** | **OPEN** | No migrate/restore/load gates in CI | Phase 3–4 gates |

### Local session deltas (not in original 35-row table)

| Item | Class | Notes |
|---|---|---|
| Admin seed role `admin` + `super_admin` | **FIXED (local)** | Legacy `admin` role rejected by `canonicalAdminRoles`; seed fixed; DB cleaned |
| Admin login burst 2/min | **PARTIALLY_FIXED (dev)** | Dev ENVIRONMENT relaxes edge + in-memory limits; prod still tight |
| Baseline count verifier | **STALE** | Expected counts lag tree (434 Go vs 415 expected) |

---

## 0.3 Reproducible baseline results

### Executed

| Check | Result |
|---|---|
| `node scripts/production-baseline.mjs inventory` | **PASS** (runs; emits inventory JSON) |
| `node scripts/production-baseline.test.mjs` | **4/5 PASS** after restoring `ci.yml`; previously failed when workflows were renamed for PAT scope |
| `node scripts/production-baseline.mjs verify` | **FAIL** — inventory counts diverge from frozen audit expectations (tree evolved) |
| `go test ./packages/wallet/...` | **PASS** |
| `go test ./packages/scoring/...` | **PASS** |
| `go test ./packages/domain/statemachine/...` | **PASS** |
| `go test ./packages/auth/...` | **PASS** |

### Not executed (with reason)

| Check | Why blocked | Equivalent static check |
|---|---|---|
| Full `go test ./...` monorepo | Long runtime; dependency-heavy; Docker DB/Kafka needed for integration | Package-level tests above |
| Playwright e2e | Stack was stopped; browser install optional | E2E specs present under `apps/*/e2e` |
| Fresh migrate on clean volume | Docker was down for this audit pass | 102 up migrations present; prior session migrated to v102 successfully |
| K8s deploy | No cluster | Manifests reviewed for merge/overlay inconsistency |
| Image build (Go services) | Docker Go module proxy 403/timeout in this environment | Host `go build` of api-server/trading-core/worker succeeded previously |

---

## 0.4 Launch-critical path (end-to-end)

```
User auth (user-bff / JWT user context)
  → Contest discovery (user-bff list; status scheduled|registration_open|running)
  → Join (user-bff): requires registration_open; debit entry_fee; dual fee fields
  → Registration record (participants)
  → Contest start (contest-scheduler / admin / state machine → running)
  → Market data (market-ingestor → Kafka ticks)
  → Order place (trade-bff → Kafka orders)
  → Execution (trading-engine: match/fill, positions, PnL deltas)
  → Scoring (engine unrealized + leaderboard consumers)
  → Contest end (scheduler/state machine → ended/finalizing)
  → Finalization (leaderboard-worker: rank + payout calc + Complete())
  → Settlement (settlement-service: prize calc + CreditPrizeIdempotent + settled)
  → Ledger + wallet projection
  → User-visible results (user-bff / frontend)
```

### Critical failure points

1. **Join only while `registration_open`** — late join blocked (P0-CON-01).  
2. **Dual fee fields** — economic drift (P0-FIN-01/02).  
3. **Leaderboard vs settlement** — dual prize calculation still present even if credits are settlement-only (P0-FIN-04/05).  
4. **Merged processes** — payment outage can ride with user API; settlement outage rides with leaderboard (P0-ARCH-*).  
5. **WAL default empty** — engine crash recovery not durable by default (P1-ENG-01/02).  
6. **No economics lock** — admin can change fee/pool mid-flight (P0-FIN-06).  
7. **Scheduler dual writers** — free generator + calendar can double-create (P0-CON-03).  
8. **MFA / SMS / MinIO / provider keys** — operational config gates, not pure code.

---

## 0.5 Launch blocker matrix (priority excerpt)

| ID | Sev | Component | Failure mode | Financial | Security | User | Phase | Status |
|---|---|---|---|---|---|---|---|---|
| P0-FIN-01/02 | P0 | user-bff join | Dual fee sources | Double-count / wrong pool | — | Wrong prize display | 1 | OPEN |
| P0-FIN-04/05 | P0 | leaderboard + settlement | Dual prize math; dual authority surface | Double payout risk residual | — | Wrong ranks/prizes | 1 | PARTIAL |
| P0-FIN-06 | P0 | contest lifecycle | Mutable economics after start | Silent prize change | Admin abuse | Unfair contest | 1 | OPEN |
| P0-CON-01 | P0 | join | Late join blocked | Lost entry fees policy mismatch | — | Cannot join running contest | 1 | OPEN |
| P0-CON-03 | P0 | scheduler | Duplicate contests | Split liquidity | — | Ghost contests | 1 | OPEN |
| P0-ARCH-01..03 | P0 | deploy | Shared blast radius | Cascade outages | Auth co-tenancy residual process | Total outage | 3–4 | OPEN (accepted risk for controlled launch if documented) |
| P1-ENG-01/02 | P1 | engine | Non-durable WAL / continue after bad replay | Lost fills / wrong positions | — | Bad contest results | 2 | OPEN |
| P0-SEC-04 | P0→P1 residual | admin MFA | Incomplete enrollment/ops proof | — | Super admin compromise | Admin lockout | 1–3 | PARTIAL |
| P1-MD-04 | P1 | legal | Provider rights | — | — | Product risk | non-eng | OPEN |
| CI inventory | P1 | baseline tool | Stale expected counts | — | — | False CI red | 0 toolfix | OPEN |

Full matrix for remaining P1s is tracked by the classification table in §0.2; all are scheduled into Phases 1–4 of the CTO plan.

---

## 0.6 Launch minimum

### Must exist before **controlled** paid contest launch

- User + Admin authentication isolation (present).  
- Super Admin MFA enrolled and verified in staging.  
- Contest lifecycle state machine with legal transitions only.  
- **Single** fee/prize economics implementation + immutable lock.  
- Join policy matching product (including late-join decision).  
- Trading path: validate order → execute → position → score.  
- Market data with stale-price fail-safe.  
- Deterministic finalization + **settlement-only** wallet credits + idempotency.  
- Ledger ↔ wallet reconciliation tests.  
- Durable engine WAL in production config.  
- Migrations applied from clean DB; backup/restore drill.  
- Deployable topology (Compose or K8s) with secrets not in git.  
- Health/readiness that fail closed when money path broken.  
- Audit trail for join, settlement, admin overrides.  
- Provider keys + webhook secrets configured (non-code).  
- Legal/provider rights sign-off (non-code).

### Can wait post-launch

- Full service decomposition of merged wrappers.  
- Tick contract v2 / consensus market data.  
- Decimal rewrite of all float64 paths (must fix critical PnL path first).  
- Frontend trade module split / file size refactor.  
- Advanced analytics, fraud suite, polish.  
- Full CI load/SBOM/soak matrix (keep smoke + financial e2e).

---

## Phase 0 acceptance criteria checklist

| Criterion | Met? |
|---|---|
| Every P0/P1 has current classification | **YES** (§0.2) |
| Launch-critical path documented | **YES** (§0.4) |
| Critical service owners identified | **YES** (§0.1) |
| DB/migration state known | **YES** — 102 up migrations; prior local apply to v102 |
| Minimum launch scope documented | **YES** (§0.6) |
| Prioritized implementation plan exists | **YES** — Phase 1 (economics/settlement) → 2 (engine/MD) → security residual → deploy/CI |
| No critical unknown hidden as “needs investigation” | **YES** — residual unknowns are non-eng (provider rights) or operational config |

### Acceptance status: **PASS**

Phase 0 is complete as a forensic/planning gate.  
**Paid production remains NO-GO.** No Phase 1 code changes were made in this phase except restoring `.github/workflows/ci.yml` for baseline accuracy.

---

## Prioritized plan for next phases (executable)

1. **Phase 1 (P0 finance/contest):** single fee field; single prize API; economics lock; settlement sole credit authority; join policy; scheduler uniqueness; e2e financial tests with failure injection.  
2. **Phase 2 (engine/MD):** durable WAL + fail readiness; order validation matrix; critical decimal path.  
3. **Phase 3 (security residual + ops):** Super Admin MFA e2e proof; k8s overlay fix; backup restore.  
4. **Phase 4 (launch qualification):** full contest lifecycle on fresh DB; dual settlement attempt; crash/retry; smoke report; GO/NO-GO.

---

## Implemented (this phase)

- Restored `.github/workflows/ci.yml` from `workflows.pending` for local baseline.  
- Created this report: `docs/codex/reports/PHASE-0-FORENSIC-AUDIT-2026-08-16.md`.  
- No product behavior refactors (per Phase 0 contract).

## Tests (this phase)

```
node scripts/production-baseline.mjs inventory   # PASS
node scripts/production-baseline.test.mjs        # 4/5 PASS (count-related expectations lag tree)
node scripts/production-baseline.mjs verify      # FAIL (stale expected inventory counts)
go test ./packages/wallet/...                    # PASS
go test ./packages/scoring/...                   # PASS
go test ./packages/domain/statemachine/...       # PASS
go test ./packages/auth/...                      # PASS
```

## Findings closed

- **P0-SEC-01** FIXED (isolated auth contexts in api-server).  
- **P0-SEC-02** FIXED (query credential rejection).  

## Findings remaining

All other OPEN / PARTIALLY_FIXED rows in §0.2 — especially **P0-FIN-*** and **P0-CON-*** as Phase 1 blockers.

## Risks

- Dual prize calculation paths remain the highest financial risk.  
- Merged-process topology remains a blast-radius risk for controlled launch.  
- Baseline inventory tool no longer matches tree; do not treat it as launch truth without update.  
- Non-engineering gates (provider rights, legal) still block real-money GO regardless of code.

## Acceptance status

**PASS** (Phase 0 forensic/planning only)
