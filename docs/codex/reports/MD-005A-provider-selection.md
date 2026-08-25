# MD-005A — Admin Forex/Crypto provider selection with audit

**Date:** 2026-08-25  
**Branch:** `codex/md-005a-admin-provider-selection-audit`  
**Status:** Implemented on branch — awaiting review/merge

## What changed

| Area | Change |
|---|---|
| `0114_md005a_*` | Forex default → Deriv; crypto mis-set rows → Nobitex |
| `admin-bff/handlers_market.go` | Allow Deriv; actor header; richer audit payload |
| `market-ingestor/app.go` | Persist forex selection; reload forex from DB; shared persist helper |
| Admin i18n + Symbols UI | Deriv labels; Deriv in forex fallback list |

## Exact tests

```text
node --test scripts/sec-md005a-provider-selection.test.mjs
```

## NOT verified

- Live market-ingestor control API switch against a running stack
- End-to-end Admin UI click → DB row → restart retains selection (`MD005A-RUNTIME-SWITCH`)
- Full §9.4 AUTO/FORCE/PAUSE (out of scope)

## Out of scope

MD-005 / MD-006 provider health + automatic selection + force review timers.
