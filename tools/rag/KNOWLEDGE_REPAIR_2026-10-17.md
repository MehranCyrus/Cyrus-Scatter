# Knowledge index repair — 17 October 2026

**Later status clarification:** P06 grids and P07 orientation were already
implemented. References below to “Phase 6 paused” preserve the repair task's
scope wording and mean further roadmap implementation was paused. See the
[current phase table](../../docs/plans/improvement-program/PROGRESS.md#original-phase-status)
and [subsequent documentation reconciliation](STATUS_RECONCILIATION_2026-10-17.md).

This is knowledge tooling work only. Plugin implementation, versions, installers,
artist scenes and Max sessions are unchanged. Phase 6 remains paused.

**Delivery state:** the updated index is active. The live project-following MCP
connection verified all 36 enrolled sources as fresh, with no source issues.
An independently launched STDIO consumer retrieved all 16 foundation contracts
and extension sections in full, with exact original-text/offset comparisons.
This document succeeds the [earlier foundation audit](FOUNDATION_REFRESH_2026-10-17.md),
whose stale-index observation and unactivated candidate remain historical evidence.

## Changes and boundaries

- Source retirement now requires exact old hashes, an explicit reason, retained
  historical evidence, a replacement/omission decision and reviewed dependencies.
  Missing files cannot retire themselves. Surviving source order is preserved.
  The retired `tools/foundation_validation/units.py` and `units_guards.py` are
  omitted from the active successor; their old corpus, full parent snapshots and
  qualification receipts remain intact. Unsupported migration code was not restored.
- Complete reviewed Markdown sections are returned with their conditions, limits
  and evidence. Matching still uses small bounded fragments, so a longer contract
  does not lose relevance merely because its qualifications add text. A section
  appears once; its `matched_chunk_id`/`matched_locator` identify the scoring
  fragment, while the result's main citation and `original_text` cover the whole
  section. `excerpt` is only a truncated display aid.
- Explicit sections must begin at a heading, end before its next peer heading,
  stay inside enrolled ranges, and fit 128 lines / 16,384 characters. Invalid,
  overlapping, partial or oversized sections fail instead of being silently cut.
  Full returned text is checked against the source hash and exact offsets.
- Broad keyword searches keep the best snippet from each historical report
  section. Exact identifier/path lookup is unaffected by that diversity rule.
  Historical snippets are still bounded and can be incomplete unless their section
  is explicitly enrolled as complete. The creation correction's qualification
  section is complete, preserving its native-reuse and physical-input limits.
- Mechanical refresh relocates a complete section only through one exact occurrence
  of its original full text. Changed or ambiguous conditions require manual review.
  No automatic enrollment, retirement or semantic approval was introduced.
- Candidate/activation validation now handles four paired evaluation sets, matching
  the existing automatic-refresh scope. The bounded input observation allowance is
  256 reads instead of 128; parent, byte, response and wall limits remain bounded.

The final corpus is [corpus-v12.json](corpus-v12.json): **36 surviving legacy
parents**, with **57 complete sections**, including F01–F12 and the four newer
native/performance/physics/evolution sections. It does not enroll every linked
proposal, skill or source file. The earlier 51-parent expansion was rejected;
its additional research scope displaced established answers. This successor
retains the original breadth while correcting its retired sources and context.

## Evaluation decisions, including limitations

Original definitions and sealed baseline generation
`44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3`
are unchanged. Current source locations and snapshot-specific conclusions are
explicitly reviewed in [review-v13.json](review-v13.json). A subsequent
[metadata-only review](review-v14.json) corrects seven stale applicability labels,
including foundation/backlog versions, the public roadmap’s actual review version
and current implementation/test snapshots. Prior labels are preserved as history;
source bytes, ranges, sections and all evaluation definitions remain unchanged. The old questions,
languages, splits, qualifiers, answerability and evidence-unit counts remain.

The schema-54/55 conversion question is an important exception to exact-owner
comparability: the old artist-guide alternative is retained, and the complete
current F11 contract is added as reviewed equivalent evidence. F11 explicitly
rejects earlier development schemas and preserves original scene data. The
original-owner-only trial still misses that artist-guide passage; its failed
comparison is retained. This is a reviewed evidence-owner addition, **not** an
unchanged-label win. The pipeline rejects removed units, removed old owners and
unreviewed alternatives. Automatic refresh cannot author this decision.

Current broad sets are [original v9](evaluation-original-v9.json),
[revised v9](evaluation-revised-v9.json), [challenge v8](challenge-v8.json) and
[foundation v4](evaluation-foundation-v4.json). The separate
[native foundation set](evaluation-native-foundation-v1.json) is unchanged.
These questions have informed development and regression checks; their historical
holdout labels are not evidence of a newly unseen holdout experiment.

Measured complete required evidence at top ten in the final paired evaluations:

| Set | Plain | Terminology | Scope |
| --- | ---: | ---: | --- |
| Original 40-question base | 36/37 | 37/37 | Three negative questions excluded from this denominator |
| Revised 40-question base | 36/37 | 37/37 | Same qualifications; each broad set also retains 30 multilingual anchors |
| Independent 12-question challenge | 8/10 | 8/10 | Two negative questions remain |
| Original foundation questions | 13/17 | 13/17 | Two negatives; broad F02/F03/F05/F06 queries still miss their full target |
| Native foundation questions | 9/9 | 9/9 | One negative; all required sections complete |

Actual isolated STDIO identifier checks retrieve complete **16/16** foundation
sections. Use the exact contract ID or heading when a broad question misses it;
do not count that guided follow-up as a successful original query. Related text
still appears for unsupported questions: this tool has no validated answer
confidence or abstention mechanism. Retrieval scores are not answer accuracy.

Strict historical comparisons still record earlier-rank and labeled-precision
losses, and two kinds of top-five coverage loss. They are explicitly reviewed in
eight profile-specific tradeoff records, not erased. The existing hard conditions
remain: no lost prior required top-ten unit under the recorded equivalent-owner
review, no lost canonical presence, no new labeled misleading evidence and no
additional negative-query results. Automatic refresh continues to require strict
comparisons and does not inherit permission to accept future tradeoffs.

## Reproducible evidence

Local task receipts are under `build/knowledge-repair-20261017-01/`. They include
the 5,736-file before snapshot, exact evidence-relocation review, failed and
accepted comparisons, test logs, full STDIO responses and preservation checks.
They are ignored local artifacts, not supplied by a source-only Git clone.

- Rejected expansion: `_local/rag/candidates/20261017-knowledge-repair-02/`.
- Reviewed context trials: `_local/rag/indexes/20261017-knowledge-contracts-04`
  and `_local/rag/evaluations/20261017-knowledge-contracts-04-*`.
- Contract/retirement paired coordinator: `_local/rag/candidates/20261017-knowledge-final-01/` (41 stages passed).
- Final metadata coordinator: `_local/rag/candidates/20261017-knowledge-metadata-final-01/`
  (41 stages passed; all eight profile comparisons against the first accepted
  successor passed strictly without new tradeoffs).
- Final paired index directories: `_local/rag/indexes/20261017-knowledge-metadata-final-01-candidate-01`
  and `-02`. Generation:
  `8ee0bf97078e155dccf21e1522798b7eaf04262904cd6e8cf36c71fb8479a1c9`.
- Final activation: `_local/rag/activations/20261017-knowledge-metadata-apply-01/`;
  state `configuration_switched_verified`. User-delegated agent review is recorded
  honestly; no human semantic review is claimed.
- Live and isolated consumers: `live-final-status.json` and
  `stdio-final-contracts.json` in the task receipt directory. The latter checks
  source bytes decoded with original CRLF retained, not newline-normalized text.
- Refresh policy: `_local/rag/refresh/20261017-knowledge-repair-policy-01/policy.json`;
  configuration binding receipt in
  `_local/rag/activations/20261017-knowledge-policy-binding-01/`.

## Ongoing refresh and preservation

The existing refresh authorization is rebased to this generation and these exact
helpers. Its four paired sets are revised (70 including anchors), challenge (12),
foundation (19) and native foundation (10): **111 question/anchor cases per
profile**. The revised set preserves the original queries and imposes equal or
stricter evidence requirements, verified in
`policy-evaluation-superset-final.json`. Original-set comparisons remain in the
activation receipts; their alternative-source rank/precision labels are not
duplicated in ongoing refresh. Future automatic changes still require strict
comparisons; they cannot retire sources or approve evidence-owner changes.

The active connection already follows the new index. It was not forcibly
restarted and retains its former watcher startup arguments; the new watcher
policy is configured for subsequent connections. The exact-policy tick returned
`unchanged`. An initial relative-path CLI invocation was rejected by the exact
registered-path guard, then passed using its registered absolute path. Closing
an owned test consumer interrupted its watcher and left a cancellation receipt;
a bounded explicit `--retry` cleared that test lifecycle state and completed
with `state: unchanged`, exit code 0 (`final-policy-watch.json`). Neither event
changed the selected generation. Watcher connection lifetime is distinct from
index availability; no permanent background service was installed.

Final preservation checks compare the original 5,736-file snapshot: 18 existing
files changed, all under `tools/rag/`; none are missing. All 374 snapshotted files
under the four product trees are unchanged. Existing changes outside knowledge
tooling are preserved; branch and HEAD are unchanged. New navigation links and
`git diff --check -- tools/rag` pass. See `preservation-final.json`.
Only the knowledge index and refresh-policy arguments change in the local MCP
configuration. Private transaction backups are retained, not rendered in reports.

All **248 tooling tests passed**: 93 core, 48 candidate/revision, 36 detector,
23 adapter, 30 activation and 18 automatic-refresh tests. The tests cover retirement review guards, malformed/oversized section refusal,
exact full-text citations, staleness outside the matched fragment, bounded
candidate preparation, actual STDIO, activation isolation and automatic refresh
lifecycle. They do not qualify any plugin behavior, UI, rendering or Max session.

No commit, push, product build, installer, installation, Max launch or session
restart is part of this repair.
