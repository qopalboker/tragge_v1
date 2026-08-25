# Tragge v1 — Production Readiness Execution Directive

> Standing instructions for the AI engineering agent (e.g. Claude Code) working on `qopalboker/tragge_v1`. This supersedes the earlier draft roadmap from a prior session — same underlying audit, restructured so an agent *executes* it instead of re-planning it. Save this file at `docs/codex/AI_AGENT_EXECUTION_ROADMAP.md` in the repo and re-read it at the start of every session. Keep the Task Tracker in §8 in sync with reality as you go — this file is your persistent memory across sessions, not a one-time brief.

Basis: the manual code + internal-docs audit summarized in a prior session (dated August 25, 2026), cross-checked at the time against the live public repo — `docs/architecture/current-state-audit.md`, `docs/codex/PRODUCTION_ROADMAP_AND_CODEX_TASKS.md`, and `docs/codex/reports/*`. The internal roadmap's own estimate — 14–18 weeks with an experienced 5–6 person team — is the right order of magnitude for this whole plan. Don't compress it by cutting the verification steps below.

---

## 1. Role & Prime Directive

You are the senior/staff full-stack engineer — acting as CTO-delegate — responsible for taking `qopalboker/tragge_v1`, a real-money trading-contest platform, from its audited status of **NO-GO for paid production** to production-safe. You report to a CTO who reviews your PRs and does not rubber-stamp them.

**This document is a work breakdown structure, not the deliverable.** Documents like it already exist in this repo (`docs/architecture/current-state-audit.md`, `docs/codex/PRODUCTION_ROADMAP_AND_CODEX_TASKS.md`), and this file already translates them into tasks. Do not respond to it by writing more audits, summaries, or plans. Your output for each task is working code — implemented, tested, and either merged or left as a reviewable PR — never a description of what should be done.

**Writing code is necessary but not sufficient.** A task is complete only when you can prove — with evidence a skeptical reviewer would accept, not a claim — that it behaves correctly, including edge cases nobody explicitly asked about. Before opening any PR, review your own diff the way a skeptical CTO would, specifically for:
- Every error return handled, or explicitly and intentionally ignored with a comment saying why
- Concurrency: races, double-processing, non-idempotent behavior on retry
- Boundary values: zero, negative, empty, max values, nil/null
- Partial failure: what state is left behind if this dies halfway through
- Match with surrounding code style, error handling, and logging conventions
- No silent behavior change for any caller not covered by your new tests

Fix what you find yourself. Don't rely on the human reviewer to catch first-pass mistakes.

**Treat every "PASS"/"FIXED" label in this repo's existing reports — including the ones referenced later in this document — as an unverified hypothesis until you personally reproduce it.** This codebase has a documented precedent for why: a critical UI bug survived a month behind audits that called the platform production-ready.

---

## 2. Continuity Protocol — read this before doing anything else

A previous attempt at this work made real progress and then lost coherence partway through. The Status column in §8 may not reflect what actually happened — treat it as a starting hypothesis, not a fact.

**Every session, in this order:**
1. Read this file's Task Tracker (§8) — but don't trust it blindly (see above).
2. Read `docs/product/FIXED_PRODUCT_AND_TECHNICAL_POLICIES.md`, `docs/codex/PRODUCTION_ROADMAP_AND_CODEX_TASKS.md`, `docs/architecture/current-state-audit.md`.
3. Run `git branch -a`, check open PRs, and check `docs/codex/decisions/` for work already in flight, so you can reconcile it against the tracker and correct any stale Status entries before doing anything else.
4. Resume the oldest incomplete task in the earliest open phase. Don't restart finished work, don't skip ahead, don't re-plan what's already planned in §8.

**While working:**
- Finish one task (or one clearly-scoped sub-task) to a mergeable, tested state before starting another. Never attempt the whole roadmap, or even a whole phase, in one unbroken pass.
- If a task turns out bigger than expected mid-way: commit working, compiling, tested code to its branch; write the exact next step in the Status column; stop cleanly. A half-finished task with an honest note is recoverable; one with no note is not.
- If finishing a task properly requires touching something outside its stated scope, stop and log it (§3, Non-Negotiable 4) instead of silently expanding it.
- Resolve blocking questions (§4) before sinking significant work into an assumption that might be wrong.
- Update the Status column in §8 the moment something changes, not at the end of the session — the session can end unexpectedly.

---

## 3. Non-Negotiables

1. **Never silently decide ambiguous product or business logic.** Ask instead (§4).
2. **No task is done on code alone.** It ships with automated tests that fail on the pre-fix code and pass on the post-fix code, plus the evidence in §7.
3. **Money-path changes get an extra gate.** Any change touching fees, prize calculation, contest finalization, or settlement needs a worked numeric before/after example in the PR description and explicit human approval before merge — regardless of how green the tests are. Never self-merge a financial-logic PR.
4. **Small, reviewable increments.** One branch, one PR, one logical change. Bugs found along the way that aren't your current task go in `docs/codex/reports/discovered-issues.md` with severity and evidence — don't fix them inline, and don't expand your current task's scope without flagging it first.
5. **Match existing conventions.** Read enough surrounding code, error handling, and logging style that your change looks native to this team.
6. **Every branch is `codex/<task-id>-<short-name>`, cut from latest `main`. Never push directly to `main`.**

---

## 4. Source of Truth & When to Ask Instead of Deciding

Priority order when sources conflict: `docs/product/FIXED_PRODUCT_AND_TECHNICAL_POLICIES.md` → `docs/codex/PRODUCTION_ROADMAP_AND_CODEX_TASKS.md` → `docs/architecture/current-state-audit.md` → this document.

Anything in `docs/codex/reports/*` marked PASS or FIXED is unverified until you reproduce it yourself.

When you hit a genuine gap or contradiction, ask **one specific, decision-ready question with your recommended default clearly labeled** — never an open-ended "what should I do?" Example: *"Policy says contests no longer cap participants, but doesn't say whether late joiners score pro-rata or on full-duration performance. I'll assume pro-rata unless told otherwise — confirm?"*

Log every question and its answer in `docs/codex/decisions/<task-id>-decision-log.md`, so the answer becomes durable documentation instead of a message that gets lost.

Don't let one open question block unrelated work — park it, keep moving on what you can, and flag it clearly in your status update.

---

## 5. Git & Delivery Workflow

- A short-lived, fine-grained, repo-scoped GitHub PAT (`Contents: Read & write`, `Pull requests: Read & write`, ~7-day lifetime) is provided at the start of each session. Treat it as expired the moment the session ends — it will not persist into the next one.
- No token available this session? Don't block: produce the change as a patch/diff file for the human to review and push manually.
- One branch per Task ID: `codex/<task-id>-<short-name>`. Open a PR against `main` for every task. Never push directly to `main`.
- PR description includes: what changed and why, what was tested (with real command output — see §7), what was deliberately left out of scope, and any open questions.
- Financial-path PRs (all `FIN-*`, and anything touching fees, prizes, or settlement) require explicit human approval before merge, in addition to automated checks passing.

---

## 6. Definition of Done — applies to every task, no exceptions

- [ ] Automated test(s) added that fail on the pre-fix code and pass on the post-fix code
- [ ] Full existing test suite still green — no regressions introduced
- [ ] Edge cases handled explicitly: zero/negative/boundary values, concurrent access where relevant, partial failure
- [ ] Documentation updated where behavior changed (architecture doc, `CLAUDE.md`, this tracker, changelog)
- [ ] Self-review checklist from §1 applied to your own diff before opening the PR
- [ ] PR contains real evidence per §7 — not a claim of correctness
- [ ] Financial-path tasks only: numeric before/after example in the PR, plus explicit human sign-off requested and received before merge

---

## 7. Reporting Format — use for every task, before marking it done in §8

1. **What changed** — files and functions touched.
2. **Exact test commands run and their real output** — pasted verbatim, not paraphrased or summarized as "tests pass."
3. **Manual verification performed**, if any, and exactly how.
4. **What was explicitly NOT verified** — known gaps, left visible rather than hidden.
5. **Any question asked** and how it was resolved, with a pointer to the decision-log entry.

Self-reported "PASS" has a track record of being wrong on this project. Evidence, not confidence, is what closes a task.

---

## 8. The Roadmap

<<<<<<< HEAD
> **Status note (2026-08-25 continuity):** FIN-001..005 signed off and landing onto main (FIN-003 code restack in progress; Postgres dual-race gap tracked as FIN003-POSTGRES-DUAL-RACE). Next: **LIFECYCLE-001**. INFRA-001 parked; INFRA-002 desired-state gate on main. Keep FIN-006 / MD-005A separate.
=======
> **Status note (2026-08-25 continuity):** Phase 1 FIN-* signed off. LIFECYCLE-001 done on branch (late-entry policy regression-locked). Next: **LIFECYCLE-002**. Open verification gaps remain tracked (FIN003-POSTGRES-DUAL-RACE, FIN005-*, not runtime-verified). INFRA-001 parked.
>>>>>>> b83c686 (LIFECYCLE-001: Regression-lock paid late entry to running contests)

### Task Tracker

| ID | Task | Phase | Priority | Status |
|---|---|---|---|---|
<<<<<<< HEAD
| DOC-001 | Correct CLAUDE.md status | 0 | Quick win | Done (merged to main) |
| INFRA-001 | Contain K8s production overlay drift (stopgap) | 0 | P0 | Blocked — awaiting live cluster / kubeconfig (decision 2026-08-25) |
| CI-001 | Turn on existing frontend test suites in CI | 0 | P1 | Done (merged to main) — Vitest in CI; Playwright quarantined |
| SEC-008 | Regression-lock the three verified auth fixes | 0 | P0 | Done (merged to main) |
| SEC-009 | Independently verify admin reauth + Super Admin MFA | 0 | P0 | Done (merged to main) |
| FIN-001 | Single source of truth for platform fee | 1 | P0 | Done (merged to main) — signed off |
| FIN-002 | Consolidate prize calculation into one shared path | 1 | P0 | Done (merged to main) — signed off |
| FIN-003 | Single owner for contest finalization | 1 | P0 | Done on branch codex/FIN-003-single-finalization-owner (2026-08-25) — signed off; Postgres dual-race NOT runtime-verified (FIN003-POSTGRES-DUAL-RACE) |
| FIN-004 | Reconcile prize distribution algorithm vs. 	ralent_v1 | 1 | P0 | Done (merged to main) — signed off; Power Law divergence-only |
| FIN-005 | End-to-end financial reconciliation test harness | 1 | P0 | Done (merged to main) — in-process harness; Compose/staging follow-ups open |
| LIFECYCLE-001 | Support valid late entry to running contests | 2 | P0 | Not started |
=======
| DOC-001 | Correct `CLAUDE.md` status | 0 | Quick win | Done on branch `codex/DOC-001-correct-claude-status` (2026-08-25) — awaiting merge |
| INFRA-001 | Contain K8s production overlay drift (stopgap) | 0 | P0 | Parked — no production cluster yet; treat overlay as desired-state only (decision 2026-08-25) |
| CI-001 | Turn on existing frontend test suites in CI | 0 | P1 | Done on branch `codex/CI-001-frontend-tests-ci` (2026-08-25) — Vitest in CI; Playwright quarantined |
| SEC-008 | Regression-lock the three verified auth fixes | 0 | P0 | Done on branch `codex/SEC-008-auth-regression-lock` (2026-08-25) — awaiting merge |
| SEC-009 | Independently verify admin reauth + Super Admin MFA | 0 | P0 | Done on branch `codex/SEC-009-admin-reauth-mfa` (2026-08-25) — awaiting merge |
| FIN-001 | Single source of truth for platform fee | 1 | P0 | Done on branch `codex/FIN-001-platform-fee-source` (2026-08-25) — signed off; awaiting merge |
| FIN-002 | Consolidate prize calculation into one shared path | 1 | P0 | Done on branch `codex/FIN-002-prize-calculation-path` (2026-08-25) — signed off; awaiting merge |
| FIN-003 | Single owner for contest finalization | 1 | P0 | Done on branch `codex/FIN-003-single-finalization-owner` (2026-08-25) — signed off; Postgres dual-race NOT runtime-verified (FIN003-POSTGRES-DUAL-RACE) |
| FIN-004 | Reconcile prize distribution algorithm vs. `tralent_v1` | 1 | P0 | Done on branch `codex/FIN-004-tralent-v1-reconcile` (2026-08-25) — signed off; Power Law divergence-only |
| FIN-005 | End-to-end financial reconciliation test harness | 1 | P0 | Done on branch `codex/FIN-005-financial-reconciliation-harness` (2026-08-25) — signed off; Compose/staging gaps tracked |
| LIFECYCLE-001 | Support valid late entry to running contests | 2 | P0 | Done on branch `codex/LIFECYCLE-001-late-entry` (2026-08-25) — awaiting merge |
>>>>>>> b83c686 (LIFECYCLE-001: Regression-lock paid late entry to running contests)
| LIFECYCLE-002 | Remove participant capacity limits | 2 | P0 | Not started |
| LIFECYCLE-003 | Replace hard-delete cleanup with audit-safe archival | 2 | P0 | Not started |
| ARCH-001…007 | Execute existing internal architecture roadmap tasks | 3 | P0 | Not started |
| ARCH-008 | Resolve fate of each legacy standalone service | 3 | P0 | Not started |
| INFRA-002 | Permanent K8s base/overlay parity + drift CI gate | 3 | P0 | Done (merged to main) — desired-state gate; live-cluster/HA follow-ups open |
| ARCH-009 | Refresh architecture docs/diagrams to final state | 3 | — | Not started |
| ENGINE-001 | pricebook.go: float64 → decimal | 4 | P1 | Not started |
| ENGINE-002 | position_management.go: float64 → decimal | 4 | P1 | Not started |
| ENGINE-003 | Regression-lock WAL fail-closed behavior | 4 | P1 | Not started |
| CI-002 | Test coverage for the 7 untested critical Go services | 5 | P1 | Not started |
| CI-003 | Enforce CI as a required branch-protection gate | 5 | P1 | Not started |
| CI-004 | Continuous secret-scanning in CI | 5 | Nice-to-have | Not started |
| DOC-002 | Ongoing documentation-sync process | 6 | — | Not started |

*P0 = blocks paid-production launch. P1 = important, not launch-blocking. Quick win = high value, low effort.*

---

### Phase 0 — Stabilize
*Cheap, fast fixes that remove active/silent risk and turn on the regression safety net before Phase 1's larger work begins.*

#### DOC-001 — Correct `CLAUDE.md` status
**Subtasks**
- [x] Diff every claim in `CLAUDE.md` against `current-state-audit.md` and `README.md`, line by line.
- [x] Rewrite the status section to state the real status (NO-GO for paid production), linking to the audit and roadmap.
- [x] Add an explicit note that PASS/FIXED labels in `docs/codex/reports` must be independently reverified before being relied on, citing the month-long hidden UI bug as precedent.

**Verify**
- [x] List every discrepancy found in the PR description (see branch commit / `docs/codex/reports/DOC-001-claude-status.md`).

**Done when:** a reviewer who reads only `CLAUDE.md` reaches the same conclusion as one who reads the full audit.

#### INFRA-001 — Contain K8s production overlay drift (stopgap)
**Status:** Blocked 2026-08-25 — human chose park until kubeconfig/cluster access exists (`docs/codex/decisions/INFRA-001-decision-log.md`). Preliminary: production overlay still targets obsolete standalone names; `kubectl kustomize overlays/production` also fails on a tab in `base/network-policies.yaml` line ~82.

**Subtasks**
- [ ] Dry-run `kustomize build` against `infra/k8s/overlays/production` and diff its output against what's actually deployed in the cluster, to establish ground truth.
- [ ] Based on that ground truth, not a guess: either (a) add the missing base Deployment/HPA manifests for `trade-bff`, `user-bff`, `admin-bff`, `market-ingestor`, `leaderboard-worker`, `payment-service` if they're genuinely still live, or (b) repoint the overlay's patch targets at `api-server` / `trading-core` / `worker` if those are what's actually live.
- [ ] Add a CI check that fails the build if a Kustomize patch targets a resource missing from base.

**Verify**
- [ ] `kustomize build overlays/production` succeeds with zero "patch target not found" warnings.
- [ ] Resulting replica/autoscaling config matches what's intended for each real running service.

**Done when:** both verify items hold and the new CI check exists.

#### CI-001 — Turn on existing frontend test suites in CI
**Subtasks**
- [x] Add CI job(s) invoking the Vitest scripts already defined (`pnpm --filter @tragge/user-frontend test` / admin). Playwright explicitly quarantined — see `docs/codex/reports/discovered-issues.md` (CI-001-PLAYWRIGHT-QUARANTINE).
- [x] Fix first-run breakage: restored Telegram Mini App router guard so `auth_bootstrap.test.ts` passes (was redirecting TG users to `/user/login`).
- [ ] Make the job(s) required checks (finalized in CI-003).

**Verify**
- [x] Local proof: pre-fix Vitest failed (`telegram-auth-error` missing); post-fix user 32/32 + admin 10/10 pass. GitHub “intentionally broken PR blocked” not verified this session (no PAT / Actions run).
- [ ] Clean GitHub PR Actions green — pending human push.

**Done when:** both verify items hold.

#### SEC-008 — Regression-lock the three verified auth fixes
Covers: shared auth between User/Admin, JWT accepted via `?token=` URL param, mock SMS logging raw OTP — all previously confirmed fixed by direct code reading, corroborated by `docs/security/user-admin-authentication-isolation.md`.

**Subtasks**
- [ ] Write an automated test asserting a request with `?token=` in the URL is rejected.
- [ ] Write an automated test asserting an admin session can't reach user-only routes and vice versa.
- [ ] Write an automated test asserting OTP never appears in logs.

**Verify**
- [ ] All three tests pass today and run in CI.

**Done when:** a future regression would be caught by CI, not rediscovered by a human browsing the app.

#### SEC-009 — Independently verify admin reauth + Super Admin MFA
These were reported fixed internally but never personally verified — treat as open until proven.

**Subtasks**
- [x] Write a regression test that attempts a sensitive admin action without fresh reauthentication and asserts it's rejected (`TestSEC009ReauthenticationMissingGrantRejected`).
- [x] Write a regression test that Super Admin without MFA is rejected when policy ON (`TestSEC009SuperAdminActionWithoutMFARejectedWhenPolicyOn`); policy OFF allows password-only.
- [x] Document exact repro steps and results in `docs/codex/reports/SEC-009-admin-reauth-mfa.md`, marked independently verified.

**Verify**
- [x] Both negative tests exist, pass, and run in CI job `sec-009-admin-reauth-mfa`.

**Done when:** both are permanent regression guards in CI.

---

### Phase 1 — Financial Integrity
*Highest real-money risk: three divergent prize-calculation paths and dual finalize authority. Do not defer this phase or shrink its verification steps.*

#### FIN-001 — Single source of truth for platform fee
**Subtasks**
- [x] Inventory every call site reading `platform_fee_bps` or `commission_rate` (see `docs/codex/reports/FIN-001-platform-fee-source.md`).
- [x] Canonical field: `platform_fee_bps` (policy §4.2); human sign-off 2026-08-25.
- [x] Migrate fee resolution + critical writers (economics resolver; scheduler/admin no longer derive bps from `commission_rate`).
- [x] DB backfill + BEFORE INSERT/UPDATE trigger guard (`0109_fin001_platform_fee_bps_canonical`).
- [x] Backfill plan: paid rows with unset/0 bps → 2000 (not commission→bps conversion).

**Verify**
- [x] Automated test `TestFIN001ConflictingLegacyFieldsDeterministic` + CI job `fin-001-platform-fee`.

**Done when:** that test passes in CI.

#### FIN-002 — Consolidate prize calculation into one shared path
**Subtasks**
- [x] Diff catalogued in `docs/codex/decisions/FIN-002-decision-log.md`.
- [x] Human chose economics + prizedistribution as sole path (2026-08-25).
- [x] Settlement + leaderboard call economics/prizedistribution; prize package thinned to economics wrappers.
- [x] Local net formulas removed; orchestration wrappers retained where they call shared math.
- [x] Golden agreement test in `packages/scoring/economics/fin002_golden_test.go` + CI `fin-002-prize-path`.

**Verify**
- [x] `TestFIN002PreviewLeaderboardSettlementAgreement` covers representative cases.
- [x] CI job `fin-002-prize-path` runs the golden suite (full settlement package link OOM on this host — economics suite is the authority).

**Done when:** both verify items hold and the duplicate code is deleted.

#### FIN-003 — Single owner for contest finalization
**Subtasks**
- [x] Traced: settlement has advisory lock + prize credits; leaderboard raced Complete + single-participant refunds (see FIN-003 decision log).
- [x] Human: Settlement sole owner; strip Complete + wallet refunds from leaderboard.
- [x] Settlement advisory lock + status idempotency retained; single-participant refund moved to settlement (RefundContestEntryFeeIdempotent); prize keys concurrent-tested.

**Verify**
- [x] `TestFIN003ConcurrentPrizeCreditIdempotencyKeys` (32 goroutines → 1 success) + CI `fin-003-finalization-owner`. Full dual-service Postgres race not run on this host (OOM); static ownership guards included.

**Done when:** that test passes reliably.

#### FIN-004 — Reconcile prize distribution algorithm vs. `tralent_v1`
**Subtasks**
- [x] Spec = FIXED_PRODUCT_AND_TECHNICAL_POLICIES §11; implemented in `tralent_v1.go`.
- [x] `TestFIN004PowerLawVsTralentV1Divergence` (dollar deltas logged).
- [x] Human chose implement `tralent_v1`; production callers use `CalculateForContest`.

**Verify**
- [ ] Implemented algorithm's output matches the approved reference within an explicitly agreed tolerance across all tested scenarios.

**Done when:** code and policy document agree.

#### FIN-005 — End-to-end financial reconciliation test harness
**Subtasks**
- [x] In-process harness `TestFIN005FinancialReconciliationHarness` (join/split → trade note → preview=settle shares → prize conservation → synthetic ledger).
- [x] Always-on CI job `fin-005-reconciliation-harness` (+ Power Law production ban). Required-check path filter deferred to CI-003 (`FIN005-BRANCH-PROTECTION`).
- [ ] Staging schedule deferred — tracked as `FIN005-STAGING-SCHEDULE` (no staging env this session).

**Verify**
- [x] Local `test:fin005` green; GitHub Actions pending push.

**Done when:** it's enforced as a required check on the relevant code paths.

---

### Phase 2 — Contest Lifecycle Correctness
*Product-blocking: the platform can't run contests the way current policy actually intends until this lands.*

#### LIFECYCLE-001 — Support valid late entry to running contests
**Subtasks**
- [x] Confirmed §5.6 / §4.3: cutoff = start+min(10% dur, 30m); prize contribution not pro-rata; scoring = filled trades after join (decision log).
- [x] `economics.JoinAllowed` + handler already/reconfirmed; join response exposes late surcharge fields.
- [x] Documented: scores accumulate only from fills after join; prize eligibility still requires a filled trade.

**Verify**
- [x] `TestJoinAllowed` + cutoff examples + charge tests in economics; CI `lifecycle-001-late-entry`.

**Done when:** that suite passes.

#### LIFECYCLE-002 — Remove participant capacity limits
**Subtasks**
- [ ] Remove `max_participants` enforcement from the handler, DB schema/constraint, and UI.
- [ ] Audit downstream code that may implicitly assume a bounded participant count (pagination, in-memory leaderboard structures, prize-pool sizing logic) and fix anything that doesn't scale.
- [ ] Load-test with a large synthetic participant count.

**Verify**
- [ ] Load test passes at the target scale.
- [ ] No UI copy or validation still references a maximum.

**Done when:** both verify items hold.

#### LIFECYCLE-003 — Replace hard-delete cleanup with audit-safe archival
**Subtasks**
- [ ] Change `contest-scheduler`'s cleanup from a destructive `DELETE` to a soft-delete/archive-table pattern or immutable cold-storage export.
- [ ] Define and document a retention policy — ask what retention period compliance/product actually requires if it isn't already specified (§4).

**Verify**
- [ ] Test proves running cleanup removes archived data from the hot path, but the data remains queryable/exportable for audit purposes afterward.

**Done when:** that test passes.

---

### Phase 3 — Architecture Consolidation Completion
*The K8s/architecture risk is contained by Phase 0's stopgap, so the full fix waits until here, after the higher-severity financial bugs close.*

#### ARCH-001…007 — Execute the existing internal architecture roadmap
**Subtasks**
- [ ] Pull the exact scope for each of ARCH-001 through ARCH-007 from `docs/codex/PRODUCTION_ROADMAP_AND_CODEX_TASKS.md` — that document is the authority; don't let a paraphrase here drift from it (this directive deliberately doesn't restate their scope).
- [ ] Execute in whatever dependency order that document implies; ask if the order isn't specified (§4).
- [ ] Treat each as its own branch/PR, following §5 and §6.

**Verify:** per-task, as specified in the source document.

**Done when:** all seven are merged and the source document's own completion criteria are met for each.

#### ARCH-008 — Resolve the fate of each legacy standalone service
**Subtasks**
- [ ] For each of `user-bff`, `admin-bff`, `payment-service`, `trading-engine`, `market-ingestor`, `trade-bff`, `leaderboard-worker`, `settlement-service`, `contest-scheduler`: determine — ask if not documented (§4) — whether it is (a) fully replaced and safe to delete, (b) still receiving live production traffic and must stay, or (c) partially replaced and needs a migration step.
- [ ] Act per-service; don't blanket-delete.
- [ ] Coordinate with FIN-002/FIN-003: `leaderboard-worker` and `settlement-service` are actively being refactored there — don't land their disposition decision mid-refactor.
- [ ] For any service you delete, confirm zero production traffic/references first via logs or metrics — not code-reading alone.

**Verify**
- [ ] Each disposition decision is logged with the evidence used to make it.

**Done when:** every legacy service has a documented, executed disposition, and `infra/k8s/base` accurately reflects only what's meant to run in production.

#### INFRA-002 — Permanent K8s base/overlay parity + drift CI gate
**Subtasks**
- [ ] Building on INFRA-001's stopgap, ensure `infra/k8s/base` fully and correctly represents every service actually meant to run in production.
- [ ] Ensure overlays only patch real base resources.
- [ ] Make the drift-check CI gate from INFRA-001 permanent and non-bypassable.

**Verify**
- [ ] Drift check has been green for a full deploy cycle with no manual intervention.

**Done when:** that holds.

#### ARCH-009 — Refresh architecture docs/diagrams to final state
**Subtasks**
- [ ] Once ARCH-001…008 land, update `current-state-audit.md` and any architecture diagrams so documentation matches reality again.

**Verify**
- [ ] A new engineer reading only the architecture docs would correctly describe what's actually deployed.

**Done when:** that's true.

---

### Phase 4 — Trading Engine Numerical Precision
*P1 and mechanical — sequenced after the P0 financial-logic bugs close, not before.*

#### ENGINE-001 — `pricebook.go`: float64 → decimal
**Subtasks**
- [ ] Introduce (or confirm and reuse) a project-wide decimal/fixed-point type.
- [ ] Migrate `pricebook.go`'s price fields off `float64`; isolate and test this file before touching ENGINE-002. (43 `float64` sites were counted across `pricebook.go` and `position_management.go` combined — the industry standard for money is decimal/fixed-point.)
- [ ] Audit serialization boundaries this file touches (DB columns, JSON API responses) so precision isn't silently lost downstream after the Go-side fix.

**Verify**
- [ ] Property-based test proves no rounding-error accumulation across a long sequence of operations.
- [ ] Static check (grep/lint rule) confirms zero `float64` remains in this file's price-relevant path.

**Done when:** both verify items hold.

#### ENGINE-002 — `position_management.go`: float64 → decimal
**Subtasks**
- [ ] Same approach as ENGINE-001, applied to PnL fields in `position_management.go`.
- [ ] Pay particular attention to any code shared with `pricebook.go` to avoid an inconsistent migration.

**Verify**
- [ ] Same bar as ENGINE-001: property-based precision tests pass, static check confirms zero remaining `float64` in the PnL path.

**Done when:** both hold.

#### ENGINE-003 — Regression-lock WAL fail-closed behavior
Believed already fixed by code reading (`config.go` fails closed if `WAL_PERSIST_PATH` is empty in prod/staging; replay failure is a hard error, not a warning) — but never confirmed by a running test. Treat like SEC-008/SEC-009: verify, then lock in.

**Subtasks**
- [ ] Write a test that starts the engine with `WAL_PERSIST_PATH` unset in a prod/staging-like config and asserts startup fails.
- [ ] Write a test forcing a replay failure and asserting it surfaces as a hard error, not a warning.

**Verify**
- [ ] Both tests exist, pass, and run in CI.

**Done when:** that holds as a permanent regression guard.

---

### Phase 5 — CI/CD and Test Coverage Expansion
*Builds on Phase 0's CI pipeline; coverage growth follows the real risk touched in Phases 1–2, not generic busywork.*

#### CI-002 — Test coverage for the 7 untested critical Go services
**Subtasks**
- [ ] Prioritize by financial blast radius: `settlement-service` and `leaderboard-worker` first, then `trading-core`/trading-engine, then `user-bff`, then the remainder.
- [ ] For each service, start with tests covering the exact functions already touched in Phases 1–2, then expand outward.

**Verify**
- [ ] A coverage report exists per service and is trending upward in CI output.

**Done when:** none of the 7 remains at zero coverage.

#### CI-003 — Enforce CI as a required branch-protection gate
**Subtasks**
- [ ] Make backend and frontend test jobs (including CI-001's suites) required status checks.
- [ ] Add branch protection on `main` requiring passing CI and review before merge.

**Verify**
- [ ] An attempted merge with a failing check or missing review is blocked by GitHub itself, not just convention.

**Done when:** that holds.

#### CI-004 — Continuous secret-scanning in CI
**Subtasks**
- [ ] Add an automated secret-scanning step to CI (pre-commit and/or CI-stage) — the prior manual pass found no hardcoded secrets; turn that one-time result into a permanent guarantee.

**Verify**
- [ ] A deliberately introduced test secret is caught and blocked on a PR.

**Done when:** the scanner runs on every PR.

---

### Phase 6 — Ongoing Documentation Hygiene

#### DOC-002 — Documentation-sync process
**Subtasks**
- [ ] As each phase above lands, update `CLAUDE.md`, `current-state-audit.md`, and the roadmap doc to reflect the new real state.
- [ ] Add a checklist item to the PR template requiring a docs update for any task that changes documented behavior.

**Verify**
- [ ] Confirm the checklist item exists in the PR template.

**Done when:** the process has been followed for at least one full phase.

---

## Starting a Session

Point your coding agent at this file and say: *"Follow `docs/codex/AI_AGENT_EXECUTION_ROADMAP.md`. Run the Continuity Protocol in §2, then resume the current task."* Attach a fresh GitHub PAT (§5) if code needs to be pushed this session.
