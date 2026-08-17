# VM Recovery Runbook (Phase 6.1)

**Scope:** Production-equivalent VM + Docker Compose + persistent WAL block volume  
**Not for:** Docker Desktop local workstation qualification  
**Kubernetes:** Not used

---

## Prerequisites

| Item | Required |
|---|---|
| Production or prod-equivalent Linux VM | Yes |
| Docker Engine + Compose | Yes |
| Dedicated WAL block volume (separate from root when practical) | Yes |
| Exact release SHA / image digests | Yes |
| Secrets on host (not Git) | Yes |
| Old host fenced/stopped before new engine starts | Yes |

Operator declaration for automation:

```bash
export PHASE61_LIVE_VM=1
export PHASE61_BLOCK_VOLUME=1
export PHASE61_WAL_IS_BLOCK=1
export TRAGGE_VM_HOST=<host>
export TRAGGE_WAL_HOST_PATH=/mnt/tragge-wal
```

---

## 1. Container recreate (trading-core only)

```bash
# proof
docker exec tragge_trading_core sh -c 'echo proof > /var/lib/tragge/wal/proof.txt'
docker compose -f docker-compose.yml -f docker-compose.production.yml \
  --profile app up -d --force-recreate trading-core
docker exec tragge_trading_core cat /var/lib/tragge/wal/proof.txt
docker exec tragge_trading_core wget -qO- http://127.0.0.1:8085/readyz
# Expect wal_recovery=ok
```

Evidence token: `WAL_HOST_PERSIST_PASS` / record under `docs/codex/reports/evidence/phase61/`.

---

## 2. Docker Engine restart

```bash
# ensure WAL mount remains
findmnt "$TRAGGE_WAL_HOST_PATH" || mount | grep tragge-wal
sudo systemctl restart docker
# wait
docker compose -f docker-compose.yml -f docker-compose.production.yml \
  --profile app up -d
node scripts/prod/health-gate.mjs
```

Evidence token: `HOST_DOCKER_RESTART_PASS`

---

## 3. VM reboot (HARD-02)

### Before

1. Controlled contest + ≥1 trade  
2. Record order/fill/position IDs and contest ID  
3. Confirm WAL path on block device: `findmnt -T $TRAGGE_WAL_HOST_PATH`  
4. Snapshot DB state / note migration version  

### Reboot

```bash
sudo reboot
```

### After

```bash
# fstab must remount WAL automatically
findmnt "$TRAGGE_WAL_HOST_PATH"
docker compose ... --profile app up -d
node scripts/prod/health-gate.mjs
# continue contest → finalize → settle → reconcile
node scripts/contest-reconcile.mjs <contest_id>
```

Evidence file must contain line: `VM_REBOOT_PASS`

---

## 4. Volume detach / reattach (controlled, offline)

```bash
# STOP app first — never detach live
docker compose ... --profile app stop
# provider-specific: detach volume, reattach, mount at same path
sudo mount /dev/disk/by-id/<wal-disk> "$TRAGGE_WAL_HOST_PATH"
docker compose ... --profile app up -d
# verify single trading-core
docker ps --filter name=tragge_trading_core
```

---

## 5. VM replacement (HARD-03)

### Before failure

Deploy exact release; controlled contest + trade; record IDs; confirm WAL volume ID.

### Failure

Terminate **application VM only**. **Do not** destroy WAL volume.

### Fencing (HARD-08)

1. Confirm old VM instance state = terminated/stopped  
2. Confirm old public IP / SSH unreachable  
3. Only then start trading-core on replacement  
4. Ensure count of trading-core containers globally = 1  

Evidence: `SINGLE_ACTIVE_OWNER_PASS`

### Recovery

```text
1. New VM + same OS baseline
2. Attach WAL block volume → mount TRAGGE_WAL_HOST_PATH
3. Install Docker Engine
4. Checkout exact release SHA
5. Restore secrets
6. node scripts/prod/deploy.mjs
7. health-gate → wal_recovery=ok
8. Continue contest → settle → reconcile
```

Evidence: `VM_REPLACEMENT_PASS`

If reattach impossible: document backup/restore path, measure RPO/RTO, tokens  
`VM_REPLACEMENT_BACKUP_RECOVERY_PASS` + `RPO_DOCUMENTED`.

---

## 6. Readiness during recovery

Trading must be **not ready** until WAL replay + DB + required deps are healthy.  
Do not force `WAL_REQUIRE_PERSIST=false`.

---

## 7. Capacity sanity

```bash
df -h "$TRAGGE_WAL_HOST_PATH"
df -h /
# thresholds (document): WAL < 20% free → alert (Phase 6.2 implements alerting)
```

---

## Evidence location

`docs/codex/reports/evidence/phase61/`

Gate: `node scripts/prod/phase61-gate.mjs`
