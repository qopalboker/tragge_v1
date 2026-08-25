## Roadmap task

- Task ID and title:
- Dependencies and merge/evidence status:
- Base branch and task branch:

## Goal and scope

- Goal:
- Files/modules in scope:
- Non-goals:
- [ ] One roadmap task only
- [ ] No unrelated cleanup, mass rename, dependency upgrade, or broad refactor

## Implementation summary

<!-- Describe the observable result and important decisions. -->

## Policy, ADR, and documentation mapping

- Fixed-policy sections:
- Applicable ADRs / new ADR decision:
- Canonical glossary terms:
- Documentation updated:

### DOC-002 — Documentation sync (required when behavior/docs change)

- [ ] If this PR changes documented behavior, APIs, topology, financial rules, or operator workflows, the matching docs were updated in the same PR (`CLAUDE.md`, `docs/architecture/current-state-audit.md`, and/or `docs/codex/AI_AGENT_EXECUTION_ROADMAP.md` as applicable).
- [ ] If no docs update is needed, state why in the Implementation summary (doc-noop rationale).
- [ ] Open verification gaps were recorded or left open in `docs/codex/reports/discovered-issues.md` (do not claim runtime/staging verification without evidence).

## Acceptance criteria

- [ ] Every task acceptance criterion passes; evidence is listed below
- [ ] All dependencies are merged into the base
- [ ] No unresolved P0/P1 issue was introduced
- [ ] No secret or sensitive record is present
- [ ] All review comments are resolved

## Tests and exact results

| Exact command | Exit/result | Pass/fail count and material warnings |
|---|---|---|
|  |  |  |

- Coverage impact and evidence:
- Known untested behavior or unavailable tooling:

## Impact review

- Migration/data impact:
- Contract/API impact:
- Security/privacy impact:
- Financial/ledger/settlement impact:
- Observability/operations impact:

## Rollback and recovery

- Rollback/revert steps:
- Data/contract compatibility and restore/reconcile impact:

## Unresolved risks

<!-- Never omit this section. State ?None identified? only after review. -->

## Delivery checks

- [ ] Required local checks pass
- [ ] Required CI checks pass on the final commit
- [ ] Required approvals are present
- [ ] Documentation is current
- [ ] Rollback impact is understood
- [ ] Protected `main` is not bypassed
- [ ] No direct paid-production change is included
