# Production Runbook — VM + Docker (No Kubernetes)

**Audience:** SRE, Release Manager, On-call  
**Authority:** Operators with production host access  
**Canonical deploy:** Docker Compose production overlay

---

## 0. Decision rule

```text
Engineering correctness
  + VM/Docker operational evidence
  + Persistent WAL + recovery
  + Backup/restore
  + Providers + MFA + pause
  + launch-gate exit 0
  + first contest reconcile CLEAN
  = PRODUCTION — GO
```

If any critical gate is missing: **NO-GO**.

Kubernetes/kubectl is **not** required.

---

## 1. Host prerequisites

- Linux VM (recommended) or Windows Server with Docker Engine  
- Docker Engine + Compose v2+  
- Dedicated disk/path for WAL: e.g. `/mnt/tragge-wal` → `TRAGGE_WAL_HOST_PATH`  
- Separate disk or managed service for PostgreSQL data  
- Firewall: public only gateway/LB ports  
- Secrets directory populated (never from Git production values)

```bash
export TRAGGE_WAL_HOST_PATH=/mnt/tragge-wal
sudo mkdir -p "$TRAGGE_WAL_HOST_PATH"
sudo chmod 700 "$TRAGGE_WAL_HOST_PATH"
```

---

## 2. Preflight

```bash
cd /opt/tragge   # or repo root
export DOCKER_BIN=$(command -v docker)
export TRAGGE_WAL_HOST_PATH=/mnt/tragge-wal
node scripts/prod/preflight.mjs
# Expect preflight_tools_ok=true and compose_config_valid=true
```

---

## 3. Deploy

```bash
export TRAGGE_WAL_HOST_PATH=/mnt/tragge-wal
export WAL_REQUIRE_PERSIST=true
export ENVIRONMENT=production
export APP_ENV=production
# Optional: PROD_PROFILES=app,frontend
node scripts/prod/deploy.mjs
```

Manual equivalent:

```bash
cd infra/docker
docker compose -f docker-compose.yml -f docker-compose.production.yml \
  --profile app --profile frontend \
  --env-file /etc/tragge/production.env \
  up -d --build
```

**Do not** load `docker-compose.override.yml` on production hosts (dev port publishing).

---

## 4. Health

```bash
node scripts/prod/health-gate.mjs
# Expect: PRODUCTION HEALTH — PASS
docker exec tragge_trading_core wget -qO- http://127.0.0.1:8085/readyz
# Expect: "wal_recovery":"ok"
```

---

## 5. Single-active trading rule

```bash
# NEVER run a second trading-core against the same WAL path
docker ps --filter name=tragge_trading_core
# Count must be 1
```

---

## 6. Failure procedures

### 6.1 trading-core down

```bash
docker compose -f docker-compose.yml -f docker-compose.production.yml \
  --profile app restart trading-core
# or force-recreate WITHOUT deleting host WAL path
docker compose ... up -d --force-recreate trading-core
docker exec tragge_trading_core wget -qO- http://127.0.0.1:8085/readyz
```

Do **not** delete `TRAGGE_WAL_HOST_PATH`.  
Do **not** set `WAL_REQUIRE_PERSIST=false` to “recover.”

### 6.2 worker / settlement stuck

```bash
docker compose ... restart worker
# Reconcile: node scripts/contest-reconcile.mjs <contest_id>
# Never hand-insert prize ledger rows
```

### 6.3 Redis / Redpanda / Postgres outage

Restart the dependency service; apps fail closed while down.  
Financial truth remains PostgreSQL ledger.  
After recovery: health-gate + reconcile open contests.

### 6.4 VM reboot

1. Ensure WAL block volume auto-mounts (`/etc/fstab`)  
2. `docker compose ... up -d`  
3. health-gate + readyz  

### 6.5 VM replacement (hard recovery)

```text
1. Stop old VM (or confirm dead)
2. Create replacement VM / attach same block volume at TRAGGE_WAL_HOST_PATH
3. Install Docker; checkout exact release SHA
4. Restore secrets to secrets/ or secret manager mount
5. node scripts/prod/deploy.mjs
6. Confirm wal_recovery=ok
7. Continue contest / settle / reconcile
```

Record evidence token: `VM_REPLACEMENT_PASS` under `docs/codex/reports/evidence/phase6nk/`.

### 6.6 Emergency pause

Preferred: Admin-authenticated controls (pause symbols / stop registration).  
Last resort: `docker compose stop trading-core` (WAL preserved on host path) and/or stop gateway.  
Settlement: do not force manual wallet credits.

After live test, write `emergency-pause-live.txt` containing `EMERGENCY_PAUSE_PASS`.

---

## 7. Backup / restore

PostgreSQL:

```bash
# Example — adapt to managed provider snapshots when available
docker exec tragge_postgres pg_dump -U tragge_admin -Fc -d app -f /tmp/app.dump
# Copy to object storage; encrypt; retain per policy
```

Restore into clean host/DB; run app smoke + `contest-reconcile.mjs`.  
Object-storage E2E must record `S3_BACKUP_RESTORE_PASS` or `OBJECT_STORAGE_BACKUP_PASS`.

WAL: prefer volume snapshots of the WAL disk + DB-authoritative repair if WAL corrupt (fail-closed).

---

## 8. Rollback

```bash
CONFIRM=yes GIT_REF=<known-good-sha> node scripts/prod/rollback.mjs
# Migrations are NOT auto-downgraded (forward-fix)
```

---

## 9. Launch gate

```bash
node scripts/prod/launch-gate.mjs
# Must exit 0 for PRODUCTION — GO
# Does not require Kubernetes
```

---

## 10. First controlled contest

Only after launch-gate exit 0 + external sign-offs:

1. Limited exposure  
2. Operator online  
3. Monitor logs + health + settlement  
4. `node scripts/contest-reconcile.mjs <id>` → CLEAN  
5. Postmortem report  

---

## Phase 6.1 — VM / WAL block / object storage / rollback

### Local infrastructure (laptop) — Phase 6.1-LOCAL-INFRA

Maximize qualification without cloud:

```bash
# WAL on D: + MinIO
set TRAGGE_WAL_HOST_PATH=D:/tragge-local-infra/wal
set TRAGGE_MINIO_HOST_PATH=D:/tragge-local-infra/minio
node scripts/prod/phase61-local-qualify.mjs
node scripts/prod/phase61-local-gate.mjs
```

| Local gate result (2026-08-16) | **PASS** (closure: WSL reboot + `docker desktop restart`) |
|---|---|
| Report | `docs/codex/reports/PHASE-6.1-LOCAL-INFRA-2026-08-16.md` |
| Closure | `docs/codex/reports/PHASE-6.1-LOCAL-INFRA-CLOSURE-2026-08-16.md` |
| Runbook | `docs/runbook/local-infrastructure-recovery.md` |
| Claim | **LOCAL INFRASTRUCTURE — FULLY QUALIFIED** — not production GO |

### Cloud / production-equivalent Phase 6.1 HARD gates

```bash
node scripts/prod/phase61-inventory.mjs
node scripts/prod/phase61-gate.mjs
```

| Hard gate | Token / evidence |
|---|---|
| WAL on dedicated block | `WAL_BLOCK_STORAGE_PASS` |
| VM reboot | `VM_REBOOT_PASS` |
| VM replacement | `VM_REPLACEMENT_PASS` |
| Object backup | `OBJECT_STORAGE_BACKUP_PASS` |
| Clean restore | `BACKUP_RESTORE_CLEAN_PASS` |
| Restore reconcile | `RESTORE_RECONCILE_PASS` |
| Rollback | `ROLLBACK_DRILL_PASS` |
| Single-active owner | `SINGLE_ACTIVE_OWNER_PASS` |

**Docker Desktop / MinIO local are not cloud evidence.**  
Cloud status: see `docs/codex/reports/PHASE-6.1-INFRASTRUCTURE-QUALIFICATION-2026-08-16.md`

Detailed procedures:

- `docs/runbook/vm-recovery-runbook.md`  
- `docs/runbook/backup-restore-runbook.md`  
- `docs/runbook/local-infrastructure-recovery.md`  


---

## Related docs

- Architecture: `docs/architecture/production-without-kubernetes.md`  
- Incident (general): `docs/runbook/production-incident-runbook.md`  
- Phase 6-NK report: `docs/codex/reports/PHASE-6-NK-PRODUCTION-2026-08-16.md`  
- Phase 6.1 report: `docs/codex/reports/PHASE-6.1-INFRASTRUCTURE-QUALIFICATION-2026-08-16.md`  

