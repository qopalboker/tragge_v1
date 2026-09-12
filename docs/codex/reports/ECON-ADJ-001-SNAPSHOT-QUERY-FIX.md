# ECON-ADJ-001-SNAPSHOT-QUERY-FIX

**Status: PARTIAL.** The five projection aliases are fixed and independently
verified on PostgreSQL. Confirmation, start, and finish creation/retry checks
pass normally and under race instrumentation. Cutoff and the existing ECON-ADJ
runtime tests expose separate pre-existing parameter inference errors. They
remain failing, with no assertion weakened or query outside scope changed.

## Task-start record

Execution: Git-backed, local task branch and commit; no remote delivery selected.
Base: `6c166292e1a148d4fc79ff360592e878f02c92cd`.
Branch: `codex/econ-adj-001-snapshot-query-fix`.

The explicit invocation authorizes only the shared snapshot CTE projection
repair, focused PostgreSQL regression coverage, relevant ECON-ADJ tests, and
this report/evidence. Stop after this task; full ECON-ADJ certification and
SETTLE-001 are excluded.

Migration repair commits `6cf3c05` and `1dacbbd` are merged through PR #44 at
`d12c76e`. The existing Codespace PostgreSQL 16.15 application connection reports
schema version 122, dirty false. No migration is needed or changed. The surviving
certification report at `fbf56c9` records SQLSTATE 42703 in the unaliased snapshot
projection; current source still contains that exact projection.

The twelve unrelated follow-up files remain in the original main checkout.
Before task work, their exact bytes, tracked binary diff, original status, and
SHA-256 manifest were backed up under
`var/codex-preservation/ECON-ADJ-001-SNAPSHOT-QUERY-FIX-20260912/` in that checkout.
The task uses a separate, initially clean worktree under
`var/worktrees/econ-adj-001-snapshot-query-fix/`.

Authority: the explicit task scope, fixed policy section 4.4 (immutable
economics), Accepted ADR-0001 (unchanged ownership boundaries), canonical
glossary/version catalog (unchanged snapshot formats), and the Codex execution
protocol. No policy, calculation, version, domain ownership, dependency, public
API, migration, or financial-ledger behavior change is authorized.

Expected changed files: `packages/db/contest_snapshots.go`, a focused PostgreSQL
test file, this report, and its command evidence. Planned validation: demonstrate
the regression before the fix; test all four snapshot creation paths and retry
reads, nullable and populated fields; run the requested ECON-ADJ command and
focused race tests, package vet/build/lint, formatting, diff, and preservation
checks. Tests use the existing local test database via the application role.
Browser E2E is not applicable to this internal SQL projection correction.
Rollback: revert this task's code/test/documentation commit; no data or schema
recovery is required. Paid production remains NO-GO.

## Files changed

1. `packages/db/contest_snapshots.go`: one explanatory comment and five aliases.
2. `packages/db/contest_snapshot_projection_postgres_test.go`: independent
   creation/retry regressions for all four stages and populated projection values.
3. `docs/codex/reports/ECON-ADJ-001-SNAPSHOT-QUERY-FIX.md`: this report.
4. `docs/codex/reports/evidence/ECON-ADJ-001-SNAPSHOT-QUERY-FIX.txt`: exact commands,
   outputs, exit codes, and preservation/structural checks.

## Root cause and exact correction

The shared `snapshotColumns` projection appears in both a CTE's `RETURNING`
clause and its outer `SELECT`. PostgreSQL labels an unaliased `COALESCE(...)`
output `coalesce`, so the outer reference to the original column name fails
with SQLSTATE 42703. The physical table column is present.

The existing expressions now have their original column names explicitly:

```sql
COALESCE(gross_base_entry_cents,0) AS gross_base_entry_cents
COALESCE(platform_fee_cents,0) AS platform_fee_cents
COALESCE(late_surcharge_cents,0) AS late_surcharge_cents
COALESCE(prize_pool_cents,0) AS prize_pool_cents
COALESCE(planned_winner_count,0) AS planned_winner_count
```

Expression order, zero defaults, types/casts, scan order, calculations, stored
NULLs, snapshot contents, locks, conflict handling, and transaction ownership
are unchanged. All source outside the projection and its new comment is
byte-identical to the base. No migration, policy, ranking, lifecycle, wallet,
payout, settlement, dependency, or API implementation is included.

## PostgreSQL regression coverage

`TestContestSnapshotProjectionPostgreSQL` gives each stage its own fixture and
rollback-only transaction. It invokes the real `EnsureContestConfirmed`,
`EnsureContestStarted`, `EnsureEconomicsCutoff`, and `EnsureContestFinished`
functions. Successful paths check identity/version/counts, NULL-to-zero reads,
unchanged stored NULLs, settlement references, identical creation/retry/stored
reads, and exactly one snapshot of the requested stage.

The cutoff subtest inserts only its prerequisite start snapshot directly so a
broken start query cannot conceal the cutoff query. This is fixture isolation,
not a workaround in production or a successful cutoff certification claim.
The finished case supplies a completed settlement as its prerequisite.

`TestContestSnapshotProjectionValuesPostgreSQL` independently executes a real
`INSERT ... RETURNING snapshotColumns` CTE followed by the same outer projection.
Five distinct nonzero values (1998 gross, 298 fee, 99 surcharge, 1700 pool, one
planned winner) must survive projection and stored reads unchanged. These are
fixed projection fixtures; the test does not claim to certify fee calculation
or generate economic-adjustment events. This test fails with 42703 under a Go
overlay containing only the base production file, and passes with the aliases.

Both new tests roll back their fixture writes. With a configured DSN, connection
or migration errors fail rather than skip. Without that DSN, the tests follow
the existing opt-in PostgreSQL convention. No test skipped in the recorded runs.

## Environment and exact validation

Existing Codespace container: `tragge_postgres`, PostgreSQL 16.15. Database:
`tragge_test_econ_adj_001_cert_20260910`, accessed as `tragge_app` over local TCP
5432. Existing schema version: 122, dirty false before and after testing. No
migration was run. The database name is historical; this execution is the
requested focused repair verification, not a new certification invocation.

`ENVIRONMENT=test` and `TRAGGE_E2E_DATABASE_URL` were set for test commands.
The DSN was assembled privately from the existing ignored application password
file; secrets are absent from the evidence. `GOCACHE` points to the original
workspace's existing `.go-cache`. Go is 1.27.0; golangci-lint is 2.13.1 built
with Go 1.27.0. CI currently pins lint 2.12.2; no CI run is claimed here.

Exact commands, complete output, and exit codes are in
[the evidence file](evidence/ECON-ADJ-001-SNAPSHOT-QUERY-FIX.txt).

| Command/check | Result |
| --- | --- |
| `go test -count=1 -p 1 -run '^TestContestSnapshotProjectionPostgreSQL$' -v ./packages/db/...` before aliases | Expected FAIL, exit 1: confirmation/start/finish reproduce 42703; independent cutoff exposes 42P08 for `$10` |
| Same command immediately after aliases | PARTIAL, exit 1: three stages pass, cutoff retains 42P08 |
| Final `go test -count=1 -p 1 -run '^TestContestSnapshotProjection.*PostgreSQL$' -v ./packages/db/...` | PARTIAL, exit 1: three creation/retry stages and populated projection test pass; cutoff fails; zero skips |
| Same final selection with `-race` | Same results, exit 1; no race report; zero skips |
| Populated projection test with `-overlay /tmp/econ-adj-001-snapshot-query-fix/baseline-overlay.json` | Expected FAIL, exit 1, 42703 against base production source; current task source is not reverted |
| `go test -count=1 -p 1 -run ECON_ADJ -v ./packages/db/... ./apps/admin-bff/...` | FAIL, exit 1: four unit/source tests pass; four PostgreSQL tests fail at existing admission fixtures with 42P08 for `$1`; zero skips |
| Read-only `PREPARE` of the unchanged cutoff statement with the new aliases, never `EXECUTE` | Confirms 42P08, `DETAIL: text versus integer`, exit 3 |
| `go vet ./packages/db/... ./apps/admin-bff/...` | PASS, exit 0, including final test source |
| `go build ./packages/db/... ./apps/admin-bff/...` | PASS, exit 0 |
| `golangci-lint run --timeout 5m --new-from-rev=6c166292e1a148d4fc79ff360592e878f02c92cd ./...`, within `packages/db` | Initial test-complexity finding; assertions extracted into a helper; final PASS, exit 0, zero issues |
| `git diff --check`, new-test formatting, local report links, exact scope, preservation and credential checks | PASS; detailed final checks in evidence |

The existing `packages/db/events` package reports no matching tests; that is
not counted as PostgreSQL coverage. The required ECON-ADJ run predates only the
new standalone projection-value test and assertion-helper extraction; production
code and existing ECON-ADJ tests were unchanged thereafter. No full workspace
suite, broader snapshot certification, migration exercise, numeric coverage,
remote CI, or full ECON-ADJ certification was run. No browser workflow changed.
Markdownlint and gitleaks are unavailable; focused report/link/whitespace checks
and comparison against ignored local credential values were used instead. This
does not claim a full secret-scanner pass.

## Remaining blockers and acceptance

1. `EnsureEconomicsCutoff` reuses `$10` as `planned_winner_count` and in
   `$12<$10`. PostgreSQL reports incompatible text/integer inference. This is
   reproduced before and after the alias edit, independently of start creation.
   No parameter casts or event query changes were made.
2. All four existing ECON-ADJ PostgreSQL tests now get past start creation and
   fail while inserting wallet-admission fixture rows. The fixture combines
   `$1` in a UUID column with `$1::text` in its idempotency expression. PostgreSQL
   reports inconsistent types for `$1`. The three DB cases use
   `insertWalletAdmissionEvidence` in `contest_snapshots_test.go`; the Admin case
   has its inline equivalent at `econ_adj_001_postgres_test.go:65`. These fixtures
   and all wallet implementation are outside this change.

Alias correctness, calculations unchanged, no migration, scope preservation,
real PostgreSQL execution, all four path attempts, and requested test execution
are verified. **All-path and ECON-ADJ runtime success are not achieved.** The
failing cutoff regression is retained as an executable finding, not disabled
or relabeled as success. Fix the separately identified parameter-typing
problems in an authorized follow-up and rerun the focused commands before any
full certification. Work stopped at these observed failures; this is not an
exhaustive inventory of later SQL/runtime problems.

## Preservation, delivery, and rollback

Final SHA-256 comparison verifies all twelve originals and their backup copies
still match the initial manifest. The original `main` remains at the base SHA
with exactly the same unstaged/untracked inventory and no staged changes.
None of those twelve paths appears in this task's four-file change set.

The requested local Conventional Commit is created on the task branch after
the scope/evidence review; its SHA is supplied in the handoff (or resolve
`git log -1 --format=%H codex/econ-adj-001-snapshot-query-fix`). The recorded
failing tests make this a PARTIAL repair handoff, not a merge-ready result.
No push, PR, merge, deployment, or approval is claimed. Rollback is a revert of
this task commit, with no schema change or historical-data rewrite.

Full ECON-ADJ certification and SETTLE-001 were not started. Paid production
remains **NO-GO**.
