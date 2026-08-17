# Production Incident Runbook

**Incident Commander:** on-call SRE / Release owner  
**Namespace:** `tragge`  
**Do not** disable `WAL_REQUIRE_PERSIST` or switch to emptyDir to “recover.”

---

## Severity guide

| Sev | Meaning | Examples |
|---|---|---|
| SEV-1 | Money or trading integrity at risk | double credit, WAL corruption, settlement stuck with payouts |
| SEV-2 | Trading unavailable | engine not ready, MD outage, PVC pending |
| SEV-3 | Degraded non-critical | leaderboard lag, non-financial worker |

---

## 1. Trading engine down

**Detect:** `up{job="trading-engine"}==0` or `/readyz` 503; user cannot trade  

**Action:**

```bash
kubectl -n tragge get sts trading-core
kubectl -n tragge get pods -l app.kubernetes.io/name=trading-core
kubectl -n tragge logs trading-core-0 -c trading-core --tail=200
kubectl -n tragge exec trading-core-0 -c trading-core -- wget -qO- http://127.0.0.1:8085/readyz || true
kubectl -n tragge get pvc | grep wal
```

1. If PVC Bound and logs show WAL replay fail → **§2**  
2. If pod CrashLoop → capture logs, restart once: `kubectl -n tragge delete pod trading-core-0`  
3. Do not scale replicas >1  

**Financial impact:** no new fills if not ready; existing DB state authoritative  

---

## 2. WAL recovery failure

**Detect:** log `CRITICAL: WAL replay failed`; metric `wal_replay_failure_total`; ready=false  

**Action:**

1. Keep trading **not ready** (do not force ready)  
2. Snapshot PVC / copy `/var/lib/tragge/wal` off-pod if possible  
3. Compare DB positions/orders/fills for open contests  
4. Engage eng on-call; prefer DB-authoritative repair over hand-editing WAL  
5. After fix: restart pod; confirm `wal_replay_success` and `/readyz`  

---

## 3. PVC unavailable

**Detect:** Pod Pending; `wal-volume-check` fail; PVC Pending  

```bash
kubectl -n tragge describe pvc
kubectl get sc
kubectl get csidriver
```

1. Fix storage class / quota / CSI — **never** patch emptyDir  
2. When Bound, pod starts; re-run readiness  

---

## 4. Market data outage

**Detect:** stale metrics; `market data not ready`; order rejects STALE_PRICE  

**Action:**

1. Confirm expected: trading paused / rejects  
2. Check provider keys and market-ingestor logs in trading-core  
3. After feed recovers, confirm `/readyz` and fresh ticks  

**Financial impact:** no silent stale fills  

---

## 5. Redpanda / Kafka outage

**Detect:** produce/fetch errors; consumer lag  

**Action:**

1. Confirm broker health  
2. Trading may reject or lag; **no** manual double-submit of settlements  
3. Restore broker; watch lag drain  
4. Reconcile contests active during outage  

**Financial impact:** at-least-once delivery + DB idempotency; verify no double prize  

---

## 6. Settlement stuck

**Detect:** contest `settling` too long; settlement status failed/in_progress  

```bash
kubectl -n tragge logs deploy/worker --tail=300
# SQL: contest_settlements, prize ledger keys for contest_id
```

1. Confirm worker single replica  
2. Restart worker **once** if process hung (advisory lock + prize idempotency)  
3. Never insert wallet_ledger prize rows by hand  

---

## 7. PostgreSQL unavailable

**Detect:** readiness fail DB ping; app errors  

**Action:**

1. Fail closed — no alternate mock DB  
2. Restore HA primary / connectivity  
3. After restore: check no dual writers; re-run reconcile on open contests  

---

## 8. Payment webhook issue

**Detect:** deposit/withdraw stuck; webhook 4xx/5xx  

**Action:**

1. Verify signature / IP / amount match (fail closed)  
2. Check provider dashboard for delivery  
3. Replay only if ledger key not already credited  
4. Escalate provider if outage  

---

## 9. Redis outage

**Detect:** redis ping fail; rate-limit / session / price cache effects  

**Action:**

1. Determine code path: financial truth is **Postgres ledger**, not Redis  
2. If trading uses Redis prices as fallback only — may reject when book empty  
3. Restore Redis; warm caches; no ledger rewrite  

---

## 10. Emergency pause (all trading)

1. Admin: move contests out of `running` or product pause flag  
2. Confirm orders rejected  
3. Communicate status  
4. Preserve WAL PVC and DB  
5. Resume only after IC + finance OK  

---

## Post-incident checklist

- [ ] Timeline recorded  
- [ ] Contests reconciled  
- [ ] No duplicate settlement/prize  
- [ ] WAL ready  
- [ ] Customer impact classified  
- [ ] Follow-up ticket filed  

---

## Appendix A — Local Docker Compose recovery (staging only)

**Not production. Not Kubernetes.** Use when the stack is `infra/docker` Compose (profiles `app` / `full`).  
Compose project directory: `infra/docker`  
Compose files: `docker-compose.yml` + `docker-compose.lite.yml` + `docker-compose.override.yml`  
On Windows, Docker may be:  
`%LOCALAPPDATA%\Programs\DockerDesktop\resources\bin\docker.exe`

### A.0 Health checks (operator)

```bash
docker compose -f docker-compose.yml -f docker-compose.lite.yml -f docker-compose.override.yml --profile app ps
docker exec tragge_trading_core wget -qO- http://127.0.0.1:8085/readyz
docker exec tragge_api_server wget -qO- http://127.0.0.1:8083/healthz || true
```

Expect engine JSON with `database`/`kafka` healthy and `wal_recovery` ok when ready.  
Host ports (override): trade-bff `8085`, engine `8093`, admin `8083`, settlement `8095`.

### A.1 Trading engine down (Compose)

```bash
docker compose ... logs trading-core --tail=200
docker compose ... restart trading-core
# if recreate required — PRESERVE named volume docker_trading_core_wal
docker compose ... --profile app up -d --force-recreate trading-core
docker exec tragge_trading_core wget -qO- http://127.0.0.1:8085/readyz
docker volume inspect docker_trading_core_wal
```

1. Do **not** delete volume `docker_trading_core_wal`  
2. Do **not** disable `WAL_REQUIRE_PERSIST`  
3. After ready: re-test one order path; reconcile open contests  

### A.2 Worker down / settlement stuck (Compose)

```bash
docker compose ... logs worker --tail=300
docker compose ... restart worker
# SQL: contest_settlements, prize idempotency keys — never hand-insert prize ledger rows
```

Expect: single settlement row per contest; prize credits idempotent on retry.

### A.3 Redis outage (Compose)

```bash
docker compose ... restart redis
# financial truth remains Postgres ledger — do not rewrite balances from Redis
```

### A.4 Redpanda outage (Compose)

```bash
docker compose ... restart redpanda
# wait healthy; watch app logs for produce/consume recovery; reconcile active contests
```

### A.5 PostgreSQL outage (Compose)

```bash
docker compose ... restart postgres
# wait healthy; apps re-ping DB; fail closed while down
node scripts/contest-reconcile.mjs <contest_id>   # DATABASE_URL required
```

### A.6 Market data not ready (Compose)

```bash
docker exec tragge_trading_core wget -qO- http://127.0.0.1:8085/readyz
# if market_data.ready=false — orders must reject; do not force ready
docker compose ... logs trading-core --tail=100
```

### A.7 Local qualification gates

```bash
node scripts/phase5lite/compose-gate.mjs
STAGING_PLATFORM=compose node scripts/phase4/preflight.mjs
# expect: live_compose_qualification_possible=true
# expect: live_qualification_possible=false  (not Kubernetes)
```

**Gap vs production runbook:** kubectl StatefulSet/PVC/CSI steps do not apply locally; use this appendix only for Compose staging.
