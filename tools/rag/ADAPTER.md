# Read-only knowledge tools, Phase 3

The STDIO adapter exposes exactly `knowledge_search` and `knowledge_status`.
Without `--follow-project`, the absolute root and generation remain fixed for the
process lifetime. With that explicit option, each request pins the index currently
registered in this root's `.codex/config.toml`; changing the registration can then
be observed by an already-running connection. Invalid selections fail without a
fallback. Neither mode scans for a latest directory or rebuilds an index.

The tools never enroll files, generate answers, write repository data, start HTTP
listeners or call the network. No Max, product plugin or existing CyrusMCP
environment is involved. The separately invoked, authorized update process is
documented in [AUTOMATIC_REFRESH.md](AUTOMATIC_REFRESH.md).

## Setup and use

From `F:\Cursor\_Cyrus_Apps\CyrusScatter`, the installed isolated environment is
`_local/rag/mcp-venv`. To reproduce it on a new checkout, create a fresh environment
with `py -3.11 -m venv _local/rag/mcp-venv`, then run its interpreter with
`-m pip install -r tools/rag/adapter-requirements.lock.txt`. The official SDK and
all resolved dependencies are pinned; the standard-library retrieval CLI remains
independent. Installation may use the network; serving does not. The lock records
the Windows Python 3.11 environment and is not a cross-platform lock.

The project server launches that environment's interpreter with `-B`, the absolute
adapter path, `--root`, and `--index`, optionally followed by `--follow-project`.
Explicit connection-owned refresh additionally supplies `--refresh-policy` and
`--refresh-policy-sha256`; both bind an inspected standing authorization. Merely
following the project selection starts no updater. Status includes `selection.mode`,
`selection.request_generation` and the configured refresh process/last observation. Isolated
activation witnesses deliberately omit the follow option. Startup and client tool timeouts are both
15 seconds; the adapter deadline is 10 seconds. Tools cannot change these bindings
or submit commands or paths to arbitrary readers. `codex mcp get cyrus_knowledge
--json` inspects registration; it does not prove a working connection. OpenAI's
[MCP configuration reference](https://learn.chatgpt.com/docs/extend/mcp) documents
project config, `cwd`, timeouts and `enabled_tools`. Project configuration requires
an already trusted project. This task does not change trust or approval settings.

`knowledge_search` accepts a nonblank query of at most 1,024 characters, mode
`keyword`, `identifier`, or `path`, integer `top_k` from 1 to 10 (default 5), and
optional named filters `component`, `role`, and `knowledge_status`. Roles and status
values are enumerated in its advertised schema; component is a bounded exact
string. Strict types reject Boolean or fractional top-k. Unknown arguments,
nested filters, raw FTS and profile overrides are rejected. Selected terminology
is the existing default. The plain profile remains a CLI evaluation diagnostic.

`knowledge_status` accepts only Boolean `verify_sources` (default false). Basic
status checks all generation artifacts, definitions and searchable rows but does
not read all source parents. Full verification attempts every enrolled parent,
including unreturned, deleted and inaccessible parents. Search rehashes returned
parents and duplicate provenance on every request. Neither is a filesystem
transaction. Tool calls never repair or rebuild evidence. A separately authorized
refresh may publish a successor after its own complete validation; failures retain
the previous artifacts, which may themselves be stale relative to current source.

## Response and transport contract

Search and status schemas are now `cyrus.search-response/2` and
`cyrus.index-status/2`. The intentional change is compact
`configuration_identities`: repository, generation, corpus and runtime fingerprints,
configuration, tool/extraction/normalization versions, audit hashes and compact
build branch/HEAD/index identity remain. Full Git path inventories stay in the
selected generation's `logical.json` and `run.json`. `build_receipt` identifies
`logical.json` relative to the explicitly selected index, with its generation SHA
and a separate identities SHA. This locator does not depend on the output folder
name, preserving deterministic comparisons between two builds of the same inputs.
Offline audit/evaluation receipts retain full provenance.

Full original text, applicability/status qualifiers, rank, duplicate provenance
and hash/offset/line citations are unchanged. Structured content is authoritative;
one compatibility text block repeats the entire JSON response. The size budget
counts both copies, escaping, SDK metadata, request ID and actual JSON-RPC envelope.
The normal empty/basic-status target is 16 KiB and default-five target is 64 KiB.
An absolute 128 KiB wire limit returns a typed `response_too_large` tool error,
discarding the complete response rather than pruning results or cutting evidence.
An impossibly large protocol ID/frame terminates the connection. Input frames are
bounded to 16 KiB before SDK JSON parsing. No output-token limit is increased.

Execution failures set MCP `isError=true` and keep structured categories:
`invalid_input`, `stale_evidence`, `incompatible_index`, `integrity_failure`,
`io_failure`, `timeout`, `response_too_large`, and `busy`. Empty retrieval is a
successful response. Unknown tool dispatch is a protocol error. Cancellation uses
the protocol cancellation notification; it may have no tool response after the
client cancels. The cleanup path still kills and reaps its worker.

Adapter-generated errors preserve the requested operation's `/2` schema, return
`results=[]` without citations, and set `isError=true`. I/O failures use
`IndexIOError` (exit 3), including a failed owned worker. Invalid input uses exit
2. These categories have `rebuild_required=false` and `stale=false`; restore read
access or correct the request and retry explicitly. Adapter-only categories are:

| Category | Exit | Action (no generation rebuild required) |
| --- | --- | --- |
| timeout | 3 | Retry explicitly with a narrower query after worker cleanup. |
| busy | 3 | Wait for an active request to finish, then retry explicitly. |
| response_too_large | 2 | Narrow the query or reduce top_k; no partial evidence was returned. |

Stale evidence and incompatible/corrupt generations retain their core typed
contracts and review/rebuild requirements. Oversize fallback at the actual wire
envelope also preserves search versus status schema. A zero-result search remains
a successful tool response with no error.

At most two requests run concurrently; extra calls receive `busy` immediately.
Each request owns a fresh standard-library subprocess, with no persistent freshness
cache. Workers block for input until their kill scope exists. On Windows they use
the base interpreter (avoiding the venv redirector race) inside a kill-on-close job;
closing the job kills the worker even after forced server termination. Cancellation,
deadline and EOF use bounded cleanup, with no background threads doing retrieval.
No visible console windows are launched. Diagnostic mode writes bounded PID
lifecycle messages to stderr. Refresh diagnostics do not start native timed
thread-stack dumps. Queries and document contents are not logged.
Normal stdout is exclusively protocol traffic. Socket audit guards deny outbound
connection, DNS and bind operations in both adapter and worker after loop setup.

## Verification and client smoke

Run core tests using `py -3.11 -B -m unittest discover -s tools/rag/tests -v`.
Run transport tests with `_local/rag/mcp-venv/Scripts/python.exe -B -m unittest
discover -s tools/rag/adapter_tests -v`. They launch real processes, use the official
SDK client and inspect raw wire traffic. The precise final commands, results,
timings and preservation receipts are in
`_local/rag/verification/20261012-phase3-acceptance-01/HANDOFF.md`.

A manual fresh-session smoke in this already trusted project is: start a new
Codex session, confirm both `cyrus_knowledge` tools are available, request
`knowledge_status` with `verify_sources=true`, and search `forRanges` in identifier
mode with `top_k=1`. Inspect an actual tool event and its generation/citation;
a model's statement is not sufficient. Check the appended `Local knowledge tools`
instructions are loaded. The isolated CLI smoke's observed outcome is recorded
in the handoff, alongside the separate fresh desktop validation and any pending
activation step. CLI success does not establish desktop activation. OpenAI's
current MCP guide documents **Settings > MCP servers > Save > Restart** for
desktop reload and `/mcp` for inspection. Reload is user-controlled; do not restart
the running app automatically. Human corpus/label review and broader acceptance remain
pending. Existing challenge qualifier gaps and unanswerable related results remain.

## Explicit refresh and reversal

After a source or runtime change, review the diff and affected source identities,
create a versioned corpus/label successor when necessary, run a fresh audit, build
to a new explicit index directory, verify sources and evaluations, then deliberately
edit only this server's index argument and start a fresh session. The optional
explicitly authorized watcher is described in [AUTOMATIC_REFRESH.md](AUTOMATIC_REFRESH.md).
[REFRESH_STATUS.md](REFRESH_STATUS.md) documents the separate
explicitly invoked Phase 4A detector. [PHASE4_REFRESH_PLAN.md](PHASE4_REFRESH_PLAN.md)
describes the lifecycle. [CANDIDATE_PREPARATION.md](CANDIDATE_PREPARATION.md) and
[ACTIVATION.md](ACTIVATION.md) document explicit preparation and confirmed
activation/rollback; neither enables automatic refresh or desktop reload.
Changes to indexed `AGENTS.md` require new full-parent hashes.
The historical Phase 3 successor retained the old lines 1–37 so the added guidance was not
enrolled and its 205 chunk texts stayed unchanged. Those successor evaluation definitions
were semantically identical; none contained AGENTS citations to update. Current
expanded-corpus acceptance is recorded separately; these historical figures do
not describe a later installed generation.

To reverse registration, remove only `[mcp_servers.cyrus_knowledge]` and its fields
from `.codex/config.toml`, preserving other future blocks. Remove only the exact
appended `## Local knowledge tools` section from `AGENTS.md`; the exact appended
bytes and original hash are in `agents-append.txt` and `identity-successors.json`
under the verification directory. If unrelated edits have appeared, review the
diff rather than restoring a whole file. Preserve all old/new evidence, source
definitions and unrelated settings. Fixed-index servers stay bound until exit;
project-following servers recheck selection on each request and fail closed if
registration is removed. Changing refresh authorization requires a fresh connection
with matching startup arguments; changing the selected index does not.
