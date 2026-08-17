# Backup & Restore Runbook (Phase 6.1)

**Scope:** PostgreSQL → real object storage → clean restore → reconcile  
**Not accepted as final evidence:** local filesystem copy labeled as “S3”  
**Kubernetes CronJob:** not required; use host cron or cloud scheduler calling scripts

---

## Object storage preflight

```bash
# AWS example
export AWS_REGION=...
export S3_BUCKET=tragge-prod-backups   # or BACKUP_S3_BUCKET
aws s3 ls "s3://${S3_BUCKET}/"

# MinIO-compatible
export MINIO_ENDPOINT=https://minio.example:9000
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export S3_BUCKET=tragge-backups
```

Required properties:

- private bucket  
- encryption at rest (SSE-S3/SSE-KMS or provider equivalent)  
- lifecycle/retention policy  
- credentials not in Git  

---

## Production backup script (existing)

```bash
export POSTGRES_HOST=...
export POSTGRES_USER=tragge_admin
export POSTGRES_PASSWORD=...   # from secret manager
export POSTGRES_DB=app
export S3_BUCKET=...
export S3_PREFIX=backups/postgres
export AWS_REGION=...

./scripts/backup/backup-postgres.sh --full
```

Automated E2E helper (refuses missing object storage):

```bash
node scripts/prod/object-backup-e2e.mjs
# Exit 2 if S3/MinIO not configured
# Exit 0 writes OBJECT_STORAGE_BACKUP_PASS + BACKUP_RESTORE_CLEAN_PASS
```

---

## Integrity checks (after upload)

1. Object exists (`aws s3 ls` / head-object)  
2. Size plausible (not empty)  
3. Download succeeds  
4. Checksum match optional (`aws s3api head-object` ETag / multipart caveats)  
5. Manifest metadata: timestamp, DB name, schema/migration version, release SHA  

Do **not** treat HTTP 200 alone as success without re-read.

---

## Clean restore (never overwrite production)

```bash
# New database or new Postgres instance
createdb app_restore_YYYYMMDD
aws s3 cp s3://$S3_BUCKET/backups/postgres/<file>.dump ./restore.dump
pg_restore -d app_restore_YYYYMMDD --no-owner --no-acl ./restore.dump

# Verify
psql -d app_restore_YYYYMMDD -c "SELECT version FROM schema_migrations ORDER BY 1 DESC LIMIT 1;"
psql -d app_restore_YYYYMMDD -c "SELECT COUNT(*) FROM contests;"
psql -d app_restore_YYYYMMDD -c "SELECT COUNT(*) FROM wallet_ledger;"
```

Point a **non-production** app profile at the restore DB for smoke (read paths only preferred).  
**Do not** run live payments against restore.

---

## Reconciliation after restore

```bash
export DATABASE_URL=postgres://...@.../app_restore_...
node scripts/contest-reconcile.mjs <contest_id>
```

Evidence tokens:

- `OBJECT_STORAGE_BACKUP_PASS`  
- `BACKUP_RESTORE_CLEAN_PASS`  
- `RESTORE_RECONCILE_PASS` or `RECONCILE_CLEAN`  
- Combined: `S3_BACKUP_RESTORE_PASS` if full pipeline documented in one file  

Write under: `docs/codex/reports/evidence/phase61/`

---

## WAL vs database backup

| Asset | Strategy |
|---|---|
| PostgreSQL | Object storage dumps/snapshots (authoritative financial state) |
| Trading WAL | Persistent block volume + snapshots; DB remains financial authority if WAL corrupt |

If WAL volume lost and only DB backup exists: RPO = last consistent DB state; engine may need fail-closed recovery — document RPO.

---

## Rollback vs restore

- **Application rollback:** `CONFIRM=yes node scripts/prod/rollback.mjs` (no schema downgrade)  
- **Disaster restore:** this runbook (new DB environment)  

Classify migrations as `BACKWARD_COMPATIBLE` or `REQUIRES_FORWARD_FIX` before any rollback drill.
