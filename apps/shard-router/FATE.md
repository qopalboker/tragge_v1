# shard-router — ARCH-008 fate

**Fate:** `KEEP` (until deploy unused is proven)

**Evidence:**
- Dockerfile exists
- Not listed in `infra/k8s/base/kustomization.yaml` resources
- Referenced by chaos/load-test tooling and docs (`tools/chaos-test`, `tools/shard-load-test`, CLAUDE.md)

**Not SAFE_TO_DELETE:** absence from base kustomization is **not** proof of zero production traffic or zero future need. Requires ops/metrics confirmation before any DELETE_AFTER_CUTOVER reclassification.
