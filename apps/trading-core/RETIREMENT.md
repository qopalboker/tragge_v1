# trading-core — ARCH-007 retirement status

**Fate:** `DELETE_AFTER_CUTOVER`

Embeds Trading Engine, Market Ingestor, and trade-bff in one process. This
violates ADR-0001 failure/credential separation.

**Blocked on:** `ENG001-TRADING-CORE-CUTOVER`, `MD001-KAFKA-V2-CUTOVER`,
trade-bff Platform ownership, `ARCH007-WRAPPER-DELETE`.

Prefer Compose profile `target` (standalone Engine + Market Data images).
