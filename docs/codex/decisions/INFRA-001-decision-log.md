# INFRA-001 decision log

## 2026-08-25 — Park pending live cluster ground truth

**Question asked:** No live cluster is reachable (`kubectl` has no current-context). Audit P0-ARCH-04 and base kustomization indicate production should patch merged wrappers (`api-server` / `trading-core` / `worker`), not obsolete standalone names (`trade-bff`, `user-bff`, …). Proceed with option (b) and document that the live-cluster diff was NOT verified?

**Recommended default:** Option (b) + explicit “live deploy diff unverified.”

**Answer (human):** **Stop — provide cluster access / kubeconfig first.** Do not choose (a) or (b) until a dry-run `kustomize build` output can be diffed against what is actually deployed.

**Implication:** INFRA-001 is blocked. Do not rewrite production overlay patch targets until ground truth exists. Unrelated Phase 0 work (CI-001, SEC-008, SEC-009) may proceed.

### Preliminary findings (not acted on)

- `kubectl kustomize infra/k8s/overlays/production` currently **fails** before patch application because `infra/k8s/base/network-policies.yaml` has a tab character around line 82 (`MalformedYAMLError`).
- Production `kustomization.yaml` and component patches (`anti-affinity`, `resources`, `security-contexts`) still target obsolete standalone Deployments/HPAs (`trade-bff`, `user-bff`, `admin-bff`, `market-ingestor`, `leaderboard-worker`, `payment-service`, `trading-engine`, `trade-bff-hpa`, `user-bff-hpa`).
- Base only ships merged workloads: `api-server`, `trading-core` (StatefulSet), `worker`, plus `gateway` / `frontend`.
- No kubeconfig/context available in this session to compare build output to the live cluster.
