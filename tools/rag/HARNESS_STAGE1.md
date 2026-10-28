# Knowledge harness stage one

27 October 2026. Implements K01–K03 and the first K06 measurement step from the
[audit](HARNESS_AUDIT_20261027.md). This is a knowledge-consumption delivery;
plugin source, installers, other agents' interaction work, project MCP registration
and watcher policy are unchanged. No Max session, Git push or website publication
was performed.

## What changed

- [Explicit delivered facts](../../docs/KNOWLEDGE_BASELINE.json) distinguish the
  qualified 0.87.5.1 Library / Max 2027 / scene 63 / recipe 9 / Edit 3 / Interactions
  12 baseline from the observed working-tree version. The command checks those
  facts against the existing scoped qualification receipt.
- The additive `context.py` CLI consumes the existing network-denied verifier
  unchanged. Compact output removes duplicate search text/excerpts and repeated
  configuration inventory. Original source text, exact citations, hashes,
  applicability, canonical/duplicate provenance, history, errors and verification
  limits remain. Over-budget responses reject without clipped evidence.
- [Short startup routing](../../docs/AGENT_START.md), AGENTS and the project
  knowledge skill load relevant owners and contracts on demand. Detailed review
  instructions remain in a conditional skill reference. Current workflow guidance
  now uses scene 63; historical schema guards and receipts remain historical.
- A [14-parent companion](corpus-harness-core-v1.json) adds native Scene owners,
  delivered Library guidance, complete F01–F12 contracts and versioned preparation
  guides. [Source review](review-harness-core-v1.json) preserves inventory statuses
  without promoting `unknown` to current. Historical package/saving boundaries
  carry explicit supersession qualifiers.

The two Scene source owners differ from their exact 0.87.5.1 producer bytes only
in version labels; the native metadata/remap owners match exactly. This does not
qualify 0.87.5.2. Source admission is an applicability review, not another full code
audit. Instruction files and evaluation labels are not enrolled in retrieval.

## Use

```powershell
python -B tools/rag/context.py facts
python -B tools/rag/context.py status --verify-sources
python -B tools/rag/context.py search "Scene preset" --top-k 1
python -B tools/rag/context.py search "F02" --mode identifier --top-k 3
python -B tools/rag/context.py --legacy status --verify-sources
```

Global options precede the command. Full provenance uses `--detail full`;
`--max-chars` raises the default 24,000-character response budget explicitly.
See [the workflow](../../docs/KNOWLEDGE_WORKFLOW.md). No restart is required for
this CLI. The original two MCP tools retain their public schemas and full views.

The local companion selection pins generation
`5bbd7f8bc2f43f41c9ad9627c5db8571f1dca0c8fec5986a3932e8d5efe4a830`
and a hashed review receipt in `_local/rag/harness/selected.json`. It never selects
the newest directory automatically. Invalid selection or drift fails closed.
The original project generation remains
`637cdc784e7dba8eab31f2703578abc9011bd792d70fa553095aa37fd1b4613a`;
its broader enrollment is still independently stale. A companion pass establishes
freshness of its 14 parents only, not the whole repository.

## Executed evidence

Owned receipts are in
[the stage-one run](../../build/knowledge-harness-stage1-20261027-01/).

| Check | Result |
| --- | --- |
| Fresh full catalog audit | 20,863 files; complete, no errors |
| New consumer contract tests | 14 passed |
| Existing retrieval/catalog tests | 93 passed |
| Existing MCP/transport tests | 23 passed |
| Knowledge skill validation | Passed |
| Paired builds | Same generation, logical export, chunks and ranked evaluation results |
| Real isolated MCP consumer | All 14 parents verified; exact original text; text/structured copies agree |
| Complete F01–F12 source retrieval | 12/12 complete contracts, worst rank 3 |
| Existing runtime and project binding | All 23 runtime fingerprints and binding SHA unchanged |

The first audit was rejected because two helper files changed during its scan.
Its incomplete directory is retained; only the subsequent stable audit was used.
The isolated source check compares decoded original bytes, preserving CRLF rather
than Python's newline-normalized text view.

## Measured context and limits

The [12 development cases](harness-task-cases.json) run without a model API.
Full structured responses totalled **139,960 JSON characters**; compact responses
totalled **76,578**, a **45.29% reduction** with identical originals and qualifiers.
The largest single compact response was 11,244 characters. The simulated existing
MCP envelope, including its text and structured copies, totalled 287,516 characters;
actual client exposure/billing is not established by this serialization.
Median retrieval/worker time was 0.2815 seconds in one warm-session pass, not a
controlled latency improvement measurement.

All 12 cases found their expected owner first. Owner matching is weaker than
complete evidence: the separate locator/coverage evaluation found relevant exact
evidence first in **9/12**, and complete required evidence within five results in
**12/12**. F02, F04 and F10 initially rank a foundation cross-reference ahead of
the full contract. Expand to three results for these exact contract lookups.
The existing broad frozen tests and labels were not modified to obtain a pass.

The captured old startup bundle (AGENTS, README, workflow, documentation index and
knowledge skill) contains **65,425 characters**. The new AGENTS, short startup and
knowledge skill contain **14,425**, a **77.95% smaller prescribed entry footprint**.
Task-specific reading is additional in both cases. This is a document-size
comparison, not an observed token bill or guarantee about model context caching.

Next work remains the audit's contract-ranking/chunk refinement (K05), explicit
owner/authority coverage beyond this companion, and matched real agent task runs
with answer/patch review, tool calls, total tokens when available, wall time and
rework (K06). These development queries are not unseen holdout; source ranking
does not prove answer accuracy, and no model training or weight update occurred.
