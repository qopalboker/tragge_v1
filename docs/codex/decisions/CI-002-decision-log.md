# CI-002 decision log

## 2026-08-25 — Critical Go service coverage floor

**Done-when (roadmap):** none of the original 7 zero-test services remains at zero coverage.

**Original 7:** `admin-bff`, `api-server`, `contest-scheduler`, `free-contest-generator`, `settlement-service`, `trading-core`, `worker`.

### Choices

| Topic | Choice |
|---|---|
| Still-zero apps | Add minimal unit tests for `trading-core`, `worker`, `free-contest-generator` |
| Already covered | Keep existing Phase 1–2 financial tests in settlement/admin-bff/scheduler |
| CI gate | `scripts/sec-ci002-critical-coverage.test.mjs` runs `go test -short -cover` per service and fails if any ≤0% |
| Depth | Floor only — deep coverage growth tracked as `CI002-DEPTH` |

### Not claimed

- High percentage coverage of settlement/leaderboard financial paths
- Runtime/integration DB coverage for admin-bff without `-short`
