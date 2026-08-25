# api-server — ARCH-007 retirement status

**Fate:** `DELETE_AFTER_CUTOVER`

Embeds `user-bff`, `admin-bff`, `payment-service`. Target owner is Platform
`--mode=api` (and payment HTTP cutover).

**Blocked on:** `ARCH004-PAYMENT-HTTP-CUTOVER`, identity/admin traffic cutover,
`ARCH007-WRAPPER-DELETE`.

Do not delete this package until those gaps are runtime-verified.
