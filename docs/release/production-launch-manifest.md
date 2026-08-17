# Production Launch Manifest

**Status:** **NOT FROZEN — LAUNCH BLOCKED**  
**Architecture:** VM + Docker Compose (Kubernetes **not** required)  
**Date:** 2026-08-16  
**Decision:** **PRODUCTION — NO-GO**

---

## Freeze eligibility

| Prerequisite | Met? |
|---|---|
| Production / prod-equivalent VM declared (`TRAGGE_PROD_HOST` / `PHASE61_LIVE_VM`) | **NO** |
| `node scripts/prod/preflight.mjs` on production host | **NO** (local tools only) |
| `node scripts/prod/health-gate.mjs` on production host | **NO** (local stack only) |
| Production object storage backup E2E | **NO** |
| Payment / market-data / MFA qualified | **NO** |
| External sign-offs CONFIRMED | **NO** |
| `node scripts/prod/launch-gate.mjs` exit 0 | **NO** (10 blocked gates) |
| First production contest + clean reconcile | **NO** — not executed |

**Release freeze is not authorized.**

---

## Authoritative deploy path (when freeze is allowed)

| Item | Path |
|---|---|
| Compose base | `infra/docker/docker-compose.yml` |
| Production overlay | `infra/docker/docker-compose.production.yml` |
| Env template | `infra/docker/production.env.example` |
| Deploy | `scripts/prod/deploy.mjs` |
| Health | `scripts/prod/health-gate.mjs` |
| Launch gate | `scripts/prod/launch-gate.mjs` |
| Rollback | `scripts/prod/rollback.mjs` |
| Architecture | `docs/architecture/production-without-kubernetes.md` |

---

## Intended freeze fields (populate only on GO)

| Field | Value (this session) |
|---|---|
| Release name | `phase-6.2-readiness-2026-08-16` |
| Architecture | `vm-docker` |
| Kubernetes required | **false** |
| Commit SHA | `478c9331e59c600942b927ce1f1e4a47c5565bed` (working tree may be dirty — **not release-clean**) |
| Image digests | **NOT CAPTURED** — no production image push |
| Migration version | **103** (local Compose PG only) |
| WAL storage identifier | Local lab `D:\tragge-local-infra\wal` — **not** production block volume |
| Backup configuration | Local MinIO lab only — **not** production object storage |
| Provider configuration | **NOT QUALIFIED** |
| Freeze timestamp | **NOT SET** |
| Responsible operator | **NOT ASSIGNED** |
| Incident commander | **NOT ASSIGNED** |

---

## Explicit non-claims

- Local infrastructure full qualification ≠ production freeze.  
- Docker Desktop ≠ production VM.  
- Local MinIO ≠ production S3.  
- Emergency pause last-resort stop on laptop ≠ production admin MFA pause path complete.  

---

## When to freeze

Only after:

1. Production VM + storage + providers + MFA + monitoring/alerts + sign-offs **PASS**  
2. `launch-gate.mjs` exit **0**  
3. Clean tagged commit + image digests recorded  
4. Named release owner signs this file  

Then set:

```text
Status: FROZEN
Decision: PRODUCTION — GO authorized for controlled first contest only
```
