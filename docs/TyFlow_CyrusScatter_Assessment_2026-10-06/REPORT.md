# Engineering report

6 October 2026. Reviewed the current tracked and untracked working tree, not just HEAD or the installed package. Evidence identifiers and exact file/line links are in [EVIDENCE.md](EVIDENCE.md). Recommendations and proposed measurements are in [ROADMAP.md](ROADMAP.md) and [EXPERIMENTS.md](EXPERIMENTS.md).

## Most useful conclusions

1. **The earlier Live slowdown has a concrete source explanation:** the old time callback dirtied all Live layers and raw clock values changed cache keys on unrelated animation. The current validity/stamp/registry implementation removes that unconditional work. Matching run19 receipts test reuse and real animated dependencies. The improvement in presented FPS on the artist's installation is still unknown because its loaded files and interactive measurements have not been established. [C1–C2, RM playback](EVIDENCE.md#current-cyrus-implementation-references).
2. **UI technology does not establish the responsiveness advantage.** tyFlow documents Qt rollouts and a selected-operator settings pane; the local binary confirms some Qt6 layout construction. Its lazy creation, binding suppression and control-reuse internals remain unknown. Cyrus already uses lazy, retained popup topics; its broader active-topic binding is a plausible latency source, not yet a measured cause. [T4–T5, B1, C10–C11](EVIDENCE.md#tyflow-material-and-repositories).
3. **There is a concrete new UI correctness regression.** The same-topic shortcut skips rebinding after the popup changes owner. Correct this before packaging the latest candidate or expanding the shared UI. A cache optimization must preserve owner identity as well as the topic number. Finding F1 below is derived from the actual call chain.
4. **Cached calculation does not eliminate viewport cost.** Mesh and Point Cloud retain render items. Proxy retains CPU batches but still submits their triangles through GraphicsWindow each redraw. Older identified navigation trials measured a very large Proxy cost without generation/upload changes. This is a separate, credible drawing bottleneck; current presented-frame measurements are needed before extending the retained path. [C8–C9, RM navigation](EVIDENCE.md#snapshot-and-measurement-identity).
5. **Preserve the working engine boundaries.** The ordered procedural solver, stable identities, bounded admission/neighbor/refill work, staged publication and joined copied-data workers are appropriate foundations. A full native rewrite, particle-simulation framework or GPU port is not supported by the present evidence.

## What we can actually establish about tyFlow

The accessible author material is documentation, public query interfaces and examples. The inspected GitHub repositories are consumers of those interfaces: Cycles for Max is renderer integration; max.js is a separate WebView2/Three.js plugin carrying a header copy. Neither exposes the tyFlow simulation/editor engine. A bounded search did not locate complete author-maintained engine source. No assumption of public engine availability is warranted. [T1–T3, G1–G3](EVIDENCE.md#tyflow-material-and-repositories).

Documented tyFlow behavior supports several transferable principles: recognize static work, cache computed results, distinguish history-dependent simulation from independent evaluation, bound thread usage, and profile simulation and GPU preparation separately. Its profiler can identify input-reset causes as well as simulation and upload timings. These are documented capabilities, not a reconstruction of its algorithms. [T4, T6–T10](EVIDENCE.md#tyflow-material-and-repositories).

The prior binary inspection verifies native machine code, Qt6 dependencies and selected widget/layout setup and particle accessor routines. It recovered small examples, not original C++ source. The observed 12-byte position/velocity access is evidence about those accessors only. It does not prove a whole-engine structure-of-arrays layout, allocator, spatial index, DAG, lock-free publication or thread-pool implementation. [B1](EVIDENCE.md#tyflow-material-and-repositories).

### Architecture comparison

| Area | tyFlow evidence | Current Cyrus Scatter implementation | Assessment |
| --- | --- | --- | --- |
| Native and script responsibilities | VI: native binary and selected accessors; API: C++ data queries. Scripting is an exposed integration surface, not proof that the main editor is scripted. | VI: MAXScript owns scene parameters, owner relationships, scheduling and orchestration; C++ handles generation, spacing, Brush/Edit support, preview preparation, retained items and diagnostics. | The hybrid split is valid. Optimize an observed boundary cost before moving it. |
| Command panel and editor | API: an object's command-panel button opens its editor; selected operator settings appear alongside its graph. Historical author statement: Qt parameter rollouts. | VI: four setup rollouts in Modify; selected layer settings currently live in one six-topic modeless popup. | The desired selected-layer Modify view is a product gap, not a missing native calculation engine. |
| Control creation/reuse | U: actual lazy/rebuild/reuse policy is unavailable. | VI: topic section controls are constructed on first use and retained until close; retargets reuse widgets. Closing destroys them. | Retain this behavior but fix context-sensitive rebinding. |
| Selection/dropdown/resize | U: exact event path and control churn. | VI: unchanged top-level dropdown contents and same selection/topic guards; broad binding of all active-topic sections; popup resize changes layout. | Measure cold versus repeated operations; do not assign dropdown-open latency to selection handlers without reproducing it. |
| Parameter ownership and Undo | API: instanced tyFlow operators share settings; private notification/Undo handling unknown. | VI: persisted root/logical-layer/paint-set objects, stable IDs, Undo-scoped edits and binding guards; popup lifecycle callbacks. | Share the model across views; do not copy settings into view-owned models. |
| Static evaluation/cache | API: static-flow and playback/terrain reuse; internal scheduling U. | VI/RM: cached intervals/stamps and prepared/controller/display publications; unchanged static timelines retain results in fixtures. | This is directly applicable to static scatter; simulation history is unnecessary. |
| Data/ordering | API: identities, channel access and grouped instances; private storage/solver U. | VI: ordered vectors, stable candidate ordinals/IDs, scoped rules, protected Edit reservations, cleanup/refill. | Keep explicit order and deterministic identity contracts. |
| Threading | API: algorithm-specific decisions and thread cap; exact worker implementation U. | VI: independent cluster field calculations on joined workers; ordered acceptance and scene SDK work on caller. | Sensible bounded parallelism already exists. |
| Viewport/renderer | API: upload diagnostics, renderer interfaces and explicit culling options; exact retained renderer U. | VI: retained Mesh/Point Cloud, immediate Proxy batches, PFlow renderer transport and IR settling state. | Renderer transport and viewport work require separate measurements. |
| Diagnostics | API: profiler, reset information, upload timing, logging cost. | VI: bounded causal recorder and counters; direct Scatter recording UI and UI-duration attribution pending. | Extend access and attribution, not a second logging system. |

## UI operations, ownership and performance

### Actual current paths

Opening Modify compiles/loads no new engine; it opens mainUI, arms a one-shot mount timer, synchronizes identity, arranges four setup rollouts through the native command-panel interface and binds setup controls. Opening the popup creates its host and twelve subrollout containers, then constructs sections for the initial topic. The remaining topic sections are lazy. This is different from constructing controls for every layer. [C10–C12](EVIDENCE.md#current-cyrus-implementation-references).

bindEditors reads logical owners/paint sets, retains unchanged selector items, then binds every section in the active topic. Other constructed sections are marked unavailable until used again. Source binding reconstructs source and color-group lists; Area binding refreshes relevant list/field state. These paths read source rows, node validity/names, map references and cached statistics. They are not placement-generation functions. Source rows may be numerous even though the layer/population count is bounded. [C10–C11](EVIDENCE.md#current-cyrus-implementation-references).

The examined bind path does not directly call placements, evaluateProcedural, retained publication or render-bridge construction. Ordinary list construction is not mesh conversion. Identity initialization and selection/UI-state writes do exist, so “every UI open is completely read-only” would be too strong. Actual notification delivery still needs qualification. The explicit Update button does request recalculation/redraw; that is distinct from browsing. [C10–C11, C17](EVIDENCE.md#current-cyrus-implementation-references).

A dropdown's selected handler is not evidence of what happens when its list opens and is cancelled. Expansion calls layout/detail visibility logic; popup resize updates the layout and minimum dimensions. Native child-control layout and DPI behavior cannot be timed from a headless script pass. Keep startup/script loading, first control creation, warm binding, layout and calculation as separate measurements.

Bindings use binding/controlsReady flags, and some specialized loading flags, to suppress control-to-model writes while values are displayed. Several section bind routines restore flags on exceptions. This is the right pattern. Redundant writes and exception recovery should be checked per binding path instead of assuming all guards are interchangeable. A guard can also skip necessary work, as F1 demonstrates.

### Recommended Modify structure

Use normal Max command-panel rollouts in this order:

| Rollout | Responsibility |
| --- | --- |
| Setup / Update | Setup enabled state, Manual/Live, explicit Update, last completed status and pending/error state. |
| Receiving surfaces | Setup-wide receiver(s), evaluation policy and optional global source rectangles. |
| Layers | One ordered list; select/rename/add/copy/remove/move; distinguish output enabled from viewport visibility. |
| Selected layer | One owner header and paint-set selector; Assets, Population, Paint, Transform and Spacing sections. Basic controls are visible; advanced settings remain reachable through standard expansion. |
| Display / Diagnostics | Setup display budgets/mode, cached counts, Record/Stop/Export/clear status, with no dependency on an MCP connection. |

The selected-layer area is one reused view, not one complete UI per layer. Bind only the current owner and necessary paint set. Construct advanced sections on first expansion where the host integration supports it, retain them while the view lives, and refresh changed sections from events. Browsing and layout must not request a solve or unchanged-buffer upload. Keep all current feature families reachable; moving settings into Modify should not simplify the calculation model.

The optional Edit Layer popup is a second view over the same persisted scene objects. It owns its controls and selected owner; Max owns the command-panel controls and their lifetime. Do not share/reparent the same widget between hosts. Share field definitions, binding/writeback routines and parameter contracts. Closing Modify does not close an explicitly owned popup. Selecting a source model may change Modify's context while the popup remains on its chosen Scatter. Each view validates its owner before any write.

View state: selection, expansion and scroll positions. Model state: authored settings, stable IDs, rules and history. Runtime state: dirty reasons, validity intervals, prepared data and completed publications. Views display runtime snapshots without asking the engine to calculate. A temporary view field must not become a second copy of an authored setting.

On Undo/Redo, re-resolve the owner by stable identity against the current scene/root and bind affected fields under write suppression. On clone, generate/remap new identities as the current model requires; never retain view references to the original clone source. On load/reset/delete, stop tool modes and dispose or detach invalid views before writes. The existing popup pre-open/reset/node-delete and Undo/Redo hooks provide a starting point, but deleting a layer while its root survives and cloning with both views visible still require direct tests.

The smallest implementation uses the existing section factories, MAXScript controls and SDK-owned rollout arrangement. The native helper verifies the HWND/thread/command-panel owner, sets category and asks Max to lay out the page. Preserve that ownership instead of adding manual reparenting, custom column scrolling or hard-coded device-pixel positions. If measurements demonstrate a host/control limitation, Autodesk's QMaxParamBlockWidget route is an alternative for the affected UI only. That contract does not automatically migrate the scripted model or justify rewriting the engine. [C12, A5–A6](EVIDENCE.md#autodesk-contracts-not-tyflow-implementation-evidence).

## Evaluation and scheduling

| Trigger | Current behavior and evidence | Necessary versus avoidable work |
| --- | --- | --- |
| Authored parameter edit | Set handlers mark input dirty; source/map/Brush/Edit changes affect relevant keys or revisions. [C2–C4] | Recompute changed semantic inputs. Same-value presentation writes should be suppressed. |
| Scene node notification | Delayed NodeEventCallback classifies sources/receivers/parents/containers and batches redraw requests. Some paths scan Scatter controllers on actual notifications. [C13; generated:5049] | Relevant dependency classification remains necessary. Unrelated events should produce no solve/publication/upload. |
| Time change | Registered owners check cached validity/stamp state; Manual/disabled/hidden owners are skipped; relevant expiry requests redraw. [C1–C2] | Lightweight per-owner checks remain. Blanket invalidation and raw-clock keys are avoidable. |
| Viewport redraw | previewCache serves cached data during interaction; otherwise relevant dirty Live/initial data may be refreshed synchronously. Retained synchronization is outside native Display. [generated:3426, 4806, 5143] | Drawing remains; placement generation and uploads of identical data should not. |
| Explicit Update | Builds pending authored state, including Manual mode; policy 3 can reuse an identical completed recipe. [C4] | It is a calculation action, not UI browsing. |
| Analyzer input | Relevant notifications/expired validity request a one-shot 250 ms timer; settled/Manual/disabled/failure states stop retrying. Scatter reads producer revisions. [C15] | Re-evaluate actual changed inputs. No perpetual idle scene-signature polling. |
| Rendering / IR | Production callbacks build a missing/changed PFlow transport; IR checks are requested and settled, with stop/build/start phases and reentrancy guard. [C14] | Renderer translation and notifications are separate from viewport upload and generation. |

Scatter's main calculations are synchronous once evaluation is admitted. Callbacks and timers coalesce/defer requests; they do not make the solver an asynchronous cancellable job system. During a drag, the last preview remains visible. Policy-3 preparation is keyed separately from controller publication and display state. Manual readers preserve the preceding completed publication once available; reopening a scene without a transient snapshot requires reconstruction. [C3–C4].

The native validity query intersects explicit owner controllers, dependency object validity, parent transforms and active map validity. It avoids mistaking unknown/script/list/foreign controllers for constants merely because they lack ordinary keys. The whitelisted stock-controller fast path is deliberately narrow. Conservative controllers can still yield one-tick intervals and real per-frame work. That is a correctness tradeoff, not evidence of broken caching. The query uses SDK calls on the host caller, not a worker. [C1].

Failures during staged procedural computation preserve the previous complete viewport publication and clear transient preparation keys for recovery. Edit transaction rollback is explicit. This is a staged main-thread transaction, not proof of a lock-free atomic cross-thread publisher or recovery from every possible host/device failure. Legacy preview and PFlow transport have different failure behavior; their catches must not be described as the same transaction. [C4, C14].

Cancelled/superseded asynchronous solver jobs are not implemented because this solver is currently synchronous. Host deferral, busy flags, interaction holds, bounded admission and joined workers provide lifecycle control. Future asynchronous work would need an immutable request, input/scene epoch, cancellation token, join on shutdown and a main-thread commit that rejects stale results. Introduce that machinery only if measured blocking calculation latency justifies it.

### Keep costs separate

| Cost | Where it occurs | What reuse proves |
| --- | --- | --- |
| Dependency checks | Cached integer checks; expired validity/controller/geometry/map query; source/container reconciliation. | Stable generation counters alone do not prove these checks are free. |
| Source geometry evaluation | Native bridge captures receiver/source meshes; density renderMap and some area calculations execute through the host. | Count and time captures independently; a cache hit can still spend time computing a key. |
| Placement generation / spacing | Native generation plus transforms/Brush/Edit/scoped rules and cleanup/refill. | Prepared and controller-build counters identify repeated computation. |
| Native preview preparation | Point sampling, copied source geometry, bounds/hash and proxy batches or MeshSnapshot. | Preview-build counters must remain stable for unchanged outputs. |
| GPU upload | Retained item Realize creates vertex/instance buffers. | Upload count/bytes must remain stable after first visible realization. |
| Drawing | Retained instanced/point draws or immediate Proxy triangle submission; material/shader/view work. | Zero uploads does not mean zero GPU or submission work. |
| UI binding/layout | Host controls, lists, selected owner and layout events. | Must be measured independently from scene work. |
| Renderer transport/notifications | PFlow bridge, material/source lookup, IR stop/start and renderer translation. | No placement change does not guarantee no renderer restart/translation. |

## Calculation pipeline and transferable principles

The pure native procedural plan stores layers, populations and samples in vectors; each sample carries numeric position/radius, ordinal, string identity and protected-edit status. It is not a complete SoA rewrite. Native bridge capture produces owned geometry/numeric data. Persistent scene owners retain author settings; reorder changes explicit order without replacing identity. Stable candidate streams separate placement, transform, source and diversity decisions. [C3, C5–C7].

| Required stage | Actual current implementation and boundary |
| --- | --- |
| Generation | Bounded deterministic candidate pool; native receiver sampling, density/area/diversity logic. MAXScript density renderMap and SDK mesh capture remain host work. |
| Surface / Brush eligibility | Generation inputs and applied Analyzer/falloff/paint/background coverage; source containers admit or park registered sources without compacting their settings. |
| Transforms / Edit / radius | Source offsets/scales and explicit Edit application precede procedural radius calculation; conservative transformScaleBound accounts for shear. |
| Collision within sets | Self rule with per-sample radii and protected placements. |
| Between paint sets / layers | Explicit scoped pair/default rules, deterministic logical order, earlier accepted rows plus protected reservations from other owners. The native predicate checks external and self conflicts together; diagnostic reason priority is layer, sibling, self. It is not three independent filters that count the same rejection repeatedly. |
| Cleanup / refill | Logical-layer union cleanup suppresses removable rows; bounded candidate prefixes extend for accepted targets; protected edits survive and conflicts/shortfall remain explicit. |
| Completed publication | Allocate/compute display and publication information before the completed epoch is installed, with Edit transaction and failure path. |
| Preview / exact / export | Consume the completed publication/owned source mapping; display budgets and final Point-placeholder filtering do not redefine accepted solver identities. |

Top-to-bottom priority applies to ordinary accepted placements. It is not an unconditional “earlier beats all later data” rule: protected Edit rows in later owners can reserve space and affect earlier calculation. This matters for any incremental dependency design. A later protected edit, pair rule or cleanup/refill interaction can require upstream reconsideration. Verify the complete dependency closure before retaining a prefix. [procedural.cpp:99–100, C5].

Spacing uses hashed cells with 9 planar or 27 spatial neighboring cells. Cell width is derived from maximum radii/reach. This bounds which cells are queried, not the number of rows inside a dense cell. Large radius variation or concentrated input can approach quadratic neighbor work. The current global visit ceiling converts that worst case into a bounded failure rather than an unbounded solve. Rebuilding grids/blocker vectors in refill rounds is a plausible allocation cost; neither a BVH nor a radius hierarchy is proven necessary by the current measurements. [C6].

Bounds include ten total populations, 100,000 per-set budget/attempt limits, up to one million admitted samples, 1–16 rounds, and at most 50 million neighbor visits. Limits bound work but are not a process-memory guarantee: strings, bridge rows, blockers, outputs, staging and temporary vectors have overhead. Retained point/mesh byte budgets separately limit prepared buffer reservations, with group limits; CPU snapshots plus kept SDK system buffers plus GPU data and overlapping generations increase the actual peak. Measure peak memory during replacement, not only steady reservation counters. [C5, C8, A2].

Useful transfers from simulation software are explicit dependencies, stable identities, batch preparation, immutable published results, separate profiling and memory/work admission. A timestep history, arbitrary looping event graph, per-particle general channel engine or broad simulation task scheduler adds unnecessary complexity to current static scatter. Parallelizing order-dependent greedy acceptance could change winners and output identity. Independent copied-data kernels are the safer measured opportunity.

## Viewport and renderer integration

Retained generations own immutable numeric preview data through shared pointers. Weak controller tracking disables old items on controller hide/deletion; disposable display-node clones do not inherit another controller's data. Items carry bounds and are submitted to Nitrous. Mesh draws shared source triangles plus instance transforms. Point groups upload positions only once per generation. Display does not evaluate scene nodes or execute MAXScript. Matching checks identities/styles, enabled/failure state and submission rather than full GPU realization. [C8–C9].

The latter correction follows Autodesk's contract: an off-screen item may never be realized. Requiring all groups to be ready can create permanent fallback/release work despite unchanged data. The final off-screen fixture had fully realized state, so it demonstrates matching and timer settlement but not actual partial culling. Device reset, loss/recovery, viewport switching and multiple-view behavior still need visual/device qualification. Retaining a system buffer is helpful preparation, not sufficient evidence of successful recovery. [A1–A2, C17].

Bounds and helper ObjectValidity FOREVER refer to the installed immutable generation; publishing a successor sends geometry/display notification. This must not be confused with the separate validity of an authored receiver or animated source. A static snapshot can have time-independent display data while its producer has changing inputs.

The PFlow render bridge groups actual sources/placements, acquires materials and verifies particle counts; it is different from the flat preview shader. Production rendering may require evaluated source geometry and renderer-specific translations even when viewport data is retained. IR stop/start can pump messages and is guarded against timer reentry. The reported stop failure remains an identity-sensitive renderer/lifecycle problem; no meaning for status code 2 or fix was established. [C14].

Higher FPS with Scatter disabled combines removal of evaluation/checks, viewport draw and possibly renderer work. It cannot by itself identify any one of these. Likewise, synchronous completeRedraw duration includes submission/host/message processing and may exclude presented GPU completion. Do not convert its inverse into a claimed FPS result.

## Threading and host safety

Maintain the current split: capture/evaluate nodes, transforms, controllers, parameter blocks, materials, MAXScript, UI and scene references on Max's supported host thread; workers receive copied immutable numeric input and write disjoint native results. The existing cluster kernel meets that boundary. All workers join before return/error; launch failure falls back after joining; floating-point state is copied for determinism. Ordered final selection remains on the caller. [C7].

Autodesk specifically documents the single-threaded node/reference subsystems. Renderer texture Eval contracts are a limited exception requiring prepared read-only shader state; they do not authorize background renderMap or arbitrary third-party map calls. Native viewport callbacks should obey the graphics API callback context, not be moved to an unrelated compute thread. [A3–A4].

The automatic four-participant limit is provisional, not a universally optimal value. A thread pool, higher cap, parallel density snapshots or parallel source capture should require stage timings and host/IR contention evidence. GPU compute requires an identified dominant pure kernel, transfer/init costs, memory bounds, equivalent deterministic output and a CPU fallback. None of these prerequisites was established for a new GPU implementation here.

## Findings and review verdict

**Recent-diff verdict: REQUEST CHANGES.** F1 is an introduced correctness regression with high source-trace confidence (0.98). The other findings below are existing product/performance/qualification gaps and must not be presented as regressions introduced by the playback patch. No production fix was made.

| ID / severity | Exact location | Finding, impact and evidence |
| --- | --- | --- |
| F1 / P1 | [layer-editor.ms:112–118](../../AminScatter/tools/ui/templates/layer-editor.ms#L112), [retarget:145–155](../../AminScatter/tools/ui/templates/layer-editor.ms#L145); [generated mainUI.bind:4484](../../AminScatter/scripts/AminScatterObject.ms#L4484) | VI/EI, introduced: same-topic fast return does not check owner/root. Retarget updates editor context then invokes showTopic; a previously built same topic returns before bindEditors. Existing section obj/root references remain stale. The following mainUI.bind only binds setup rollouts and does not repair it. Parameter edits can target the preceding layer or Scatter while the title names the new one. |
| F2 / P2 | [generated mainUI:4508](../../AminScatter/scripts/AminScatterObject.ms#L4508), [layer controls:4682](../../AminScatter/scripts/AminScatterObject.ms#L4682) | VI, requirement gap: Modify mounts setup rollouts and directs layer edits to a popup. The requested primary selected-layer Modify workflow is not implemented. Keep one authoritative model and two independent view lifetimes. |
| F3 / P2 | [layer-editor.ms:87–105](../../AminScatter/tools/ui/templates/layer-editor.ms#L87), [source bind:444](../../AminScatter/scripts/AminScatterObject.ms#L444), [lists:326](../../AminScatter/scripts/AminScatterObject.ms#L326) | VI path/EI latency: active-topic refresh binds all its sections; source/color lists are rebuilt. Work grows with source rows and can create control churn. The user-reported dropdown latency has not been tied to this path. Measure first, then refresh affected fields/lists with unchanged-value suppression. |
| F4 / P2 | [geometry_preview.inc:43–48](../../AminScatter/src/geometry_preview.inc#L43), [preview.cpp:161–172](../../AminScatter/src/preview.cpp#L161) | VI/RM historical: Proxy retains CPU batches but submits every cached triangle each redraw. Older high-count measurements show substantial drawing cost without cache work. Retained Proxy is a focused experiment, not justification for replacing Mesh/Point Cloud. |
| F5 / P2 | [diagnostics_bridge.cpp:25](../../AminScatter/src/diagnostics_bridge.cpp#L25), [diagnostics.cjs:1](../../AminScatter/tools/ui/diagnostics.cjs#L1), [mainUI:4471](../../AminScatter/scripts/AminScatterObject.ms#L4471) | VI/EI observability gap: bounded recorder and direct primitives exist; Scatter's own normal UI lacks Record/Stop/Export and cause-to-duration/UI-bind attribution. Stable counters cannot isolate the remaining responsiveness costs. Extend the existing system. |
| F6 / P2 | [Max_Playback_Regression.ms:18](../../tools/procedural_lab/Max_Playback_Regression.ms#L18), [204](../../tools/procedural_lab/Max_Playback_Regression.ms#L204), [Analyzer fixture:5](../../tools/procedural_lab/Max_Analyzer_Playback_Regression.ms#L5) | VI/RM coverage gap: delayed node events are disabled for isolated fixtures; culling state is fully realized; no popup retarget or interactive FPS case. Passing counts must not qualify real notification delivery, partial realization, visual UI, device recovery or latest Corona IR. |

**G1 — P1 release qualification gate, not a diagnosed regression:** the user-reported Corona IR stop error must be reproduced on identified bytes. Current call sites include [generated:4977](../../AminScatter/scripts/AminScatterObject.ms#L4977), [4982](../../AminScatter/scripts/AminScatterObject.ms#L4982) and [5002](../../AminScatter/scripts/AminScatterObject.ms#L5002). An installed line number from another script is not this source identity. Impact is potential interruption of save/open/reset or IR refresh. Root cause and status-code interpretation remain U; the smallest experiment is E5.

### F1 minimal source-trace reproduction

1. Create two logical layers A and B with distinct source lists. Open A's popup on Assets, so topic 1 is built.
2. Select B while it is new to the popup's remembered view state. Its default nextTopic is 1.
3. retarget sets owner=B. showTopic(1) takes the new same-topic/built return and only refreshes statistics/title.
4. Existing sourceUI.obj is still A; no section bind executed. The layer-selector handler's mainUI.bind does not bind popup sections.
5. A source field edit is therefore routed through A's object reference. Changing to another topic or explicit Refresh can hide the problem by causing a later bind.

The smallest fix is to make owner/root/set context changes force binding of the retained active controls. Keep same-topic no-op behavior only for the same bound context. Do not recreate widgets or regenerate placements to correct ownership. Test same-topic layer and cross-controller retarget, not only clicking the current topic twice.

## Quality of existing tests and diagnostics

The latest campaign has unusually useful identity evidence: exact source/build receipts, loaded native module paths/hashes and script payload verification. Native SDK suites check pure contracts; offline checks verify generation/inventory/integration; the Max fixture checks actual output changes, idempotence, rewind and Manual freeze. Real time callbacks run. Analyzer's real timer/message loop is exercised, including failure settlement and lifecycle. These are meaningful correctness tests. [C17; RM playback].

The limits are equally material. Time fixtures intentionally disable delayed Scatter node delivery and call classifiers directly. There is no presented playback timing, current visual layout, real dropdown open/cancel, DPI, root/layer retarget or genuine partly unrealized render-item test. Many assertions repeat per placement, so their total says little about breadth. Static counters prove no monitored generation/publication/upload; they do not prove zero dependency-check CPU, no unseen renderer notification or better FPS. Older runtime/installation campaigns apply only to their frozen candidates.

The recorder is already bounded to at most 16,384 events, 4 MiB accounted event storage and ten minutes, with field limits, eviction/truncation/drop/failure health and paged snapshots. It is default-off, avoids native record allocation when disabled, uses try-lock/drop rather than blocking the host, and never aborts scene work. Passive script wrappers check active state before recording. These limits are event storage, not whole-process memory/disk guarantees. [C16].

Extend it with bounded owner/event correlation, invalidation reason/dependency, cache decision, stage duration, UI create/bind/layout count, renderer phase/result and upload delta. Separate an event cause from its later execution: a timer firing is not necessarily the original invalidation. Native upload/draw counters are partly process-wide, so identify the session/owner or sample in isolated fixtures before attributing them. Export only on explicit artist action with a size cap; preserve existing local-sharing controls. Do not log full meshes/placement arrays or serialize full keys on every frame.

## Parameter contracts, MCP and future AI

Define each setting's stable name, owner scope, type/unit/range, animation support, normalized value, capability/policy gate and impact: presentation, display, prepared candidates, solver, publication or renderer transport. Define an edit transaction and the resulting authored revision separately from a completed generation. Readers return the exact published epoch and pending/error state without evaluating.

These contracts let Modify, popup and future authorized tools apply identical validation and Undo semantics. A future proposal can cite stable layer/set/source IDs and a scene/input epoch, be validated against capabilities, previewed using an explicit calculation action and applied through the same setter boundary. A changed epoch invalidates the proposal. MCP policy 3 currently remains read-only; cached inspection/diagnostic access does not grant authoring. ML remains future research, and a saved record does not itself implement training, prediction or consent. [C18].

The prioritized changes, concrete acceptance targets and unresolved experiments are intentionally specified in the companion documents. No full native migration, additional scheduler framework, GPU implementation or license change is required by this assessment.
