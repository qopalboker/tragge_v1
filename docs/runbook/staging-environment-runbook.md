# Staging Environment Runbook (Phase 5)

**Purpose:** Provision and operate a production-equivalent staging cluster for Phase 4.1.  
**Do not** run unrestricted production contests from this environment without Phase 4.1 GO.

---

## 0. Hard stop

```bash
node scripts/phase5/provision-checklist.mjs
# exit 0 → tools + cluster + StorageClass OK
# exit 2 → BLOCKED — fix tools/cluster first

node scripts/phase4/preflight.mjs
# need live_qualification_possible=true before Phase 4.1
```

If tools are missing, install them on the operator machine (examples):

### Windows (operator)

```powershell
# Example — choose tools your org supports
winget install Kubernetes.kubectl
winget install Docker.DockerDesktop   # or Rancher Desktop
winget install Helm.Helm
# Cloud CLI as needed: AWS.CLI / Google.CloudSDK / Microsoft.AzureCLI
```

### Linux

```bash
# kubectl, docker, helm, awscli per distro packages
```

---

## 1. Platform A — kind (smallest local cluster)

**Requires:** Docker + kubectl + kind.

```bash
# Create cluster with local-path / default StorageClass
kind create cluster --name tragge-staging

kubectl cluster-info
kubectl get nodes
kubectl get storageclass

# Optional: install ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Apply TRAGGE staging (fix WAL StorageClass to kind's class if needed)
kubectl apply -k infra/k8s/overlays/staging

kubectl -n tragge-staging get pods,sts,pvc,svc
```

**WAL StorageClass:** set `standard` or whatever `kubectl get sc` shows (see `patches/wal-storage-patch.yaml`).

**Destroy (non-data shared cloud):**

```bash
kind delete cluster --name tragge-staging
```

---

## 2. Platform B — managed Kubernetes

1. Create cluster (EKS/GKE/AKS) with ≥ 4 vCPU / 8 GiB worker capacity.  
2. Install CSI (EBS CSI / pd.csi / disk.csi).  
3. Create StorageClass matching WAL patch (or patch value to `gp3` / `premium-rwo`).  
4. Configure kubeconfig:

```bash
# EKS example
aws eks update-kubeconfig --name <cluster> --region <region>
kubectl get nodes
```

5. Deploy secrets (ExternalSecrets or sealed secrets — **not** committed values).  
6. `kubectl apply -k infra/k8s/overlays/staging`.

---

## 3. Align Redis/Kafka service names

Before Phase 4.1, ensure ConfigMap endpoints match actual Services:

| Staging patch (current) | Base Service name |
|---|---|
| `redis-staging:6379` | base often `redis` / `redis-master` |
| `redpanda-staging:9092` | base `redpanda:9092` |

Either:

- deploy dependencies with staging names, **or**  
- patch ConfigMap to in-cluster DNS of base resources.

Verify:

```bash
kubectl -n tragge-staging get svc
kubectl -n tragge-staging get cm tragge-config -o yaml | grep -E 'REDIS|KAFKA'
```

---

## 4. Secrets (staging)

```bash
# Example skeleton — use real secret manager in org
kubectl -n tragge-staging create secret generic postgres-secrets \
  --from-literal=POSTGRES_DB=app \
  --from-literal=POSTGRES_ADMIN_USER=... \
  --from-literal=POSTGRES_ADMIN_PASSWORD=... \
  --from-literal=POSTGRES_APP_USER=... \
  --from-literal=POSTGRES_APP_PASSWORD=... \
  --dry-run=client -o yaml | kubectl apply -f -

# JWT / Redis / provider test keys similarly
```

Never commit passwords. Rotate after shared staging demos.

---

## 5. Deploy Phase 3 topology

```bash
kubectl apply -k infra/k8s/overlays/staging
kubectl -n tragge-staging rollout status sts/trading-core
kubectl -n tragge-staging get pvc | grep wal
kubectl -n tragge-staging describe pod trading-core-0
```

Confirm:

- [ ] PVC Bound  
- [ ] Init `wal-volume-check` succeeded  
- [ ] `WAL_REQUIRE_PERSIST=true`  
- [ ] trading-engine readiness (may wait for MD / DB)  

---

## 6. Migrations

```bash
# Prefer job/image used by CI; example:
kubectl -n tragge-staging run migrate --rm -it --image=... -- \
  migrate -path /migrations -database "$POSTGRES_DSN" up
```

Record final migration version.

---

## 7. Object storage for backups

1. Create staging bucket (e.g. `tragge-backups-staging`).  
2. IAM/policy for CronJob service account.  
3. Wire CronJob secrets from `infra/k8s/cronjobs/daily-backup.yaml`.  
4. Do **not** claim backup certified until Phase 4.1 restore E2E.

---

## 8. Network / TLS

- Ingress hostnames from staging overlay patches.  
- Let's Encrypt **staging** issuer for non-prod certs.  
- Confirm DBs/brokers are ClusterIP-only:

```bash
kubectl -n tragge-staging get svc -o wide
```

---

## 9. Baseline smoke (after deploy)

```bash
export SMOKE_ENGINE_URL=https://<staging-api-or-port-forward>
# or port-forward:
kubectl -n tragge-staging port-forward svc/trading-core-lb 8085:8085
node scripts/phase3/smoke-test.mjs
node scripts/phase4/preflight.mjs
```

---

## 10. Recreation test

Without destroying unique data:

```bash
kubectl delete ns tragge-staging --wait=false
# recreate from IaC / kustomize + secrets procedure above
kubectl apply -k infra/k8s/overlays/staging
```

Prove docs reproduce the environment.

---

## 11. Handoff to Phase 4.1

Only when:

```text
provision-checklist.mjs exit 0
preflight.mjs live_qualification_possible=true
Phase 3 pods Ready
WAL PVC Bound
```

Then execute Phase 4.1 live qualification (pod delete, soak, Kafka outage, contests). **Do not merge Phase 4.1 into Phase 5.**
