# Current Cyrus comparison and findings

6 October 2026. Current working-tree source is the comparison target; existing packages and the artist's installed plugin are different snapshots. No fixes were implemented during this research.

## Architectural comparison

| Concern | tyFlow evidence | Current Cyrus evidence | Decision |
| --- | --- | --- | --- |
| Product / native boundary | Native object class, PBAccessor, Qt/Max widget wrapper and Nitrous interfaces mapped from this binary | Scripted scene/UI orchestration with compiled `.dlx` calculation, native Edit/storage/display modules | A hybrid is already present. A filename extension cannot explain the observed FPS. Optimize measured work at each boundary. |
| UI lifetime | Selected popup lazy/retained; matching rollouts transferred, others destroyed | [Lazy topics and binding](../../AminScatter/tools/ui/templates/layer-editor.ms#L87), equal-list guards, stable owner-state records | Preserve lazy construction; fix retarget correctness. Investigate a bounded Qt selected-layer pilot. |
| Parameter effects | Selected PB dispatcher branches and unchanged-value guard | Generated notification/dirty hooks, shared layer defaults, cached status | Use explicit field effects and changed-field refreshes; do not solve from a view bind. |
| Time dependence | Stored intervals and override gates before heavy dispatch | [Input validity](../../AminScatter/tools/ui/templates/input-time.ms#L13), [registered callback generation](../../AminScatter/tools/ui/input-time.cjs#L41), [native controller query](../../AminScatter/src/input_validity.cpp#L15) | Preserve static reuse and real animated dependencies. Avoid treating every timeline tick as a dirty input. |
| Calculation ordering | Full private scheduler/collision policy unknown | [Ordered procedural solver](../../AminScatter/src/procedural.cpp#L24): layers/sets, stable ordinals, independent scopes | Keep the required top-to-bottom semantics. Do not import an inferred particle-simulation schedule. |
| Publication | Selected caches/intervals and display context identified; full publication protocol unknown | [Stage/commit/catch](../../AminScatter/tools/ui/templates/procedural-evaluation.ms#L138), Edit transaction and completed publication reader | Preserve coherent completed results and explicit pending/failure states. Do not claim renderer/GPU atomicity from CPU staging. |
| Viewport | Confirmed custom render items and instanced mesh contexts; exact upload policy unknown | [Retained Point/Mesh items](../../AminScatter/src/point_display.cpp#L229), guarded Realize and immutable snapshots | Retained display is a shared architectural strength. Measure submission, realization, upload and draw separately. |
| Proxy | No comparable tyFlow Proxy path benchmarked | [Cached proxy batches](../../AminScatter/src/preview.cpp#L51), but `gw->triangle` remains per redraw | A distinct CPU submission cost can remain after placement caching. Evaluate retained proxy rendering after measurement. |
| Workers | Documented CPU controls; private pool/locks not recovered | [Joined numeric workers](../../AminScatter/include/execution.h#L31); [thread limit](../../AminScatter/src/execution.cpp#L11) | Keep host calls on the Max thread. Consider a pool only if thread-launch cost is material. |
| Diagnostics | Vendor documents simulation/upload/reset profiling; private recorder implementation unknown | [Bounded native recorder](../../AminScatter/src/diagnostics.cpp#L33), [passive hooks](../../AminScatter/tools/ui/diagnostics.cjs#L5) | Expose it directly in Scatter and make invalidation causes visible. |

## Solid foundations to preserve

The native solver validates unique layer/set/instance identities, finite positions/radii, rules and work limits before evaluation. It keeps ordinal order and distinct self, sibling-set and layer-pair rules. Ordinary acceptance and protected artist edits have explicit behavior. Cleanup and refill are bounded; impossible accepted targets report a shortfall instead of silently searching forever. Current limits include ten layers/ten total populations, one million admitted candidates, 100,000 per-set budget/attempt limit, sixteen repair rounds and fifty million neighbor visits. These are hard admission/work contracts, not promises of interactive timing. [procedural.cpp](../../AminScatter/src/procedural.cpp#L24).

The script stages accepted rows, statistics, radii, preview state and publication information before committing the Edit transaction and completed epoch. A failure invalidates preparation/binding keys and retains the previous completed state in the supported failure path. This is a valuable host-side transaction design. Allocation/device failures during later retained realization and renderer callbacks have separate handling/qualification needs. [procedural-evaluation.ms](../../AminScatter/tools/ui/templates/procedural-evaluation.ms#L163).

Source containers admit/park registered source rows; persistent rows own saved settings. That is compatible with keeping an asset's identity/settings when it moves out of a rectangle and returns. Retargeting its UI must not confuse the source catalog with a transient filtered list. The current implementation uses bounded ordinary Rectangle splines, not arbitrary newly generated scattering surfaces. [source-containers.ms](../../AminScatter/tools/ui/templates/source-containers.ms#L1).

Retained Point Cloud/Mesh snapshots and buffers already exist. Same snapshot/color identities reuse generations; preparation only rebuilds dirty items; realization initializes buffers under a ready/failure guard. The current matching predicate accepts an unchanged submitted generation while retaining enabled/failure/identity checks. This accommodates culled groups without demanding that every group be GPU-ready. [publish/match](../../AminScatter/src/point_display.cpp#L261), [Mesh realization](../../AminScatter/src/mesh_display.inc#L50).

Point reservations are 64 MiB per owner / 128 MiB process; Mesh reservations are 512 MiB per owner / 1 GiB process, with 1,024 groups admitted. Proxy batch reservations are 16 MiB per cache / 64 MiB process. They bound those reservations and groups, not all source/working/SDK/GPU memory or process RSS. [Point/Mesh limits](../../AminScatter/src/point_display.cpp#L68), [Proxy limits](../../AminScatter/src/preview_batches.inc#L4).

## Severity-ranked findings and gaps

### F1 — P1: same-topic popup retarget can edit the preceding owner

**Exact source:** [layer-editor.ms:114](../../AminScatter/tools/ui/templates/layer-editor.ms#L114) and [retarget at 145](../../AminScatter/tools/ui/templates/layer-editor.ms#L145); corresponding active binding starts at [87](../../AminScatter/tools/ui/templates/layer-editor.ms#L87). The generated script carries the same behavior.

**Source trace:** Open the editor for root A/layer A on Assets so topic 1 is built. Open Edit layer for a different layer B whose default/remembered topic is also 1. `retarget` changes the editor's root/owner and resolves its node, then calls `showTopic 1`. The same-topic branch updates checks/title/statistics and returns without `bindEditors`. Section `obj`/root/owner references and cached members/sets can still target A. The same failure can occur across Scatter roots.

**Impact:** The title may name B while a control edits A, or a cached layer/set dropdown operates on the prior list. This is a correctness risk independent of speed. It independently confirms the other assessment's F1. The reproduction here is a source-level execution trace, not a new interactive Max reproduction.

**Smallest fix:** Always rebind after a context identity change, even when the topic is warm. Separate ensure-topic-created from bind-current-context, or make the skip guard require the full root/layer/set context. Keep same-owner/same-topic refresh inexpensive. Change the template and regenerate through the existing generator; do not hand-patch only generated output.

**Acceptance:** Two roots, two layers each, distinct sources/counts/sets. Retarget on every built topic; read fields and perform one edit. Only the intended owner changes. Switching, closing/opening, Undo/Redo and owner deletion must preserve identity/Undo behavior without incrementing solve/publication counters merely from viewing.

### F2 — P2: current playback candidate lacks artist-session FPS and renderer qualification

**Exact source/evidence:** [input-time.ms:49](../../AminScatter/tools/ui/templates/input-time.ms#L49), [input-time.cjs:41](../../AminScatter/tools/ui/input-time.cjs#L41), [Point matching:295](../../AminScatter/src/point_display.cpp#L295), [playback results](../Playback_Performance_2026-10-06/RESULTS.md).

The earlier unconditional time callback and clock-based keys plausibly explain the reported Live animation stalls. The current source corrects those paths, and preserved receipts support static reuse/relevant animation. But the artist's installed plugin is older; no presented FPS benchmark or Corona reproduction was performed here. The recorded headless point test ended fully realized, so it does not qualify partial culling/device recovery either.

**Smallest next step:** Qualify one exact matching script/native pair on controlled copies, correlate counters with frame/CPU measurements, and exercise real queued notifications and partial realization. Keep the reported Corona stop exception open until the actual callback/API result is isolated. No package installation was done in this task.

### F3 — P2: cached Proxy still submits triangles each redraw

**Exact source:** [preview.cpp:170](../../AminScatter/src/preview.cpp#L170) and [179](../../AminScatter/src/preview.cpp#L179).

World-space proxy batches avoid some preparation/transform work, but every visible triangle still goes through `gw->triangle`; a fallback loops cached shapes/transforms too. Static placement counters can remain flat while animation slows from repeated display submission. This explains a possible mechanism, not the measured size of the user's slowdown.

**Smallest next step:** Compare cached Proxy draw CPU time against retained Point/Mesh with identical placements. If material, prototype retained proxy source shapes plus instance transforms using the existing retained display owner. Preserve appearance, bounds, picking, fallback and memory limits. A replacement is proposed, not implemented or proven faster here.

### F4 — P2: full active-section binding remains a potential UI hotspot

**Exact source:** [bindEditors:91](../../AminScatter/tools/ui/templates/layer-editor.ms#L91) through the active-section bind at 101; [UI documentation](../UI_Performance_2026-10-06/README.md).

The binder enumerates layers/sets and refreshes every active section. Existing equal-list and unchanged-selection guards help. They do not measure list opening, layout, source-row enumeration or parameter-read cost. Replacing the popup with Qt will not automatically remove excessive handler work.

**Smallest next step:** Measure construction, retarget, changed-field synchronization, dropdown model work and layout separately. Then update only affected active controls, using stable identities and guarded programmatic writes. Keep correctness on retarget ahead of skip optimizations.

### F5 — P2: native recording exists but direct artist controls remain planned

**Exact source:** [diagnostics.cpp:33](../../AminScatter/src/diagnostics.cpp#L33), [script emit guard](../../AminScatter/tools/ui/diagnostics.cjs#L5), [existing diagnostic specification](../Current_System_2026-10-05/DIAGNOSTICS_SPEC.md).

The recorder is native Scatter code, initially off. It bounds event count/bytes/duration, drops on lock contention and reports evictions/truncation/failures. It does not itself write disk, poll scene geometry or redraw. Direct Scatter Start/Stop/Save/health UI is still a next task; MCP is one current control/export route, not a fundamental requirement for recording.

**Smallest fix:** Expose those native operations with an explicit bounded session and export action. Include source/binary identity and cause/epoch counters. Avoid serializing the full log on every UI refresh or printing each frame. Engineering recordings are not automatically approved ML training data. [records.py](../../CyrusMCP/cyrus_mcp/records.py#L14).

### F6 — P3: current workers launch per call; value of a pool is unmeasured

**Exact source:** [execution.h:31](../../AminScatter/include/execution.h#L31), joins at [66](../../AminScatter/include/execution.h#L66), [execution.cpp:17](../../AminScatter/src/execution.cpp#L17).

Workers operate on copied numeric data and join synchronously; the default participant ceiling is four, with a configurable limit up to 64 constrained by hardware. Repeated small actual jobs may spend time launching threads. A pool adds lifetime/cancellation/reset complexity and should follow a measured need. Ordered collision acceptance must retain its semantics.

## Test quality and interpretation

Inspected preserved results: SDK 2026/2027 each pass fourteen Scatter and one Analyzer native suites; Python reports 137 passes; final private headless Max 2027 run19 reports 1,312 assertions with matching module/script identities. These were **not rerun** during the vendor research. Assertions include many per-placement comparisons; they are not 1,312 independent feature scenarios.

The campaign checks static reuse, relevant animated sources/surfaces/parents/settings/maps, Manual freeze, deterministic rewind, retained counters and owner lifecycle. It deliberately invokes some node-event classification directly and disables the delayed Scatter callback in the timeline fixture. That isolates a cause but leaves real queued delivery/batching as a qualification gate. Analyzer's real one-shot timer/message loop is exercised; no presented FPS is measured. [Detailed boundaries](../Playback_Performance_2026-10-06/RESULTS.md).

This source review is not a fresh all-requirements correctness certificate. Brush/radius/cleanup/container behavior has its own dated tests; the original requirement matrix remains linked through the [current system guide](../Current_System_2026-10-05/README.md). Our evidence supports preserving those designs while adding focused regression coverage.

MCP policy 3 inspection declares `mutation_supported: False`; older plan mutations reject a policy-3 controller. [procedural.py:70](../../CyrusMCP/cyrus_mcp/procedural.py#L70). The current feature catalog and source boundary should remain explicit. A preference-study/offline ranking foundation is not a deployed scene-composition ML model. No MCP writes or ML implementation were added, and licensing was outside this investigation.
