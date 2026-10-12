# Read-only local response contract

Current search/status schemas are `/2`; the Phase 3 revision at the end supersedes
the historical `/1` examples. Adapter-only errors and their exact exit/rebuild
semantics are documented in [ADAPTER.md](ADAPTER.md).

Search function: `retrieval.search(index, query, top_k=10, mode="keyword",
filters=None, advanced=False, profile=None, expected_root=None)`. Status function:
`status.index_status(index, verify_sources=False, expected_root=None)`.
The CLI equivalents are search.py and status.py. Explicit index selection is
required. Optional `--root` rejects a different repository/worktree; it never
redirects the generation to new files. UTF-8 JSON goes to stdout with `--json`.
Malformed CLI arguments also return a JSON error; help remains ordinary text.

## Versioning and successful search

`schema: cyrus.search-response/1`, `ok: true` identifies the first explicit response
schema. Existing query/mode/filters/fts_expression/results keys are retained.
`query` is the original string, never the expanded form. `advanced`, `top_k`,
`diagnostics` and `configuration_identities` make interpretation explicit.
Diagnostics contain normalized_query, original_terms, search_terms,
applied_expansions (concept, matched_alias, added_terms), expansion_bound_reached,
glossary_bypassed, fts_expression and profile. Profiles are plain and terminology.
Normalized terms and BM25 scores are heuristics, not probabilities.

`index_schema: cyrus.lexical-index/2` and `index_generation` identify the immutable
logical export. Configuration identities contain root, corpus_path/hash,
audit_path/hashes/schema, all runtime/configuration/glossary hashes, tool/extraction/
normalization versions, settings/ranking and the captured Git observation. Git
identity records provenance; it does not replace content verification.

Results retain order and explicit one-based rank. Each contains chunk_id, path,
parent_sha256, locator (decoded-character start/end offsets, start/end lines and
columns with an exclusive end column), original_text, search_text, context,
method/method_limits and text_group. Offsets are Python Unicode character offsets,
not UTF-8 byte offsets; line numbers/columns are one-based. `excerpt` is at most
600 characters and `excerpt_truncated` marks shortening. `original_text` remains
complete within the extraction bound. Consumers must use it for evidence.

`source` retains all corpus fields: role, knowledge_status/status_source, original
inventory decision/reason, navigation references, generated ownership, canonical
preferred_path and applicability snapshot/limits. `match` contains exact_path,
exact_identifier and fts_bm25 (null outside keyword mode). No version caption alone
grants applicability. `equivalent_sources` retains each duplicate path's parent
hash, locator, source metadata and matching signals; it never merges authority.

`stale: false`, `sources_checked`, `all_sources_verified: false`, verification_checks
and freshness_scope describe actual checks. Search fully rehashes only returned
and duplicate parents and compares original source slices. Successful zero matches
means `ok: true`, `results: []`, exit 0; it establishes neither absence nor abstention.
`duration_seconds` is volatile and excluded from deterministic comparisons.

## Status and integrity

Status uses `schema: cyrus.index-status/1`. A compatible response includes generation,
configuration identities, corpus_scope paths/source_count/chunk_count,
verification_checks, source_verification_requested, sources_checked,
sources_verified, all_sources_verified and source_issues. Basic mode checks no
parent contents, even when all artifact checks pass. Full mode attempts all enrolled
parents; issues have path, source_status and error. Status distinguishes missing,
changed, inaccessible and forbidden, and continues checking other parents. Any
issue gives ok=false, stale=true, rebuild_required=true and exit 3. Compatibility
can remain true while parent evidence is stale. No partial corpus is fully verified.

Both operations reject partial/failing generations and incompatible schema/runtime/
configuration/corpus identities. They verify the logical generation SHA-256,
run/logical/SQLite metadata equality, publication hashes of logical.json,
chunks.jsonl and index.sqlite3, chunk export equality, SQLite quick_check and row
counts. Status additionally compares every stored chunks and FTS text/context/path
row with the logical export. Hashing the SQLite bytes detects inverted-index
changes as well. No write-only FTS integrity command is used. Reads use mode=ro
and query_only. Links/reparse points are rejected before content access.

These checks detect corruption or accidentally mismatched local generations.
They are not signatures against coordinated edits to every locally owned receipt.
Reads are individually checked/bounded observations, not a filesystem transaction;
a concurrent writer after the final check can still change evidence. Root and
generation directories must be locally owned. No arbitrary file scan/enrollment
occurs during search or status.

## Errors and bounds

Error responses use the operation's schema and `ok: false`, error (human string),
error_type, error_details, exit_code, rebuild_required, action, stale and results=[];
status adds all_sources_verified=false on a generation-level failure and reports
checks actually completed. A partial source failure instead reports every attempted
parent and all source_issues. No citations are returned on failure.

| error_type | Exit | Meaning |
| --- | --- | --- |
| invalid_input | 2 | Invalid arguments/query/filter, explicit FTS syntax or response bound |
| incompatible_index | 2 | Unsupported schema or changed runtime/configuration/root; rebuild |
| stale_evidence | 3 | Parent evidence or reviewed corpus definition changed/unavailable |
| integrity_failure | 3 | Corrupt/mismatched generation; review and rebuild |
| io_failure | 3 | Generation inputs unreadable; restore access and retry explicitly |

Search is bounded to 1,024 query characters, 64 unique terms including additions,
top-k 1..100, three named equality filters with values up to 256 characters,
64 parents, 20,000 chunks and the unchanged extraction bounds. Glossary maximums
are eight applications/sixteen added terms with no recursive expansion. Generation
artifacts are limited to 64 MiB each; compact encoded response size is at most
4 MiB. An oversized response fails explicitly; results are not silently pruned.
The CLI prints that bounded compact JSON. Human output prints complete bounded
chunk originals. Evaluation reports are offline artifacts with separate totals,
not adapter response bodies. Search/status never rebuild, switch generations,
change hashes or execute retrieved text.
# Phase 3 response revision

Search/status response schemas are `/2`. Public configuration provenance is compact;
the complete selected-index build inventory remains addressable by artifact name
and SHA. See [ADAPTER.md](ADAPTER.md) for strict tool inputs, typed errors, actual
wire budgets, cancellation and freshness limits. Earlier `/1` examples above are
historical contracts; original text and citation fields remain unchanged.

Adapter worker I/O failure is `io_failure`, exit 3, rebuild_required=false.
Adapter-only `timeout` and `busy` use exit 3; `response_too_large` uses exit 2.
All three have rebuild_required=false and stale=false, with an explicit retry or
narrowing action. They use the requested operation's `/2` schema, `ok=false`,
`results=[]`, no citations and MCP `isError=true`, including actual wire-size
fallback. Successful zero-result searches keep `ok=true` and `isError=false`.
