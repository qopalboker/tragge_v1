# ARCH-009 decision log

**Date:** 2026-08-25  
**Branch:** `codex/arch-009-refresh-architecture-docs-to-final-state`

## Scope

Refresh architecture documentation to match the **staged** codebase through
ARCH-008. Explicitly **do not** claim live-production topology.

## Documents updated / added

- `docs/architecture/current-state-audit.md` — continuity refresh
- `docs/architecture/staged-runtime-topology.md` — diagrams + dual topology
- `docs/architecture/service-inventory.md` — inventory table
- `docs/architecture/phase-3-production-runtime.md` — superseded note for target path

## Next infrastructure task

**INFRA-002** (K8s base/overlay parity + drift CI), after ARCH-009.

## Unchanged

- All runtime verification gaps remain open
- FIN-006 / MD-005A remain separate
