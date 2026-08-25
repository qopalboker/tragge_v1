# LIFECYCLE-001 decision log

## 2026-08-25 — Product rules (from FIXED_PRODUCT_AND_TECHNICAL_POLICIES)

| Rule | Source |
|---|---|
| Free contests: no post-start join | §5.6 |
| Paid: join while `running` until `start + min(10% duration, 30m)` | §5.6 |
| `late_join_enabled` can disable | §5.6 |
| Late surcharge = 10% of base entry, 100% platform revenue | §4.3 |
| Late entrant prize-pool contribution = same as on-time (not pro-rata pool) | §4.3 |
| Ranking/prize eligibility = filled-trade based (not duration pro-rata) | §11.3 |

**Scoring fairness:** Late joiners only score trades after `joined_at` (they cannot trade before join). No separate pro-rata score multiplier.

## 2026-08-25 — Scope

**Question:** Join policy already existed; what remains?

**Answer (human):** Lock regression with expanded tests + CI; verify charge/scoring docs; log economics-lock-at-cutoff (P0-FIN-06) separately if incomplete.

**Implemented:** `economics.JoinAllowed` as shared policy; user-bff delegates; join response exposes late surcharge breakdown; CI `lifecycle-001-late-entry`.
