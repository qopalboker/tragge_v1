# Kubernetes manifests (OPTIONAL / NON-CANONICAL)

**Production authority (Phase 6-NK):** **VM + Docker Compose**  
See:

- `docs/architecture/production-without-kubernetes.md`
- `infra/docker/docker-compose.production.yml`
- `scripts/prod/*`
- `docs/runbook/production-without-kubernetes.md`

This `infra/k8s/` tree is **retained for optional future use** and historical Phase 3 design work.  
It is **not** required for production launch and is **not** the canonical production deployment path.

Do **not** block production on:

- StatefulSet / PVC / CSI
- Helm
- kubectl cluster access

Equivalent safety must be proven with:

- host/block WAL bind mounts
- VM replacement or snapshot recovery
- Docker Compose health/deploy/launch gates

---

## Historical structure

```
k8s/
├── base/           # desired-state base (consolidated api-server/trading-core/worker)
├── overlays/       # staging/production kustomize (optional)
└── cronjobs/       # backup job templates (adapt to VM cron + object storage)
```

### INFRA-002 desired-state parity gate

Overlays must only patch workloads that exist in `base` (`api-server`,
`trading-core`, `worker`, `frontend`, `gateway`, plus data-plane objects).

```bash
kubectl kustomize infra/k8s/base
kubectl kustomize infra/k8s/overlays/production
kubectl kustomize infra/k8s/overlays/staging
pnpm test:infra002   # or: node --test scripts/k8s-overlay-parity.test.mjs
```

This gate proves **manifest consistency**, not live-cluster parity. No production
Kubernetes cluster is assumed.

If you intentionally run Kubernetes in a future program, treat it as a **separate** platform project—not a silent dual production path.
