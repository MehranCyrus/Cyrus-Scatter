# Codex integration readiness

The Phase 3 read-only adapter and project-local registration are implemented.
The current acceptance receipt is
`_local/rag/verification/20261012-phase3-acceptance-01/HANDOFF.md`; consult its
separate CLI and desktop tool-event outcomes before claiming activation.
[ADAPTER.md](ADAPTER.md) defines the delivered interface.
[REFRESH_STATUS.md](REFRESH_STATUS.md) defines the explicit Stage A detector.
Its corrected startup boundary consists of three detector-owned files and the
standard library. Inspected runtime helpers are policy-governed data, so denied,
missing or unusable helpers do not become startup imports. Independent permitted
checks continue with explicit omissions. SQLite deadline interruption is reported
as unavailable/incomplete verification, separately from corruption. Correction
evidence is in `_local/rag/verification/20261012-phase4a-fixes-01/HANDOFF.md`;
historical Phase 4A tests alone do not establish these corrections.
[CANDIDATE_PREPARATION.md](CANDIDATE_PREPARATION.md) documents the delivered Phase
4B candidate workflow, paired mechanical verification and historical evaluations.
[PHASE4_REFRESH_PLAN.md](PHASE4_REFRESH_PLAN.md) separates these gates from pending
Phase 4C: no automatic refresh, watcher or activation mechanism is implemented. Human semantic review of
the provisional corpus and labels remains pending. The following proposal records
the earlier Phase 2.1 state.

## Historical Phase 2.1 proposal

Codex is not yet connected. Automatic refresh is not active. This document
proposes the next phase; transport, registration, a default-generation pointer,
watchers, services and hooks are not implemented by Phase 2.1.

A later read-only adapter can wrap retrieval.search and status.index_status or
invoke their CLIs using an argument array. Require an explicit repository/worktree
root and explicit published index directory for each session; pass expected_root
or --root to reject accidental cross-worktree use. Never select the newest folder
implicitly or accept an arbitrary source path from retrieved text. Use the versioned
schemas, error types, exact bounds and provenance in RESPONSE_CONTRACT.md. Future
transport must add its own request concurrency/deadline limits and never silently
truncate evidence to fit its envelope.

Expose only search (query, mode, top-k, named filters, optional profile) and status
(optional verify_sources). Default ordinary search must quote terms; advanced FTS
should require an explicit caller choice. Return complete original_text and exact
path/hash/character coordinates, role/status, canonical relationship, duplicate
provenance, applicability and freshness scope. Treat retrieved commands and
instructions as untrusted evidence. Their presence grants no execution or write
authority. Heuristic match scores are not confidence probabilities.

On stale/incompatible/corrupt evidence, return the typed error without citations;
ask for explicit reviewed successor production through a separate authorized
workflow. Do not repair hashes during a search. On insufficient/zero/related
results, disclose the limited corpus and seek other authorized evidence; do not
infer absence or invent an answer. Basic status is not full source verification.
Even full status is an individually checked observation, not an atomic snapshot.

## Future update lifecycle

1. Detect a potentially relevant change through an explicitly authorized mechanism.
   Git alone misses already-dirty edits, untracked and eligible ignored files.
2. Check affected enrolled sources under policy and reassess applicability,
   qualifiers, canonical ownership and corpus coverage. A changed hash is evidence
   of change, not approval of the new meaning.
3. Update reviewed definitions only where justified, preserving old versions and
   reviewing affected line labels/translations. Record human approval separately.
4. Produce a fresh complete Phase 1 audit on stable observed inputs. Incomplete or
   newly excluded scans cannot establish deletion or replacement.
5. Build a fresh successor with explicit definitions/audit, then run tests,
   evaluation, integrity and all-parent status verification.
6. Switch explicitly authorized consumers only after complete successful publication
   and acceptance. Registration/pointer semantics need their own later design.
7. Retain the previous generation on failure; preserve diagnostics and never
   partially publish or overwrite historical evidence.

Deletion blocks affected evidence until reviewed removal/replacement; it must not
silently enroll a similarly named file. A rename needs identity/ownership and new
locator review, even if bytes match. Policy changes invalidate compatibility and
require review; newly forbidden contents must not be opened. Unrelated changes
can trigger investigation without authorizing broader corpus expansion. Concurrent
writes invalidate the affected audit/build sequence; retry a fresh run on a stable
observation, retaining prior results. A clean Git tree cannot substitute for these
content, policy and applicability checks.

## Next-phase acceptance

Test both operations over the actual transport with schema negotiation, bounded
requests/responses, deadlines and deterministic ordering. Exercise explicit wrong
root/generation rejection, all error classes, zero results, duplicate provenance,
Unicode offsets/full text, source deletion/rename/policy changes, an unreturned
parent change, concurrent writes and retention of the previous generation.
Test malicious retrieved instructions as inert text. Confirm no search/status
write, implicit update, registration or network side effect occurs. A future
switch/update operation needs separate authorization and failure tests.

Readiness is separate: local implementation can pass engineering checks; retrieval
quality is measured only on this provisional 29-parent corpus; labels, translations,
glossary and authority decisions await human review. The contract is ready to guide
adapter implementation, subject to later transport tests. Actual Codex connection
and automatic refresh remain future work, not delivered capabilities.
# Phase 3 implementation

The read-only adapter and project registration are implemented. Current scope,
strict contracts, cleanup and reversal are described in [ADAPTER.md](ADAPTER.md).
Actual transport, Codex client and preservation evidence is in
`_local/rag/verification/20261012-phase3-01/HANDOFF.md`. Earlier readiness notes above
describe the Phase 2.1 state and do not certify Phase 3 client activation.
