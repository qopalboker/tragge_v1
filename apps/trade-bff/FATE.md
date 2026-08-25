# trade-bff — ARCH-008 fate

**Fate:** `REPLACE` (source retained)

**Evidence of remaining callers/refs:**
- Imported by `apps/trading-core/main.go`
- Gateway/ingress YAML still name `trade-bff` / WebSocket trade routes
- No complete Platform trade BFF module replacement

**Blocked on:** **`ENG001-TRADING-CORE-CUTOVER`**, Platform realtime/trade surface

**Not SAFE_TO_DELETE:** wrapper import + ingress/gateway references.
