# Phase 4A: explicit change detection

`refresh_status.py` is a standard-library, read-only consumer of one explicitly
selected lexical-index/2 generation. It detects changes; it does **not** update
the index automatically. No enrollment, hash repair, semantic approval, candidate,
activation, MCP tool, pointer, watcher, hook or scheduled work is added.

Run from the repository root. Both root and index are required:

```powershell
py -3.11 -B tools/rag/refresh_status.py --root . --index _local/rag/indexes/20261012-phase3-acceptance-final-02
py -3.11 -B tools/rag/refresh_status.py --root . --index _local/rag/indexes/20261012-phase3-acceptance-final-02 --json
py -3.11 -B -m unittest discover -s tools/rag/refresh_tests -v
```

The only output destination is stdout. Redirect it only to a fresh, explicitly
chosen receipt using your surrounding workflow; the command creates no files.
There is no implicit active/latest generation or persistent cache. Project-local
registration and fingerprinted retrieval/adapter runtime remain unchanged.

## Publication integrity before current-input compatibility

The detector validates complete publication, supported schema, logical SHA,
run/logical metadata equality, the exact three artifact byte hashes, chunk export,
source/chunk bounds, source scope and explicit root binding. SQLite is deserialized
from the fingerprinted bytes into a query-only in-memory connection. Its metadata,
quick_check, row counts, all chunk rows and FTS text/row identities must match the
export. It uses the established locally owned receipt model, not signatures
against coordinated tampering with all artifacts.

Normalized FTS context/path derivation uses the detector's small independent
`unicode-persian/1` calculation, only when that version and the permitted current
`extract.py` hash match the recorded, explicitly supported producer SHA
`2806b4b303cf6145a2414f8766e59461756137cdf8d2900924f3304b8310b717`.
The helper is inspected as bytes; it is never executed. Otherwise that derivative
check is explicitly omitted and integrity completeness is `incomplete`; sealed
artifact fingerprints and independent row checks still run. This avoids calling
an intact historical generation corrupt merely because current normalization
code, runtime or corpus definitions changed. No retrieval, ranking or arbitrary
instructions from artifacts are executed.

Current corpus/runtime files are checked separately. A changed corpus is never
adopted as new scope. Every recorded parent is hashed, including unreturned and
duplicate-provenance parents; chunk sources must belong to that recorded scope.
Entire parents are compared even when only selected ranges were indexed. No new
files are discovered or enrolled. No repository scan or rename search occurs.

## Access and interval semantics

The startup trust boundary is exactly `refresh_status.py`, `refresh_inspect.py`
and `refresh_boundary.py`, plus the Python standard library. All three detector
files appear in `detector.implementation_sha256`; none is added to the installed
retrieval runtime fingerprint. The boundary owns the small policy-schema validator,
deny/path rules, file identity primitives, normalization calculation and worker
kill scope. Its policy and cleanup semantics match the existing contracts, with
parity regressions. No installed retrieval/adapter module is imported, loaded or
executed, directly or transitively, in either the parent CLI or its worker.

The current `tools/rag/config.toml` is a bounded bootstrap control, parsed through
the detector-owned validator using the already-read bytes. Invalid/unreadable
policy blocks dependent content checks. Current policy and ancestor/link checks
precede each parent/runtime/corpus/registration content read. Policy identity is
checked again before dependent reads; mid-run changes block later observations.
The three executing detector files are explicit implementation identity controls;
inspected retrieval helpers remain policy-governed data. A denied helper has zero
content opens and a null observed hash. A missing helper produces a `missing`
input, incompatible current runtime and exit 1 when other checks are complete.
Inaccessible helpers produce exit 2. Changed or unusable helper code is hashed as
data and reported changed with exit 1; syntax or import failures cannot run.
Independent sealed-generation, permitted parent/corpus, registration and Git
checks continue. Only the optional normalized-field derivation can depend on the
known current producer's permitted identity. No permissive fallback is used.
Explicit generation/evaluation artifacts and bounded Git staging metadata are
separate authorized evidence controls, not recursively inspected `_local`/`.git`
contents. Newly denied parents/helpers are not opened to compute hashes.

Full hashes, not Git status, size or mtime, determine byte equality. Reads check
path/handle identity, size, mtime and ctime before and after; unstable results do
not publish a current hash. A change confirmed on one parent remains reported if
another is inaccessible. Observations cover an interval, not a filesystem-wide
transaction; changes after an individual final check can occur.

Paths retain recorded spelling and use the existing case-insensitive policy and
scope keys. On ordinary Windows filesystems, case-only renames resolve to the
same path/bytes; no replacement path is guessed. On a case-sensitive volume, a
lookup that no longer resolves is `missing`. Missing means an absent recorded
lookup, not proof of deletion or a proven rename. Denied/inaccessible/unstable
lookups do not establish absence. Duplicate case-folded enrollment is invalid.
Absolute/root containment follows native Path semantics; links/reparse ancestors,
cross-root and other-worktree generations are rejected before parent access.

## JSON contract: cyrus.refresh-status/1

There is no combined healthy Boolean. These fields have independent meanings:

| Field | Meaning |
| --- | --- |
| detector | Version, all three detector-owned implementation hashes (null when unavailable), limits and their canonical configuration SHA. Inspected runtime hashes are in inputs. This consumer is not added to the retrieval runtime fingerprint. |
| repository; selected | Explicit absolute root/index and verified logical generation identity, or null if untrusted. |
| observation | UTC start/end, elapsed seconds and interval scope. These three time fields alone are volatile. |
| checks | Attempted categories, completed categories and explicit omitted/incomplete checks. Per-input rows retain details. |
| generation_integrity | valid, invalid, unsupported, wrong_root, unavailable or initial unknown; completeness and issue/reason with completed/omitted integrity checks. Valid describes the checks completed; an optional omitted derivation is disclosed separately. Invalid means internal/publication inconsistency; unavailable means access/bound/observation uncertainty. |
| current_policy | loaded or unavailable_or_invalid, plus bootstrap hash/outcome. |
| compatibility | compatible, incompatible or unknown; separate observation completeness for recorded runtime and corpus inputs. |
| source_freshness | unchanged, stale or unknown; completeness (complete, incomplete or not_checked), enrolled/attempted/completed/unchanged counts. |
| parents; inputs | Deterministically ordered paths, recorded SHA, actually observed SHA or null, outcome and bounded reason. Inputs distinguish policy/runtime/corpus. No source text is copied. |
| evaluation_definitions | Optional separately supplied baseline comparisons; never silently inferred from filenames. |
| provenance | Current branch/HEAD and bounded staging-file hash; changed branch/HEAD fields compared with build provenance. No full Git path inventory or worktree scan. |
| consumer_binding | matches, differs, absent or unknown for configured future startup; only configured root/index and config hash are reported. Running consumer generation is always unknown. |
| review_state; candidate_state | Human semantic review remains pending; candidate is not_prepared. Byte equality implies neither approval nor candidate acceptance. |
| next_actions; exit_code | Explicit operator actions and precedence below. |
| resources | Actual input-read attempts and bytes, including parent bytes. |

Per-input outcomes: `unchanged`, `changed`, `missing`, `inaccessible`,
`policy_blocked`, `policy_unknown`, `link_rejected`, `not_regular`, `size_limited`,
`unstable`, `not_checked`; evaluation receipts additionally use
`baseline_unavailable`. Changed/unchanged require stable complete full hashes.
Missing is a determinate lookup outcome; all other uncertainty outcomes count as
incomplete. A parent change or missing lookup makes freshness **stale** even with
other unknowns; otherwise any unknown makes freshness **unknown**. Only all
determinate unchanged parents produce **unchanged**. Compatibility similarly
retains confirmed mismatches while reporting independent incompleteness.

The build's catalog staging hash covers `git ls-files --stage` output; the current
bounded raw-index hash has different semantics and is explicitly not compared to
it. This limitation is reported. Unrelated working edits are not source changes;
they are not scanned. Branch/HEAD changes need provenance review without making
unchanged parent bytes stale. A registration match is not a session activation
claim; no consumer is contacted or restarted.

Generation metadata has no accepted evaluation-definition identity. By default
the report states this omission. To supply an explicit baseline (up to eight):

```powershell
py -3.11 -B tools/rag/refresh_status.py --root . --index _local/rag/indexes/20261012-phase3-acceptance-final-02 --evaluation tools/rag/evaluation-original-v3.json _local/rag/evaluations/20261012-phase3-acceptance-original-terminology-final-02/run.json --json
```

Receipts must be explicit `run.json` paths inside that root's
`_local/rag/evaluations/`, complete and bound to this generation. Their adjacent
results export hash, generation and evaluation identity must agree. The supplied
definition is compared with that recorded hash under current policy. This is an
operator-selected mechanical baseline, not evidence of independent human approval.
Invalid/missing receipts produce baseline_unavailable; no alternate is selected.

| Exit | Meaning and operator action |
| --- | --- |
| 0 | Complete determinate observation within declared scope, unchanged enrolled/runtime/corpus/evaluation inputs and no known binding/provenance mismatch. Human review and running-consumer state remain separate; optional absent baselines are explicitly disclosed. |
| 1 | Complete observation with confirmed changes/missing inputs, differing configuration binding or changed branch/HEAD. Review affected evidence, ranges, qualifiers/labels or provenance; authorize a separate candidate workflow if needed. |
| 2 | Invalid/unsupported/wrong-root publication, input/access/policy uncertainty, incomplete inspection, deadline or output bound. Resolve uncertainty and retry explicitly. Confirmed changes remain in JSON where the worker completed a report. |
| 130 | Cancellation; owned worker stopped, no update performed. |

Exit 2 takes precedence over 1, which takes precedence over 0. Thus mixed changed
and unknown parents retain stale=true meaning through `state=stale` but exit 2.
No outcome authorizes hash repair, label approval, rebuilding or switching.

## Bounds and failure behavior

At most 64 parents, 20,000 chunks, 32 recorded runtime inputs, eight evaluation
baselines, 256 input reads and 1,024 characters per recorded relative path.
The read-count allowance covers the supported 64-parent scope plus four paired
evaluation sets and their control files; byte and wall limits remain unchanged.
Artifacts are at most 64 MiB each; sources 16 MiB each and 32 MiB total; corpus
definition 32 MiB; policy/runtime/registration/receipt controls 2 MiB each. Current
policy may lower hash limits. Total read budget is 384 MiB, in chunks up to 1 MiB.
Report output is at most 256 KiB, without source text, full Git inventories or
unrelated config. An oversized complete report returns explicit
report_size_exceeded with the omitted byte count and exit 2; issues are not silently
pruned into an apparently complete report.

Checks are sequential in one transient owned worker; no persistent threads/cache,
repository recursion or uncontrolled retry. Cooperative checks use 20 seconds;
SQLite has a deadline progress handler and each of four bounded Git commands has
a two-second timeout. The public CLI independently imposes a 25-second worker wall
deadline, with up to three seconds for cleanup. Windows uses an owned kill-on-close
job established before the child start gate; POSIX uses an owned process group.
Cancellation/timeout stops only that worker scope, including its Git children.
Direct Python `inspect()` is an internal cooperative API; use the CLI for the wall
guard. If the guard cannot obtain a full report, it explicitly reports unavailable
detail rather than implying earlier checks completed. No file output is performed.

SQLite `SQLITE_INTERRUPT` with an expired reader deadline returns integrity
`unavailable`, completeness `incomplete`, issue `deadline_exceeded`, an explicit
deadline reason and exit 2. Completed integrity checks are retained and unfinished
ones listed. An interrupt without an established deadline is separately reported
as `verification_interrupted`, never corruption. SQLite resource/access errors
are unavailable; other SQL errors, corrupt database bytes and publication
inconsistencies remain invalid. An arbitrary `OperationalError` is not a timeout.
Human output prints integrity reasons and unfinished checks as well as input rows.

The three detector startup files and the Python installation must themselves be
usable to run the command; this detector cannot diagnose a broken interpreter or
its own missing startup implementation. Their reported hashes describe bounded
on-disk observations, not authenticated executing-code attestation. Repository
helpers are not part of this startup prerequisite. No optional helper execution
or dynamic import fallback exists. Policy contract evolution requires a reviewed
detector-boundary update; unknown policy schemas fail closed.

Retain a complete generation after failure, but do not describe it as fresh when
parent hashes changed. Detection is Stage A only. Candidate preparation (B),
semantic review and verified activation (C), and automatic refresh remain separate
unimplemented workflows requiring explicit authorization.
