# PHASE 6.1-LOCAL-INFRA — Autonomous Local Infrastructure Qualification

**Date:** 2026-08-16  
**Decision (initial):** **PHASE 6.1-LOCAL-INFRA — PARTIAL**  
**Decision (closure):** **PHASE 6.1-LOCAL-INFRA — PASS** — see `PHASE-6.1-LOCAL-INFRA-CLOSURE-2026-08-16.md`  
**Strongest claim:** **LOCAL INFRASTRUCTURE — FULLY QUALIFIED**  
**Not claimed:** `PRODUCTION — GO` · cloud VM · cloud block volume · production S3  

Initial gate: exit **2** (optional WSL reboot + Docker Engine restart skipped)  
**Closure gate:** exit **0** after both remaining drills

---

## Executive Decision

```text
PHASE 6.1-LOCAL-INFRA — PASS
(LOCAL INFRASTRUCTURE — FULLY QUALIFIED)
```

Initial PARTIAL status is **closed**. The two remaining optional full-host drills were executed in the closure phase:

1. Full WSL2 reboot via `wsl --shutdown` → **LOCAL_VM_REBOOT_PASS**  
2. Full Docker Engine/Desktop restart via `docker desktop restart` → **HOST_DOCKER_RESTART_PASS**  

Companion VHD detach/reattach had already passed. Full details: `PHASE-6.1-LOCAL-INFRA-CLOSURE-2026-08-16.md`.

Phase 6.2 **not started**. Cloud Phase 6.1 hard gates remain separate and **BLOCKED** without cloud.

---

## Host

| Item | Value |
|---|---|
| OS | Windows 10/11 (10.0.26200), AMD64 |
| CPU / RAM | 12 logical CPUs, ~15.7 GiB |
| Disks | C: ~18 GB free · **D: ~163 GB free** |
| Docker | Desktop 4.86 / Engine 29.7.2 (`desktop-linux`) |
| Compose | v5.3.1 |
| WSL2 | **Ubuntu** + `docker-desktop` |
| Hyper-V tools | Present at platform level (hypervisor detected); no Multipass/VBox/QEMU |
| Cloud CLI / S3 creds | Absent |

### Virtualization choice

```text
Existing WSL2 Ubuntu + Docker Desktop Linux VM
  + dedicated path on D: (non-OS volume)
  + companion VHDX for detach/reattach
  = strongest available local stack
```

Did **not** install Hyper-V GUI VMs or Multipass (unnecessary complexity; elevation risks).

---

## VM Evidence — classification `LOCAL-VM`

| Capability | Result | Notes |
|---|---|---|
| WSL2 Linux available | **PASS** | Ubuntu distro |
| Dedicated WAL storage path | **PASS** | `D:\tragge-local-infra\wal` (D: ≠ C:) |
| Companion VHDX 2 GiB | **PASS** | `D:\tragge-local-infra\wal-disk.vhdx` |
| VHD detach/reattach + data restore | **PASS** | `LOCAL_VM_DISK_REATTACH_PASS` |
| Full WSL reboot | **NOT RUN** | Optional; set `WSL_REBOOT_DRILL=1` |
| Full VM replacement (new VM) | **NOT RUN** | Not required for PARTIAL; no multipass |

**Limitation documented:** Docker Desktop cannot bind-mount into a Windows VHD **folder mount**. Running WAL uses native `D:\tragge-local-infra\wal`; VHD used as detachable companion disk with file copy.

---

## Object Storage Evidence — classification `LOCAL-OBJECT-STORAGE`

| Step | Result |
|---|---|
| MinIO container | **PASS** (`tragge_minio` healthy :9000/:9001) |
| Bucket `tragge-local-backups` | **PASS** |
| `pg_dump` → upload | **PASS** (~700 KB dumps) |
| Download size match | **PASS** |
| Clean restore DB | **PASS** (89 public tables, migration **103**) |
| Live contest reconcile | **PASS** (`durable-contest-evidence`) |

**Not** production AWS S3. Lab credentials: local MinIO only (not committed secrets).

---

## WAL Evidence

| Drill | Classification | Result |
|---|---|---|
| Host-visible bind (not container layer only) | LOCAL-VM | **PASS** |
| Container force-recreate + proof + `wal_recovery=ok` | LOCAL-CONTAINER | **PASS** (~24 s) |
| Compose restart trading-core/worker/api | LOCAL-CONTAINER | **PASS** (~29 s) |
| Full Docker Engine restart | LOCAL-VM | **NOT RUN** (optional) |
| VHD companion reattach | LOCAL-VM | **PASS** |

Config: `WAL_REQUIRE_PERSIST=true`, bind → `/var/lib/tragge/wal`.

---

## Backup / Restore

| Step | Result |
|---|---|
| Dump | **PASS** |
| Object upload (MinIO) | **PASS** |
| Integrity (re-download size) | **PASS** |
| Restore to new DB | **PASS** |
| Schema / migration 103 | **PASS** |
| Reconciliation (live durable contest) | **PASS** |

---

## Rollback

| Step | Result |
|---|---|
| Release marker A → B → A | **PASS** |
| Strategy | Compose recreate `api-server` (same images); **DB forward-fix** |
| Trading readiness after | **PASS** (`wal_recovery=ok`) |
| Migration class | Same schema — **BACKWARD_COMPATIBLE** for this drill |

---

## Single-active owner

`tragge_trading_core` count = **1** after recovery — **PASS**.

---

## Cloud gaps (still open for production)

| Gap | Status |
|---|---|
| Real cloud VM + block volume reattach | **OPEN** |
| Cloud VM replacement fencing | **OPEN** |
| Production networking / TLS edge | **OPEN** |
| Real S3 (non-MinIO) | **OPEN** |
| Payment provider | **OPEN** (Phase 6.2) |
| Market-data production | **OPEN** (Phase 6.2) |
| MFA | **OPEN** (Phase 6.2) |
| Monitoring / alerts | **OPEN** (Phase 6.2) |
| Legal / external sign-off | **OPEN** (Phase 6.2) |
| Controlled first production contest | **OPEN** (Phase 6.2) |

Phase 6.1 cloud gate (`scripts/prod/phase61-gate.mjs`) remains **BLOCKED** without live VM declaration — correctly.

---

## Deliverables

| Artifact | Role |
|---|---|
| `infra/docker/docker-compose.local-infra.yml` | MinIO + WAL bind overlay |
| `scripts/prod/phase61-local-qualify.mjs` | Autonomous local drill runner |
| `scripts/prod/phase61-local-gate.mjs` | Local-only gate |
| `docs/runbook/local-infrastructure-recovery.md` | Operator recovery |
| Evidence | `docs/codex/reports/evidence/phase61-local/` |

Business logic was **not** modified.

---

## Final claim

```text
LOCAL INFRASTRUCTURE — QUALIFIED
```

```text
PHASE 6.1-LOCAL-INFRA — PARTIAL
```

```text
NOT: PRODUCTION — GO
NOT: CLOUD-PRODUCTION-EQUIVALENT
```

To move PARTIAL → PASS on this host only: run optional drills  
`WSL_REBOOT_DRILL=1` and/or `DOCKER_ENGINE_RESTART=1`, then re-run local gate.

To satisfy cloud Phase 6.1 HARD gates: provision real cloud VM + object storage (separate evidence category).
