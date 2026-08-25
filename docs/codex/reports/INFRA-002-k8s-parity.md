# INFRA-002 — K8s base/overlay desired-state parity

**Branch:** `codex/INFRA-002-k8s-base-overlay-parity-drift-ci`  
**Commit:** `ci(k8s): enforce base overlay desired-state parity`  
**Base:** `main`

## What changed

| Change | Purpose |
|---|---|
| Fix tab in `network-policies.yaml` | Unblocks `kubectl kustomize` base build |
| Repoint production/staging patches to consolidated names | Overlays only touch base workloads |
| Component dirs for kustomize load-restrictor | `patches/*` are Component directories |
| `scripts/k8s-overlay-parity.test.mjs` | Permanent CI drift gate (desired-state) |
| Image tags use `tragge/api-server\|trading-core\|worker\|frontend` | Match base container images |

## Explicit non-claims

- **Not** live-cluster parity
- **Not** a production deploy
- Does not merge `postgres-ha` into production overlay (`INFRA002-POSTGRES-HA-OVERLAY`)

## Verification

```text
kubectl kustomize infra/k8s/base
kubectl kustomize infra/k8s/overlays/production
kubectl kustomize infra/k8s/overlays/staging
node --test scripts/k8s-overlay-parity.test.mjs
```

## Gaps kept open

- `INFRA002-POSTGRES-HA-OVERLAY`
- Prior FIN/LIFECYCLE/ARCH/MD cutover gaps unchanged
