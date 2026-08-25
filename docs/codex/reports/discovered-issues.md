# Discovered issues

Issues found while executing `docs/codex/AI_AGENT_EXECUTION_ROADMAP.md` that are **out of the current task’s scope**. Do not silently fix these inside an unrelated PR.

---

## CI-001-PLAYWRIGHT-QUARANTINE

| Field | Value |
|---|---|
| **ID** | CI-001-PLAYWRIGHT-QUARANTINE |
| **Severity** | P1 (frontend E2E not in CI) |
| **Found during** | CI-001 (2026-08-25) |
| **Status** | Quarantined — tracked, not silently disabled |

### Evidence

- Root scripts: `pnpm e2e` / `e2e:user` / `e2e:admin` (Playwright).
- `playwright.config.ts` sets `webServer: undefined` when `CI` is set, so CI cannot auto-start Vite panels.
- Suites under `apps/user-frontend/e2e` and `apps/admin-frontend/e2e` expect `E2E_USER_URL` / `E2E_ADMIN_URL` (defaults `localhost:5173` / `5174`) and many need real auth/backends (`E2E_INTEGRATION=1` RC projects).

### Why not enabled in CI-001

Turning on `pnpm e2e` without a CI webServer + backend stack would fail every frontend PR. Roadmap allows explicit quarantine with a tracked ticket.

### Lift criteria

1. CI job starts user + admin Vite (or serves production builds) under `CI=1`.
2. Decide which projects are unit-mocked vs integration (`E2E_INTEGRATION`).
3. Job is green on a clean PR and fails when a covered UI assertion is intentionally broken.
4. Promote to a required check under CI-003.

### Workaround in place

Vitest for `@tragge/user-frontend` and `@tragge/admin-frontend` runs in `.github/workflows/ci.yml` on frontend path changes.

---

## INFRA-001-KUSTOMIZE-TAB-YAML (preliminary)

| Field | Value |
|---|---|
| **ID** | INFRA-001-KUSTOMIZE-TAB-YAML |
| **Severity** | P0 (blocks `kubectl kustomize overlays/production`) |
| **Found during** | INFRA-001 exploration (2026-08-25) |
| **Status** | Parked with INFRA-001 (awaiting cluster ground truth before overlay edits) |

### Evidence

`kubectl kustomize infra/k8s/overlays/production` fails with:

`MalformedYAMLError: yaml: line 82: found a tab character that violates indentation in File: network-policies.yaml`

### Note

Do not “fix by guessing” overlay patch targets until the human provides kubeconfig (see `docs/codex/decisions/INFRA-001-decision-log.md`). The tab fix may still be landed as a tiny prerequisite once INFRA-001 resumes.
