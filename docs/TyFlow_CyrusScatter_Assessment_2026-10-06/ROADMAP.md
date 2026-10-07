# Prioritized implementation roadmap

These are proposals, not implemented changes. The assessment changed documentation only. Source references and evidence labels are defined in [EVIDENCE.md](EVIDENCE.md); controlled cases are in [EXPERIMENTS.md](EXPERIMENTS.md). Preserve existing deterministic placements, owner/source identities, Manual semantics, retained Mesh/Point Cloud display, lifecycle guards, licensing and MCP policy 3.

Order: correct owner routing; expose the existing recorder and establish identities; build the selected-layer Modify view; measure binding, drawing and renderer costs; then optimize only the demonstrated bottleneck. The Corona and host-lifecycle gates can be investigated alongside the UI work but must remain explicit release gates.

## R0 — Correct popup owner routing before packaging

**Classification:** Applicable now. **Priority:** P1 correctness, first change.

**Problem:** A popup retarget to a different layer/root can take the built same-topic return. Its title and editor owner change, but child controls remain bound to the preceding owner. Editing can alter the wrong layer. This is finding F1, a source-traced regression rather than an interactive reproduction.

**Evidence:** [layer-editor.ms:112](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/layer-editor.ms#L112), [retarget:145](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/layer-editor.ms#L145), [bindEditors:87](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/layer-editor.ms#L87), and [generated mainUI.bind:4484](../../AminScatter/scripts/AminScatterObject.ms#L4484). The setup bind does not repair popup child references.

**Change and smallest implementation:** On a context change, rebind the retained active controls and selector lists under existing write suppression. Permit the same-topic shortcut only when root, owner and selected paint-set context are already bound. Invalidate inactive sections until next use. Do not recreate controls or request calculation to repair references.

**Benefit/tradeoff:** Correct edit destination while retaining lazy controls and same-context no-ops. A genuine owner change must pay its necessary binding cost; skipping that cost is unsafe.

**Acceptance:** E1 passes for two layers and two Scatter roots on every built topic, including a remembered topic and different set lists. All active section references and displayed values match the chosen owner. One edit changes only that owner, with one meaningful Undo action. Browsing causes zero generation, publication, bridge-build and unchanged upload increments. Clicking the already selected topic performs no redundant binding.

**Uncertainty:** The interactive manifestation and all host callbacks were not executed here. First reproduce the routing error with distinct source lists, then verify the candidate in the same fixture. Keep failure visible; a later Refresh that masks stale binding is not a pass.

## R1 — Make existing diagnostics directly usable and identify every trial

**Classification:** Applicable now. **Priority:** P2 observability, before further performance claims.

**Problem:** A recorder already exists, but normal Scatter editing lacks direct Record/Stop/Export controls. Current counters do not connect every input cause to UI and stage durations. A 0.7.1 caption identifies multiple different script/native candidates.

**Evidence:** [diagnostics.cpp:33](../../AminScatter/src/diagnostics.cpp#L33), [record path:67](../../AminScatter/src/diagnostics.cpp#L67), [direct primitives:25](../../AminScatter/src/diagnostics_bridge.cpp#L25), [script instrumentation](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/diagnostics.cjs), and the [snapshot identities](EVIDENCE.md#snapshot-and-measurement-identity). This is F5, not a missing backend.

**Change and smallest implementation:** Add a small diagnostics section to Scatter's own UI over existing primitives. Provide explicit recording, stop and bounded export; show cached recorder health. Add bounded correlation/reason and coarse duration fields for validity, capture, prepare/solve, publication, UI bind/layout, upload deltas and renderer phases. Record full script/module identities once per campaign, outside hot frame paths. Read cached build metadata thereafter.

**Benefit/tradeoff:** Artists can collect actionable evidence without MCP. Enabled instrumentation and file export have a cost; keep expensive detail optional and measure recording overhead independently.

**Acceptance:** Recording is default-off; no recording-only timer or full-input serialization runs when disabled. Retain the current event-count, storage, duration and field bounds; expose drops/evictions/truncation. Set an explicit export byte cap including metadata/encoding, and reject or truncate with a visible status. Cancelled/failed export preserves the bounded snapshot and does not evaluate the scene. Record/Stop/status/export work with MCP absent and policy 3 remains read-only. An export distinguishes full-file SHA, payload marker and loaded module hashes. E0/E2/E3 validate attribution and overhead.

**Uncertainty:** Existing upload counters are partly process-wide. Start with an isolated owner fixture and clearly label their scope; introduce per-owner attribution only if required. Timer dispatch must not replace the original invalidation reason.

## R2 — Put one selected-layer view in standard Modify

**Classification:** Applicable now as the requested workflow; qualify a bounded prototype before replacing the existing view. **Priority:** P2 product requirement, after R0.

**Problem:** Modify currently mounts setup controls while primary layer editing opens the popup. The desired integrated workflow is not implemented. Duplicating authored state across hosts would create divergence and Undo ambiguity.

**Evidence:** [generated mainUI:4508](../../AminScatter/scripts/AminScatterObject.ms#L4508), [section factories:4503](../../AminScatter/scripts/AminScatterObject.ms#L4503), [rollout_flow.cpp:10](../../AminScatter/src/rollout_flow.cpp#L10), [current UI report](REPORT.md#recommended-modify-structure), and Autodesk contracts A5–A6. The existing lazy section/binding code is reusable infrastructure.

**Change and smallest implementation:** Keep Setup/Update, Receiving Surfaces and the ordered Layers list. Add one selected-owner header/set selector and normal rollouts for Assets, Population, Paint, Transform and Spacing, with cached results/display/diagnostics reachable. Use existing section factories and shared parameter validation/writeback routines. Each host owns separate controls over the same persisted root/layer/set objects. The optional popup retains its own chosen owner; it does not steal/reparent Modify widgets.

**Benefit/tradeoff:** Primary editing follows Max's standard workflow; control count scales with visible sections rather than complete UIs for every layer. A second open view requires affected-field synchronization and owner validation. Cold control creation still has a cost.

**Acceptance:** All 241 inventoried controls/feature families remain reachable in the appropriate contexts, including per-source, Brush/Edit, pair rules and advanced options. Selecting a layer uses its stable identity; reorder does not reset settings. Browsing has zero calculation/publication/bridge-build/unchanged-upload deltas after initialization. Both views edit the same model with one Undo transaction per edit and no notification loop. E1/E2/E11 pass load/reset/clone/delete/Undo, scrolling, ordering, resize and DPI cases. A popup can remain valid while selecting a source model changes Modify context.

**Uncertainty:** Headless mounting checks do not establish visual correctness or latency. Prototype one representative layer/set section in the existing native command-panel ownership path. Measure cold/warm behavior before expanding. Qt is an alternative only if this prototype demonstrates a specific host limitation.

## R3 — Narrow UI refresh work after tracing it

**Classification:** Worth measuring first. **Priority:** P2 potential interaction latency.

**Problem:** Active-topic binding traverses all its sections and reconstructs some source/color lists. The reported dropdown latency is unmeasured; opening/cancelling a list may use a different path from selecting an item.

**Evidence:** [layer-editor.ms:87](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/layer-editor.ms#L87), [source bind:444](../../AminScatter/scripts/AminScatterObject.ms#L444), [source lists:326](../../AminScatter/scripts/AminScatterObject.ms#L326), and F3. tyFlow's private binding strategy is unknown.

**Change and smallest implementation:** Measure E2, then retain unchanged list contents and refresh only the affected section/field family. Use existing owner/revision contracts and binding guards. Restore guards on failure. A context change still forces complete active-section binding as R0 requires.

**Benefit/tradeoff:** Reduces native-control churn and owner-list work if those dominate latency. More selective invalidation can miss changes; avoid a new generic observer framework before concrete field dependencies are established.

**Acceptance:** No-op selection, list open/cancel and repeated same-topic clicks generate zero model writes, Undo entries, list replacement and solve/upload increments. Owner changes and real source-list changes refresh correctly. As provisional design targets on a recorded reference machine, warm UI response should be within 100 ms at p95 and cold selected-section creation within 250 ms at p95. These are proposed UX budgets, not measured results; report actual cold/warm CPU and visible-response distributions separately. If necessary operations exceed them, document scaling and revise the design rather than hiding work in an idle poller.

**Uncertainty:** Control binding, layout, dropdown population and redraw may contribute differently. E2 must identify their counts and durations before optimizing any one. Scaling should be tested at 1, 32 and the supported maximum 1,024 registered source rows, not by inventing unlimited layer counts.

## R4 — Separate drawing cost; pilot retained Proxy only if it dominates

**Classification:** Worth measuring first. **Priority:** P2 viewport performance.

**Problem:** Mesh/Point Cloud retain GPU items; Proxy uses cached CPU triangle batches submitted each redraw. Historical large-count Proxy timings are poor, but the latest presented FPS is unknown.

**Evidence:** [geometry_preview.inc:43](../../AminScatter/src/geometry_preview.inc#L43), [preview.cpp:161](../../AminScatter/src/preview.cpp#L161), [Mesh draw:91](../../AminScatter/src/mesh_display.inc#L91), F4, and [historical navigation boundaries](EVIDENCE.md#snapshot-and-measurement-identity). Autodesk A1 distinguishes preparation from repeated drawing.

**Change and smallest implementation:** Run E4's current-identity comparison first. If Proxy draw/submission dominates, prototype retained items over the same existing proxy geometry/batches and immutable-generation lifetime. Preserve Mesh/Point Cloud paths and an explicit fallback. Bound instance/geometry storage before supporting high counts.

**Benefit/tradeoff:** Could remove repeated per-triangle host submission. Additional GPU/system buffers and device-lifecycle handling increase peak memory. Retained storage does not eliminate drawing, overdraw or renderer work.

**Acceptance:** Identical proxy shape, transform, color, visibility and count semantics; no placement changes. After visible realization, unchanged frames cause zero publication/upload increments. Compare median and tail frame times and submission time against the current path at identical count/triangles/camera/material settings. A useful pilot must reduce the demonstrated dominant stage without materially worsening tails or exceeding declared buffer budgets. E6/E7 qualify partial culling and recovery. Disable the pilot if the current bottleneck is elsewhere.

**Uncertainty:** Proxy's exact latest cost, GPU limitation and group-culling granularity remain unmeasured. Older redraw timing is neither current source evidence nor presented FPS. Do not run an unbounded 100k Proxy trial merely to reconfirm a known historical stall.

## R5 — Resolve the Corona stop failure on identified bytes

**Classification:** Applicable now as qualification; no speculative behavior fix. **Priority:** P1 release gate G1.

**Problem:** A user reported Corona IR stop failure code 2. Save/open/reset callbacks and IR refresh can be interrupted, but the installed candidate and meaning of that return value are not established.

**Evidence:** [generated scene-change:4975](../../AminScatter/scripts/AminScatterObject.ms#L4975), [save:4980](../../AminScatter/scripts/AminScatterObject.ms#L4980), [IR phase:4985](../../AminScatter/scripts/AminScatterObject.ms#L4985), and [UI checkpoint](../UI_Performance_2026-10-06/README.md). No matching primary API contract for code 2 was found.

**Change and smallest implementation:** Execute E5 in a permitted private synthetic campaign with exact renderer, host, scripts and modules recorded. Inspect the installed public interface contract; trace request/stop/wait/build/start and callback reentry. Change only the demonstrated state/return-handling defect after reproducing it.

**Benefit/tradeoff:** Protects scene lifecycle and prevents invalid IR restart logic. Renderer calls can pump host messages; explicit error/pending states and reentrancy protection remain necessary.

**Acceptance:** Active/inactive and docked/floating IR, repeated edits, explicit stop, save, reset and opening a synthetic file settle with no runaway timer, lost error or stale transport. Unchanged published input causes no gratuitous stop/build/start. A failed stop never proceeds as though IR is safely stopped. A corrected return interpretation must be supported by the exact version contract or reproduced state plus documented uncertainty.

**Uncertainty:** The reported installed line number belongs to potentially different bytes. Do not label code 2 success, ignore it, or suppress the callback error without establishing its semantics. Production-render correctness is a separate gate from IR convenience.

## R6 — Close targeted correctness and lifecycle coverage gaps

**Classification:** Applicable now for qualification. **Priority:** P2 coverage, plus existing product release gates.

**Problem:** Current tests meaningfully verify intervals, output and counters but bypass delayed node delivery in key fixtures, do not create actual partly unrealized retained groups, and do not qualify current visual UI or Max 2026 runtime. Existing Brush/Edit identity migration remains an independent concern.

**Evidence:** [Max fixture:18](../../tools/procedural_lab/Max_Playback_Regression.ms#L18), [cull fixture:204](../../tools/procedural_lab/Max_Playback_Regression.ms#L204), [Analyzer fixture:5](../../tools/procedural_lab/Max_Analyzer_Playback_Regression.ms#L5), F6, and [existing live next work](../Live_Runtime_2026-10-06/NEXT_WORK.md). BR-01 concerns signed-zero/subnormal versus ordinary-coordinate identity round trips, not a newly discovered tyFlow issue.

**Change and smallest implementation:** Extend specific existing synthetic fixtures: real enabled delayed dependency notifications; UI routing/lifecycle; actual partial culling; supported device/backend recovery; source-container animation; Max 2026 host behavior. For BR-01, preserve and compare old identity inputs and exact vertices/faces before any compatibility change.

**Benefit/tradeoff:** Tests the missing host behavior rather than multiplying equivalent per-placement assertions. Visual/renderer campaigns are more expensive; keep them bounded and identify candidate/hardware each time.

**Acceptance:** E1/E3/E6/E7/E9/E10/E11 pass with explicit expected counters, visible outcomes and no perpetual idle timers after settling. Real dependent edits change output; unrelated events do not. Old authored Brush/Edit data either loads correctly or retains a clear genuine-topology rejection; never disable identity checks wholesale. SDK build success is not substituted for Max 2026 runtime results.

**Uncertainty:** Device recovery may require supported resource recreation even without placement changes. An animated model entering a source rectangle may depend on registration/notification semantics not covered by the present clock fixture. Test these contracts before broadening invalidation.

## R7 — Optimize measured pure calculation kernels and allocations

**Classification:** Useful later, only after a dominant calculation stage is measured. **Priority:** P3 opportunity.

**Problem:** Dense spatial cells, disparate radii and refill rounds can increase neighbor visits and blocker/grid allocations. There is no current stage/memory profile proving which data structure should change.

**Evidence:** [procedural.cpp:23](../../AminScatter/src/procedural.cpp#L23), [protected reservations:99](../../AminScatter/src/procedural.cpp#L99), [group_spacing.cpp:31](../../AminScatter/src/group_spacing.cpp#L31), [workers:32](../../AminScatter/include/execution.h#L32), and C5–C7. Current admission and visit bounds already prevent unbounded work.

**Change and smallest implementation:** Run E8 first. Reuse scratch/vector capacity or reserve predictable buffers in the demonstrated hot stage before introducing a hierarchy or pool. If parallelism helps, extend an independent copied-data kernel; preserve ordered final acceptance. Incremental layer reuse requires complete dependencies, including future protected reservations and cleanup/refill interactions.

**Benefit/tradeoff:** Less allocation or neighbor work can improve edits while preserving output. Retained scratch increases steady memory; broad incremental caching increases invalidation complexity. More participants may contend with Max/IR or memory bandwidth.

**Acceptance:** Exact stable candidate/accepted IDs, transforms, rules, shortfalls and failures match the serial reference across seeds, thread limits and rewind. Current limits remain enforced. Measured dominant-stage time or peak replacement memory improves on fixed fixtures; record full distributions, not a best trial. No worker touches SDK scene state, MAXScript or materials; all workers join on success/error/shutdown.

**Uncertainty:** Hash-cell density, recipe-key construction and host geometry capture may dominate different scenes. Do not replace the grid, prescribe SoA, introduce an asynchronous solver or increase the four-participant default without evidence.

## R8 — Define parameter contracts for both views and future tools

**Classification:** Applicable now for shared UI contracts; useful later for expanded authoring/AI. **Priority:** P2 model consistency, P3 future capabilities.

**Problem:** Two views and later tools need identical validation, ownership and Undo rules. Reading a completed publication must remain separate from initiating a solve or writing authored settings.

**Evidence:** Current persisted model C3–C4, [published reader](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/publication-read.ms), [MCP cached diagnostics:72](../../CyrusMCP/cyrus_mcp/server.py#L72), and [parameter contracts](REPORT.md#parameter-contracts-mcp-and-future-ai).

**Change and smallest implementation:** For the UI fields being reused, document stable parameter name, owner scope, units/type/range, animation and capability gates, normalized value and affected revision/stage. Route both views through the existing setter/Undo boundary. Read pending/error/completed epoch from cached runtime state. Later authorized proposals may reference stable IDs and an input epoch with validation before an explicit apply action.

**Benefit/tradeoff:** Prevents view divergence and supports explainable, stale-safe future tool requests. Metadata must be maintained with actual setters; an exhaustive new schema framework is unnecessary for the first shared section.

**Acceptance:** Identical inputs through Modify/popup validate and produce identical owner/revision/output behavior. Presentation-only changes do not dirty placement inputs. Same-value writes are suppressed. Cached reads perform no solve or write. Policy-3 authoring remains refused; no model training/prediction or automatic scene changes are implied. Future capability tests must distinguish read, propose, validate and authorized apply.

**Uncertainty:** Expanded policy-3 write contracts and ML ranking/training are not implemented or qualified by this assessment. They need separate product authorization, data/evaluation design and lifecycle testing.

## R9 — Do not add complexity without a demonstrated product need

**Classification:** Unnecessary for the current product.

**Problem/requirement:** Learn from tyFlow without importing a general particle simulation engine or assuming C++/Qt/GPU automatically creates responsiveness.

**Evidence:** tyFlow T1–T12 document capabilities rather than private engine algorithms; Cyrus already has native copied-data kernels, bounded ordered solving and retained display C5–C9. No measured case establishes a need for full migration.

**Proposed decision and smallest implementation:** Keep the current hybrid architecture. Do not introduce a full native rewrite, arbitrary event/history simulator, generic asynchronous DAG/task system, GPU compute port, new thread pool, or per-layer control trees merely to resemble another plugin. Perform R0–R8's focused work instead.

**Benefit/tradeoff:** Preserves validated behavior and avoids extra ownership, invalidation, migration and GPU-transfer risks. This may forgo a later useful specialization until a concrete bottleneck is demonstrated.

**Acceptance:** Roadmap changes retain existing source/owner/placement identity and output contracts. Any future architectural expansion states a measured dominant cost, smallest prototype, memory/host-safety constraints, deterministic fallback and comparison result before adoption. Licensing remains untouched.

**Uncertainty:** Future product scale or asynchronous editing requirements may justify new machinery. Revisit only with those requirements and measurements, rather than treating this classification as a permanent ban.
