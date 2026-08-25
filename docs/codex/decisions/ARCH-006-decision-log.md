# ARCH-006 decision log

**Date:** 2026-08-25  
**Branch:** `codex/arch-006-implement-schema-ownership-and-transaction`

## Boundary

ARCH-006 implements:

1. Per-owner target migrations for transactional `outbox` / `inbox` / `dead_letter` / `schema_migrations`.
2. Envelope contract `envelope.v1` (ADR-0001 required fields).
3. In-process durable store with commit/rollback crash-window semantics.
4. Platform events module + Engine/Market Data ownership markers.

## Explicitly deferred (not product ambiguities)

- Migrating legacy `public` domain tables into owned schemas (DATA/CON/ENG/MD tasks).
- Live PostgreSQL grant/permission E2E and crash-window against real Postgres (`ARCH006-POSTGRES-PERMISSIONS-E2E`).
- Broker relay publishing of outbox rows to Kafka (ops/cutover follow-on).
- FIN-006 and MD-005A remain separate roadmap tasks.
