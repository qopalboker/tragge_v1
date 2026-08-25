# CI-003 decision log

## 2026-08-25 — Required CI gate on main

**Goal:** Branch protection on `main` so failing/missing CI cannot merge.

### Choices

| Topic | Choice |
|---|---|
| Conditional Go/Frontend jobs | Aggregate always-on jobs (`Go CI complete`, `Frontend CI complete`) so skips do not break required checks |
| Required contexts | `CI required gate`, Go/Frontend complete, CI-002, SEC-008, SEC-009 |
| Approving reviews | Count **0** for automation continuity; enabling `1` tracked as `CI003-REVIEW-ENFORCEMENT` |
| `enforce_admins` | **false** so emergency admin merges remain possible |
| Force pushes | Disabled |

### Apply

```bash
GITHUB_TOKEN=... node scripts/ci003-apply-branch-protection.mjs
```
