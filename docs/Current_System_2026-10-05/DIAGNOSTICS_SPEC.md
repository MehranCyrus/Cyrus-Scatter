# Diagnostics and engineering records

**0.73 successor:** [current implementation](../Unified_System_0.73_2026-10-06/IMPLEMENTATION.md) preserves direct Scatter recording/export and adds bounded container movement/ownership summaries. [Matching results](../Unified_System_0.73_2026-10-06/RESULTS.md) qualify idle counters and MCP consent/lifecycle. The broader archive/training proposals below remain future work.

**0.72 delivery:** recording controls now also live directly in Scatter Modify > Diagnostics. The explicit local export is `cyrus.diagnostic-bundle/1.0`, containing stopped native event pages and script/native identities. Automation's `cyrus.diagnostic-report/1.0` format is preserved. Neither format grants sharing or training permission. See [0.72 workflow and limits](../Integrated_UI_0.72_2026-10-06/WORKFLOW.md).

**6 October implementation boundary:** the opt-in bounded native recorder, Automation-panel start/stop/export and separately consented MCP reading now have [Max 2027 runtime evidence](../Live_Runtime_2026-10-06/RESULTS.md). The broader action/batch schema, searchable archive and artist-feedback pipeline below remain design targets. The implemented default is 10 minutes / 4,096 events / 4 MiB; an engineering trace remains ineligible for training by default.

**Status: proposed extension to existing tools.** Nothing here activates a recorder or creates a telemetry service. Priority: explain IR-01 while preserving normal interaction, then support repeatable comparisons and future debugging.

The [vendor follow-up](VENDOR_RECHECK.md) adds host lifecycle and measurement contracts. Diagnostics source wiring appeared independently during that reading pass; its existence is not acceptance of this specification or evidence that a recorder was activated in the artist host.

That work also introduces native recorder/bridge files, a Python diagnostic page/export module and the 1.2.0 MCP `scatter_read_diagnostic_events` registration. Treat them as a source candidate until their own receipts qualify the final matching build. The proposals and provisional quotas below describe the broader design, not measured guarantees or a claim that this first slice already implements every field.

## What already exists

| Mechanism | Source / behavior | Gap |
| --- | --- | --- |
| Performance recorder 0.2.2 | [Monitor](../../tools/performance/CyrusPerformanceMonitor.ms): selected controller, cached layer observations, manual event notes, controlled rebuild trials, CSV/JSON manifest/results | Manually loaded; not an integrated multi-controller activity archive |
| Detailed edit trace | [Collector](../../tools/performance/CyrusEditTrace.ms), [generated hooks](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/trace.cjs): input receipt, legacy invalidation wrapper, placements and preview spans | Watched-input filtering can miss generated helpers; direct procedural invalidation, container reconciliation and render reasons are not fully instrumented |
| Resource sampler | [PowerShell sampler](../../tools/performance/Measure-CyrusProcess.ps1): separate process, CPU/private bytes/working set and file fingerprints | Whole-Max resource totals, sampled peaks; not attributable native/GPU allocation or presented FPS |
| Runtime statistics | `procStatistics`, `cacheSnapshot`, `CyrusScatterLiveBatchStats`, `CyrusPFBuilds`, retained/Brush/Analyzer counters and last errors | Several values are memory-only; no complete causal history |
| MCP journal | [Service](../../CyrusMCP/cyrus_mcp/service.py): at most 128 operation records, retry/recovery and unknown outcomes | Operational recovery history only; not all UI behavior or an ML dataset |
| Host/renderer/test logs | Listener errors, Corona log, test receipts with identities | Separate clocks/formats/scopes; no single explanation of an update |

The recorder caps a run at 30 minutes or 60,000 observation rows; detailed trace buffers have their own 100,000-row bound and loss counters. These existing bounds do not amount to a product-wide retention policy. Its controlled rebuild button intentionally changes caches; passive recording and active benchmarking must be visibly separate modes.

## Three record purposes

1. **Engineering diagnostics:** explain actions, invalidation, failures, resource use and performance. No aesthetic label inferred.
2. **Reproduction/test evidence:** pin source/binaries, input recipe/assets, fixture steps, result digests, assertions and environment. A log alone cannot reconstruct missing meshes/textures or a crash-time scene.
3. **Artist design examples:** reference/brief, exact candidate/publication, explicit accept/reject/tie/neither/correction, provenance and eligibility. This is future companion work with its own consent and lineage. A click, long session, successful render or no exception is not a positive artistic label.

Store these purposes explicitly and keep their access/retention controls distinct. Link records through IDs when authorized; do not silently promote support logs into training data.

## Artist-facing behavior to build

- **Recent activity:** concise significant events, current pending/published state and actionable errors. Basic mode keeps a bounded local memory history.
- **Record a problem / Stop:** an explicit duration-limited trace around a reproduced problem, with scope, verbosity and estimated storage shown.
- **Mark this moment:** an artist note correlated with events; its timestamp includes human reaction and is not exact input latency.
- **Export diagnostic report:** a local bundle with manifest, timeline, summary, loss/health counters and optional explicitly selected attachments. The user can inspect it before sharing.
- **History:** list/search local saved sessions by build, case, error/reason and operation. Start with structured files; a later local SQLite index is a rebuildable search aid, not a requirement for the runtime hook.

Basic history, detailed trace and controlled benchmark are separate modes. No automatic screenshot, asset upload or network collector is proposed for the first delivery. Names/paths can identify private projects; exported identifiers should default to scoped aliases, with richer attachments chosen explicitly.

## Event contract, version 1 proposal

Use append-only JSONL plus a manifest and summary. Each complete record carries the schema version and declared purpose. A partially written final line is detectable and does not invalidate earlier complete records.

| Field group | Required meaning |
| --- | --- |
| Identity | Session ID, monotonically increasing sequence, build/script/native hashes, host/renderer version in the manifest |
| Time | UTC timestamp with known offset provenance, monotonic elapsed time for local durations, producer/process and thread context. Never subtract unrelated process clocks without synchronization |
| Correlation | Operation/interaction ID, span ID, optional parent span, originating event and MCP request/journal ID where applicable |
| Scope | Controller/layer/set/source-entry IDs, publication epoch, recipe revision, receiver binding. Runtime node handles are session-local, not persistent identity |
| Action | Stable event name, origin (`artist_ui`, `host_callback`, `renderer`, `mcp`, `timer`, `test`), reason code and affected dependency |
| Outcome | Started/completed/rejected/failed/cancel-requested/cancelled/outcome-unknown; previous/new publication references, no false success from timeout |
| Measurements | Duration scope, relevant cached counters/counts, bounded byte/work estimates versus measurements, error code. Unknown values remain null/unavailable |
| Recorder health | Dropped/coalesced events, queue high-water mark, truncation, write errors, shutdown completeness and trace overhead mode |

The trace/span/time fields are informed by the [OpenTelemetry log data model](https://opentelemetry.io/docs/specs/otel/logs/data-model/), which defines event/observation timestamps and optional trace/span correlation. Cyrus's record policy and event names here are our proposal; no collector deployment or protocol compliance is claimed.

### First instrumentation slice

Proposed event families: input received; relevant/ignored dependency decision; container membership decision; input revision changed; cache reused/missed; solve admitted/limited/failed; publication staged/committed/retained; retained publication/upload; PFlow build; IR stop/start requested; observed renderer restart; operation completion; recorder loss.

Record **the reason for requesting work**, not only a counter after it happened. Record the node class and whether a node is an input, generated helper or transient render node. Preserve the first event and aggregate repeated identical events with first/last time and count; unlimited per-plant/per-frame logs would hide the useful signal.

Observe values already computed by normal execution. `procInputKey()` currently reconciles containers and watches density; a logger must not call it repeatedly as a pure getter. Existing watched-node trace filters need explicit coverage of generated helpers and direct procedural paths. Resolve metadata on the host thread; workers may serialize bounded copies only and must never dereference live Max objects.

### Callback and measurement semantics

Node events arrive in delayed batches; record batch ID, callback receipt time and any known originating operation separately. Unknown original action time remains unavailable. A dequeued event is not necessarily the first cause. Polling and delayed/mouse-up modes have different contracts. Qualify message-loop-dependent capture separately in an interactive worker and Batch. [Autodesk Node Event System](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-7C91D285-5683-4606-9F7C-B8D3A7CA508B.html).

Use owned registrations and teardown; reloading a function must also replace its registered function callback. Inspect owned handler/timer counts after repeated load, editor close, save/open/reset, cancellation and Undo/Redo. The 2027 `notificationEvent()` accessor needs a version-gated alternative for 2026. [Autodesk callbacks](https://help.autodesk.com/cloudhelp/2027/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-C1F6495F-5831-4FC8-A00C-667C5F2EAE36.html).

Record these separately: host callback/queue latency; source/key/coverage/solve/staging wall time; cache hit and rebuild counts; retained preparation and upload counts/bytes; render setup and render progress. CPU time is a separate measurement. Store inclusive spans and parent IDs; derive exclusive time only where nesting and overlap permit it. Do not sum parent and child elapsed times as independent work. GPU completion and presented-frame intervals remain unavailable unless independently instrumented. This distinction is informed by [Houdini's Performance Monitor categories](https://www.sidefx.com/docs/houdini/ref/panes/perfmon.html), not a claim that Cyrus exposes all of them.

Observe changes under their actual render phase. Do not move mesh mutation into frame callbacks to avoid an earlier notification. Keep cache validity distinct from `NotifyDependents`' required interval; blanket notification suppression is not an acceptance result. The [recheck](VENDOR_RECHECK.md) links the Autodesk contracts and existing source paths.

## Resource and failure policy

Initial engineering budgets are **proposed admission ceilings to validate**, not measured product guarantees: basic memory ring at most 8 MiB; detailed queue at most 32 MiB; individual record at most 8 KiB; detailed sessions at most 10 minutes or 100 MiB; saved history quota 1 GiB unless the user chooses less/more. Store caps in the manifest and report truncation. Preserve pinned support reports from automatic rotation; stop or rotate ordinary history visibly when its quota is reached.

Enqueue should be bounded and nonblocking. Coalesce or drop lower-priority records under pressure, with an honest loss summary. A disk failure, queue overflow or serializer exception must not fail scene publication or launch repeated modal dialogs. A crash may lose unflushed tail events; do not promise crash-proof capture. Flush/checkpoint at safe boundaries, finish pending writes under a bounded shutdown policy and mark incomplete sessions.

Before accepting a default mode, compare it off/on for idle navigation, a Brush stroke, source parking, dense solve and production/IR. Predeclare acceptable overhead from baseline variability. Collect p50/p95 interaction and stage durations, CPU and memory; do not assign a universal percentage from intuition. Verify zero logging-induced generation/upload changes. Failure-injection tests cover full disk, permissions, damaged/truncated files, overflow, worker shutdown and logger exceptions.

## IR-01 diagnostic runbook

1. Pin matching script/DLL identities and copy the scene into an isolated profile. Record camera, renderer, Manual/Live and current output before changing anything.
2. Record 30–60 seconds of untouched IR. Collect renderer restart markers, bridge phases/build count, already stored recipe/publication revisions and helper notifications.
3. Distinguish explicit bridge stop/start from renderer restarts following scene notifications. The observed rapid cadence is a clue, not proof of either origin.
4. Test one intervention at a time: editor closed/deselected, Manual/Live, bridge timer suspended after geometry preparation, preview publication suspended, selected event handlers suspended. Restore between trials. These are private diagnostics, never the final behavior.
5. Identify the first unwanted notification and trace its consequence. Treat `containerNote`, false Pending and retained publication as candidates, not established causes.
6. Reduce to a small fixture, then implement the smallest demonstrated correction in a later task. Verify real edits still update.

Acceptance: agreed idle soak progresses without unexplained resets; camera/UI browsing does not regenerate placements or upload unchanged buffers; a real Brush/source/spacing edit produces the expected bounded update and settles; Manual/Undo/save/reopen remain correct; production rendering remains valid. Resolve or classify missing asset/plugin warnings before appearance comparisons. Store pass/fail and original failures without rewriting them.

## Engineering archive and access through MCP

A saved diagnostic session should be searchable by bug/case ID, exact build, policy, renderer and reason code. Compare equivalent workloads and mark missing records. Add MCP read-only summaries and bounded trace references only after the recording path is passive and privacy-reviewed. Starting a detailed recording is an explicit scoped operation; retrieving its summary is not authority to read arbitrary logs/files.

The next loop is **D01 + R01** in [ROADMAP.md](ROADMAP.md). Historical performance tools remain useful and should be extended instead of maintaining a competing profiler.
