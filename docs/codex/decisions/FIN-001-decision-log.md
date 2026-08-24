# FIN-001 decision log

## 2026-08-25 — Canonical field

**Source of truth:** `docs/product/FIXED_PRODUCT_AND_TECHNICAL_POLICIES.md` §4.2  
**Canonical field:** `platform_fee_bps` (default **2000** = 20%).  
**Deprecated:** `commission_rate` is not a source of truth.

## 2026-08-25 — PR scope

**Question:** Full removal of all `commission_rate` reads/writes in one PR, or smallest mergeable increment?

**Answer (human):** Smallest mergeable increment — shared resolver ignores `commission_rate` + conflict test + critical join/finalize readers (already call `ResolvePlatformFeeBps`). FE/SQL column removal deferred.

## Numeric before/after (entry fee 100 USDT = 10000 cents)

| Scenario | Before (legacy fallback) | After FIN-001 |
|---|---|---|
| `platform_fee_bps=2000`, `commission_rate=50` | 2000 bps → platform 20 / prize 80 | **unchanged** 2000 → 20/80 |
| `platform_fee_bps=0`, `commission_rate=50` | 5000 bps → platform 50 / prize 50 | **2000** default → 20/80 |
| `platform_fee_bps=0`, `commission_rate=17` | 1700 bps → 17/83 | **2000** default → 20/80 |

**Financial sign-off required before merge** (roadmap §3 / §5).
