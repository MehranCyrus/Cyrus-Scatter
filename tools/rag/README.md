# Local catalog and lexical search

**Current maintenance — 21 October 2026:** maintained product guidance now follows
**Scatter 0.86.8.2 / schema 59** and its scoped Max 2024/2026/2027 delivery.
**The live knowledge index is stale; the successor is a draft, not activated.**
Use the [current handoff](../../docs/plans/source-clearance/DELIVERY_08682.md),
[artist guide](../../docs/ARTIST_GUIDE.md) and source inspection until the gates
below are resolved. The 19 October freshness statement is a historical observation.
No plugin behavior, installed profiles, package bytes or retrieval runtime changed.

The [12 October completion handoff](COMPLETION_2026-10-12.md) records the expanded
foundation corpus, measured limits, selected generation and actual consumers.
It also explains source-only sharing and the separately authorized refresh policy.

Current interface: [ADAPTER.md](ADAPTER.md), including explicit project-following
selection. Historical Phase 3 acceptance evidence, including separate CLI and
desktop connection results, is in
`_local/rag/verification/20261012-phase3-acceptance-01/HANDOFF.md`.
[REFRESH_STATUS.md](REFRESH_STATUS.md) documents the delivered, explicitly invoked
Phase 4A detector. [CANDIDATE_PREPARATION.md](CANDIDATE_PREPARATION.md) documents
Phase 4B's explicit bounded candidate command and mechanical gates.
[ACTIVATION.md](ACTIVATION.md) documents explicit activation and recovery.
[AUTOMATIC_REFRESH.md](AUTOMATIC_REFRESH.md) documents the mechanical refresh
coordinator, bounded watcher and explicit connection-owned startup. Production
enablement and final consumer acceptance are recorded separately from implementation. The
earlier [PHASE4_REFRESH_PLAN.md](PHASE4_REFRESH_PLAN.md) retains its planning scope.

Python 3.11+, Git, and the standard library are the catalog/search prerequisites.
The MCP adapter and its actual STDIO acceptance checks additionally use the pinned
isolated SDK environment described in ADAPTER.md. Phase 1 inventories
files and provenance. Phase 2.1 adds bounded terminology hints, status and versioned
responses to Phase 2's FTS5 keyword and exact lookup with
checked citations. It does not generate answers, embeddings, lessons or validated
engineering knowledge. Run from the repository root:

```powershell
py -3.11 -B -m unittest discover -s tools/rag/tests -v
py -3.11 -B tools/rag/build_manifest.py --root . --out _local/rag/out/my-audit-01
py -3.11 -B tools/rag/build_manifest.py --root . --out _local/rag/out/my-audit-02
py -3.11 -B tools/rag/verify_runs.py _local/rag/out/my-audit-01 _local/rag/out/my-audit-02
```

Use unused run names. Even an existing empty destination is rejected. `-B` avoids
Python bytecode caches beside source; temporary fixtures live under
`_local/rag/test-data/`. Tests create and commit only owned temporary Git repos,
never the real repository. No Max/plugin builds or application launches occur.

## Documentation and candidate review — 21 October 2026

The root/product entrypoints, artist/library workflow, architecture, engineering
foundation, capability help and execution ledger were reconciled with 0.86.8.2.
They now distinguish source clearance, layer-owned Point/Boundary Relax, the
schema-58 upgrade, supported textured/opacity preview and shared optional content.
The capability catalog was regenerated as help metadata; the dispatcher, plan API,
plugin script and native payloads are unchanged. The ledger's 700-line historical
library narrative was [archived](../../docs/archive/plans/real-model-library-execution-20261020.md)
with original hashes/recovery commit and verified equivalent prose/link targets.
Its obsolete pending states no longer compete with current completion status.
Separate website changes and artist assets are preserved outside this backup.

Prepared successor definitions: [corpus v22](corpus-v22.json),
[review v27](review-v27.json), [original v16](evaluation-original-v16.json),
[revised v16](evaluation-revised-v16.json), [challenge v15](challenge-v15.json),
[foundation v10](evaluation-foundation-v10.json),
[native foundation v7](evaluation-native-foundation-v7.json),
[navigation v3](evaluation-navigation-v3.json) and
[workflow v2](evaluation-workflows-v2.json). They retain prior source authority,
questions, requirements, qualifiers and denominators. Hashes/equivalent locators
follow reviewed current text; H06's unscored schema note is explicitly updated.
The historical 0.86.2 installer question points to a labeled historical paragraph,
not the 0.86.8.2 installation claim. The source set has 50 parents and 124 complete
selected sections, including both latest delivery reports. Website applicability
explicitly identifies the separate uncommitted 0.86.7 reference edition; these
hashes do not claim latest-product website parity or a published site.

Two bounded attempts are preserved:

- `20261021-docs-currency-01`: the full audit reached its 120-second stage
  deadline during verification of 18,778 files while tooling tests were running.
  It produced no candidate index. No limit was increased or bypassed.
- `20261021-docs-currency-02`: serial retry completed paired audits, builds and
  initial verification. Both indexes have generation `1e0b884cf56c4f91fe77453d2694be05dec95875ec74961ca93713a29198c4bd`.
  The original/plain suite has complete top-ten evidence for **35/37** answerable
  questions, versus **36/37** in the selected baseline. **B02**, the MCP resource
  limits question, loses required top-ten evidence and its canonical source.
  The first comparison reports 21 base/anchor rank or precision findings in total.
  Preparation stops at `retrieval_regression`; later suites/final gates are omitted.
  No ranking, evaluation requirement, resource bound or activation gate was weakened.

Tooling checks: **247/248 passed** across core, detector, pinned SDK adapter,
candidate, activation and automatic-refresh tests. The candidate test
`test_total_timeout_competing_invocation_and_abandoned_lock` fails at the missing
`interrupted-receipt.json` assertion after timeout. An isolated repeat also fails.
Its cause is not established by this documentation task. This is knowledge-tool
evidence, not a Scatter native/UI test or a new plugin regression.

The actual project-following tool still selects historical generation
`c14f3d16e81bcf39ebd488d53bcec1239b522a0de37dcc8a81738bffdcf9be3e`.
Full-source status verifies 28 of its 48 parents and reports 20 changed parents
with `stale_evidence`. No registration, refresh policy or consumer was switched
or restarted. A separate read-only CLI check of the draft verifies all 50 parent
hashes and returns current Point Relax contracts from the artist guide, architecture
and capability matrix. Exact lookup success does not resolve the failed broad
retrieval comparison. A source-only Git clone also lacks ignored indexes/receipts, and
the draft website hashes refer to preserved local work outside this commit.

Evidence is under `build/docs-currency-20261021-01/` and
`_local/rag/candidates/20261021-docs-currency-01/02/` (the latter denotes the two
separately named candidate directories). Generated checks and the feature-catalog
test pass; maintained local links, archive preservation and existing package/build
identities were checked separately. No new Max, renderer, installation or timing
qualification is claimed.

**Remaining gates:** reproduce/correct the timeout-receipt failure; review the
lost B02 evidence and remaining strict findings without dropping old obligations;
complete paired evaluation of all retained suites and actual full-contract
consumer checks; then prepare a separately verified activation under applicable
authorization. Automatic refresh cannot supply these semantic decisions.

## Historical Scatter and Physics Brush knowledge — 19 October 2026

The set activated on 19 October is [corpus v21](corpus-v21.json), [review v26](review-v26.json), [original v15](evaluation-original-v15.json), [revised v15](evaluation-revised-v15.json), [challenge v14](challenge-v14.json), [foundation v9](evaluation-foundation-v9.json), [native foundation v6](evaluation-native-foundation-v6.json), [navigation v2](evaluation-navigation-v2.json) and [current workflows v1](evaluation-workflows-v1.json). Previous source authority, frozen questions, original qualifications and historical evidence remain intact. The index now contains 48 parents and 92 complete contract sections. It adds current installation, licensing, library, navigation and ledger guidance plus explicitly reviewed standalone Physics Brush sources. Scatter is 0.86.2; Physics Lab / Brush is independently versioned 0.2.1 for Max 2027, with the applicable 0.2.0 artist workflow and older historical receipts kept distinct. This does not establish Scatter/Physics integration.

Maintained corrections cover the licensing generator and current installer route, bundled starter masks, the user's successful installer report, readable punctuation, and separate knowledge-maintenance versus paused-roadmap status. The Physics documentation now routes to the current delivery and labels the older 0.1.4 download historically. The final check of twenty current guides found 404 resolving local links. All four Scatter installer hashes, the Physics 0.2.1 MZP hash/CRC, its 70 non-document source hashes and four installer build-source hashes were checked. All 1,467 protected tracked code/tool files match the initial snapshot. No plugin/installer was modified, installed or rebuilt by this maintenance task; no new Max, physical-input or renderer qualification is claimed.

Validation: **248 tooling tests passed** (core 93, detector 36, pinned SDK adapter 23, candidate 48, activation 30, pinned SDK automatic refresh 18). Stable paired full audits, sealed builds, source/runtime checks and both retrieval profiles passed in `20261019-docs-currency-03`. The four-suite single operation reached the unchanged 16 GiB aggregate read estimate in run 02; it remains blocked evidence. Run 03 uses original/challenge/foundation in one bounded operation (11,958,424,274 estimated read bytes), with the complete revised suite separately evaluated against both exact indexes and both profiles. Its historical comparisons exactly match the reviewed findings. No suite, evidence requirement, scoring rule or resource bound was weakened.

Original/revised complete top-ten coverage remains 36/37 plain and 37/37 terminology; challenge improves from 8/10 to 9/10; foundation remains 13/17. Native foundation is 9/9 and navigation 8/8 on both profiles and paired builds. The new workflow suite is 10/11: a generic installer query returns the current delivery but misses the specifically labeled installation-guide owner in the top ten. Exact path lookup returns that guide. These are retrieval measurements, not answer-accuracy or universal-coverage claims. Twenty ranking/precision tradeoffs across the eight historical comparisons were explicitly reviewed in v26; their strict findings and reasons are preserved. No original top-ten evidence unit, previously retrieved canonical owner, new labeled misleading hit or additional unanswerable-result count was waived. Review is agent semantic review; independent human review was not performed.

Both the explicit-candidate and post-activation project-following SDK consumers returned all 92 selected sections as exact original text with correct locators, and verified all 48 full-parent hashes. The live desktop tool adopted the activated generation and independently returned the full installer, licensing and Physics artist contracts. A CyrusArrange path query returned zero results. Two initial concurrent search probes received the tool's documented busy response; explicit retries passed. Narrow exact lookups prove complete text, not complete broad-keyword recall.

Activation evidence is retained under `_local/rag/candidates/20261019-docs-currency-03/`, `_local/rag/activations/20261019-docs-currency-review-01/`, `20261019-docs-currency-plan-02/` and `20261019-docs-currency-apply-01/`. Supporting document, artifact, supplementary evaluation and actual-consumer checks are under `build/docs-currency-20261019-01/`. The first activation preparation rejected a review packet in policy-skipped `build/`; the supported activation-evidence copy passed. Earlier concurrent-edit, draft-section and read-budget failures remain preserved, never relabeled passed. Local index/receipt/build artifacts are ignored and are not included in source-only clones.

The existing refresh policy was rebased to this generation and retains **all four original evaluation suites**. A manual tick returned `unchanged`; a fresh isolated connection started the authorized watcher and shut down its own worker cleanly. The existing desktop connection already reads the new index, but its previously launched watcher still has the old authorization; it was not forcibly restarted. New connections load the new policy. A future full automatic refresh of this larger corpus may reach the unchanged aggregate read budget and require manual bounded review; the previous index is retained. This task does not claim improved background refresh capacity or a continuously running new desktop watcher. The unshipped combined-question scratch proposal was rejected because it did not fit the frozen schema. No retrieval runtime implementation was changed.

## Documentation consolidation — 18 October 2026

Six superseded plan/checkpoint narratives are [archived](../../docs/archive/README.md); two old TODO paths now route to the maintained execution ledger. The six current pages shrink from 133,010 to 20,437 bytes (84.6%); archive checks preserve all original prose outside relocated link targets. Frozen source/test/package evidence, original research manifests and unrelated active work remain preserved. Maintenance decisions are updated in the existing register rather than another dated report.

Reviewed candidate definitions: [corpus v19](corpus-v19.json), [review v23](review-v23.json), [original v14](evaluation-original-v14.json), [revised v14](evaluation-revised-v14.json), [challenge v13](challenge-v13.json), unchanged [foundation v8](evaluation-foundation-v8.json) and [native foundation v5](evaluation-native-foundation-v5.json). The [navigation regression](evaluation-navigation-v1.json) is new development evidence, not unseen holdout testing. All previous 37 sources, required evidence and authority labels are retained. The current documentation index and execution ledger are explicitly enrolled as two new current sources: 39 parents / 61 complete sections. Frozen historical sources keep their existing authority labels and historical roles/snapshot qualifiers; no promotion was performed.

Two preview builds, using one completed full audit, produced identical generation `2715982abdb0a62dab39964e70f3bdd35abb0cd3461843fa9f930a72816f5354`. Preview native-foundation queries return complete required top-ten evidence for 9/9 answerable questions on both profiles; navigation queries do so for 8/8, with paired results identical. Original/revised complete top-ten coverage stays 36/37 plain and 37/37 terminology; challenge improves 8/10 to 9/10 and foundation stays 13/17. These are retrieval results, not answer accuracy or general coverage guarantees. The two new unsupported-claim questions remain labeled unanswerable even if related sources are returned.

Full historical-comparison review remains pending: W02 canonical rank moves 1 to 2 and H02 5 to 6 (top-five loss); other improvements/precision changes are preserved in `build/docs-consolidation-20261018-01/preview-comparisons.json`. No ranking/scoring or evaluation requirement was weakened. These preview results do not constitute a passing activation packet. The direct SDK/STDIO preview consumer verified all 39 source hashes and returned all 61 complete sections as exact original text with correct locators; results are in `build/docs-consolidation-20261018-01/preview-complete-contracts.json`. This used an explicit preview index, not the live project binding. An initial relative-index invocation was rejected by the adapter; the corrected absolute-path invocation passed. Narrow exact identifier/path routing verifies complete text, not 100% general keyword coverage.

The full candidate runs `20261018-docs-consolidation-01/03/04` were stopped by snapshot checks observing concurrent independent Physics Lab changes; run 02 exposed inventory provenance drift, corrected by the separately reviewed v19/v23 successor. Failed receipts and partial audits remain under `_local/rag`. No failure is relabeled passed. That task ended with activation deferred. Those were the remaining requirements at the 18 October stop. The 19 October maintenance above completes the reviewed activation and records the current consumer/refresh-policy state. The old watcher observation `review_required` remains historical; running alone never proves an index refreshed.

## Inspection boundaries

`config.toml` contains ordered kind/component, generated-source and knowledge
rules, folder-token regexes, version observations, and inspection boundaries.
Matching is case-insensitive while original path spelling is retained. Component
and kind are independently classified; `classification_rule` records both IDs.

| Policy | Access | Hash / manifest behavior |
| --- | --- | --- |
| skip | Observe the excluded entry; do not descend or open contents | No file record; reason in exclusions.csv; target counts/sizes null |
| metadata_only | Enumerate directories and lstat files | Nullable hash; skipped_policy; catalog_only=true |
| full | Metadata plus bounded, streamed SHA-256 | 1 MiB read buffer; hash limit 64 MiB by default |

`.git/` and `_local/` are mandatory skip boundaries. Configurable skip names
include build/dist/output/temp directories, node_modules, caches, environments,
secrets/private/signing directories and key/credential filename patterns. Nested
ignore files are Git membership evidence, not inspection authorization. The
experiment scene/raw-output paths are explicitly skipped. Git-ignored ordinary
files can still be inspected. No ignored directory is traversed to count it.

`Test Scene/` is metadata-only, including every scene and texture. PSDs, native
modules, installers and archives are metadata-only by extension. Maps/textures
directories at the root and at any depth are metadata-only, including all descendant
file types. The explicit `maps/**` and `textures/**` patterns complement
`**/maps/**` and `**/textures/**`. These patterns require whole directory segments;
`roadmaps/` and `textures_backup/` do not match. Matching uses case-insensitive,
slash-normalized fnmatch: `*` can span slashes. For metadata patterns ending in
`/**`, the base pattern also matches directory entries themselves, including nested
directories; a plain file named `maps` or `textures` does not match that shortcut.
Skip rules still take precedence. Oversized full-policy candidates retain metadata,
with `hash_status=skipped_size`, `catalog_only=true` and `hash_skip_reason`.
All reparse points (including Windows junctions) and symlinks are excluded; their
targets are never traversed. Permission to inspect a link target is not inferred.

Only configured control inputs are decoded: the documentation inventory, root
README local Markdown references, configured version-observation READMEs, and the
website source manifest. These bounded provenance reads are explicit exceptions
to the scan's hash-only content handling. Other documents/images/archives are not
parsed, extracted, executed or OCRed. The source manifest's reviewed hashes are
compared with observed identities; mismatches are audit findings, not automatic
edits. There is no network code or runtime dependency installation.

## Authority, schema and artifacts

Tool 0.2.0 writes manifest schema `cyrus.file-catalog/2`, containing path, metadata,
hash/status, Git membership and worktree XY status, kind/component, folder-token
sources, original inventory evidence, derived knowledge status/source, generated
source and duplicate fields. `hash_skip_reason` adds the exact skip rationale.
Schema 2 adds navigation fields and removes navigation-driven authority promotion.
Previous schema-1 audits keep their original fields and semantics, including the
reviewed classification defect; this tool does not migrate or reinterpret them.
JSON null becomes an empty CSV cell; booleans use true/false. CSV is UTF-8 with LF
records. List-valued fields are compact JSON arrays inside CSV cells; an empty
list is `[]`, not an empty cell. `git_worktree_status="  "` means tracked and clean; a null status means
no worktree observation (including ignored files), not clean. Git membership uses
batched NUL-safe ls-files/check-ignore operations; tracked membership wins.

Inventory rows are joined by normalized relative path, without rewriting their
decisions/reasons. Duplicate rows, unsafe paths, malformed CSV and unknown
decisions are integrity errors. Every ambiguous duplicate is excluded from the
join. Missing paths appear only in inventory_audit.csv.

Derived status uses these small rules, in order:

1. Explicit config rules grounded in maintained repository/component contracts.
2. Curated `documents[]` entries only in explicitly configured
   `maintained_source_manifests`, a subset of `source_manifests`. The website's
   maintained source list is supported by website/content/README.md and
   docs/DOCUMENTATION.md. Its reviewedSourceHashes and catalog paths are supporting
   references and do not grant authority. Without designation, a source manifest's
   documents entries also provide references only.
3. Configured inventory mapping: maintained/interface → current; retained-history
   → historical. Other maintenance actions → unknown. No date-based obsolescence.
4. Unknown when there is no evidence. The archive rule requires an explicit
   docs/archives directory. Design reference packages remain unknown.

Navigation evidence is separate:

- `referenced_by_current_docs` means at least one reference was observed in the
  configured entrypoints, not that every current document was analyzed.
- `current_reference_sources` is the case-insensitively sorted, deduplicated list
  of repository-relative entrypoint paths. Source spelling is retained. Multiple
  references from the same source occupy one element; different sources accumulate.
- Observed scope is local `.md` Markdown link targets in the configured `readme`,
  plus `documents[].path`, `catalog`, and `reviewedSourceHashes` keys in configured
  source manifests. No supporting prose, imported bodies or other documents are
  scanned for links. This is bounded provenance, not a complete backlink graph.

A README link cannot promote a historical or unknown report. Inventory-supported
historical reports retain that status and their original decisions/reasons.
An unclassified report remains unknown even when it is the latest linked evidence.
Maintained-source status is also distinct from qualification for a particular build.

Conflicts between original decisions and current rules are preserved in the
audit. These are review candidates, not an autonomous semantic classification.
Path versions/dates never inherit a component's current version. Invalid or
conflicting folder tokens get a separate report; ordinary missing tokens are
aggregated. Generated mappings cite actual generators; JSON alone is no evidence
of generation. Required copies are not deletion candidates merely because their
bytes match.

Each successful directory contains manifest.jsonl, manifest.csv, summary.md,
run.json, inventory_audit.csv and errors.jsonl, plus exclusions.csv,
duplicates.json and path_token_issues.csv. Detailed listings stay in those data
files. run.json records initial/final Git state, branch/HEAD, configuration and
control/source-manifest hashes, versions and sources, tool-source hashes,
timing, applied policies and completeness. Volatile data stays out of the
deterministic artifacts.

## Integrity and exit codes

| Code | Meaning |
| --- | --- |
| 0 | Complete within the declared inspection policy; atomically published run |
| 2 | Invalid configuration/usage/prerequisites or destination |
| 3 | Incomplete scan, unreadable/unstable input, integrity or publication failure |

Progress and errors go to stderr. Open-handle identity is checked before reading;
size/mtime/ctime/device/inode are compared before/after hashing and at final
verification. Directory membership, control-input hashes and Git state are also
checked. Windows uses lstat rather than cached DirEntry identity fields.
Detected changes invalidate hashes and prevent successful publication. Diagnostics
and explicitly named manifest.partial files remain in a uniquely named hidden
`.run-name.partial-*` sibling; the requested successful directory is absent.
An interrupted process may leave this staging directory. Existing runs are never
replaced. Unwritable storage may prevent diagnostics from being saved; stderr
still reports failure.

This is an observation, not a transactional filesystem snapshot. A change after
final verification or a writer restoring all observed metadata can escape
detection. Unhashed content identity and protected-directory contents remain
unverified. Duplicate bytes describe potential content redundancy, not actual
disk savings or copying direction.

`verify_runs.py` compares deterministic artifacts and reports input/path changes
when they differ. Incompatible manifest schemas are explicitly rejected with exit
2 and are not compared as a determinism test. Old-schema runs may be compared with
each other, without changing their semantics. run.json is deliberately excluded from byte equality. A failed
comparison is not a determinism claim until inputs are checked. See [DESIGN.md](DESIGN.md)
for the longer-term proposal and provisional evaluation gate.

## Phase 2: explicit corpus and local search

[corpus.json](corpus.json) enrolls 29 inspected sources: maintained guides and
component contracts, code and tests, six build reports, and website editorial
guidance. Most files are enrolled in full. Only lines 4591–4662 of the MAXScript
template and lines 1–3 / 15442–15476 of its delivered script are extracted; their
complete parent hashes are still verified. This is a small evidence selection,
not whole-repository search. Assets, metadata-only files, excluded directories,
tooling, evaluation answers and runtime handoffs never enter this corpus.

The inventory reference is `_local/rag/out/20261012-phase1-review-fix-02`, schema
`cyrus.file-catalog/2`. Every entry keeps its original inventory decision, derived
authority, navigation provenance, role, canonical relationship and applicability.
The three authority differences and the limits of selected unknown reports are
reviewed in [CORPUS_REVIEW.md](CORPUS_REVIEW.md). This is an agent-inspected proposal,
pending human review; enrollment does not upgrade knowledge_status. In particular,
a `proposal` can be current as a maintained document without describing implemented
behavior. Historical evidence can retain unknown inventory authority.

The Python 3.11.13 / SQLite 3.50.2 runtime used here supports FTS5. Builds test it by
creating an FTS5 table. A runtime without FTS5 fails clearly; there is no automatic
installation or fallback. A future standard-library alternative could use a
bounded inverted index, but none is silently substituted.

Use fresh names for each build and evaluation:

```powershell
py -3.11 -B tools/rag/build_index.py --root . --audit _local/rag/out/my-audit-01 --out _local/rag/indexes/my-phase2-01
$ragIndex = '_local/rag/indexes/my-phase2-01'
py -3.11 -B tools/rag/search.py --index $ragIndex --query 'Manual Update pending' --top-k 5
py -3.11 -B tools/rag/search.py --index $ragIndex --query 'forRanges' --mode identifier
py -3.11 -B tools/rag/search.py --index $ragIndex --query 'docs/ARTIST_GUIDE.md' --mode path --top-k 5
py -3.11 -B tools/rag/search.py --index $ragIndex --query 'Manual Update' --status current --role maintained_guide --component docs --json
py -3.11 -B tools/rag/search.py --index $ragIndex --query 'در حالت Manual تغییرات کی با Update اعمال می‌شوند؟' --top-k 5
py -3.11 -B tools/rag/search.py --index $ragIndex --query 'dar halate Manual taghirat key ba Update emal mishan?' --top-k 5
py -3.11 -B tools/rag/evaluate.py --index $ragIndex --questions tools/rag/evaluation.json --out _local/rag/evaluations/my-phase2-01
```

`--corpus` and `--audit` can select an explicit definition and complete schema-2
audit. The default audit is the definition's initial reference. Selected files
must still match their complete audited hashes and current inspection policy.
A fresh full catalog can be generated with the Phase 1 command above. Keep the
same declared audit for comparable builds; changed inputs require a new review.

Search modes and signals:

- `keyword` splits normalized ordinary text into Unicode word tokens, quotes each
  token, and joins them with FTS5 OR. Quotes, punctuation and apparent FTS operators
  in ordinary text are data. The default `terminology` profile adds bounded,
  reported one-hop hints from [glossary-v1.json](glossary-v1.json). `--profile plain`
  preserves the original token/ranking behavior. No stop-word removal is used.
- `identifier` scans the bounded corpus for the normalized literal, with word and
  dotted-name boundaries. `0.79` does not match `0.79.5`; a sentence-ending period
  does not hide a version. Case and documented Unicode normalization still apply.
- `path` matches the whole repository-relative path, case-insensitively with
  slash/backslash equivalence. It keeps the requested path's provenance.
- Exact whole-path and identifier signals precede keyword BM25. Smaller FTS5 BM25
  scores rank first, with text/context/path weights 1/1/0.25. Ties use normalized
  path, original path, character offset and chunk ID. There are no question-specific
  ranking rules. `--advanced` explicitly passes a raw FTS5 keyword expression as a
  SQL parameter; invalid syntax returns exit 2 with a diagnostic.

`--component`, `--role` and `--status` are explicit equality filters, applied before
deduplication. A current-only search excludes historical/unknown records even when
linked from current navigation. Unknown/historical content remains available
without that filter. Equivalent normalized chunk text occupies one result, with
all other path-specific citations in `equivalent_sources`. A canonical original is
preferred only among matching identical-text candidates, based on corpus metadata.
This is not fuzzy copy detection or a general authority reranker.

Human output shows path, lines/columns, complete original chunk text, SHA-256, role/status,
component, snapshot/limits and match signals. JSON adds exact decoded-character
offsets, chunk identity, full original text, all source metadata and equivalent
citations. Top-k defaults to 10, bounded to 100. A zero-result search exits 0 and
does not prove the repository lacks an answer. Indexed instructions/commands are
untrusted text and are never executed.

## Extraction, normalization and freshness

`retrieval.toml` declares bounds: 64 sources, 16 MiB per parent, 32 MiB total,
20,000 chunks, 1,800 characters / 40 lines per chunk and up to 3 overlapping lines.
Queries are bounded to 1,024 characters and 64 distinct word tokens. Extraction
prefers Markdown headings/paragraphs and recognizable code declarations, retaining
heading/symbol context. JSON/CSV/TOML use exact line windows. Large tables,
paragraphs/functions and single lines use bounded line/character windows; some
qualification/context can cross a chunk boundary. These are heuristic boundaries,
not AST parsing or structured semantic understanding. Full expected evidence can
span multiple retrieved chunks in evaluation.

`unicode-persian/1` applies NFKC, Persian/Arabic ی/ک variants, casefolding and whitespace
collapse; zero-width separators become spaces. Original text, version/hash strings
and citation coordinates remain unchanged. Derived search text preserves dots and
slashes; ordinary keyword tokenization splits punctuation, so use exact modes for
literal identifiers, paths and versions. A few reviewed terminology hints are
explicitly configured; general translation and Finglish transliteration are absent.
Persian/Finglish prompts containing product
identifiers can match those identifiers; pure translated terminology may miss.

Each generation records corpus/audit/runtime/configuration hashes, selected parent
hashes, Git branch/HEAD/index/worktree observations, extraction/normalization
versions, Python/SQLite versions and a logical generation SHA-256. Builds verify
selected parents before extraction and before publication, then atomically rename
a fresh staging directory. Failed generations leave failure.json in a unique
hidden partial sibling and retain earlier generations. No incremental update or
deletion inference is implemented.

Every query verifies the logical generation fingerprint, all three artifact byte
hashes, chunk export equality, SQLite metadata, `quick_check` and row counts, plus
schema/tool/configuration/corpus compatibility. It then fully
rehashes returned parents and equivalent citation parents under current policy.
It also verifies original text against its source offsets. Changed/disappeared
parents return exit 3, `stale: true`, no results and a rebuild diagnostic. Re-review
changed evidence, create a fresh complete audit, update the explicit corpus and
affected evaluation labels with a change-log entry, then build a new generation.
Do not overwrite an old index. Tool/configuration incompatibility exits 2 and
requires rebuilding even if content is unchanged. Other I/O/publication failures
exit 3; invalid usage, definitions and SQL/FTS syntax exit 2. Missing FTS5 is an
explicit SQLite error, exit 2.

Freshness covers returned sources, not every unreturned source, and is not a
filesystem transaction. Excluded contents and metadata-only identities are not
validated. Protected source mutations after the final read can still escape this
observation. Runtime paths/definitions should be locally owned; this is not an
authenticated artifact store or an adversarial filesystem sandbox.

## Candidate evaluation and reproducibility

[evaluation.json](evaluation.json) contains 40 frozen base questions: 10 workflow,
8 ownership, 8 history/build, 6 boundary, 4 website and 4 contradiction/unanswerable;
16 English, 12 Persian and 12 Finglish. Three are unanswerable within this corpus.
Ten anchors have 30 language views (including their original language); these are
reported separately, not 30 independent new questions. A stratified 25 development
/ 15 holdout split is declared. The same agent selected evidence and authored
labels, so this is provisional candidate gold pending human review, not an
independent benchmark. No ranking tuning used either split in this initial release.
Initial immutable definitions and their hashes are recorded in
[EVALUATION_CHANGELOG.md](EVALUATION_CHANGELOG.md).

Labels contain required evidence units with acceptable alternatives, optional
evidence, exact source hash/line range, canonical paths, misleading substitutions,
qualifiers and reference conclusions. They are never indexed. Validation rejects
unknown parents, hash mismatches, invalid locators and evidence outside enrolled
spans. Evaluation persists labels, ranked citations, per-question judgments and
qualifiers, with timings separated from deterministic results.

Metric definitions:

- Required coverage@k is the mean, across answerable questions, of the fraction of
  required evidence units completely covered by the top-k citations. Any one
  alternative can satisfy a unit; the union of multiple chunk offsets can cover
  its full line interval. Optional evidence does not affect the denominator.
  Micro recall weights units equally; complete-query rate requires every unit.
- Source precision is the fraction of retrieved groups overlapping any required
  or optional exact-hash evidence interval. Canonical MRR uses the first primary
  canonical path with relevant overlap in top 10, with missing rank scored zero.
- Wrong-build/historical-current hits count overlap with explicitly labeled
  misleading intervals. The misleading-query rate denominator includes only
  questions with such labels (three base questions here), not every query or every
  possible authority mistake. Results alone do not establish an erroneous answer.
- Answerable empty rate excludes the three unanswerable questions. Unanswerable
  nonempty counts and contradiction results are reported directly. An empty result
  is not validated abstention. No unsupported-answer or answer-correctness metric
  is measured because there is no answer generator.

The proposed ≥90% macro required coverage@10 gate is assessed honestly; it is not
guaranteed by implementation completion. Language/category/split and anchor parity
are reported separately. Timings include a new read-only SQLite connection and
returned-parent hashing per query, sequentially in one process with generally
warm OS caches and uncontrolled background activity. Report median and nearest-rank
p95, database size, chunk count and build duration; timings are observations.

After finalizing sources and labels, build and evaluate two fresh generations
sequentially with the same audit and definitions, then compare:

```powershell
py -3.11 -B tools/rag/build_index.py --audit _local/rag/out/my-audit-01 --out _local/rag/indexes/my-phase2-02
py -3.11 -B tools/rag/evaluate.py --index _local/rag/indexes/my-phase2-02 --out _local/rag/evaluations/my-phase2-02
py -3.11 -B tools/rag/verify_indexes.py _local/rag/indexes/my-phase2-01 _local/rag/indexes/my-phase2-02 _local/rag/evaluations/my-phase2-01 _local/rag/evaluations/my-phase2-02
```

Logical exports include selected parents, chunks, originals, coordinates, metadata
and build inputs. Evaluation exports include ranked citations and deterministic
metrics. Raw SQLite bytes, timestamps and query durations are excluded from equality.
The comparison checks exported fingerprints against recorded generation identities.
The full focused unittest command at the top covers both phases, including owned
stale/changed-source and failed-publication fixtures; it never mutates product files.

The preserved Phase 2 run on 12 October 2026 (205 chunks, 1,925,120-byte SQLite file) measured
91.89% / 93.24% macro required coverage@5/@10, canonical MRR 0.8248 and no empty
answerable searches. Coverage@10 was English 92.86%, Persian 86.36%, Finglish 100%;
the boundary category reached only 66.67%. All three unanswerable prompts returned
related content. One explicitly labeled wrong-build interval appeared at rank 6;
zero labeled historical/current substitutions appeared. The ≥90% coverage target
was met provisionally; these results do not certify authority or answer correctness.
No tuning followed this run. The next bounded work is human review plus general
lexical/terminology experiments for missing qualifiers and Persian boundary terms,
measured separately before considering semantic retrieval. Final paired-run receipts,
category/language breakdowns, failures and preservation evidence live under
`_local/rag/verification/20261012-phase2-01/`.

## Phase 2.1 interface and reviewed candidates

Retrieval tool 0.2.1 publishes `cyrus.lexical-index/2`. Schema-1 generations remain
preserved evidence and are explicitly rejected by the new runtime; use the frozen
old source copy for historical reproduction. Build a fresh generation for this
runtime. Search is read-only and never updates definitions, accepts source changes,
or refreshes a generation. Exact modes and the plain profile retain baseline semantics.

The selected glossary has six source-grounded concepts, at most eight applications
and sixteen added terms, within the existing 64-term query bound. Expansion is
one hop and bypassed for exact modes and explicit advanced FTS. Alias matching
avoids identifier, path and dotted-token interiors. There are no query-ID rules,
gold-path boosts or runtime label loads. [GLOSSARY_REVIEW.md](GLOSSARY_REVIEW.md)
records the meanings and pending human review. [EXPERIMENT_PLAN.md](EXPERIMENT_PLAN.md)
predeclares two possible candidates; [SELECTION.md](SELECTION.md) records selection
of the first using development results, so the second was never run or implemented.
The BM25 weights remain 1/1/0.25. Generic words are not silently discarded.

```powershell
py -3.11 -B tools/rag/status.py --index $ragIndex --root . --json
py -3.11 -B tools/rag/status.py --index $ragIndex --root . --verify-sources --json
py -3.11 -B tools/rag/search.py --index $ragIndex --root . --query 'historical applicability' --profile plain --json
py -3.11 -B tools/rag/evaluate.py --index $ragIndex --questions tools/rag/evaluation-v2.1.json --out _local/rag/evaluations/my-revised-01
py -3.11 -B tools/rag/evaluate.py --index $ragIndex --questions tools/rag/challenge-v2.1.json --out _local/rag/evaluations/my-challenge-01
```

Basic status checks all generation artifacts plus every stored chunk/FTS row
against the exports, without claiming source freshness. `--verify-sources` also
attempts every enrolled parent under the unchanged Phase 1 policy. Missing,
changed, inaccessible and forbidden parents are separate issue types; partial
verification cannot set `all_sources_verified`. Generation incompatibility,
integrity failure and I/O failures have separate errors. Search checks returned
parents; it cannot certify unreturned parents. Neither operation is a filesystem
transaction. These hashes detect local mismatches/corruption, not a coordinated
forgery of all locally owned artifacts. See [RESPONSE_CONTRACT.md](RESPONSE_CONTRACT.md)
for schemas, limits, checks and exit codes.

The original corpus/evaluation bytes are frozen. [evaluation-v2.1.json](evaluation-v2.1.json)
contains four stricter source-grounded label corrections, with complete old/new
records in [label-review-v2.1.json](label-review-v2.1.json). Question strings,
languages and splits are unchanged. Semantic review by the implementation author
is separate from mechanical hash/locator validation; human acceptance is pending.
Original holdout results are exposed historical regression evidence. The twelve
English [challenge questions](challenge-v2.1.json) were frozen before experiments
and evaluated only after candidate selection. They are agent-authored, not an
independent benchmark. Translated anchors remain separate from base counts.

Evaluation schema 2 adds diagnostics, full text, denominators and misleading ranks;
the existing metric definitions remain version 1. Precision divides by the actual
retrieved group count within k, averaged over answerable questions; no result
pruning changes that denominator. Comparison must use the same labels and profile
inputs. Final paired audits, indexes, per-question changes, deterministic checks,
timings and preservation receipts are under
`_local/rag/verification/20261012-phase2-1-01/`. Retrieval coverage is not answer
accuracy, and related results on unanswerable questions are not validated abstention.

[INTEGRATION_READINESS.md](INTEGRATION_READINESS.md) records the Phase 2.1 proposal
for the later read-only adapter and update lifecycle. At that historical stage,
Codex connection and automatic refresh were not implemented. See the current
operating guides linked above for the subsequently implemented lifecycle.
# Phase 3 read-only adapter

See [ADAPTER.md](ADAPTER.md) for the two STDIO tools, pinned isolated environment,
project registration, explicit generation binding, response revision and reversal.
Phase 3 uses `corpus-v3.json`, `evaluation-original-v3.json`,
`evaluation-revised-v3.json` and `challenge-v3.json`; the original definitions remain
preserved. Current verification is recorded under
`_local/rag/verification/20261012-phase3-01/HANDOFF.md`.

## Explicit activation and rollback

[ACTIVATION.md](ACTIVATION.md) documents Phase 4C read-only preparation, exact
terminal confirmation, transactional index-binding changes, isolated consumer
verification and separately approved rollback. Preparation grants no consent;
automatic refresh and desktop reload are not performed by this command.
