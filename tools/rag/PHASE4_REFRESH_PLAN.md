# Phase 4 refresh plan (Stages A, B and C tooling delivered)

Stage A is implemented as the explicitly invoked, standard-library
`refresh_status.py` command. [REFRESH_STATUS.md](REFRESH_STATUS.md) specifies its
scope, versioned report, bounds and exit codes. It detects changes without updating
generations or bindings. No automatic scheduling or refresh is enabled. The
explicit Phase 4B command is documented in
[CANDIDATE_PREPARATION.md](CANDIDATE_PREPARATION.md). [ACTIVATION.md](ACTIVATION.md)
documents explicit read-only plans and confirmed transactional activation/rollback.
Delivery of that tooling does not authorize a real binding change.

Stage A's startup boundary now uses only detector-owned code and the standard
library. Runtime helpers are inspected as data under current deny rules; absence
or unusable code cannot prevent a versioned report. Independent checks continue
and optional derivation omissions are explicit. SQLite deadline interruption is
unavailable/incomplete verification, separately from invalid publication data.
The correction evidence is in
`_local/rag/verification/20261012-phase4a-fixes-01/HANDOFF.md`. Automatic
refresh remains unimplemented. Human semantic approval is separate from Phase 4B
mechanical validation. The historical fix's error file is `receipt_errors.json`.

The current adapter exposes only `knowledge_search` and `knowledge_status`, bound
to one absolute repository and explicit index for its lifetime. Search verifies
returned parents and duplicate provenance; full status checks all 29 enrolled
parents. Artifact/runtime checks precede either operation. Basic status does not
establish source freshness. A changed unreturned parent can therefore remain
undetected until full verification; there is no persistent freshness cache,
watcher, update tool or active-generation pointer.

## Invalidations and isolation

| Observation | Required response |
| --- | --- |
| Enrolled full-parent hash changed, including bytes outside selected ranges | Mark affected evidence stale; review meaning, hashes and ranges before replacement. |
| Enrolled path deleted, inaccessible or renamed | Block affected evidence. Distinguish deletion from incomplete inspection; byte-identical rename still requires path/ownership/locator review. Never silently substitute a nearby file. |
| Corpus definition changed | Current integrity checks reject its changed identity; prepare an explicitly reviewed versioned successor. |
| Inspection policy changed | Runtime compatibility changes; apply current deny rules before content access. Review enrollment consequences and rebuild. |
| Runtime, extraction, normalization, retrieval configuration, glossary or ranking changed | The existing runtime fingerprint invalidates compatibility; full rebuild and regression evaluation. Do not change authority/ranking as a refresh side effect. |
| Evaluation definitions or labels changed | Revalidate acceptance evidence; labels are not all runtime inputs. Version and review labels independently. |
| Project MCP registration changed | Recheck root/index/executable/allowlist and consumer activation. Registration is audit-observed configuration, not itself a runtime fingerprint input. Existing processes retain their original binding. |
| Git branch/HEAD/index or other catalog file changed | New provenance/investigation; not automatically a stale enrolled parent or permission to enroll more sources. |

Use resolved repository/worktree identity plus the explicit generation identity.
Reject cross-root candidates and reparse/link paths; do not share a freshness cache
between checkouts. Continue the current skip, metadata-only, bounded-read and
source-authority rules. An excluded or failed scan cannot prove deletion.

## A. Automatic detection and observable status

The delivered first implementation is a bounded, explicitly invoked offline
change-report command, with disposable-fixture tests. It compares the selected
generation's reviewed definitions/runtime and all enrolled parents against current
observations, without editing definitions or preparing an index. Its report can be
used by a later authorized scheduler; scheduling is not implemented.

Use content hashes, not Git cleanliness or mtime alone. Detect repeated edits to
already-dirty files, eligible untracked files already enrolled, same-size edits,
deletions and case/path changes. Discovery of other eligible files is a separate
coverage suggestion requiring enrollment review. Do not open newly forbidden
content merely to compare its old hash. Record inaccessible/policy-blocked cases
as unknown or blocked, never unchanged. Recheck file identity before/after bounded
reads; report concurrent mutation and incomplete observations without approval.

Report root, active generation, observation time/scope, completed/attempted checks,
changed paths and old/new hashes, policy/runtime/corpus identities, uncertainty and
next required decision. Separate `compatible`, `source_freshness`,
`candidate_state`, `review_state` and `consumer_binding`. A complete retained
generation can be stale. Automatic detection may report facts, never approve new
meaning. No background work or MCP write tool is required for this first step.

## B. Candidate preparation

After explicit authorization, prepare an immutable candidate in fresh directories
using a complete stable audit and a selected versioned corpus. Preserve the active
generation. Before adopting changed source bytes, review affected applicability,
knowledge status, canonical/duplicate ownership, full-parent hashes, selected
line/character ranges and evaluation labels/translations. Mechanical hash updates
are not semantic approval. Unchanged corpus members retain their reviewed scope.

The delivered `prepare_candidate.py` uses the existing full audit/build/evaluate
pipeline, two audits, two builds using the same first audit, and both profiles for
every explicit definition. It checks historical comparison, all enrolled parents
and immutable exports; no incremental extraction or cache is implemented. Runtime,
policy, extraction, schema, glossary/ranking or broad definition changes require
full rebuild/re-evaluation. Do not incrementally mutate the active SQLite database.

Bound work by existing parent/chunk/artifact/read limits, one candidate build per
root, explicit deadlines/cancellation and zero automatic retries. Invalidate an
in-flight candidate if its inputs change. Retain
failure receipts and partial directories; no uncontrolled retry loop.

## C. Review and verified activation

An explicit reviewer decides semantic acceptance and any label/enrollment changes.
Then run paired deterministic builds/evaluations, integrity checks, full source
verification and transport regressions. Record what was reviewed, by whom and
against which exact identities; mechanical verification is a separate gate.

Use the existing unique staging directory and atomic rename for complete candidate
publication. Only after successful verification and explicit activation approval
change the project server's index argument to that exact successor. Keep activation
configuration outside the generation runtime fingerprint to avoid a cycle; record
configuration before/after as distinct observations. Never claim unchanged audit
inputs across that edit. Start/reload consumers through supported user-controlled
mechanisms and inspect their actual generation/tool events. Old sessions must
report their bound generation, not imply they followed registration automatically.

Keep the previous generation and registration receipt for explicit rollback.
Rollback restores a binding, not source freshness: reverify it against current
policy/runtime/parents. A failed or interrupted build never changes the active
binding. On recovery, diagnose retained partial artifacts; retry into a new
directory. If activation was interrupted, inspect actual config and each consumer
binding before any retry. No automatic pointer or switching is proposed for the
first implementation.

## Session behavior and acceptance

When stale evidence is detected, return the existing typed error without citations;
disclose the bound generation and verification scope, request an authorized review
workflow, and use other repository evidence only within the session's scope.
Do not repair hashes, rebuild, switch silently or describe retained output as fresh.

Test changed/deleted/renamed/unreturned parents; already-dirty and eligible
untracked edits; same-mtime edits; wrong worktree; policy denial before reads;
runtime/corpus/config changes; incomplete scans and concurrent writers; candidate
interruption/cancellation; semantic-review rejection; failed verification;
atomic publication and explicit activation/rollback; stale existing sessions;
bounded work and unchanged active bytes after failure. Status receipts must expose
each gate and exact identities so detection, candidate readiness, human approval
and actual consumer activation cannot be conflated.

Stages A, B and C tooling and their tests are delivered. Stage B prepares provisional
candidates only through explicit invocation and frozen evidence/definition review.
It never switches registration or grants human approval. Stage C requires separate
authorization for each real switch and explicit review decisions; automatic refresh
remains unimplemented. Stage C plans and tests do not grant that authorization.
