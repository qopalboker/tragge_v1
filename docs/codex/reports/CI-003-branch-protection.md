# CI-003 — Enforce CI as a required branch-protection gate

**Date:** 2026-08-25  
**Branch:** `codex/CI-003-branch-protection-gate`

## What changed

- Always-on aggregate jobs: `Go CI complete`, `Frontend CI complete`, `CI required gate`
- Apply script: `scripts/ci003-apply-branch-protection.mjs`
- Verification: `scripts/sec-ci003-branch-protection.test.mjs`

## Required contexts

- CI required gate
- Go CI complete
- Frontend CI complete
- CI-002 critical Go coverage floor
- SEC-008 auth regression lock
- SEC-009 admin reauth + Super Admin MFA

## Gaps

- `CI003-REVIEW-ENFORCEMENT` — approving review count still 0 for automation
- Protection must be applied once with admin token after merge
