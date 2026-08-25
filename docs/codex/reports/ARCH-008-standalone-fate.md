# ARCH-008 — Fate of legacy standalone services

**Branch:** `codex/arch-008-resolve-legacy-standalone-service-fate`  
**Commit:** `docs(runtime): resolve legacy standalone service fates`

## Disposition legend

| Fate | Meaning |
|---|---|
| **KEEP** | Target production runtime; retain and deploy independently |
| **REPLACE** | Logic migrates to Platform/Engine/Market Data; **source stays** until cutover verified |
| **DELETE_AFTER_CUTOVER** | Intended eventual delete; **blocked** until zero callers + cutover gaps closed |
| **SAFE_TO_DELETE** | Proven zero callers/traffic/refs — **none this PR** |

## Evidence matrix

| Service | Dockerfile / cmd | Live process path today | Go callers (non-self) | Platform module? | Fate | Blocked on |
|---|---|---|---|---|---|---|
| `trading-engine` | yes / yes | `trading-core` embed + Compose `target`/`engine-standalone` | `apps/trading-core/main.go`, `cmd/trading-engine` | n/a (Engine) | **KEEP** | — |
| `market-ingestor` | yes / yes | `trading-core` embed + Compose `target` | `apps/trading-core/main.go`, `cmd/market-ingestor` | n/a (Market Data) | **KEEP** | `MD001-KAFKA-V2-CUTOVER` for contract cutover |
| `user-bff` | no | `api-server` embed; gateway/ingress names still reference `user-bff` | `apps/api-server/main.go` | `identity` (partial) | **REPLACE** | Platform API traffic cutover; wrapper delete |
| `admin-bff` | no | `api-server` embed; gateway/ingress `admin-bff` | `apps/api-server/main.go` | `admin` (partial) | **REPLACE** | Platform API traffic cutover |
| `payment-service` | no | `api-server` embed | `apps/api-server/main.go` | `payment`/`wallet`/`kyc` (partial) | **REPLACE** | **`ARCH004-PAYMENT-HTTP-CUTOVER`** |
| `trade-bff` | no | `trading-core` embed; gateway/ingress `trade-bff` | `apps/trading-core/main.go` | none complete | **REPLACE** | Platform trade/realtime surface; **`ENG001-TRADING-CORE-CUTOVER`** |
| `leaderboard-worker` | no | `worker` embed | `apps/worker/main.go` | `leaderboard` (projection) | **REPLACE** | Platform worker cutover; affiliate path still in worker tree |
| `settlement-service` | no | `worker` embed | `apps/worker/main.go` | `settlement` (authority) | **REPLACE** | **`ARCH005-SETTLEMENT-HTTP-CUTOVER`** |
| `contest-scheduler` | no | `worker` embed only | `apps/worker/main.go` | `scheduler` | **DELETE_AFTER_CUTOVER** | Worker cutover + zero import proof; **`ARCH007-WRAPPER-DELETE`** |
| `free-contest-generator` | no | `worker` embed only | `apps/worker/main.go` | `scheduler` | **DELETE_AFTER_CUTOVER** | Same as scheduler |
| `shard-router` | yes | Not in `infra/k8s/base` kustomization; tooling/chaos/docs reference it | load/chaos tools | none | **KEEP** (until proven unused in deploy) | Ops confirmation; not SAFE_TO_DELETE |

### K8s note (not a deletion license)

- **Base** deploys wrappers: `api-server`, `trading-core`, `worker` (`infra/k8s/base/kustomization.yaml`). That matches transitional production topology from ARCH-007.
- **Overlays** still patch obsolete standalone Deployment names (`user-bff`, `trade-bff`, …). That drift is **INFRA-001 parked / INFRA-002**, not proof those Deployments receive traffic — and also **not** proof they can be removed. ARCH-008 does not rewrite overlays.

## Executed disposition (this PR)

1. Per-service `FATE.md` under each app with evidence pointers.
2. CI lock that **no** listed service is marked SAFE_TO_DELETE while callers exist.
3. Roadmap/status update; **no source trees deleted**.

## Gaps kept open (must remain)

- `MD001-KAFKA-V2-CUTOVER`
- `MD001-FRONTEND-CUTOVER`
- `ARCH007-WRAPPER-DELETE`
- `ARCH007-TARGET-COMPOSE-E2E`
- `ARCH004-PAYMENT-HTTP-CUTOVER`, `ARCH005-SETTLEMENT-HTTP-CUTOVER`, `ENG001-TRADING-CORE-CUTOVER`
- Prior FIN/LIFECYCLE/ARCH verification gaps
- New: `ARCH008-NO-SAFE-DELETE` (documentation of zero SAFE_TO_DELETE)

## Out of scope

- FIN-006, MD-005A
- Physical deletion of any app
- Claiming production traffic is zero without logs/metrics
