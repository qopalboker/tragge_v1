# DOC-001 — Correct CLAUDE.md status

**Date:** 2026-08-25  
**Branch:** `codex/DOC-001-correct-claude-status`  
**Status:** Implemented + regression-locked; awaiting human merge (no PAT this session)

## What changed

| File | Change |
|---|---|
| `CLAUDE.md` | Rewrote **Current State** from false “Production-ready” to **NO-GO**; linked audit + roadmap; PASS/FIXED re-verify warning; corrected stale inventory/migration/provider/runtime claims |
| `scripts/codex/doc-001-claude-status.test.mjs` | New Node test suite locking NO-GO + anti–Production-ready + PASS/FIXED warning + README/audit agreement |
| `package.json` | Added `test:doc001` → `node --test scripts/codex/doc-001-claude-status.test.mjs` |
| `docs/codex/AI_AGENT_EXECUTION_ROADMAP.md` | Saved execution roadmap; tracker DOC-001 → Done on branch |
| `docs/codex/reports/DOC-001-claude-status.md` | This evidence report |

## Discrepancies found (pre-fix `main` CLAUDE.md vs audit/README)

1. **Status claim:** CLAUDE said `**Status**: Production-ready platform…`; audit + README say **NO-GO** for paid production.
2. **No NO-GO / no audit link:** CLAUDE omitted the paid-production decision and did not point agents at `current-state-audit.md` / production roadmap.
3. **No PASS/FIXED caution:** CLAUDE did not warn that `docs/codex/reports/*` PASS/FIXED labels need independent re-verification (UI bug precedent).
4. **Stale migrations:** CLAUDE hard-coded “68 migration pairs”; tree has 100+ up migrations — do not hardcode.
5. **Stale inventory:** CLAUDE hard-coded “~270 Go files, ~185 Vue components”; live counts drift — defer to audit / `production-baseline.mjs inventory`.
6. **Market providers:** CLAUDE listed Massive primary; current MVP lab default is Deriv forex + Nobitex crypto (Massive LEGACY when not selected).
7. **Runtime merge omitted:** CLAUDE listed 11 standalone Go services as “Fully Operational” without noting Compose/K8s merge into `api-server` / `trading-core` / `worker`.
8. **K8s / CI optimism:** CLAUDE implied production K8s + CI were fine; INFRA-001 (overlay drift) and CI-001/CI-003 remain open P0/P1.

## Exact test commands and output

### Pre-fix proof (`main` CLAUDE.md)

```text
git show main:CLAUDE.md
# → **Status**: Production-ready platform with 11 Go services...
# → no NO-GO

PRE-FIX FAIL (expected): no NO-GO in main CLAUDE.md
```

### Post-fix suite

```text
node --test scripts/codex/doc-001-claude-status.test.mjs
```

```text
TAP version 13
# Subtest: CLAUDE.md exists and is non-empty
ok 1 - CLAUDE.md exists and is non-empty
# Subtest: CLAUDE.md states paid-production NO-GO
ok 2 - CLAUDE.md states paid-production NO-GO
# Subtest: CLAUDE.md does not claim Production-ready platform
ok 3 - CLAUDE.md does not claim Production-ready platform
# Subtest: CLAUDE.md warns that PASS/FIXED reports need re-verification
ok 4 - CLAUDE.md warns that PASS/FIXED reports need re-verification
# Subtest: README.md and audit agree on NO-GO
ok 5 - README.md and audit agree on NO-GO
1..5
# tests 5
# pass 5
# fail 0
```

## Manual verification

- Diffed Current State bullets against `docs/architecture/current-state-audit.md` header (**Paid-production decision:** **NO-GO**) and `README.md` Production readiness section.
- Confirmed a reader of only the new CLAUDE Current State reaches NO-GO and is pointed at the audit/roadmap.

## Explicitly NOT verified

- Full line-by-line rewrite of every “What's Implemented” capability claim against live code (out of DOC-001 scope; architecture truth remains the audit).
- `scripts/production-baseline.test.mjs` inventory mismatch (counts drifted after new scripts/docs) — **out of scope**; log if it blocks other work.
- No GitHub PR opened this session (no PAT). Human should push branch and open PR.

## Questions

None. Source-of-truth priority was clear: audit/README over stale CLAUDE claims.
