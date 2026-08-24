# Discovered issues

Issues found while executing the AI agent roadmap that are out of the current task scope.

---

## SEC001-REMOTE-URL-ASSERTION

| Field | Value |
|---|---|
| **ID** | SEC001-REMOTE-URL-ASSERTION |
| **Severity** | P2 (doc/script drift) |
| **Found during** | SEC-008 (2026-08-25) |
| **Status** | Open |

`scripts/sec001-auth-isolation.test.mjs` asserts `.git/config` contains `tragge_v0.git`, but origin is `https://github.com/qopalboker/tragge_v1.git`. Nine of ten isolation tests pass; this metadata assertion fails. Update the script when convenient — not a runtime auth regression.



---

## SEC004-STALE-STRING

| Field | Value |
|---|---|
| **ID** | SEC004-STALE-STRING |
| **Severity** | P2 (script drift) |
| **Found during** | SEC-009 (2026-08-25) |
| **Status** | Open — intentionally not fixed in SEC-009 |

`scripts/sec-004-sensitive-action-check.mjs` requires the exact comment fragment `Super Admin password verification establishes only the first factor` in `handlers_helpers.go`. Current helpers document policy-gated MFA instead. Behavioral reauth/MFA locks are covered by SEC-009; update the SEC-004 script separately.
