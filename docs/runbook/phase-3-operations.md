# Phase 3 Operations Runbook

Practical procedures for production/staging. Commands assume namespace `tragge`.

---

## 1. Trading engine down

### Inspect

```bash
kubectl -n tragge get sts trading-core
kubectl -n tragge get pods -l app.kubernetes.io/name=trading-core
kubectl -n tragge logs sts/trading-core -c trading-core --tail=200
kubectl -n tragge exec sts/trading-core -c trading-core -- wget -qO- http://127.0.0.1:8085/readyz
kubectl -n tragge exec sts/trading-core -c trading-core -- wget -qO- http://127.0.0.1:8085/healthz
```

### Recover

1. Confirm PVC bound: `kubectl -n tragge get pvc | grep wal`
2. If CrashLoop: check logs for `WAL replay failed` / `WAL_PERSIST_PATH`
3. Do **not** delete PVC
4. `kubectl -n tragge delete pod trading-core-0` (StatefulSet recreates, remounts PVC)
5. Wait Ready; re-run smoke: `node scripts/phase3/smoke-test.mjs`

Trading must stay not-ready until WAL recovery succeeds.

---

## 2. WAL recovery failure

### Signal

- `/readyz` → 503 with `wal_recovery` false  
- Metrics: `trading_engine_wal_replay_failure_total`  
- Logs: `CRITICAL: WAL replay failed`

### Action

1. Keep traffic off (readiness already false)
2. Snapshot PVC: backup volume or copy `/var/lib/tragge/wal`
3. Inspect `engine.jsonl` for corruption
4. Prefer DB-authoritative recovery: positions/orders/fills already in PostgreSQL
5. Only after forensics: compact/replace WAL file under change control
6. Restart pod; confirm `wal_replay_success`

**Never** set `WAL_REQUIRE_PERSIST=false` in production to "fix" readiness.

---

## 3. PVC unavailable

### Symptoms

- Pod `Pending` / `Init:CrashLoop` on `wal-volume-check`
- PVC `Pending` (no StorageClass / quota)

### Action

```bash
kubectl -n tragge describe pvc -l app.kubernetes.io/component=wal
kubectl get storageclass
```

1. Fix storage class / quota / CSI driver
2. Do **not** patch emptyDir into the StatefulSet
3. When Bound, pod starts; init write probe must pass

---

## 4. Kafka / Redpanda outage

### Inspect

```bash
kubectl -n tragge get pods -l app.kubernetes.io/name=redpanda
# engine logs: fetch/produce errors
```

### Expected

- Engine may fail readiness if DB/Redis also impacted; Kafka outage alone should not invent fills
- Orders accepted only after durable path available; acks may lag
- On restore: consumers resume; **at-least-once** → rely on order_id / prize / settlement uniqueness

### Action

1. Restore broker
2. Confirm consumer lag decreasing
3. Run financial smoke / reconcile: `node scripts/contest-reconcile.mjs <contest_id>`

---

## 5. Settlement stuck

### Inspect

```bash
kubectl -n tragge logs deploy/worker -c worker --tail=200 | findstr /i settlement
# SQL
# SELECT * FROM contest_settlements WHERE contest_id = '...';
# SELECT pg_try_advisory_lock(...) -- another worker holding?
```

### Action

1. Confirm single worker replica
2. If status `failed` after max retries: investigate position close / prize errors
3. Safe retry: restart worker pod — advisory lock + `CreditPrizeIdempotent` prevent double pay
4. Do not manually insert prize ledger rows

---

## 6. Database outage

### Action

1. Apps become not-ready (DB ping fails)
2. Restore Postgres primary (Patroni/HA if production overlay)
3. Confirm connections via PgBouncer
4. Restart only if stuck connections; avoid dual writers
5. Run `RUN_BACKUP_DRILL` only on staging clones, not primary

---

## 7. Market-data outage

### Expected

- With `REQUIRE_MARKET_DATA_READY=true`: engine `/readyz` false when feed stale/missing
- Orders rejected; no silent stale execution

### Action

1. Check market-ingestor logs inside trading-core
2. Provider keys / failover
3. When ticks resume, readiness returns

---

## 8. Deployment rollback

### Application image

```bash
# set previous tag in overlays/production/kustomization.yaml images:
kubectl -n tragge rollout undo sts/trading-core
kubectl -n tragge rollout undo deploy/api-server
kubectl -n tragge rollout undo deploy/worker
```

### Configuration

- Re-apply previous ConfigMap/Secret revisions
- Do not rollback irreversible migrations; use expand/contract forward-fix

### Migrations

- Prefer expand (add columns nullable) → deploy → contract (drop later)
- Destructive down migrations are **not** automatic

---

## 9. Multi-service restart (controlled)

```bash
kubectl -n tragge rollout restart sts/trading-core
kubectl -n tragge rollout status sts/trading-core
kubectl -n tragge rollout restart deploy/worker
kubectl -n tragge rollout restart deploy/api-server
node scripts/phase3/smoke-test.mjs
```

---

## 10. Backup / restore (staging)

```bash
# backup + restore into temp DB
RUN_BACKUP_DRILL=1 node scripts/phase3/backup-restore-drill.mjs

# k8s cron
kubectl -n tragge get cronjob
```

---

## Operational checklist (launch)

See Phase 3 report § Operational readiness.
