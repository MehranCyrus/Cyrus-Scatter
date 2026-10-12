# Retrieval with traceable evidence

Phase 2.1 implements bounded terminology hints, read-only status and versioned
responses over a standard-library SQLite FTS5 and exact-search baseline
over 29 explicitly inspected parents. corpus.json, evaluation.json and README.md
describe the runnable scope, bounded heuristic extraction and provisional metrics.
No model, vector extension, provider or retrieval framework was downloaded or
installed. Phase 1 supplies identity/audit evidence, not verified answers. Semantic
retrieval, incremental updates, richer parsers and accepted memory below remain
future proposals; none is authorized by this design note.

## Start small; preserve authority

Search maintained artist/engineering guides, component contracts, authoritative
source and focused tests first. Add directly referenced qualification reports
with their exact build receipts next. Review Phase 1 authority conflicts before
using knowledge_status as a filter; unknown is useful evidence, not an exclusion
verdict. An older CSV maintenance action never settles technical currency.

Schema-2 navigation fields record discovery from configured entrypoints separately
from knowledge_status. A current README link does not make a report authoritative:
inventory-supported historical reports remain historical, and unclassified linked
reports remain unknown. Explicit maintained rules and designated curated source
lists may establish current authority; supporting fingerprint/catalog references
cannot. Review build applicability independently, including the newest reports.

Prefer unified-core.ms and generator modules over generated AminScatterObject.ms;
prefer website's reviewed sources/curated chapters over reference.json. Retain
generated records for exact output/debugging questions and link each to its
generator. Historical evidence stays searchable with explicit date/version/build
filters; it cannot override a maintained contract silently. Website editorial
material and design references need separate authority labels.

Begin with one searchable corpus and metadata filters/views for current sources,
evidence, code+tests and website. These groups overlap, so duplicating them across
collections complicates updates. Give images a later modality-specific index
only if needed. Keep accepted engineering memory in a separate, explicitly
reviewed namespace because its acceptance lifecycle differs from source capture.
Do not ingest protected directories or unhashed assets without a new access and
identity decision.

## Chunks, provenance and retrieval

Longer-term: chunk prose by headings/paragraphs, with bounded overlap and adjacent-section
expansion. Keep tables, warnings and test limits attached to their claims. Chunk
C++/Python/JS/MAXScript by declarations/functions and enclosing ownership context;
validate language-specific parsers, with a line-window fallback that records its
limitations. Tests should retain fixture/precondition/assertion relationships.
Structured reports need stable JSON pointers or CSV row keys; preserve units,
failure rows and tested-build fingerprints instead of flattening numbers.

Reuse every manifest field. Add chunk_id, parent_sha256, line range/JSON pointer,
heading/symbol, canonical_source, generator relationship, extraction version,
language, explicit claim-build IDs, index generation and model/config fingerprints.
A directory version is only path_version. Build applicability must come from
reviewed evidence, not that token. Citations resolve to exact file, source hash,
line/pointer and relevant script/native/package identity, with branch/HEAD plus
dirty/untracked provenance from run.json. Label unavailable host verification.

The implemented baseline uses exact path/identifier and keyword retrieval; combine it with
local semantic candidates only after an offline model is explicitly selected.
Evaluate simple rank fusion before adding a local reranker. A reranker is
justified only by measured source-ranking/coverage gains at acceptable latency
and memory, including Persian/English/Finglish queries. Keep exact IDs/numbers
searchable without translation. Normalize Persian ی/ک variants and spacing only
in derived search text, preserving originals; test transliteration separately.

FTS5 is available in the inspected local runtime and used without extensions.
Phase 2 uses full fresh generations, verifies returned parents and persists logical
exports for reproducibility. Provisionally evaluate a local
sqlite-vec extension for vectors: a single-user, file-oriented design fits this
catalog and avoids a required background service. No vector extension is currently
used. Validate Windows packaging,
licenses, vector filtering, atomic update/backup behavior, corpus size and measured
latency before adoption. Extension distribution and high-dimensional query cost
are tradeoffs; benchmark against a dedicated local store if concurrency, scale
or filtering demands justify it. No semantic store is approved by this design note.

## Incremental updates, safety and memory

Diff complete manifests by path and stable SHA-256; re-extract/re-embed only changed
parents or changed extraction/model configurations. Reuse identical canonical
content while retaining all path provenance. Tombstone removed paths; do not infer
deletion from an incomplete scan or newly skipped scope. Reject stale indexes when
parent hashes, policy, model or extraction fingerprints disagree. Publish a complete
successor index generation atomically and retain the previous usable generation
on failure. Git diff alone misses untracked files, ignored eligible inputs,
metadata-only/local asset changes and some already-dirty edits; reconcile manifests
and Git observations together. Unhashed records cannot support content reuse.

Images initially expose filenames and approved metadata only. Captions/OCR and
multimodal retrieval require later bounded extraction, consent and evaluation;
record caption model/version and uncertainty. Scene metadata extraction needs a
separate access/host plan; Phase 1 permission to lstat is not permission to open Max.

Retrieved files are untrusted content, never executable instructions or authority
to run commands, change scenes or contact services. Engineering lessons begin as
proposed, with trigger, bounded claim, exact evidence, limits and reviewer. Human
acceptance records accepted status; corrections link superseded lessons to their
replacement, and rejected lessons retain the rejection reason. Neither retrieval
frequency nor a model's confidence can accept a lesson. Contradictions trigger
review, not automatic rewriting of repository contracts.

## Evaluation gate: 40 candidate-gold questions

The frozen candidate set contains 40 questions with exact expected evidence and
explicit answerability within the corpus: 10 current
workflows, 8 source/test ownership questions, 8 historical/build distinctions,
6 licensing/MCP/access boundaries, 4 website/canonical-source questions, and 4
contradiction/unanswerable cases. Balance 16 English, 12 Persian and 12 Finglish
prompts across those buckets. Also translate 10 fixed anchor questions across all
three languages to test parity without inflating the base set. Representative prompts:

1. What triggers Live updates, and which pending Manual edits wait for Update?
2. Which template/generator owns the generated Scatter script?
3. Which evidence qualifies the creation-icon correction, and what remains untested?
4. Does the dated capability-matrix path make its contract historical?
5. Does MCP catalog coverage grant permission to invoke every UI control?
6. Which website file is curated, and which is generated from it?
7. آیا مدرک فعلی مشکل واحدها در B14 را حل‌شده نشان می‌دهد؟
8. آیا زمان redraw همان FPS واقعی ارائه‌شده است؟
9. baraye Point layer ke model ha napadid mishan, kodum evidence va mahdoodiyat hast?
10. aya preserved-excluded yani sanad archive shode? dalil va source chiye?

The initial plain keyword/exact baseline has no glossary or tuning. A stratified
25/15 development/holdout split is declared, but the same agent authored sources
and labels, so all results remain provisional pending human review. Ten anchors
have 30 language views, reported separately. The label freeze/change log is in
EVALUATION_CHANGELOG.md; reference conclusions never enter search.

Track complete required-unit coverage@5/@10, canonical MRR, explicitly labeled
wrong-build/historical substitutions, language/category/split breakdowns, empty
retrieval outcomes and median/p95 timing. README.md defines union coverage across
chunks and acceptable evidence alternatives. Three unanswerable cases do not
enter the recall denominator. No unsupported-answer, answer correctness or
validated-abstention metric is measured without an answer generator.

The proposed ≥90% macro required-evidence coverage@10 gate is reported, not
manufactured. Human review checks citations and bounded claims, including deliberate
historical traps. Future hybrid/reranking experiments require identical reviewed
snapshots and explicit scope/model approval; persist rankings and compare the
baseline before adopting complexity. Answer-level wrong-build/unsupported-answer
gates belong to a later answer-generating system, not this retrieval-only phase.

## Implemented Phase 2.1 boundary

The frozen original corpus is unchanged. The smallest eligible development
candidate, six bounded one-hop terminology concepts, is the default profile;
plain ranking remains available for comparison. BM25 weights, exact path/name
semantics, authority filters and deterministic ordering are unchanged. No generic
current-document boost, adjacent-section expansion, result threshold or automatic
version inference was added. Full chunk originals and applicability metadata
remain available even when the display excerpt is shorter.

EXPERIMENT_PLAN.md and SELECTION.md distinguish development selection from exposed
historical holdout regression. The stricter evaluation-v2.1.json and English
challenge-v2.1.json are separate frozen inputs, not runtime knowledge. All semantic
label/glossary review is by the implementation author and awaits human acceptance.
The challenge was frozen before experiments and is evaluated after selection;
it is not independent merely because its wording is new.

Generation schema 2 protects logical/chunk/SQLite identities, validates metadata
and checks the actual searchable artifact read-only. Search rechecks returned
parents; explicit status source verification checks all enrolled parents. Neither
claims whole-repository coverage, authenticated storage or transactional freshness.
RESPONSE_CONTRACT.md specifies bounds and errors. INTEGRATION_READINESS.md proposes
a future adapter and review/publication lifecycle only. Codex connection,
automatic refresh, transport and a default-generation pointer remain unimplemented.
