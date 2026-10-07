# Implementation and engineering contracts

6 October 2026. Scope is the user's [unified requirements](../Unified_Procedural_Settings_2026-10-06/README.md). [Results](RESULTS.md) identify exact qualification; [roadmap](ROADMAP.md) records limits. This is a development slice, not publication readiness or an architectural rewrite of the retained engine.

## Sole model and maintainable source

[unified-core.ms](../../AminScatter/tools/ui/templates/unified-core.ms) is the canonical product core: authored settings, evaluator/publication integration, rendering adapters, callbacks and shared controls. [generate.cjs](../../AminScatter/tools/ui/generate.cjs) adds the [container helper](../../AminScatter/tools/ui/templates/container-node.ms)/[properties](../../AminScatter/tools/ui/templates/container-properties-ui.ms) and shared view through [container-system.cjs](../../AminScatter/tools/ui/container-system.cjs). [inventory.cjs](../../AminScatter/tools/ui/inventory.cjs) derives semantic controls/current hover help. `generate.cjs --check` is read-only and verifies reproducibility.

The previous 91 patch-stage/template inputs are retired after preserving hashes and ignored before-copies. Historical source links point to the baseline commit; licensing documentation is preserved unchanged. See [retirement inventory](evidence/retired-generator-inputs.json). Maintaining another compatibility factory chain is not part of the new model. A shared control definition is copied into views at generation time; its data owner/evaluator is not duplicated.

Old policy selection/conversion, collision-priority/blocker settings, index-based Edit adaptation, scene migrations and always-stable `paintIdentity` switch are removed. Product is 0.73.0, script 0.73, serialization 54 and explicit `CyrusUnified1`. Existing internal registration identifiers remain; the new helper has its own native/script class IDs. Stable-only CS Edit uses chunk `0x7301`; old `0x3901`/`0x4001` storage is rejected. Old development scene/plan formats are intentionally unsupported, not silently upgraded.

Useful lower-level native kernel interfaces remain, including ordinary non-keyed sampling for direct numerical callers/tests. These are not an alternate product policy, scene migration or compatibility UI. Retiring unpublished settings is not a reason to rewrite shared distributions or rename registration identifiers.

Max can continue loading a scene after an `on update` exception, then relabel a scripted record with the new version. A version check alone therefore does not reject old data reliably. The new persisted `procSchemaValid` marker is set false on an unsupported update; the controller checks itself and its leaves before calculation, validation, cold placements or publication, and copying requires a valid origin. Re-save/reopen cannot turn a denied record into a valid one. Ordinary scene geometry may still open. This is a denial boundary, not a migration path. The [retirement fixture](../../tools/procedural_lab/Max_Unified_073_Retirement.ms) proves copying/output denial and byte preservation of the original ignored scene.

The [245-row port report](CONTROL_PORT_RESULTS.csv) maps each previous semantic control. Current 240 controls comprise 49 general/editor, 184 selected-layer and seven helper properties. Removal of redundant controls is not deletion of their useful function: constant self distance becomes factor 0 plus gap; priorities become explicit layer order; overlaps/blockers become canonical pair rules; boundary Relax moves into Relax; centre visibility is a display mode; statistics use the current statistics section.

## Settings ownership and UI

Controller owns receivers, enable, update mode, global source pool, layer order, inter-layer pairs and global presentation/output/session actions. Layer owns count/density/seed, candidate assignment, Area/Analyzer/falloff, transforms, self/sibling defaults, Relax and union cleanup. Each paint set owns its identity/order/share/visibility/enable, source records, coverage history, self override and earlier-sibling composition references. Each set's source row owns its own metadata even when the physical scene model is shared.

Modify mounts sixteen selected-layer sections; unused per-layer pages are gone. The optional six-topic popup and selected-helper panel bind the same owner records. Binding is guarded against handler feedback and warm retargeting. Fields commit on their appropriate events; spacing has no Apply step. Explicit history/source/radius/background actions remain deliberate.

The final helper view captures an explicit `view` reference in its open event. An externally invoked rollout function cannot rely on MAXScript's implicit current-plugin `this`. A regression caught the wrong assumption during shared consumer switching; the new test covers warm layer/context browsing. Popup Relax/cleanup open/close layout uses the actual panel's `layoutPanels()` rather than an undefined callback.

The [selection correction](../Container_Selection_Fix_0.73_2026-10-06/README.md) addresses a separate startup defect: child rollups can expand before the owner-binding timer runs. Helper children capture their panel in `open`; selected-layer expansion requires readiness and excludes reentrant binding. The shared mount handler ignores a queued tick after close before accessing disposed controls. Natural selection is now an independent acceptance gate; manually mounting a timer does not qualify this sequence. Scene reopen warms cold preview owners with nothing selected before passive UI counters are sampled.

UI mounts/status timers are one-shot or limited to a relevant pending interaction. No second evaluator or periodic membership timer is attached to a container. Linked inactive pools still expose controls with zero active consumers/followers; a global helper with no layers exposes setup controls. Root setup/selected-layer aliases are initialized before controls bind. Pointer/DPI/real scrolling are separate qualification gates.

## Candidate ports and accepted publication

[scatter.cpp](../../AminScatter/src/scatter.cpp) now admits stable Line/Analyzer candidates and Point Relax. Fixed anchors consume a bounded prefix with stable ordinals, deterministic channels and stroke scale across range/count requests. Direct/color-group band choices resolve against each set's own allowed source identities; a missing band choice is ineligible rather than falling back to random assignment. Analyzer retains its published cached data and independent Manual/Live contract.

Point and constrained boundary movement happen in **ordinary candidate preparation**. [max_bridge.cpp](../../AminScatter/src/max_bridge.cpp) reanchors moved boundary candidates to triangle/barycentric support. Final Area/density/falloff/Brush use the new support; final transforms/Edit/radius then enter the three-scope solver. Brush edits reuse the prepared candidates. Boundary traversal counts all visited edges, including coincident/out-of-radius edges, against its cap.

**Deliberate tradeoff:** old late relaxation of accepted output is not retained. The port relaxes each set's ordinary candidate pool using the layer recipe before final eligibility/collision; accepted-union cleanup stays after collision. Protected Edit is applied after preparation and is not relaxed away. Relax defaults off; its stage/ranges are explicit. All Analyzer channels/corners/curved combinations still need wider artist acceptance, beyond the numerical fixtures and bounded host cases.

Layer within-set defaults (`procLayerSelf*`) are inherited through `procSelfRule()` unless a set declares `procSelfOverride`. Sibling defaults and explicit set/layer pairs remain separate. The UI's five selector entries represent the three scopes plus their defaults/overrides, not five independent collision engines. Radius comes from source scaling/follow-scale and bound instance overrides; protected conflicts retain their explicit reporting.

Cleanup operates on the accepted layer union. Candidate budget and accepted target remain different modes; attempts/rounds/refill are finite and shortfall is honest. Stage accepted rows, source correspondence, effective radii, statistics, Edit state and preview/publication data, then commit one epoch. An invalid successor retains the previous complete generation and exposes its error. Cached return to the previous valid recipe clears the error without fabricating another publication.

## Native source-container node

[source_container.cpp](../../AminScatter/src/source_container.cpp) implements a small non-rendering `HelperObject` delegate. It draws a rectangular frame/cached label and owns only boundary/presentation and transient movement state. It does not sample/solve Scatter or upload placement buffers. [edit_plugin.cpp](../../AminScatter/src/edit_plugin.cpp) registers it beside Edit and retained display. Native configure/translate/gesture/stats APIs are version-matched to the script.

Controller-to-container node references are the durable ownership direction. Reverse contexts use controller/set UUIDs plus cached lookup; native followers are weak references. Save/clone does not retain live scene pointers or duplicate movement ownership. Unique copies get new container UUIDs; a shared instanced delegate refuses following. Scene-boundary registry rebuild is one-time, not per-frame enumeration.

**Usage and movement are separate.** Effective pools determine source participation; declared links determine available editors. Parking preserves source-slot ID and per-set metadata. One physical model has at most one movement owner: keep a still-valid owner, admit a unique eligible container, or expose an overlap for the artist's explicit choice. Cached active/saved palette counts deduplicate physical models across actual consumers. Labels identify the editing context and shared consumers, not set quotas.

One `CyrusContainerInside` predicate governs labels, membership and movement: source pivot in container-local XY, height ignored, inclusive epsilon `max(1e-4, max(width,length)*0.5e-6)`. Ordinary supported Rectangle input is copied into a helper in the same Undo transaction; the artist spline is not replaced. Width/Length resize only the boundary; translation-only following does not scale/rotate sources.

## Movement, failure and host safety

The native operation freezes container transform, movement units, every admitted descendant/parent identity and initial world transforms. It accepts ordinary static stock PRS controllers with transform locks off; entire groups/hierarchies must be managed. Group heads are allowed movement roots; unrelated geometry, cameras/helpers, parked/unmanaged descendants, animated/constrained controllers and partial selections are excluded or rejected. No scene parenting is introduced.

Apply a translation from the frozen start, not accumulated deltas. Do not acquire models encountered by the moving rectangle mid-gesture. Revalidate live weak refs, parent/controller eligibility and finite transforms before writes and verify uniform translation afterward. Independently edited children cause full rollback. Existing selected units already translated with the container are not moved twice. Failure restores captured source/container transforms while the Undo hold is suspended; status/error increments once.

Follow the SDK lifecycle: capture in `TransformStart` before Max creates its hold; carry sources in `TransformHoldingFinish` before Accept; cancel after Max restores its hold, then clear frozen state in Finish. Script/API translation creates its own hold only if needed. All node/controller writes run on Max's host thread. Bounds are **1,024 hierarchy nodes per gesture, 64 ancestor steps**, with current pool registration limits unchanged. SDK-entry-point tests do not prove pointer forwarding by Max to the scripted helper delegate in every real gesture.

Native diagnostics emit one started/completed/cancelled/failed summary per movement action and a summarized ownership status change. Off recording returns before constructing detailed records. No per-model/vertex logging is added to hot loops.

## Cache and retained display

Relevant input validity remains the scheduling authority: unrelated animation/static time changes do not regenerate; real receiver/parent/source geometry/parameter/map changes do. Membership changes mark the affected recipe; pure palette translation with unchanged membership/object-space geometry preserves candidate/accepted identities and preparation. [input_validity.cpp](../../AminScatter/src/input_validity.cpp) treats world-space-derived source geometry as a genuine dependency rather than bypassing every transform notification.

[preview.cpp](../../AminScatter/src/preview.cpp) and [point_display.cpp](../../AminScatter/src/point_display.cpp) are byte-normalized identical to the 0.72 baseline. Navigation/helper browsing and unchanged palette translation preserve actual preparation/node-publication/upload counters and data signature. A retained revision can change when Max's interaction hold enables/disables a retained owner; revision alone is not an upload counter. Proxy drawing remains a separate CPU cost.

Raw MAXScript writes to embedded layer records mark dirty. The real authoring handlers request redraw; API authoring commits/evaluates explicitly. The final idle fixture uses those handlers and explicit redraw signals for scripted map/failure injection, then passively samples settled counters. It does not turn a direct field write into a promise of an autonomous polling evaluator.

## MCP and extension boundaries

[models.py](../../CyrusMCP/cyrus_mcp/models.py)/[settings.py](../../CyrusMCP/cyrus_mcp/settings.py) define the closed Plan 0.73 subset. [max_host.py](../../CyrusMCP/cyrus_mcp/max_host.py) emits the sole unified model with typed source metadata, canonical self/default/pair rules, bounded include/exclude masks and requested display. [contracts.py](../../CyrusMCP/cyrus_mcp/contracts.py) rejects retired plans before scene mutation; arbitrary fields remain forbidden.

Keep enrollment, local exact-digest approval, ownership, scene freshness, idempotency, budgets, journal and rollback. A failed preview/refinement restores the original full controller/publication/meshes/selection and redraw state. Passive [procedural.py](../../CyrusMCP/cyrus_mcp/procedural.py) adds bounded cached helper presentation without containment queries. Publication pages copy immutable accepted epochs; they do not reconcile or reconstruct all assets.

Twelve tools/seven resources remain, with current catalog/hover data and source/inventory hashes. Full Brush/container/Edit/recipe authoring and rendering stay outside this closed plan. No automatic learning, telemetry or commercial-license activation is introduced. [Capability matrix](../Current_System_2026-10-05/CAPABILITY_MATRIX.md) is the extension authority, not a list of remotely invocable UI controls.

## Primary contracts consulted

- [Autodesk HelperObject](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_helper_object.html) and local 2027 `object.h` transform lifecycle comments; [ReferenceTarget](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_reference_target.html)/[INode](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_node.html) for references and hierarchy writes.
- [MAXScript fileIn compilation](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Introduction/Accessing-MAXScript/GUID-86D82FCE-B88F-4487-9B34-B6222EDA1C71.html): dependent probes compile after definition loading, not in the same precompiled block.
- [Node Event System](https://help.autodesk.com/cloudhelp/2026/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Change-Handlers-and-Callbacks/GUID-7C91D285-5683-4606-9F7C-B8D3A7CA508B.html): message-loop and mouse-up/delay behavior matter in scripted fixtures; passive idle checks must not manufacture observer updates.
- [Updating scripted plugins](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Plug-ins/GUID-44D4AC45-65DD-401B-B4A1-07B71B35D544.html): the old version remains visible in `on update` before Max sets the new version. The handler marks unsupported records persistently; the private-host test establishes that an exception alone does not abort scene loading.

These contracts support the implementation choices; they do not replace concrete runtime or pointer tests.
