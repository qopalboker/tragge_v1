# CI-004 — Continuous secret scanning

**Date:** 2026-08-25
**Branch:** `codex/CI-004-secret-scanning`

## What changed
- Always-on `ci-004-secret-scanning` job with gitleaks-action
- Fixture/wiring test `scripts/sec-ci004-secret-scanning.test.mjs`
- Required gate + branch-protection apply script include CI-004

## Verify
`node --test scripts/sec-ci004-secret-scanning.test.mjs`
