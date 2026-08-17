# PHASE 6.1 — VM / Persistent WAL / Object Storage / Rollback Qualification

**Date:** 2026-08-16  
**Decision:** **PHASE 6.1 — BLOCKED**  
**Architecture:** VM + Docker Compose (Kubernetes **not** required)  
**Gate:** `node scripts/prod/phase61-gate.mjs` → **BLOCKED (9 hard, 10 total)**  
**Next phase:** Phase 6.2 **not authorized** until 6.1 PASS

---

## Executive Decision

```text
PHASE 6.1 — BLOCKED
```

**Primary stop reason (CTO Task 1 / stop conditions):**

```text
BLOCKED — LIVE VM REQUIRED
```

This operator session has:

| Item | Result |
|---|---|
| Docker | **Docker Desktop** (WSL2) — **not** a production-equivalent VM |
| Cloud VM host (`TRAGGE_VM_HOST` / SSH target) | **Unset** |
| Dedicated cloud block volume for WAL | **Not provisioned / not declared** |
| Object storage (`S3_BUCKET` / MinIO / GCS / Azure) | **Unavailable** |
| AWS / Azure / GCP CLI | **MISSING** |
| multipass / qemu / VBox for alternate lab VM | **MISSING** |

Per Phase 6.1 rules, **Docker Desktop, local directory WAL paths, and local filesystem “S3” are not final evidence** for HARD gates.  
No infrastructure was invented. No gates were weakened.

---

## Infrastructure (this session)

| Field | Value |
|---|---|
| Provider | **None** (local workstation) |
| Host | Windows + Docker Desktop `docker-desktop` |
| OS (Docker) | Docker Desktop / Kernel WSL2 |
| Docker | 29.7.2 |
| Compose | v5.3.1 (prior) |
| VM size | **N/A — no VM** |
| Root disk | Workstation disk |
| Dedicated WAL block device | **N/A** |
| WAL path observed | Repo path `var/lib/tragge/wal` (local) — **not** cloud block |
| PostgreSQL / Redis / Redpanda | Local Compose containers (healthy) — **not** production VM topology |

Inventory evidence: `docs/codex/reports/evidence/phase61/inventory-latest.txt`

### Preflight

```text
node scripts/prod/preflight.mjs
→ preflight_tools_ok=true (local Docker path only)
```

Does **not** satisfy LIVE VM requirement.

---

## HARD gate results

| ID | Gate | Result | Notes |
|---|---|---|---|
| **HARD-01** | Persistent WAL on dedicated block storage | **BLOCKED** | No block volume; Desktop path rejected |
| **HARD-02** | VM reboot recovery | **BLOCKED** | No VM to reboot |
| **HARD-03** | VM replacement + volume reattach | **BLOCKED** | No VM / volume |
| **HARD-04** | Backup to real object storage | **BLOCKED** | No bucket/credentials; `object-backup-e2e.mjs` exit 2 |
| **HARD-05** | Clean restore | **BLOCKED** | Depends on HARD-04 |
| **HARD-06** | Restore financial reconciliation | **BLOCKED** | Depends on HARD-05 |
| **HARD-07** | Rollback drill / forward-fix | **BLOCKED** | Not executed (requires prod-equivalent host) |
| **HARD-08** | Single-active trading owner | **BLOCKED** | Replacement fencing not testable without dual hosts |

### Supporting

| ID | Gate | Result |
|---|---|---|
| SUP-01 | Container recreate WAL (prior path) | **PASS** (Phase 6-NK `WAL_HOST_PERSIST_PASS` on local stack — **not** HARD-01) |
| SUP-02 | Docker engine restart on prod-equivalent host | **BLOCKED** |
| SUP-03 | Health after recovery (phase evidence) | **BLOCKED** (no post-VM-recovery evidence file) |

Gate output: `docs/codex/reports/evidence/phase61/phase61-gate-latest.txt`

---

## WAL Evidence

| Drill | Status |
|---|---|
| Container recreation (local Compose / prior 6-NK) | Proven previously — **not** accepted as dedicated block HARD-01 |
| Docker Engine restart (host) | **Not executed** on real VM |
| VM reboot | **Not executed** |
| Volume detach/reattach | **Not executed** |
| VM replacement | **Not executed** |

---

## Backup Evidence

| Step | Status |
|---|---|
| Object storage preflight | **UNAVAILABLE** |
| `node scripts/prod/object-backup-e2e.mjs` | Exit **2** — refused local FS substitute |
| Upload / integrity / clean restore / reconcile | **Not run** |

Scripts ready for when credentials exist:

- `scripts/backup/backup-postgres.sh`  
- `scripts/prod/object-backup-e2e.mjs`  
- `docs/runbook/backup-restore-runbook.md`

---

## Rollback Evidence

| Item | Status |
|---|---|
| Release A → B → A live drill | **Not executed** |
| Migration classification for rollback pair | **Not executed** |
| `scripts/prod/rollback.mjs` | Present; requires `CONFIRM=yes` on real host |

---

## Recovery times

| Operation | Measured |
|---|---|
| Docker restart recovery | **Not measured** (no host drill) |
| VM reboot recovery | **Not measured** |
| VM replacement recovery | **Not measured** |
| Database restore | **Not measured** |
| Application rollback | **Not measured** |

```text
TARGET NOT YET APPROVED
```

---

## Financial verification

No Phase 6.1 restore or VM-recovery contest was executed.  
No new production financial claims.  
Prior Phase 4.1-Lite local reconciliation remains **local-only** evidence.

---

## Deliverables created this phase (tooling / docs only)

| Artifact | Purpose |
|---|---|
| `scripts/prod/phase61-inventory.mjs` | Detect Docker Desktop vs live VM; inventory hard blockers |
| `scripts/prod/phase61-gate.mjs` | HARD-01…08 gate (no self-PASS, no K8s) |
| `scripts/prod/object-backup-e2e.mjs` | Real S3/MinIO backup E2E; fails closed if missing |
| `docs/runbook/vm-recovery-runbook.md` | Container / Docker / reboot / replace procedures |
| `docs/runbook/backup-restore-runbook.md` | Object storage backup + clean restore |
| Evidence under `docs/codex/reports/evidence/phase61/` | Inventory + gate results |

Business logic was **not** modified.

---

## Remaining Phase 6.2 gates (explicitly out of 6.1)

Do **not** start until Phase 6.1 PASS:

- payment provider (non-mock)  
- market-data production provider  
- Admin MFA  
- monitoring / alerts  
- emergency pause live  
- external / legal sign-offs  
- controlled first production contest  

Also still required after 6.1 for full production GO (from 6-NK): any residual operational items covered by `scripts/prod/launch-gate.mjs`.

---

## Unblock checklist (for operators with cloud access)

```text
1. Provision Linux VM + dedicated WAL block disk
2. export PHASE61_LIVE_VM=1 PHASE61_BLOCK_VOLUME=1 PHASE61_WAL_IS_BLOCK=1
3. export TRAGGE_WAL_HOST_PATH=/mnt/tragge-wal
4. Deploy production compose; health-gate
5. Record HARD-01…03, HARD-08 evidence tokens in evidence/phase61/
6. Configure S3/MinIO; node scripts/prod/object-backup-e2e.mjs
7. Rollback drill CONFIRM=yes on that host
8. node scripts/prod/phase61-gate.mjs → exit 0
9. Only then: PHASE 6.2
```

---

## Final Decision

```text
PHASE 6.1 — BLOCKED
```

**Reason code:** `LIVE_VM_REQUIRED` (+ object storage unavailable)

**Did not claim:** Phase 6.1 PASS, production VM durability, object-storage backup, production GO.
