# Local Infrastructure Recovery Runbook

**Scope:** Developer laptop / lab — Phase 6.1-LOCAL-INFRA  
**Classification:** `LOCAL-CONTAINER` · `LOCAL-VM` · `LOCAL-OBJECT-STORAGE`  
**Not:** cloud production

---

## Layout (this host)

| Path | Role |
|---|---|
| `D:\tragge-local-infra\wal` | WAL bind mount (D: volume, not OS C:) |
| `D:\tragge-local-infra\minio` | MinIO object data |
| `D:\tragge-local-infra\wal-disk.vhdx` | Companion 2 GiB VHDX for detach/reattach drills |
| Compose overlay | `infra/docker/docker-compose.local-infra.yml` |

Docker Desktop **cannot** bind-mount into a VHD that is mounted as a Windows folder.  
WAL for running containers uses the native `D:\tragge-local-infra\wal` path; VHD is used for detach/reattach of a virtual disk image with file copy.

---

## Start stack

```powershell
$env:TRAGGE_WAL_HOST_PATH = "D:/tragge-local-infra/wal"
$env:TRAGGE_MINIO_HOST_PATH = "D:/tragge-local-infra/minio"
# Do NOT set APP_ENV=local-infra globally (breaks api-server security-code config)
cd infra/docker
docker compose -f docker-compose.yml -f docker-compose.lite.yml `
  -f docker-compose.override.yml -f docker-compose.local-infra.yml `
  --profile app up -d
```

## Health

```powershell
docker exec tragge_trading_core wget -qO- http://127.0.0.1:8085/readyz
# expect wal_recovery=ok
```

## Container recreate

```powershell
docker compose ... --profile app up -d --force-recreate trading-core
# host file under D:\tragge-local-infra\wal must survive
```

## Compose restart

```powershell
docker compose ... restart trading-core worker api-server
```

## MinIO backup

```powershell
# Console http://127.0.0.1:9001  user/pass: traggelocal / traggelocalpass (lab only)
node scripts/prod/phase61-local-qualify.mjs   # includes backup/restore
```

## VHD detach/reattach (companion disk)

```powershell
# Stop trading-core first
# diskpart: attach wal-disk.vhdx, assign letter, copy WAL files, detach, reattach, copy back
# Scripted in phase61-local-qualify.mjs
```

## Full WSL / Docker Desktop reboot (qualified 2026-08-16)

```powershell
# Pre: verify wal_recovery=ok and write proof under D:\tragge-local-infra\wal
wsl --shutdown
# Wait until: docker version shows Engine
# If needed: Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
cd infra/docker
$env:TRAGGE_WAL_HOST_PATH = "D:/tragge-local-infra/wal"
$env:TRAGGE_MINIO_HOST_PATH = "D:/tragge-local-infra/minio"
docker compose -f docker-compose.yml -f docker-compose.lite.yml `
  -f docker-compose.override.yml -f docker-compose.local-infra.yml `
  --profile app up -d
docker exec tragge_trading_core wget -qO- http://127.0.0.1:8085/readyz
# Expect wal_recovery=ok and host proof still present
```

Evidence token: `LOCAL_VM_REBOOT_PASS`

## Full Docker Engine / Desktop restart (qualified 2026-08-16)

```powershell
# Full Desktop + Engine restart (NOT container-only)
docker desktop restart --timeout 300
# Wait for Engine
docker compose ... --profile app up -d
node scripts/prod/health-gate.mjs
# Expect PRODUCTION HEALTH — PASS and wal_recovery=ok
```

Evidence token: `HOST_DOCKER_RESTART_PASS`

## Gate

```powershell
node scripts/prod/phase61-local-gate.mjs
# Closure: exit 0 → PHASE 6.1-LOCAL-INFRA — PASS
```

---

## Evidence

`docs/codex/reports/evidence/phase61-local/`
