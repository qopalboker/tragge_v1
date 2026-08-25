# ARCH-007 decision log

**Date:** 2026-08-25  
**Branch:** `codex/arch-007-retire-merged-wrappers-and-dead-standalone`

## Scope choice (human-approved)

**Boundary + retire-ready inventory** — do **not** hard-delete live wrappers while
payment/settlement/trading-core/Kafka cutover gaps remain open.

## What this PR does

1. Publishes a fate matrix (`KEEP` / `REPLACE` / `DELETE_AFTER_CUTOVER`).
2. Adds Compose profile `target` for Platform + standalone Engine + Market Data.
3. Marks merged wrappers deprecated at runtime and documents retirement blockers.
4. Adds Market Data standalone image/entrypoint (required for target topology).
5. Keeps `app`/`full`/`legacy-wrappers` profiles for rollback until cutover verified.

## Explicitly excluded

- FIN-006, MD-005A
- Physical deletion of `api-server` / `trading-core` / `worker` source
- Claiming production deploys only Platform/Engine/Market Data without runtime evidence
