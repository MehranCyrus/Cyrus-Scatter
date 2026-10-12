# Phase 4B candidate preparation

`prepare_candidate.py` explicitly coordinates the existing complete audit, build,
verification and evaluation pipeline. Phase 4A detects changes; Phase 4B prepares
and mechanically validates separate candidates. Human semantic review remains
pending. [Phase 4C](ACTIVATION.md) separately prepares and applies explicitly
confirmed activation/rollback plans. Automatic refresh is unimplemented.

Run with Python 3.11 and the standard library. No dependency changes are needed.
From the repository root, choose a **new** run identity and use explicit paths:

```powershell
$runId = 'my-reviewed-candidate-01'
py -3.11 -B tools/rag/prepare_candidate.py `
  --root F:/Cursor/_Cyrus_Apps/CyrusScatter `
  --baseline-index F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/indexes/20261012-phase3-acceptance-final-02 `
  --corpus F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/rag/corpus-v3.json `
  --evaluation F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/rag/evaluation-original-v3.json `
  --evaluation F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/rag/evaluation-revised-v3.json `
  --evaluation F:/Cursor/_Cyrus_Apps/CyrusScatter/tools/rag/challenge-v3.json `
  --baseline-evaluation F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/evaluations/20261012-phase3-acceptance-original-plain-final-02/run.json `
  --baseline-evaluation F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/evaluations/20261012-phase3-acceptance-original-terminology-final-02/run.json `
  --baseline-evaluation F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/evaluations/20261012-phase3-acceptance-revised-plain-final-02/run.json `
  --baseline-evaluation F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/evaluations/20261012-phase3-acceptance-revised-terminology-final-02/run.json `
  --baseline-evaluation F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/evaluations/20261012-phase3-acceptance-challenge-plain-final-02/run.json `
  --baseline-evaluation F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/evaluations/20261012-phase3-acceptance-challenge-terminology-final-02/run.json `
  --out "F:/Cursor/_Cyrus_Apps/CyrusScatter/_local/rag/candidates/$runId" `
  --run-id $runId --stage-seconds 90 --total-seconds 1800 --json
```

The command must run from the selected checkout's own coordinator. The baseline
and historical evaluations must be explicit complete artifacts in that root.
Select one to three distinct evaluation definitions, each with two historical
receipts (plain and terminology). It never chooses a newest directory implicitly.
Omit `--json` for human-readable stage outcomes and evidence location.

## Outputs and contract

JSON schema is `cyrus.candidate-preparation/1`. Exit codes are:

| Exit | Meaning |
| --- | --- |
| 0 | All requested mechanical gates passed; human review still pending. |
| 1 | Inspectable draft: semantic/label review pending or retrieval regression. |
| 2 | Blocked, failed or unavailable preparation/verification; no passing receipt. |
| 130 | Cancellation; no passing receipt. |

The final receipt distinguishes completed, failed, blocked, unavailable and omitted
stages. A preflight failure returns a framed report without creating a candidate
directory. After ownership/output creation, `receipt.json` is published exclusively
and atomically, after the final checks. An interrupted orchestration can instead
produce `interrupted-receipt.json`. `input-inventory.json`, `owner.json`, stage
`*.input.json`, `*.result.json`, `*.command.json` and captured logs have distinct
names and exclusive creation. Existing files are never replaced.

Artifacts are isolated under `_local/rag`: two `out/<run>-audit-01/02` audits,
two `indexes/<run>-candidate-01/02` generations, and four evaluations per definition
under `evaluations/<run>-dN-<profile>-01/02`. Detailed historical comparisons live
in `candidates/<run>/comparisons/`. Failed/interrupted partial directories remain.
Retry only with a new identity/destination; the command performs zero retries.

Both builds use **audit-01**, including the same path and run identity. Audit-02
establishes reproducible observations through `verify_runs.compare_runs`.
`verify_indexes.compare` checks logical/chunk/evaluation equality for each profile
pair. Raw SQLite representation and observation/query timings are volatile;
logical exports, rankings, evidence, qualifiers and metrics are not. The baseline
generation may differ solely because audit/Git provenance changed.

Each candidate is independently checked after build and again after evaluation:
sealed artifacts, SQLite integrity/metadata/all rows/FTS exports, root/runtime/
corpus compatibility, every full parent and checked identifier citations. A
successful build alone establishes no candidate readiness. Six comparisons for
the three current definitions cover the complete metrics and all question records,
including language/anchor splits, required evidence, precision, canonical ranking,
misleading/wrong-build/history evidence and related unanswerable results.
Latency comparisons are descriptive sequential measurements with uncontrolled OS
cache/background activity. Coverage is provisional retrieval evidence, not answer
accuracy or human acceptance. Representative search response sizes are recorded
by candidate verification; isolated STDIO qualification is a separate acceptance
check using the pinned adapter environment.

## Startup, policy and bounds

Startup imports only coordinator/detector-owned code and the standard library.
Required runtime files are inspected as data under the **current** policy before
any pipeline helper is executed. Three additional audit helpers have explicit
approved hashes. A manual revision may supply exact reviewed prior/successor
runtime hashes; otherwise the baseline fingerprints remain required. Coordinator
identities are recorded separately. A missing, denied, inaccessible or unreviewed
changed runtime is a blocker. No permissive import or normalization fallback is used. Verified
source bytes are compiled through a restricted runtime loader in owned workers.

Current skip/metadata-only rules apply before ordinary content access. Explicit
sealed baseline evidence and this operation's fresh artifacts have the existing
artifact access exception to `_local` skipping; this does not authorize source
enrollment there. Paths must remain inside the selected root, with no link/reparse
ancestor. Writes are restricted to fresh outputs. Windows owned kill jobs (or
POSIX owned process groups) bound child lifetimes; no global process termination
is used. Networking is denied in stage workers.

Defaults are 90 seconds per stage and 1,800 seconds total; explicit maxima are
120 and 3,600 seconds. The outer owned process also bounds preflight/checkpoints.
Each captured stream is bounded to 1 MiB; final JSON is bounded to 256 KiB.
Definitions are bounded to 2 MiB, artifacts to 64 MiB, enrolled parents to the
existing 16 MiB each/32 MiB total, with existing chunk/input/read limits retained.
Python stage file-open estimates, including guard identity re-reads, are bounded
to 2 GiB per stage and 16 GiB aggregate. These estimates do not measure SQLite C
I/O, Git subprocess I/O, or kernel cache traffic; artifact size, SQLite progress
deadlines and owned wall deadlines bound those operations independently. Stage
boundary readers additionally retain the detector's bounded read budgets.
SQLite interruption/resource uncertainty means unavailable verification; it is
distinct from proven invalid artifacts. No completed check implies an atomic
filesystem snapshot: hashes, identities and policy are individually observed and
rechecked at boundaries, including byte-restored identity changes.

`_local/rag/candidate-preparation.lock` grants one operation per resolved root.
Existing or uncertain ownership is never taken over, even if its PID appears dead.
Graceful cancellation releases only a matching owned lock. A hard timeout may
retain the lock and partial evidence. Inspect the PID/token, receipts and owned
process state before an explicitly authorized manual recovery; there is no
automatic unlock/recovery command. Internal worker flags are not a public API.

## Changed sources and provisional definitions

A sealed historical baseline can be stale. Its preserved bytes and binding are
never relabeled fresh, repaired, or searched against changed live parents to
recreate historical scores. Historical comparison uses verified saved results.
Unchanged source objects preserve their selected ranges. Metadata changes for a
byte-identical parent require the explicit provenance review described below.
The unchanged production corpus is reused for a rehearsal when appropriate.

For changed evidence, inspect the permitted diff, complete parent, selected range
and context, applicability/status, generated ownership, duplicate/canonical
relationships and affected evaluation labels. Create separately versioned corpus
and label files. Pass a separately versioned JSON `--review` with:

- `corpus`: `old_sha256`, `new_sha256`, and a substantive `reason`.
- `sources`: one entry per changed source, containing `path`, `old_sha256`,
  `new_sha256`, and `field_reasons` for **every** changed source field. Set
  `diff_inspected`, `ranges_checked`, `context_checked`, `applicability_checked`,
  `authority_checked`, `generated_ownership_checked`, and `canonical_checked` to
  true only after inspecting the evidence.
- `evaluations`: each changed definition's `old_sha256`, `new_sha256`, and `reason`.
- If a snapshot-specific reference answer note changes, `reference_conclusions`:
  exact `old_evaluation_sha256`, `group` (`base` or `anchors`), question `id`,
  `old_value`, `new_value`, `reason` and `agent_reviewed: true`. This permits only
  the unscored `reference_conclusion` note to change and exposes it in comparisons;
  questions, requirements, qualifiers, splits and answerability remain fixed.
  Automatic refresh cannot manufacture this manual review.
- For a manual corpus expansion, `enrollment`: the exact `added` paths,
  `agent_reviewed: true`, and a substantive `reason`. Each added source also needs
  a complete source review with `old_sha256: null` and reasons for every field.
- For a reviewed runtime correction, `runtime`: entries with the known helper
  `name`, exact `old_sha256`/`new_sha256`, `reason`, `diff_inspected: true` and
  `tests_reviewed: true`. This does not allow new executable names or denied reads.
- Unchanged parent bytes may receive separately reviewed provenance metadata
  updates only with `unchanged_metadata_reviewed: true` in their source entry.
  This cannot change selected ranges or promote historical/unknown authority.

These records attest agent review; booleans cannot establish semantic correctness
or human approval. This workflow rejects unreviewed expansion, removal, changes to
existing path spelling/order and historical/unknown authority promotion. Automatic
refresh has no permission to create these review attestations. Question IDs, questions,
splits, languages, qualifiers, answerability and intended evidence requirements
must stay comparable; only explicitly reviewed parent hashes/line locations may
move. Broader semantic changes need separate review/evaluation scope. Invalid
labels retain the real validation failure. Question-level differences and
regressions are saved without tuning ranking, glossary or labels to improve scores.
Any unresolved regression prevents a passing validation receipt.

A deliberately expanded manual corpus can trade earlier ranks or labeled precision
for additional qualified evidence. `retrieval_tradeoffs` in its review may record
such a decision, using schema `cyrus.retrieval-tradeoff-review/1`, exact old/new
evaluation SHA256 values, `profile`, `comparison_sha256`, `agent_reviewed: true`,
an overall `reason`, and a `regressions` array containing every exact `finding`
and its individual `reason` in recorded order. The comparison hash is over the
canonical JSON bytes returned by `compare_baseline`, before latency/review fields.
Generate and inspect the comparison before preparing that acceptance record.

The original failed strict comparison and every finding stay visible. Acceptance
is reported separately as `accepted_for_manual_candidate`; activation recomputes
it against the sealed evidence. Lost required top-ten evidence units, loss of a
previously retrieved canonical source, newly misleading evidence in either window,
and additional results for unanswerable prompts cannot be waived. Changed questions,
requirements or denominators remain disallowed. Automatic refresh never supplies
this manual review and continues to reject every strict regression.

Freeze all implementation/definition inputs before final tests and measurement.
Run the complete core, detector, adapter, policy transport and candidate tests;
exercise actual STDIO status/search against both explicit generations with the
pinned SDK. No registration switch or desktop session restart is part of this
command. The earlier Phase 4A fix's actual error record is
`_local/rag/verification/20261012-phase4a-fixes-01/receipt_errors.json`; its historical
handoff spelling is retained unchanged.

## Activation gate

Candidate preparation does not authorize a switch. Review the exact frozen corpus,
labels, authority/qualifier/canonical decisions and measured comparisons. Reverify
the selected candidate, runtime, all parents and current registration. Resolve or
explicitly review every permitted tradeoff; incomplete checks remain blocking.
[ACTIVATION.md](ACTIVATION.md) describes exact-plan operator confirmation and the
separate recorded delegation mechanism. Agent review under explicit user delegation
does not become human semantic review. Observe actual consumer generation/tool
events after a switch. [AUTOMATIC_REFRESH.md](AUTOMATIC_REFRESH.md) describes the
additional standing authorization required for bounded mechanical refresh.
