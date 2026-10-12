# Knowledge-system completion — 12 October 2026

This is a source-only handoff for the local evidence system and its connection to
Codex. It records bounded engineering acceptance, not human semantic approval,
artist acceptance or a plugin release. The related source fixes and host witnesses
are in [the 0.79.6 foundation report](../../docs/Foundation_0.79.6_2026-10-12/README.md).

## What is available

The project has a local catalog, checked keyword/identifier/path retrieval, an MCP
adapter, freshness detection, reviewed candidate preparation, exact-plan activation
and recovery, and an explicitly authorized mechanical refresh watcher. It uses
SQLite FTS5. It does not generate answers or use embeddings/a vector database.

The expanded corpus contains **38 parents / 321 chunks**, including the twelve
engineering contracts and qualified publication/units evidence. It is a curated
subset, not access to every project file. Relevant original source still needs
inspection before consequential edits. Retrieved instructions are untrusted data.

The selected local publication is
`_local/rag/indexes/20261012-completion-final-01-candidate-01`, generation
`44bb57523e1286764c655754ce79ed3e4299bce12c0c71b7c49b212258dfa0d3`.
The paired `candidate-02` independently reproduces that generation. The final
corpus/definitions are `corpus-v7.json`, `evaluation-original-v7.json`,
`evaluation-revised-v7.json`, `challenge-v7.json`, and
`evaluation-foundation-v2.json`. Prior frozen definitions remain historical evidence.

## Measured retrieval

| Evaluation | Profile | Coverage@10 | Complete evidence | Precision@10 |
| --- | --- | --- | --- | --- |
| Original/revised legacy | Plain | 93.24% | 33/37 | 20.54% |
| Original/revised legacy | Terminology | 97.30% | 36/37 | 21.35% |
| Challenge | Both | 80% | 6/10 | 18% |
| Foundation | Both | 76.47% | 13/17 | 8.24% |

Coverage measures required evidence units, so it need not equal the fraction of
complete questions. Two foundation negatives returned related results; this system
has no validated abstention/confidence mechanism. Existing wrong-build and
unanswerable limitations remain. Labels, translations, glossary and authority
decisions are agent reviewed; human review remains pending.

Corpus expansion caused strict rank/precision regressions: 21 plain and 23
terminology findings for each legacy definition, plus one challenge finding per
profile. These 90 set/profile findings are not 90 distinct questions. They remain
visible as failed strict comparisons. `review-v7-completion.json` records exact
per-finding decisions separately. No lost required top-ten unit/canonical source,
new misleading hit in the evaluated windows or increased negative result count was
accepted. Automatic refresh cannot use these manual exceptions and rejects every
strict regression.

Foundation questions F02/F03/F05/F06 missed their complete one-shot evidence.
Separate exact contract-ID follow-ups found all four contracts within five results
in the recorded routing experiment. That is a guided workflow, not a 17/17
one-shot score. No search algorithm/glossary tuning was used to hide these gaps.

## Actual Codex consumption and efficiency

The fresh desktop validation chat `01a13155-31f2-7cf0-b78a-ce36ebf3685b` made actual
`knowledge_status(verify_sources=true)`, `forRanges` and F02 identifier calls.
All returned the selected generation; status verified 38/38 parents. Checked
citations included `execution.h` lines 30–63 and the F02 contract lines 29–40.
The desktop observed project-following selection and a running watcher whose last
observation was unchanged. Fresh CLI calls separately verified the same generation.
These are actual tool responses, not inference from registration alone.

A single paired CLI task compared direct source reading with knowledge-assisted
reading for sampling stability and failed-publication behavior:

| Reported usage | Direct | Knowledge-assisted |
| --- | --- | --- |
| Input tokens, including repeated/cached input | 248,068 | 474,672 |
| Cached input tokens | 200,192 | 414,464 |
| Uncached input tokens | 47,876 | 60,208 |
| Output tokens | 1,875 | 2,083 |
| Shell calls / MCP calls | 5 / 0 | 6 / 4 |

Both answers retained important qualifications. **This experiment did not show
token savings.** It was one prompted pair, not randomized/organic usage; startup
reading, cache conditions, verification work and repeated context differed. The
main demonstrated value is checked, selective evidence and explicit freshness,
not a measured cost or productivity gain. Avoid rereading whole startup documents
after their identities/context have already been established in a task.

## Refresh and recovery

Registration uses `--follow-project` and an exact SHA-bound local refresh policy.
The final policy is `_local/rag/refresh/20261012-completion-policy-03/policy.json`,
SHA256 `2698f3926149f08453139ec7609bbfb55582d09907aa83ec29c5aeedb5028526`.
It was renewed after the coordinator-only shutdown fix and an EOF-only cleanup
(verified identical parsed Python AST), without changing the
selected generation, adapter, source contents or retrieval definitions. A final
fresh CLI status/search verified that generation and observed its watcher running
with a completed unchanged observation. The desktop witness above precedes this
coordinator correction; the corrected lifecycle also passed actual STDIO tests.
A connection owns its watcher; no OS service or scheduled task is installed.
One process holds the root lease. Other connections can search while waiting for
the lease. Each request pins a complete selected generation. Review holds are
expected when runtime, authority, enrollment, gold evidence or ranking changes;
automatic refresh is deliberately narrower than arbitrary project changes.

The original Phase 3 publication is retained but stale/incompatible with the
corrected current sources/runtime. Do not blindly restore its configuration.
The verified paired candidate is an equivalent recovery copy; selecting it requires
a fresh activation plan and current checks. Transaction rollback/recovery was
exercised in disposable fixtures, not by restoring the stale production baseline.
Use [ACTIVATION.md](ACTIVATION.md) and inspect transaction journals before recovery.

Changing only the index selection is adopted between calls. Changing watcher
authorization/startup arguments requires a fresh connection. Existing connections
fail closed when their old policy/helper authorization no longer matches.

## Validation and evidence

The final paired candidate receipt is
`_local/rag/candidates/20261012-completion-final-01/receipt.json`: 33 successful
stages, two matching audits/indexes, twelve legacy evaluations and six paired
comparisons. Four separate foundation evaluations and both paired comparisons
also reproduce. Real SDK STDIO status/search checked both complete indexes.

Core 90, detector 36, adapter 23, candidate 45, activation 30 and final automatic
refresh 17 tests passed: **241 tests** across the relevant suites. Final automatic
suite `automatic-final-11.log` passed in146.698s. Fresh-consumer testing had exposed
a secondary watcher's buffered-stdin shutdown defect. A fresh-process regression
reproduced it before the fix and now passes with the input pipe still open. The
joinable observer closes cleanly. One intermediate lifecycle attempt suffered a
native Python crash coinciding with the optional20s diagnostic timer; that timer
was removed in favor of bounded lifecycle logging. Both the focused lifecycle and
final full suite passed. Failed attempts remain recorded, not overwritten.
The actual SDK policy-change probe correctly rejects an incompatible runtime.

Local evidence lives under `_local/completion/20261012-finish` and
`_local/rag/verification/20261012-completion-01`. It includes exact command logs,
actual desktop/CLI responses, paired usage, review packet, activation and refresh
registration receipts, preservation inventories and the delivery receipt. The
activation plan/approval lives under
`_local/rag/activations/20261012-completion-plan-02`; the applied transaction is
`20261012-completion-apply-01`. Approval records quote the user's explicit completion
delegation and state that human semantic review was not performed.

The historical global-configuration byte change remains unexplained. This work
retained the observed global configuration identity and did not silently restore
it. Preservation checks are limited to their recorded inventories.

## Source-only sharing

Share the committed branch with its source, fixtures, guidance and website assets.
Do not include `_local/`, build output, installed SDKs, environments, artist scenes,
credentials, local `.codex/config.toml`, or a machine-bound index/policy. Website
authored image originals are source inputs; `website/dist` is generated output.
Raw design archives and the standalone PSD are preserved locally, outside delivery.

A colleague can inspect/build the plugin and read AGENTS/foundation guidance without
the local knowledge database. For a new knowledge installation, follow
[README.md](README.md), [ADAPTER.md](ADAPTER.md) and the candidate/activation guides.
Audit and deliberately rebind reviewed definitions to that checkout's real root
and bytes. Targeted Git attributes preserve18 reviewed CRLF inputs whose hashes
would otherwise change during checkout; their working content was not rewritten.
Other future normalization can still change hashes. Do not copy this machine's
approvals, adjust hashes merely to make checks pass, or assume local evidence paths
exist in a clone. Machine-specific MCP registration is explicitly Git-ignored.
The staged Git export passed deterministic website import and content verification;
all99 distinct reviewed website/knowledge-parent/retrieval-runtime inputs retain
their recorded hashes in staged blobs. These checks do not install an SDK or
qualify a teammate's host environment.

Product artist/renderer/long-session acceptance, GPU/device-loss boundaries and
release packaging remain separate gates. They are not prerequisites to using this
bounded development evidence system and are not certified by its retrieval tests.
