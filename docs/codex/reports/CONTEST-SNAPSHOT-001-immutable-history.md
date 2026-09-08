# CONTEST-SNAPSHOT-001 — Immutable contest history

**Status:** Implemented — Cloud verified; real PostgreSQL certification pending.

Migration `0117` adds the explicit `legacy` / `contest_snapshot_v1` boundary,
one typed `contest_snapshots` row per lifecycle stage, and database triggers
that reject history mutation. Existing contests are not backfilled or inferred
from missing snapshots.

V1 relies on typed constraints plus PostgreSQL immutability rather than a
payload hash. Hashing is deferred until a canonical serialization contract can
be defined without creating a second representation of typed authoritative
fields.

The authoritative creators are user admission for confirmation, the typed
snapshot repository for cutoff, the contest state machine for start, and
FIN-003 settlement for finish. The scheduler only discovers candidate contest
IDs and invokes the cutoff repository; it supplies no participant count,
winner plan, or financial value.

Cutoff creation holds the same contest-row lock as admission while it reads the
real participant set, calculates `TralentV1PlannedWinners`, reconciles every
admission, and inserts the snapshot. Every paid admission must have exactly one
matching wallet debit and the expected Fee Wallet postings under its existing
`contest_id:user_id` admission identity, policy version, and locked fee bps.
The durable participant `joined_at` is compared with the immutable START
snapshot to prove late status. Missing, duplicate, reversed, wrong-context,
wrong-amount, or contradictory surcharge evidence fails closed.

On the first modern transition to `running`, the state-machine transaction now
updates `started_at`, verifies CONFIRMED history, inserts CONTEST_STARTED, and
only then invokes cutoff creation. A normal not-yet-due cutoff returns
`ErrSnapshotNotReady` without aborting START. A delayed start creates START and
the already-due cutoff in that same transaction; corrupt cutoff evidence rolls
back the running status and both new snapshots.

Cutoff never falls back to mutable `contests.started_at`. A modern running or
paused contest without immutable START history fails with an explicit snapshot
integrity error rather than a nullable timestamp scan error.

Per-admission rounding remains authoritative: `999` cents at `1500` bps for
three admissions is `2997` gross, `447` fee, and `2550` Prize Pool. Late
surcharge is stored separately and excluded from the Prize Pool.

FINISHED history has a composite `(settlement_id, contest_id)` foreign key.
Finalization updates a settlement only when both IDs match and requires one
affected row before completing the contest. Rankings and winner allocations are
read using both the contest ID and exact settlement ID, excluding stale result
rows from other attempts.

Free-contest confirmation semantics are intentionally unchanged: one real
participant confirms a free contest, irrespective of a larger configured
`min_participants`. Product review may change that rule only in a later policy
task.

Snapshots preserve contest truth only. Wallet, Treasury, and fee ledgers remain
money authority. This change deliberately does not create a Prize Pool account
or custody transfer; CONTEST-POOL-001 remains required and is now unblocked.

P0-FIN-06's standalone cutoff-snapshot assumption is superseded: its required
immutable cutoff fact is the `economics_cutoff` stage in this lifecycle model.

Open issue: `CONTEST-SNAPSHOT-CANCELLATION-POLICY`. Existing cancellation is
preserved, but policy is not sufficient to add a non-redundant cancellation
snapshot in this task.
