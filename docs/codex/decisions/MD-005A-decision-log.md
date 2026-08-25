# MD-005A decision log

## 2026-08-25 — Auditable Admin provider selection

**Scope (product decision):** Defaults + Admin selection UI with audit. Full AUTO / FORCE_PROVIDER / PAUSE_SYMBOL remains **MD-005 / MD-006**.

**Defaults (§9.2):**
- Forex active provider = **Deriv**
- Crypto active provider = **Nobitex**

### Implementation choices

| Topic | Choice |
|---|---|
| Forex DB seed | Migration `0114` sets `provider_config.forex` → `deriv` |
| Forex durability | Persist on switch; reload from DB after provider manager start |
| Crypto durability | Already persisted; also sets `updated_by` when actor header present |
| Admin allow-list | BFF accepts `deriv` for forex / switch-provider |
| Actor propagation | Admin-bff sends `X-Actor-User-Id` for `provider_config.updated_by` |
| Dual crypto `both` | Left selectable (legacy); tracked as `MD005A-CRYPTO-BOTH` vs strict single-active reading of §9.2 |
| AUTO/FORCE/PAUSE | Explicitly **not** implemented |

### Sign-off

MD-005A is non-financial; merge after review (no FIN sign-off required).
