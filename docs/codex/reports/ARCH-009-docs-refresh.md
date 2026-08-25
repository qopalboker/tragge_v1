# ARCH-009 — Architecture docs refresh

**Branch:** `codex/arch-009-refresh-architecture-docs-to-final-state`  
**Commit:** `docs(architecture): refresh staged topology and inventory`

## What changed

| Doc | Change |
|---|---|
| `current-state-audit.md` | ARCH-009 banner, refreshed app/topology/DB sections, mitigation status table |
| `staged-runtime-topology.md` | **New** — mermaid target + transitional diagrams |
| `service-inventory.md` | **New** — apps/packages/migrations/Compose/K8s |
| `phase-3-production-runtime.md` | Marks merged-wrapper “launch keep” as superseded for target path |

## Explicit non-claims

- Not live-production topology
- Paid-production remains **NO-GO**
- Does not close `MD001-*`, `ARCH007-*`, `ARCH008-NO-SAFE-DELETE`, or prior gaps
- FIN-006 / MD-005A untouched

## Next

**INFRA-002**
