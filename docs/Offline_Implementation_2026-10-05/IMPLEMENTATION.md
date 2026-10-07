# Offline implementation results

5 October 2026. Source candidate: Scatter **0.7.1**, MAXScript serialization **53**, MCP **1.2.0**. Work started at `addccb492a88292529594de81c287cc26e5ffe98` on `codex/floating-layer-editor-0.7.1`, with the pre-existing dirty checkout recorded separately. No Max process, computer-use tool, artist scene/profile, installer, commit or push was used in this campaign.

## Implemented and checked offline

### Bounded engineering diagnostics — D01/D02

- [Native recorder](../../AminScatter/include/diagnostics.h), [implementation](../../AminScatter/src/diagnostics.cpp), [MAXScript bridge](../../AminScatter/src/diagnostics_bridge.cpp) and [generator hooks](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/diagnostics.cjs).
- Off by default. Explicit session start; nonblocking event writes; count/byte/duration bounds; UTF-8-safe field truncation; monotonic receipt timestamps; sequence paging; eviction, lock-drop, failure and truncation counters. Stopped recordings retain their stop time; idle sessions expire without needing another event. A new start cannot erase an active session.
- Hooks cover input receipt/classification, container notification classification, density notifications, preparation reuse/start, solve start, committed/retained publication, preview install, bridge requests/completion/failure, render pre/post and explicit Corona IR start/stop requests. Hook failures are swallowed so diagnostics do not abort scene work.
- [Python validation/export](../../CyrusMCP/cyrus_mcp/diagnostics.py) assembles only one stopped session, rejects changed/corrupt/incomplete pages and writes a report atomically. Existing reports survive a failed replacement. A report states whether the retained history is complete and whether recording was lossless; those are different claims.
- The [local panel](../../CyrusMCP/cyrus_mcp/panel.py) gains Start, Stop, Save report and a separate, default-off sharing checkbox. A process-wide trace is not confined to the selected controller; the checkbox says so. Scope/session changes revoke sharing. Scene reset/close stops this panel's recording. No new background disk writer or automatic upload exists.
- `scatter_read_diagnostic_events` reads the exact locally shared session. It cannot start/stop recording or grant itself sharing. It consumes ordinary scope calls. Existing IPC busy checks still apply during rendering; record locally and inspect after the host is available.

The loaded script publishes a SHA-256 of its exact payload, excluding the fingerprint header. Build identity now includes Brush and BrushStorage modules as well as Scatter/Edit/Analyzer, and corrects the stale Automation version string. Module hashes identify loaded **files**, not a memory image; reports preserve identities at recording start and export.

**Remaining:** Max UI/lifecycle/IR validation, observer off/on overhead, batch/reentrancy/action correlation, full causality attribution, archive index/retention management and renderer-specific completion events. Receipt times do not measure user-action latency, GPU work or presented FPS.

### Container notifications — R01 candidate correction

[Source classification](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/source-containers.ms) previously dirtied every container-backed population for any node notification. It now ignores unrelated helpers and unregistered geometry outside the rectangles, while retaining registered-source, rectangle/ancestor and descendant-entry cases. Known generated Scatter/Point/PFlow helpers are excluded. Deletions remain conservative after the dispatcher's known-helper deletion filter.

The changed subtree queue is copied and capped at 512 entries per population. Overflow requests one full scan during normal reconciliation; the callback does not scan the whole scene. Full reconciliation can still scan scene geometry, so this is not a guarantee of constant total work for arbitrarily large scenes.

This removes a source-demonstrable over-invalidation path. **It does not establish the initiating cause of the reported Corona IR restarts.** The direct notification fixture and actual asynchronous callback/IR tests are separate. False Pending remains an independent runtime investigation; it was not hidden by disabling Live or forcing a solve from readers.

### Read-only procedural publication — M02 slice

- [Native adapter](../../AminScatter/src/procedural_bridge.inc) returns a fourth result containing the exact radii associated with retained rows. The solver and its first three return fields remain unchanged. Radii are selected by the solver's retained indices, not recomputed from pending source settings.
- The [publication stage](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/procedural-evaluation.ms) prepares radii and plain metadata before commit. [Passive getters](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/publication-read.ms) return a manifest and bounded pages without `procInputKey`, `validSources`, `containerRefresh`, node geometry evaluation or a solver call.
- Each successful publication has a new transient ID; a failed successor retains the preceding data. Manual pending radius/source changes do not rewrite old publication values. Old page handles fail after a new publication; reopen reconstructs a new transient ID. Instance identity is `(set_id, instance_id)`, not a row offset.
- Configuration now also copies cached active/parked/missing/placeholder source-pool rows and the reconciliation revision. If current source order no longer matches the cached node order, it reports membership/identity unavailable rather than attaching stale flags to another source. This read never reconciles the pool or tests current pivots.
- [MCP adapter/validation](../../CyrusMCP/cyrus_mcp/publication.py) exports column-vector 4×4 transforms with translation in metres, actual effective radii, layer/set/source IDs and protected/exact-output flags. Point/unassigned placeholders remain distinguishable from exact output. Cached pending flags are labelled as cached flags, not a fresh dependency comparison.
- `scatter_get_publication` supplies a five-minute manifest. `scatter_read_publication_page` is capped at 500 rows and 1,500,000 bytes, with 2,048 page attempts per scope. This read budget does not enlarge the existing two-application mutation authority. Host failures/stale attempts after paging admission consume that budget.

**Remaining:** runtime matrix/radius/count parity, Manual/Live/Undo/reopen behaviour, an independently verified complete multi-page artifact collector, and a fully reconstructable immutable recipe/asset export. Current metadata includes budgets, source identities, explicit pair rules and an opaque input-signature digest; it must not be advertised as a complete recipe. Native readers are a source candidate pending Max qualification.

`deepCopy` is used for nested plain metadata as documented by [Autodesk's array reference](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Language-Reference/Collections/Collection-Types/GUID-A5B54C67-BFDD-45C0-9D6B-E6869817282A.html). Actual MAXScript compilation and wrapper behaviour still require the private host fixture.

### MCP help and contract boundaries — M01/M03

- Twelve tools and seven resources now register through the real stdio server. The three new tools are annotated read-only.
- [Feature catalog](../../CyrusMCP/cyrus_mcp/feature-catalog.json) maps all 34 capability families and all 241 current controls. It includes artist tooltips where available. [Workflows/error help](../../CyrusMCP/cyrus_mcp/agent_help.py) describe inspection, approved existing plans, IR diagnosis and learning boundaries. Help grants no authority; native UI controls are not remotely callable by name.
- The existing closed plan 1/2 model and validator files are byte-preserved. Policy 3 cannot be overwritten or silently converted by these plans.
- [Offline draft compiler](../../CyrusMCP/cyrus_mcp/procedural_plan.py) validates `3.0-draft1`: explicit layer/set identity/order, declared inheritance, stable sampling salts, largest-remainder quotas, three rule scopes, earlier-sibling background references, nonzero applicable between-plants spacing, receiver/topology-bound Brush references, source enrollment and candidate admission. Unknown fields fail closed. It does not execute through MCP.

**Remaining:** policy-3 host authoring/approval/Undo/rollback adapter and UI/API parity; typed model-container, Brush history, Area and protected Edit authoring. These are deliberately not advertised as supported writes before the dependency gates are met.

### Offline study and preference baseline — M05/A01/A02 foundations

[Design Lab](DESIGN_LAB.md) adds a local CLI and SQLite journal for candidate recipes, immutable job/view receipts, attempt tokens, technical failures, recovery, explicit artistic comparisons and separate final decisions. It validates decoded PNGs, dimensions, content hashes and required-view joins. Changed/late/incomplete output cannot impersonate another attempt. Synthetic fixtures and non-consented data are excluded from the pairwise dataset.

A small logistic preference model uses a versioned layout feature vector, training-only normalization and project-grouped holdout. It refuses insufficient independent data, candidate/lineage leakage and stale dataset identity when scoring. Tests prove that it can learn a deliberately constructed synthetic direction; **they provide no evidence of learned artistic quality**. Models remain marked non-deployable experiments.

There is no connected Max/renderer worker, GUI review gallery, learned reference-image analysis, production style profile, online RL, provider upload or automatic scene application. The job state machine supplies the offline recovery contract for a future qualified worker. Imported `host_qualified` receipts are an explicit caller assertion, not cryptographic attestation or proof created by this library.

## Resource and compatibility accounting

| Path | Bound and practical limitation |
| --- | --- |
| Diagnostic recorder | Native maximum 16,384 events, 4 MiB accounted event/string storage, ten minutes; panel defaults to 4,096. Deque/allocator overhead is separately count-bounded, not measured RSS. |
| Diagnostic transport/export | At most 500 events; 2,500,000-byte decoded page budget accounts for JSON escaping. Report cap 16 MiB; pathological manually supplied heavily escaped records can exceed export budget and fail explicitly. No silent trimming. |
| Publication radii | One additional native MAXScript Float per accepted row plus array pointers, capped by existing one-million candidate admission. Max heap/RSS overhead is not yet measured. Candidate caches, retained Point/Mesh implementation and placement algorithms were not replaced. |
| Publication metadata | Ten populations; 1,024 source records per population. Input-key transport is guarded before crossing Python; metadata/page limits fail explicitly. |
| Container callback | Up to 512 queued changed/subtree nodes per population. Rectangle/ancestor checks and a deferred full reconciliation still have scene-dependent cost. |
| Study | At most 1,000 candidates, eight required views, three attempts, and 3,000 candidate×view×attempt combinations. One running job per journal. Artifact byte budget at most 512 MiB; bounded SQLite metadata is additional. |
| Images/features | PNG input ≤16 MiB, ≤4,096² pixels, decoded and hashed. Feature preparation ≤20,000 actual rows, linear work; no all-pairs nearest-neighbour computation. |
| Ranking | ≤10,000 comparisons, ten versioned features, bounded iterations, at least three projects; experimental CPU implementation with no host pointers. |

All Max access remains on the host UI thread. The native recorder accepts plain data and never calls the host, filesystem or renderer. Study/ranking code imports none of pymxs, Qt, MCP transport or a model provider. Max SDK compilation is not a thread-safety/runtime certificate.

## Qualification and remaining priority

See [verification receipts](evidence/verification.json), [the exact scope](evidence/source_after.json) and [the next host campaign](RUNTIME_ACCEPTANCE.md). The first Python campaign found a control-inventory test assumption (a metadata list treated as a section dictionary); the test was corrected, and the complete suite was rerun. Final counts are recorded by the collector rather than inferred from historical reports.

The next coding loop should be driven by the private Max/Corona trace: resolve demonstrated IR/false-Pending causes, verify the new passive reader and recording lifecycle, then qualify a narrow policy-3 write slice. Larger automated rendering studies and any artist-quality claims remain downstream of those gates. Licensing, artist assets and earlier evidence were preserved.
