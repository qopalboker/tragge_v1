# ARCH-001 decision log

**Date:** 2026-08-25  
**Branch:** `codex/arch-001-create-the-platform-modular-monolith-skele`

## Scope

**Question:** Stub modules only vs thin HTTP placeholders?

**Answer (human):** Stub modules + wiring only (recommended). No BFF migration in ARCH-001.

## Architecture source

Followed PRODUCTION_ROADMAP ARCH-001 + ADR-0001 exactly. Did not invent additional bounded systems or modes.

## Gaps

Existing FIN/LIFECYCLE verification gaps remain open. Docker image multi-mode build tracked as `ARCH001-DOCKER-IMAGE` (not runtime-verified until built/pushed).
