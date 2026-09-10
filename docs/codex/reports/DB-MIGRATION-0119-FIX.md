# DB-MIGRATION-0119-FIX — PostgreSQL migration chain repair

## Status and delivery

**PARTIAL.** Migration repair, fresh installation, and dirty-database recovery
**PASS**. Required application-wide tests fail in three packages, with an
additional platform race failure. These failures are outside the repaired
constraint lookup. Human review is required before merge or another ECON-ADJ
certification invocation.

- Execution: Git-backed, GitHub Codespace, 2026-09-09 UTC.
- Repository: `qopalboker/tragge_v1`.
- Base: `672d996fe5faf6fb76e41cfd4a96b8f5216617fe`, fetched `origin/main`.
- Branch: `codex/db-migration-0119-fix`.
- Commit: the commit containing this report; exact SHA supplied in the handoff.
- Pull request: [#44](https://github.com/qopalboker/tragge_v1/pull/44), opened
  during the 2026-09-10 delivery continuation described below.
- Open PRs inspected: #35 and #18; neither overlaps the repair.
- Dependency evidence: certification commit
  `0a3049a0df37c1a6c214d283f68935fea383b141` on
  `codex/econ-adj-001-postgres-certification`. Its report is intentionally not
  copied into this branch. Its preserved dirty database was inspected directly.

## Pre-change work note

Current behavior: `0118` creates anonymous Prize Pool ledger checks. `0119`
tries to remove one using an incorrect name and stops the runner at dirty
version `119`, before any of its schema changes commit.

Authority: the existing top-level SQL migration chain and `golang-migrate`
version table own schema evolution. PostgreSQL owns constraint identity and
enforcement. Existing ledgers retain financial authority. The separate
`migrations/target` foundation is outside this task.

Assumptions: the preserved Codespace database is disposable test data; no
production migration history is being changed. Editing the failed `0119` is
explicitly requested. Already successfully applied databases do not re-execute
it. No assumption is made that this repair certifies application economics.

Minimal approach / expected files: one migration, one PostgreSQL regression
test, this report, and command/output evidence. Preserve the unrelated untracked
`package-lock.json`.

1. Add a PostgreSQL regression → reproduce the original failure in four cases.
2. Repair discovery → verify retained checks, historical data, and up/down/up.
3. Run fresh installation, dirty recovery, and workspace checks → retain exact
   evidence and commit for review; stop before ECON-ADJ certification.

## Root cause and chain audit

The audited top-level chain has 122 sequential up/down pairs, `0001`–`0122`,
plus the previously documented orphan `0000_baseline.down.sql`. The runner
prints `0/u <empty>` for that orphan before running `0001`; no baseline reset
or down migration was executed by fresh installation.

`0118_contest_prize_pool.up.sql` declares:

```sql
amount_cents BIGINT NOT NULL CHECK (amount_cents > 0)
```

There is no explicit constraint name. On the clean PostgreSQL 16.15 database,
the catalog name is `contest_prize_pool_ledger_amount_cents_check`. The broken
`0119` prepends an unrequested `chk_` prefix. PostgreSQL did not randomly rename
an explicitly declared constraint; the migration guessed a name that was never
declared. The other three removed checks were also anonymous.

Generated names are repeatable for the same schema state, but are not an
application-owned naming contract. The regression demonstrates suffixes when
equivalent anonymous checks coexist and also tests explicitly renamed checks,
including a quoted name with spaces. The existing `0119` down migration
recreates all four checks anonymously, so correcting only `0118` would not
repair existing databases or down/up replay.

All top-level `DROP CONSTRAINT`, `RENAME CONSTRAINT`, catalog-name tests, and
constraint references were inspected in both directions. Forward references:

| Migration | Reference | Finding |
| --- | --- | --- |
| `0054` | `chk_limit_price_for_limit`, `chk_stop_price_for_stop` | Optional `IF EXISTS` replacement, then explicitly named definitions in the same migration |
| `0063`, `0110` | `chk_current_participants_lte_max` | Explicitly created in `0016`; optional removal |
| `0098` | `users_phone_key` | Relies on the conventional name of inline `UNIQUE` in `0092`; guarded by a catalog-name check. A differently named duplicate could remain. Recorded, not broadened into this repair |
| `0106` | `chk_template_auto_create_requires_cron` | Explicitly named in `0008`; optional replacement |
| `0116` | Two Treasury checks | Explicitly named in `0115` |
| `0118`, `0119` | `chk_treasury_entry_shape` | Explicitly named in `0116`, then replaced under the same explicit name |
| `0119` | Four Prize Pool checks | Anonymous definitions in `0118` and `0119` down; repaired here |

Down references otherwise use explicitly declared names or optional removal;
`0098` down recreates `users_phone_key` explicitly. Many older migrations use
anonymous checks, foreign keys, and uniqueness declarations without subsequently
dropping them by guessed name. No other fresh-chain name mismatch was observed
when every forward migration ran on PostgreSQL. This is not certification of
every legacy down migration or every possible drifted schema.

## Old behavior, new behavior, and safety

Old behavior: four fixed `DROP CONSTRAINT` names, one incorrect. A missing or
renamed check aborts the entire migration.

New behavior: lock the Prize Pool ledger, inspect its `pg_constraint` rows of
type CHECK, and remove only the four exact legacy expressions rendered by
`pg_get_expr`. Quote discovered identifiers with `format('%I', ...)`. Missing
checks produce no iterations; renamed and duplicate equivalent checks are
removed regardless of their names. The existing, explicitly named
`chk_pool_entry_shape` is then installed unchanged.

The query is scoped by table OID and exact predicate. It preserves other checks,
including an added amount cap on the same column and an identical check on a
different table. Balance/policy checks, primary/foreign keys, and uniqueness
constraints are retained. This follows existing procedural migration blocks
without changing `0118` or introducing a reusable migration framework.

PostgreSQL documents table identity, constraint type, and expression metadata in
[`pg_constraint`](https://www.postgresql.org/docs/16/catalog-pg-constraint.html),
and expression reconstruction in
[`pg_get_expr`](https://www.postgresql.org/docs/16/functions-info.html).
Discovery matches the actual `0118` predicates and column types on the tested
PostgreSQL 16 line; arbitrary expression rewrites or type changes are not
silently treated as equivalent and are outside this repair.

The additional code contains no row mutation, table recreation, cascading drop,
or trigger disable. Migration `0119` already requires exclusive table locks for
its ALTER statements; discovery obtains the lock before reading/removing checks.
Use the existing single migration runner and stop application writers during
recovery. Apply finite session lock/statement timeouts appropriate to the
maintenance window; the regression uses 5 seconds / 15 seconds.

The full migration is not an arbitrary rerunnable SQL script: its existing
column/table additions still assume version `0118`. The runner's version gate
handles repeats after success. Recovery after an interrupted attempt requires
schema verification, not automatic forced version changes.

## PostgreSQL and fresh installation

- Existing Compose container: `tragge_postgres`, `postgres:16-alpine`.
- Server/container client: PostgreSQL 16.15; readiness succeeds.
- Host `psql --version` and `pg_isready`: exit `127`, tools unavailable; the
  same commands run successfully inside the existing container.
- Migration CLI: repository-documented `golang-migrate` 4.17.0.
- Go: `go1.27.0 linux/amd64`.
- Connection: local TCP `127.0.0.1:5432`, generated administrative credentials
  loaded from ignored local files, `sslmode=disable`, `ENVIRONMENT=test`.
- Repository initialization: unchanged `01-create-users.sql` and
  `02-grant-privileges.sql` on the new named test databases; existing roles and
  container reused. No Compose or credential setup code changed.

`tragge_test_migration_0119_fresh` was newly created. `make -s migrate-up`
applied `0001`–`0122`, including `0119`, exit `0`. Final version is `(122,false)`.
A repeated `make -s migrate-up` returns `no change`, exit `0`. Catalog inspection
confirms the snapshot, Prize Pool, and economic event tables and replacement
ledger constraint. No ECON-ADJ business scenario was executed.

`tragge_test_migration_0119_baseline` was independently created and migrated to
`118`, clean. It remains at that version for repeatable migration regressions.

## Dirty database recovery

Recovery was tested on the actual prior failed database,
`tragge_test_econ_adj_001`, not just a newly manufactured dirty flag.

1. Verified `(119,true)`, zero other client connections, and absent `0119` /
   `0122` event tables.
2. Compared `pg_dump --schema-only --no-owner --no-privileges` with the clean
   `0118` database. After removing only random `\restrict` / `\unrestrict`
   tokens, the dumps were byte-identical. This proves the prior failed
   transaction left schema version `0118`, despite the runner's dirty marker.
3. Preserved a complete custom-format dump at
   `/tmp/db-migration-0119-fix/backups/dirty-119.dump`, mode `0600`; size and
   SHA-256 are in the evidence. The backup contains local test data and is not
   committed. A separate restore drill was not performed.
4. Captured row counts and deterministic hashes of original columns for all 94
   pre-existing public tables, excluding the runner's `schema_migrations`.
5. Used the repository's documented `migrate force 118`, then `migrate up`.
   Both exited `0`. There was no direct SQL UPDATE of migration history and no
   forced jump over the repaired migration.
6. Verified `(122,false)`. Every captured row count/hash remained identical.
   The recovered schema exactly matched the fresh `0122` schema under the same
   dump normalization. All four financial ledgers were empty in this preserved
   database; nonzero Prize Pool data preservation is additionally covered by
   the regression fixture.

The existing convention is described in
[`packages/db/README.md`](../../../packages/db/README.md) under dirty-state
troubleshooting and [`docs/DEVELOPMENT.md`](../../DEVELOPMENT.md). The
[migration recovery policy](../../architecture/database-migration-reset-strategy.md)
requires proving state and preserving recovery evidence; its production
backup/PITR rules continue to apply.

Recommended path for this exact failure, after review and while writers are
stopped: take a backup, prove the schema still equals clean `0118`, then use:

```bash
migrate -path packages/db/migrations -database "$DATABASE_URL" version
migrate -path packages/db/migrations -database "$DATABASE_URL" force 118
make -s migrate-up
make -s migrate-version
```

`DATABASE_URL` must be supplied securely for the verified target. Do not run
`force 119` or `force 122`: that skips required SQL. If any partial `0119`
objects, unknown schema differences, or active writers exist, stop and use a
reviewed restore/forward-recovery plan. A clean database already at `119` or
later must not be forced backward. Production execution is not authorized by
this test report.

## Regression coverage

`TestMigration0119PostgreSQL` requires the separate opt-in
`TRAGGE_MIGRATION_TEST_DATABASE_URL`, a DDL-capable role, and clean version
`118`. An explicitly configured incompatible database fails rather than skips.

Four cases cover implicit names, all old checks absent, all renamed, and
duplicate checks receiving generated suffixes. Each executes the actual full
`0119` up/down/up scripts inside a transaction. It verifies the validated
replacement, retained unrelated checks, rejected zero-value credit, unchanged
historical account/ledger/participant data, and complete rollback of fixture
and migration objects. The old migration fails all four cases with SQLSTATE
`42704`; the fixed migration passes all four, including under `-race`.

The fixture has a 1,000-cent contest entry and an 800-cent Prize Pool admission
ledger/account balance. The migration preserves the 800-cent ledger and balance
exactly; it neither posts nor reverses funds. This is migration data-preservation
evidence, not end-to-end fee allocation or ECON-ADJ financial certification.

## Tests and commands

Full commands, environment construction, exit codes, and output are retained in
[the evidence file](evidence/DB-MIGRATION-0119-FIX.txt).

All Go checks use `ENVIRONMENT=test`. `TRAGGE_E2E_DATABASE_URL` remains unset;
the separate migration DSN is configured only for the new regression. Existing
ECON-ADJ PostgreSQL certification scenarios therefore remain unexecuted. Wallet
tests independently start their existing Testcontainers PostgreSQL fixtures.

The repository root has `go.work` and no `go.mod`. Each literal root command
`go test ./...`, `go test -race ./...`, and `go vet ./...` exits `1` with:

```text
pattern ./...: directory prefix . does not contain modules listed in go.work or their selected dependencies
```

The equivalent commands were also executed over all 35 `go.work` module paths,
each with `/...` appended. The evidence records the fully expanded arguments.

| Command / check | Result |
| --- | --- |
| `git diff --check` | PASS, exit 0 |
| `migrate -path packages/db/migrations -database "$DATABASE_URL" goto 118` | PASS, clean regression baseline |
| `make -s migrate-up` on new database; repeated up | PASS; `122,false`; repeat `no change` |
| `go test -count=1 -run '^TestMigration0119PostgreSQL$' -v ./packages/db/...` before repair | Expected FAIL, four cases, missing constraint / SQLSTATE `42704` |
| Same regression after repair | PASS, four cases; db package `0.734s` |
| Same regression with `-race` | PASS, four cases; db package `2.867s`; no race report |
| `migrate ... force 118`, then `migrate ... up` on verified dirty database | PASS; `122,false` |
| Schema / history comparison | PASS; clean 118 equals failed schema; recovered 122 equals fresh 122; all 94 original-table counts/hashes unchanged |
| `go test` over every workspace module | FAIL, exit 1; 58 packages pass, 3 fail, 23 contain no tests |
| `go test -race` over every workspace module | FAIL, exit 1; 57 packages pass, 4 fail, 23 contain no tests; one platform race report |
| `go vet` over every workspace module | PASS, exit 0, no output |
| Focused failing tests on an untouched archive of base `672d996` | FAIL as detailed below; establishes pre-existing failures |

Full normal-suite failures:

- `apps/leaderboard-worker/server`: `TestCalculateWinnersCountRounding`, five
  subcases. Examples: `(11,30)` produces `3`, expects `4`; `(10,100)` produces
  `3`, expects `10`. Reproduced unchanged on the base. No rounding or payout
  policy was altered.
- `apps/market-ingestor/server`: `TestRegistryDerivMappingAndSubscriptions`
  receives `[frxEURUSD frxXAUUSD]`. Reproduced unchanged on the base. No market
  data behavior was altered.
- `packages/wallet`: its synthetic minimal schema applies `0116`, `0118`, and
  `0119` without migration `0016` or its `trg_update_participant_count` trigger.
  After the repaired check lookup, the unchanged trigger replacement fails
  with SQLSTATE `42704`. The base's focused Treasury fixture fails earlier at
  the original constraint mismatch. This is an existing incomplete test
  prerequisite exposed by progress past the repaired statement, not a failure
  of the real full migration chain. Wallet fixture/business code and the
  trigger replacement were deliberately left unchanged.

The full race run repeats those three package failures and additionally fails
`apps/platform/internal/adapters` in `TestModeStartupSmokeHealthAndReady/worker`.
It reports concurrent writes in `outboxRelayJob.Start` / `Stop` at
`apps/platform/internal/modules/events/module.go:100` and `:106`. A focused
`go test -race -count=1 -run '^TestModeStartupSmokeHealthAndReady$' -v
./apps/platform/internal/adapters` on the untouched base reproduces the same
race. No platform event/runtime code changed.

The affected `packages/db` and `apps/admin-bff` packages passed in the full
normal run; the independent PostgreSQL migration regression actually executed
and passed. Broad-suite failures are retained, not converted into a successful
application gate. No test was weakened, disabled, or rewritten for those failures.

## Acceptance criteria

| Criterion | Result / evidence |
| --- | --- |
| 1. Audit `0001` through latest, creation/reference/naming review | PASS; 122 forward migrations, all up/down name references inspected; `0098` caveat retained |
| 2. Safe constraint handling in `0119` | PASS; table/predicate discovery, quoted identifiers, unchanged replacement constraint |
| 3. Exists, already absent, different generated name | PASS; four PostgreSQL regression cases, including duplicates and quoted renamed names |
| 4. Fresh database through latest without dirty state | PASS; full `0001`–`0122`, `(122,false)`, repeated up is a no-op |
| 5. Existing dirty database recovery | PASS; backup, exact schema proof, repository-conventional `force 118`, actual rerun, data/schema comparisons |
| 6. No data loss, table recreation, or historical mutation from repair | PASS; migration diff review, populated regression, 94-table original-data comparison |
| 7. Real PostgreSQL and readiness | PASS in existing container, version 16.15; host tools absent |
| 8. Required commands executed / all application tests green | Execution PASS; normal gate FAIL in three packages; race gate FAIL in four; workspace vet PASS |
| 9. Regression protection | PASS; red-before / green-after / race / up-down-up / rollback evidence |
| 10. Report and stop boundary | PASS; no ECON-ADJ recertification, no later task, review pending |

## Files changed and scope review

| File | Purpose |
| --- | --- |
| `packages/db/migrations/0119_lifecycle004_financial_reversal.up.sql` | Replace guessed check names with narrowly scoped catalog discovery |
| `packages/db/migration_0119_postgres_test.go` | Real PostgreSQL regression, data preservation, and replay/rollback coverage |
| `docs/codex/reports/DB-MIGRATION-0119-FIX.md` | Audit, recovery instructions, outcomes, limitations, and review handoff |
| `docs/codex/reports/evidence/DB-MIGRATION-0119-FIX.txt` | Exact command/output and comparison evidence |

No ECON-ADJ, contest economics, settlement, payout, or wallet behavior changed.
The replacement financial constraint and all existing business SQL remain
unchanged. No new duplicate financial/state authority, dependency, hidden
fallback, or unrelated refactor was introduced. The original untracked lockfile
is excluded. No full ECON-ADJ runtime certification was restarted; no later task
was started. Paid production remains NO-GO pending its separate gates and human
approvals.

Final document validation passed for local links, code fences, whitespace,
actual merge-conflict markers, and the exact four-file staged scope. The
documents contain none of the local database password-file values. Markdownlint
and gitleaks binaries are unavailable; focused structure checks, local credential
comparison, and diff review were used instead. SQL before and after the changed
constraint-removal block is byte-identical to the base.

## Remaining limitations

- PostgreSQL 16.15 was executed; no cross-major-version or arbitrary schema-drift
  matrix was run.
- The name assumption in `0098` remains a separately recorded audit finding.
- Only the `0119` down/up path was exercised, on a pre-reversal test fixture;
  financial-history rollback restrictions remain intact.
- Local runtime regression is opt-in, matching the repository's PostgreSQL
  testing approach; CI must provision a clean `0118` database to execute it.
- The full application test gate remains red. Leaderboard, market-ingestor,
  wallet-fixture, and platform outbox-race findings need separate review; this
  branch does not repair those systems or suppress their failures.
- Migration success is not approval of ECON-ADJ behavior. That certification
  remains deferred until this repair is reviewed.

## Delivery continuation — 2026-09-10

The original execution stopped before PR creation completed. The existing
`6cf3c05fad3611de137fa5a28ca1efd24360e218` commit was already on GitHub. PR #44
now targets `main` and includes exactly the four migration-repair paths listed
above. A detached review checkout at `/tmp/tragge-migration-0119-review` isolates
delivery from twelve local application follow-up files. Those files were
preserved byte-for-byte and are excluded from this PR. Their focused race and
PostgreSQL regressions pass locally, but that result does not certify this PR's
application-wide suite.

Rechecking the migration package on its dedicated existing clean-0118 test
database passed both normally and under `-race`, including all four real
PostgreSQL migration cases. Vet and build passed. Lint against the original main
base found two unchecked cleanup errors and a variable-filename G304 warning in
the new regression. A small follow-up commit handles database-close and rollback
errors, accepts `sql.ErrTxDone` after the explicit tested rollback, and documents
that the read helper receives only the two literal migration filenames. This
uses a line-scoped `#nosec G304` rationale; no linter configuration or test
assertion changes. The original migration commit and all its SQL are preserved.
The final package race suite, vet, and comparison-based lint pass.

CI run [34472773211](https://github.com/qopalboker/tragge_v1/actions/runs/34472773211)
also exposes failures beyond this migration repair:

| Job | Observed failure |
| --- | --- |
| CI-003 branch protection wiring | Live protection query returns HTTP 403, `Resource not accessible by integration` |
| ARCH-001 platform skeleton | Identity module source does not match the test's `type repository interface` expression |
| ARCH-007 runtime retirement boundary | Trading-core source does not match the test's `DEPRECATED wrapper` expression |
| MD-001 tick contract v2 | Node 20 rejects direct import of `tick-event.ts` with `ERR_UNKNOWN_FILE_EXTENSION` |
| FIN-006 admin funded deposit classification | Payment gateway source does not match the test's `LedgerTypeDeposit` expression |

The corresponding scripts, application files, and workflow are unchanged from
the base. These are observed failures, not proof that their assertions should
be removed or weakened. Repository protection and CI credentials were not
modified. Additional CI outcomes and final-head status are recorded on PR #44;
this snapshot does not claim all CI jobs finished successfully.

Delivery remains **PARTIAL**: the migration repair is reviewable, but merge is
not performed while the required checks remain unresolved. The original broad
application failures remain applicable to the migration-only PR. No ECON-ADJ
recertification, SETTLE work, wallet/payout implementation, or production action
is included. Current local commands and outputs are appended to the evidence
file. The new delivery cleanup can be reverted without changing migration SQL.
