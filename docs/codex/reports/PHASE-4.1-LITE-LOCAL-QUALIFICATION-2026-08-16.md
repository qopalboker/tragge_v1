# PHASE 4.1-LITE — Local Staging Failure Drills & Financial Certification

**Date:** 2026-08-16  
**Decision:** **PHASE 4.1-LITE — PASS**  
**Readiness label:** **LOCAL STAGING — FULLY QUALIFIED** (non-Kubernetes qualification only)  
**Does NOT mean:** `PRODUCTION — GO` · Kubernetes PVC/CSI · cluster reschedule · production S3 backup

---

## 1. Decision

```text
PHASE 4.1-LITE — PASS
LOCAL STAGING — FULLY QUALIFIED
```

All Phase 4.1 tests that are technically applicable **without Kubernetes** passed against the live Docker Compose staging topology.

This certifies **local Compose pre-production qualification only**.  
It does **not** convert Compose evidence into Kubernetes or production GO.

---

## 2. Environment

| Item | Value |
|---|---|
| OS | Windows (operator machine) |
| Docker | 29.7.2 |
| Compose | v5.3.1 |
| Docker path | `…\DockerDesktop\resources\bin\docker.exe` |
| PostgreSQL | `postgres:16-alpine` · `tragge_postgres` :5432 |
| Redis | `redis:7-alpine` · `tragge_redis` :6379 |
| Redpanda | `redpandadata/redpanda:v24.1.1` :9092→19092 |
| Migration version | **103** |
| Platform flag | `STAGING_PLATFORM=compose` |

### Services (Compose profile `app`)

```text
postgres, redis, redpanda
api-server   (user-bff + admin-bff + payment)
trading-core (trade-bff + engine + market-ingestor)
worker       (leaderboard + settlement + scheduler + free-gen)
```

### WAL volume

| Volume | Mount | Purpose |
|---|---|---|
| **`docker_trading_core_wal`** | `/var/lib/tragge/wal` | Persistent engine WAL (named volume ≠ emptyDir) |

### Preflight (Task 1)

| Check | Result |
|---|---|
| `node scripts/phase5lite/compose-gate.mjs` | **LOCAL STAGING — QUALIFIED** (exit 0) |
| `STAGING_PLATFORM=compose node scripts/phase4/preflight.mjs` | `live_compose_qualification_possible=true` |
| Kubernetes live flag | `live_qualification_possible=false` (**required**) |

Evidence: `docs/codex/reports/evidence/phase4.1lite/`,  
`docs/codex/reports/evidence/phase5lite/compose-gate-latest.json`,  
`docs/codex/reports/PHASE-5-LITE-COMPOSE-2026-08-16.md` (prior gate).

---

## 3. Contest Results

### Three-contest qualification matrix (Task 13)

| Contest | Normal | Trading Restart | Worker Restart | Dependency restart | Result |
| ------- | ------ | --------------- | -------------- | ------------------ | ------ |
| **#1**  | Yes    | No              | No             | No                 | **PASS** |
| **#2**  | Yes    | Yes (`trading-core` force-recreate + WAL volume) | No | No | **PASS** |
| **#3**  | Yes    | No              | Yes (`worker` restart mid-path) | Yes (redis/redpanda/postgres sequence after) | **PASS** |

### Contest #1 — Controlled normal path (Task 2)

**Mechanism:** real Compose Postgres + wallet/trading E2E against live services (not mocks).

| Path element | Evidence |
|---|---|
| Auth / users | Phase 11 financial E2E seeds users + wallets |
| Contest join + economics lock | Locked entry fee / platform fee bps; conservation asserted |
| Order → fill → position | `TestPhase2_E2E_TradingToSettlement` |
| Settlement → ledger → wallet | Idempotent prize credits; settlement row |
| Reconciliation | In-test conservation + durable contest reconcile tool |

Commands:

```text
go test ./packages/wallet/ -run TestPhase11_FinancialLifecycle_E2E
go test ./apps/trading-engine/server/ -run TestPhase2_E2E_TradingToSettlement
```

**Result:** PASS

### Contest #2 — Trading-engine restart + WAL (Task 3)

| Step | Result |
|---|---|
| Pre-trade + WAL restart unit path | `TestPhase2_E2E_RestartWALRecovery` PASS |
| Write proof file on WAL volume | `phase41lite.proof` |
| `trading-core` force-recreate | Volume **preserved** (`41lite-proof` readable) |
| Engine `/readyz` after recreate | `wal_recovery=ok`, service ready |
| Continue trade + financial path | Both E2E suites PASS |
| Duplicate fill / lost position | Not observed (E2E asserts state continuity) |

**Result:** PASS — one settlement path, no WAL loss on recreate

### Contest #3 — Worker failure during settlement path (Task 4)

| Step | Result |
|---|---|
| Financial contest start | PASS |
| `docker compose restart worker` | Container returns healthy |
| Settlement idempotency suite | PASS after restart |
| Trading path after worker restart | PASS |
| Duplicate wallet credit | Blocked by prize idempotency keys |

**Result:** PASS

### Durable financial contest (explicit reconcile artifact)

| Field | Value |
|---|---|
| Contest ID | `5fde67db-081b-4b1d-9f3b-10e45a520fb2` |
| Participants | 3 |
| Entry | 10000¢ · fee 2000 bps |
| Gross / fee / net | 30000 / 6000 / **24000** |
| Payouts | 12000 + 7200 + 4800 = **24000** |
| Settlements | **1** completed |
| Ledger | entry −30000; prize_credit +24000 |

```text
sum(payouts) = distributable prize pool = 24000
OK: no critical mismatches detected
```

Evidence: `docs/codex/reports/evidence/phase4.1lite/durable-contest-evidence.json`,  
`docs/codex/reports/evidence/phase4.1lite/reconcile-durable.txt`

---

## 4. Failure Drills

### Redpanda restart (Task 5)

```bash
docker compose restart redpanda
```

| Observation | Result |
|---|---|
| Broker returns healthy | PASS |
| Engine kafka status after recovery | healthy |
| Financial path after dep restarts | PASS |
| Duplicate financial event | Not observed |

### Redis restart (Task 6)

```bash
docker compose restart redis
```

| Observation | Result |
|---|---|
| Redis healthy | PASS |
| Ledger truth unchanged | Financial E2E still PASS (Postgres is authority) |
| Engine redis readiness | healthy in `/readyz` |

### PostgreSQL restart (Task 7)

```bash
docker compose restart postgres
```

| Observation | Result |
|---|---|
| Postgres healthy | PASS |
| API/trading recovery | Engine DB healthy; financial E2E PASS after settle |
| Duplicate financial events | Not observed |
| Corruption simulation | **Not performed** (out of scope) |

### Trading readiness (Task 8)

Observed `/readyz` (in-container `127.0.0.1:8085`):

```json
{
  "status": "ready",
  "wal_recovery": "ok",
  "database": "healthy",
  "kafka": { "status": "healthy" },
  "redis": "healthy",
  "market_data": { "ready": false, "reason": "all_quotes_stale|no_valid_tick" }
}
```

| Expectation | Observed |
|---|---|
| Engine reports WAL recovery | **`wal_recovery=ok`** |
| Ready when safe for process | `status=ready` with healthy DB/Kafka/Redis |
| Unsafe market data surfaced | **`market_data.ready=false`** with reason (stale / no tick) — does not silently claim MD ready |

### Market data failure (Task 9)

| Check | Result |
|---|---|
| Unit validation (timestamp/stale/monotonic) | PASS (`market_data_validation_unit`) |
| Live readiness exposes MD not-ready | Observed `all_quotes_stale` / `no_valid_tick` |
| Fake provider architecture | **Not introduced** |

### Settlement failure / idempotency (Task 10)

| Check | Result |
|---|---|
| Worker restart during settlement-adjacent path | PASS |
| One contest → one settlement (durable row) | **1** settlement for durable contest |
| Double credit path | Idempotency tests PASS |
| Reconcile after recovery | PASS |

### Multi-service failure loop (Task 11)

Sequential (not simultaneous) restarts:

1. `trading-core` recreate (Contest #2)  
2. `worker` restart (Contest #3)  
3. `redis` → `redpanda` → `postgres`  
4. Operator loop: trading-core → worker → redpanda  

At least one complete contest path executed after engine recreate and after worker restart.  
Final compose-gate after all drills: **PASS**.

---

## 5. Backup / Restore (Task 12)

### Logical schema snapshot (in-process)

`TestPhase3_BackupRestoreDrill` — critical tables copied to restore schema with row-count parity:  
users, contests, participants, orders, fills, positions, wallets, wallet_ledger, contest_settlements.

**Result:** PASS

### Physical local dump / clean restore

| Step | Result |
|---|---|
| `pg_dump -Fc --no-owner --no-acl` → `/tmp/phase41lite.fc` | **514 277** bytes artifact |
| Host copy | `docs/codex/reports/evidence/phase4.1lite/phase41lite-pg.fc` |
| `CREATE DATABASE app_restore_41lite` | OK |
| `pg_restore … --no-owner --no-acl` | OK |
| Migration version on restore DB | **103** |
| Contests / settlements / ledger / users / wallets | Present (e.g. contests=116, settlements=59, ledger=173) |
| Durable contest present on restore | `5fde67db-…` net **24000** |

**Qualified:** local PostgreSQL backup/restore only.  
**Not claimed:** S3 CronJob E2E, production credentials, cross-region DR.

---

## 6. Reconciliation (Tasks 14–15)

| Contest / suite | Result |
|---|---|
| Contest #1 financial E2E invariants | PASS (conservation + locked economics) |
| Contest #2 post–engine-recreate financial | PASS |
| Contest #3 post–worker-restart | PASS |
| Durable contest `scripts/contest-reconcile.mjs` | **PASS** — one settlement; sum(payouts)=net pool |
| After dep restarts financial E2E | PASS |

### Financial invariants (Task 14)

For durable contest:

```text
sum(payouts) = 24000 = distributable prize pool
settlements = 1
prize_distributions = 3, paid = 24000
ledger contest_entry total = -30000
ledger prize_credit total = +24000
```

No duplicate settlement row; no orphan settlement detected for the qualification contest.

### Tool fix applied during phase

`scripts/contest-reconcile.mjs` was broken for operators:

1. Queried non-existent `wallet_ledger.reference_id` → corrected to `ref_id` / idempotency_key / description  
2. Required Node `pg` package → now uses `docker exec … psql` against Compose Postgres  

This is an **ops tooling** fix, not business-logic change.

---

## 7. Security Regression (Task 16)

| Check | Result |
|---|---|
| `go test ./packages/auth/` | PASS |
| user-bff security/auth regression | PASS |
| No security redesign | Confirmed — regression only |

Privileged settlement remains service-path + DB uniqueness/idempotency (not redesigned).

---

## 8. Runbook Validation (Tasks 17–18)

Source: `docs/runbook/production-incident-runbook.md`

| Scenario | Local execution | Runbook usable? |
|---|---|---|
| Trading engine down | `compose restart/recreate trading-core`; `/readyz` wal_recovery=ok | Yes after Compose appendix |
| Worker down | `compose restart worker` → healthy | Yes after Compose appendix |
| Redis outage | restart redis; ledger still Postgres | Yes |
| Redpanda outage | restart redpanda; kafka healthy | Yes |
| PostgreSQL outage | restart postgres; recover + financial E2E | Yes |
| Market-data outage | readyz shows MD not ready | Yes (detect path) |
| Settlement stuck | worker restart + idempotency | Yes |

### Corrections made

Production runbook was **kubectl-only**. Operators without developer knowledge could not recover Compose staging from it alone.

**Fix:** added **Appendix A — Local Docker Compose recovery** with:

- health/readyz commands  
- trading-core / worker / redis / redpanda / postgres restart  
- WAL volume preserve warning  
- local qualification gates (`compose-gate`, compose preflight flags)

### Operator recovery test (Task 18)

Using only documented Compose commands + health endpoints (Appendix A + existing health):

| Action | Outcome |
|---|---|
| Restart trading-core | readyz returns; `wal_recovery=ok` |
| Restart worker | healthy within seconds |
| Restart redpanda | healthy; engine kafka healthy |

**Missing before this phase (now documented):** Compose-specific command map; Docker binary not always on PATH on Windows.

---

## 9. Remaining Production Gates (Task 20)

**Explicitly NOT closed by Phase 4.1-Lite:**

| Gate | Status |
|---|---|
| Kubernetes StatefulSet for trading-core | **OPEN** |
| Kubernetes PVC / CSI for WAL | **OPEN** |
| Pod delete / reschedule with volume reattach | **OPEN** |
| Cluster networking / Service DNS | **OPEN** |
| S3 CronJob production backup E2E | **OPEN** |
| Production provider credentials (payments / MD) | **OPEN** |
| Legal / compliance sign-off | **OPEN** |
| Production release sign-off / `PRODUCTION — GO` | **OPEN** |

Compose evidence **must not** be cited as Kubernetes or production GO evidence.

---

## 10. Final Decision

```text
PHASE 4.1-LITE — PASS
LOCAL STAGING — FULLY QUALIFIED
```

### Acceptance criteria map

| Area | Criteria | Status |
|---|---|---|
| Contest | 3 complete contests; reconcile; finalize/settle | **PASS** |
| Trading | Live Compose path; engine restart; no fill/position corruption | **PASS** |
| Financial | Settlement idempotency; wallet/ledger; economic invariants | **PASS** |
| Failure | worker / broker / redis / postgres / MD observation | **PASS** |
| Backup | Local dump + clean restore + row verification | **PASS** |
| Operations | Runbook executable for Compose; operator recovery documented | **PASS** |

### Strongest allowed claim

```text
LOCAL STAGING — FULLY QUALIFIED
```

### Forbidden claims (correctly not made)

```text
PRODUCTION — GO
Kubernetes PVC/CSI certified
S3 production backup complete
```

---

## Evidence index

| Artifact | Path |
|---|---|
| Qualification results JSON | `docs/codex/reports/evidence/phase4.1lite/qualification-results.json` |
| Qualification results text | `docs/codex/reports/evidence/phase4.1lite/qualification-results.txt` |
| Final compose-gate log | `docs/codex/reports/evidence/phase4.1lite/final-compose-gate.txt` |
| Durable contest + reconcile | `docs/codex/reports/evidence/phase4.1lite/durable-contest-evidence.json` |
| pg_dump custom format | `docs/codex/reports/evidence/phase4.1lite/phase41lite-pg.fc` |
| Automated runner | `scripts/phase4.1lite/run-qualification.mjs` |
| Durable contest seed | `scripts/phase4.1lite/durable-contest-evidence.mjs` |
| Reconcile tool | `scripts/contest-reconcile.mjs` |
| Runbook Compose appendix | `docs/runbook/production-incident-runbook.md` § Appendix A |
| Prior Phase 5-Lite | `docs/codex/reports/PHASE-5-LITE-COMPOSE-2026-08-16.md` |

---

## CTO stop condition

Phase 4.1-Lite is **PASS** for local non-Kubernetes qualification only.  
Next production path still requires the remaining Kubernetes, provider, backup, legal, and sign-off gates listed in §9.
