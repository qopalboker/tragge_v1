# Production Launch Runbook

**Audience:** Release Manager, SRE, CTO  
**Prerequisite:** Phase 0–3 engineering PASS  
**Authority:** Only operators with production privileges

---

## 0. Decision rule

A launch is allowed only when:

```text
Engineering correctness
  + Operational evidence (live staging/prod-equivalent)
  + External/provider/legal approvals
  = PRODUCTION — GO
```

If any critical gate is missing: **NO-GO**. Do not substitute local simulations for live PVC/Kafka/S3 tests.

---

## 1. Pre-flight (Task 1)

```bash
node scripts/phase4/preflight.mjs
# Expect exit 0 with kubectl=PRESENT and k8s_cluster=REACHABLE
# Exit 2 → NO-GO (tools/cluster missing) — STOP. Do not invent live tests.
```

### Phase 4.1 hard stop

If preflight reports `live_qualification_possible=false`:

1. Status remains **PRODUCTION — NO-GO**  
2. Do **not** run pod-delete / soak / S3 tests as “simulated”  
3. Document blockers in `docs/codex/reports/evidence/phase4/`  
4. Provision cluster + tools, then restart from Task 1  

Latest 4.1 record: `docs/codex/reports/PHASE-4.1-LIVE-STAGING-UNBLOCK-2026-08-16.md`

### Phase 6 hard stop (2026-08-16)

Phase 6 (Kubernetes path) recorded **PRODUCTION — NO-GO** (no cluster).  
Report: `docs/codex/reports/PHASE-6-PRODUCTION-GO-LIVE-2026-08-16.md`

### Phase 6-NK — production path without Kubernetes (2026-08-16)

**Canonical production architecture is now VM + Docker Compose.**  
Kubernetes/PVC/CSI/kubectl are **not** required for GO.

| Item | Path |
|---|---|
| Architecture | `docs/architecture/production-without-kubernetes.md` |
| Runbook | `docs/runbook/production-without-kubernetes.md` |
| Compose | `infra/docker/docker-compose.production.yml` |
| Preflight | `node scripts/prod/preflight.mjs` |
| Deploy | `node scripts/prod/deploy.mjs` |
| Health | `node scripts/prod/health-gate.mjs` |
| Launch gate | `node scripts/prod/launch-gate.mjs` |
| Phase report | `docs/codex/reports/PHASE-6-NK-PRODUCTION-2026-08-16.md` |

Latest 6-NK decision: **PRODUCTION — NO-GO**.  
Phase 6.1-LOCAL-INFRA: **PASS** (local fully qualified).  
Phase 6.2: **BLOCKED** — see `docs/codex/reports/PHASE-6.2-EXTERNAL-READINESS-2026-08-16.md`  
(`node scripts/prod/phase62-gate.mjs`).  

**Do not** treat local Compose / MinIO / last-resort pause as payment, market-data, MFA, or legal qualification.

Record:

| Item | Command / source | Value |
|---|---|---|
| K8s version | `kubectl version` | |
| Nodes | `kubectl get nodes -o wide` | |
| StorageClass | `kubectl get sc` | must include Phase 3 class (e.g. `premium-rwo`) |
| CSI | vendor docs / `kubectl get csidriver` | |
| Postgres | endpoint + `pg_isready` | |
| Redis | `redis-cli PING` | |
| Redpanda | brokers list | |
| Object storage | bucket reachable | |
| Secrets | ESO / sealed secrets / cloud SM | |

---

## 2. Deploy production topology (Task 2)

```bash
# From repo root — adjust context/namespace
kubectl config use-context <staging-context>
kubectl apply -k infra/k8s/overlays/staging   # or production overlay for prod
# Prefer kustomize build | kubectl apply -f -

kubectl -n tragge get sts,deploy,svc,pvc,ingress
kubectl -n tragge get sts trading-core -o yaml | grep -A20 volumeClaimTemplates
kubectl -n tragge get pvc | grep wal
```

Verify:

- [ ] StatefulSet `trading-core` Ready 1/1  
- [ ] PVC `*-wal-data-*` **Bound**  
- [ ] Mount `/var/lib/tragge/wal`  
- [ ] `WAL_REQUIRE_PERSIST=true`  
- [ ] `/readyz` on trading-engine :8085 returns ready only after WAL recovery  
- [ ] worker 1/1, api-server Ready, gateway Ready  

**Do not** hand-edit live YAML without committing the change.

---

## 3. Live PVC / WAL qualification (Task 3) — mandatory

```bash
# 1) Confirm Bound
kubectl -n tragge get pvc -l app.kubernetes.io/component=wal

# 2) Confirm mount + path
kubectl -n tragge exec trading-core-0 -c trading-core -- ls -la /var/lib/tragge/wal
kubectl -n tragge exec trading-core-0 -c trading-core -- sh -c 'test -w /var/lib/tragge/wal && echo WRITABLE'

# 3) Execute trading activity (controlled contest / internal order tools)
#    Record order_ids / fill counts BEFORE delete.

# 4) Delete pod (PVC must survive)
kubectl -n tragge delete pod trading-core-0
kubectl -n tragge rollout status sts/trading-core

# 5) WAL recovery evidence
kubectl -n tragge logs trading-core-0 -c trading-core | grep -i wal
kubectl -n tragge exec trading-core-0 -c trading-core -- wget -qO- http://127.0.0.1:8085/readyz

# 6) Continue trading → finalize → settle → reconcile
node scripts/contest-reconcile.mjs <contest_id>
```

Write evidence file:

`docs/codex/reports/evidence/phase4/pod-reschedule-<date>.txt`

Must include lines:

```text
PVC_BOUND=true
POD_RESCHEDULE_PASS=true
WAL_REPLAY_AFTER_POD_DELETE=true
```

---

## 4. Controlled contest (Tasks 17–18)

Minimum:

1. Create paid/free contest per product policy  
2. ≥2 users join  
3. Real market ticks  
4. Real market orders → fills → positions  
5. Contest end → force close → settlement  
6. Ledger + wallet check  
7. `contest-reconcile.mjs` clean  

Repeat **3** contests. Record each contest_id (no PII).

---

## 5. Failure drills (summary)

Follow `docs/runbook/production-incident-runbook.md` and `docs/runbook/phase-3-operations.md`.

After every drill: reconciliation.

---

## 6. Backup / restore (Task 11)

```bash
kubectl -n tragge get cronjob
kubectl -n tragge create job --from=cronjob/<postgres-backup> manual-backup-$(date +%s)
# Verify S3 object, restore to clean DB, smoke + reconcile
```

Evidence must include `S3_BACKUP_RESTORE_PASS=true`.

---

## 7. Rollback (Task 19)

```bash
kubectl -n tragge rollout undo sts/trading-core
kubectl -n tragge rollout undo deploy/api-server
kubectl -n tragge rollout undo deploy/worker
kubectl -n tragge rollout status sts/trading-core
```

Migrations: **forward-fix only** if irreversible. No blind `migrate down` in production.

---

## 8. Emergency pause (Task 28)

Operator-controlled (authorization required):

1. Pause new registration (admin contest status / feature flag per product)  
2. Set contest status so engine rejects new orders (`settling` / paused per policy)  
3. Confirm `trading-core` readiness / order rejects  
4. **Do not** force settlement while state is uncertain  
5. Page on-call; preserve WAL PVC  

---

## 9. Launch gate

```bash
node scripts/phase4/preflight.mjs
node scripts/phase4/launch-gate.mjs
# Exit 0 required for GO
```

---

## 10. First production contest constraints

- Limited participants (product-approved)  
- Named operator + backup  
- Monitoring window open  
- Emergency pause rehearsed  
- Settlement dual-check before payout communication  

---

## 11. Freeze (Task 25)

Record in `docs/codex/reports/evidence/phase4/launch-manifest-freeze.txt`:

- image digests/tags  
- kustomize git SHA  
- migration version  
- storage class  
- replica counts  
- secret reference names (not values)  
- provider config mode  
