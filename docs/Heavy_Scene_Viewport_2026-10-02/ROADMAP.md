# Roadmap and working checklist

Date: 2 October 2026. This backlog implements the owner's choice of a fast preview and a full-detail switch. Completion means the stated evidence exists, not that a report suggested the idea. This is a sequence of bounded engineering loops, not a promised delivery calendar.

**Mesh loop completed:** [0.64 uses retained GPU instancing](../Retained_Mesh_Preview_2026-10-02/README.md) at unchanged geometry limits. [Accepted measurements](../Retained_Mesh_Preview_2026-10-02/RESULTS.md) include visible artist foliage, a native Max control, 61.7M-triangle stress navigation, transform/appearance checks, lifecycle and allocation limits. Max 2026 runtime, a second GPU, device recovery and wider studio qualification remain open. Point-cloud automatic detail selection below is still future work.

## Loop 1 — prove an inexpensive retained point preview

- [x] Reconcile the supplied reports with current source and previous experiments.
- [x] Verify relevant primary sources; identify Forest Pack's fixed retained budget and Autodesk's native display pathway.
- [x] Choose the product contract: explicit Preview / Full Detail, exact render data.
- [x] Write the implementation plan and keep the existing 0.62 work intact.
- [x] Build a separate native point-buffer experiment with both 2026 and 2027 SDKs.
- [x] Inspect visible points in interactive Max 2027 and record the finer retained pixel footprint.
- [x] Compare current GraphicsWindow, retained points and disabled drawing using identical exported data.
- [x] Verify stable data and no extra explicit buffer initialization/realization during unchanged navigation.
- [x] Sweep point budgets and source groups; record preparation and redraw costs, then check memory over repeated ownership cycles.
- [x] Exercise replacement, clear, hide/show, clone/delete, multiple viewports, real mouse navigation, reset and clean shutdown.
- [x] Record the result and accept the mechanism for integration, subject to preview appearance and product correctness gates.

**Exit:** a visible, reproducible result with raw data and a defined next action. Neither invisible geometry nor fewer displayed points counts as an equal-quality speedup.

**Outcome:** completed. [Results](RESULTS.md) document 11,880 accepted camera steps, a separately aligned presentation trace and preserved inputs. At one million preview points the retained camera-step median was 3.813 ms versus 73.194 ms for current drawing. Equal point data is verified; equal pixel footprint is not. The result authorizes the next engineering step, not a release claim.

## Loop 2 — integrate existing Point Cloud mode and ownership

**Implemented as candidate 0.63:** see [integration and measurements](../Retained_Point_Preview_2026-10-02/README.md). The owner clarified that Point Cloud / Proxy / Mesh already provide the mode choice. Full release qualification below remains separate.

- [x] Introduce a native display owner per controller; share an immutable snapshot with the GC cache using explicit lifetime management.
- [x] Publish only complete generations on the host thread. Camera movement consumes a completed generation; it does not run placement, source conversion or sampling.
- [x] Preserve the existing generator-owned Point Cloud / Proxy / Mesh controls and their artist settings, including budgets, color mode and enabled layers.
- [ ] State the actual visible instance/point/triangle count and active limits. Full Detail must not imply an unlimited or complete render population when a cap is active.
- [x] Keep the current native marker/proxy implementation as fallback for an unavailable retained path; make failures observable without repeated modal messages.
- [x] Set the native owner nonrenderable and nonconvertible; strip disposable nodes before save. Broader exporter/merge qualification remains below.
- [x] Define persistent state versus disposable buffers; rebuild on open and release on controller deletion/reset. Do not serialize GPU resources or raw pointers.
- [x] Add host checks for mode switches, source geometry edits, source failure/recovery, colors, empty data, manual/automatic mode, undo/redo, clone and save/open. Broader animated/transform cases remain below.
- [x] Verify exact final-placement fingerprints across display modes; unchanged computation suites pass.
- [ ] Measure cold edit-to-first-correct-preview latency and peak memory with the integrated owner; the prototype's already-warmed mode-switch timing is insufficient.

**Exit:** correct integrated behavior in the original copied scene plus supported synthetic fixtures, with no regression to render data or existing modes. Package only after this gate.

## Loop 3 — make heavy preview quality predictable

**Small correction already included:** exact budget selection replaces the rounded stride that could halve density just beyond a limit. All 43 original-scene sources currently sample, including Corona proxies; the earlier BushesCenter failure was not reproduced, so its original cause is not claimed fixed. The fixed-budget close-up gap remains the next acceptance target.

- [ ] Define supported mesh and renderer-proxy source extraction. Reproduce the BushesCenter sampling failure and implement a tested diagnostic/fallback policy.
- [ ] Compare fixed budgets at bird's-eye and close inspection distances. Include rare source types, boundaries, uneven densities and multiple controllers.
- [ ] Introduce a scene-wide budget if per-controller caps accumulate excessively. Preserve a useful minimum per visible layer.
- [ ] Evaluate a stable progressive sample ordering if the existing flattened stride causes missing plants or periodic patterns. Keep this as a display-only algorithm version.
- [ ] Share source samples across unchanged layers when stage timings justify it; key the cache by evaluated geometry, time, seed, sample policy and relevant display attributes.
- [ ] Measure selection separately. Keep picking bounded without losing access to the controller or selected instances.

**Exit:** an artist-approved preview default on representative scenes, plus a quality control whose cost is measured. Do not pick a magic point count from a competitor's documentation.

## Loop 4 — accelerate full-detail inspection

- [ ] Record the cost of current Mesh mode at fixed instances, triangles, source groups and viewport styles.
- [ ] Compare retained expanded geometry against the current path with matched face/color/depth behavior.
- [ ] Test shared source geometry plus GPU instance transforms if memory or draw cost warrants it. Preserve source material/UV semantics that the selected mode promises.
- [ ] Verify nonuniform and negative scales, object offsets, animated sources, selected/frozen/hidden states, multiple views, bounds and clipping.
- [ ] Respect existing CPU cache limits and introduce measured GPU/process limits with safe allocation fallback.
- [ ] Consider selected-region full detail as an optional workflow when complete detail exceeds the frame budget.

**Exit:** a justified display mode, with explicit quality and memory limits. Full detail may remain slower than preview; report that honestly.

## Loop 5 — add spatial levels only if needed

- [ ] First test coarse spatial chunks with bounds and frustum rejection.
- [ ] If required, build a hierarchy with stable precomputed point levels and conservative transformed bounds.
- [ ] Use projected size, budget and hysteresis to choose existing buffers. Avoid camera-triggered resampling and whole-cloud uploads.
- [ ] Measure CPU traversal, GPU work, upload traffic, object/item count and flicker across bird's-eye to ground-level transitions.
- [ ] Test multiple viewports with different cameras and budgets; do not let one view invalidate another's cache.

**Exit:** a measurable improvement over the simpler retained cloud. If quality and timing are already acceptable, leave this loop deferred.

## Parallel concern — editing and computation

This is a separate bottleneck queue, not a reason to delay the display experiment.

- [ ] Trace input → dirty notification → calculation → publication → first correct visible result for a named edit.
- [ ] Remove duplicate conversions or rebuilds before adding a broader worker system.
- [ ] Preserve the qualified bounded CPU path and exact output ordering.
- [ ] Use the surface tree only after matching face winners, normals and UV-dependent behavior at ties; keep small-mesh crossover measurements.
- [ ] Consider asynchronous work only with immutable owned inputs, generation checks, cancellation and safe host-thread publication.
- [ ] Consider GPU computation only when the complete operation is compute-bound and an actual transfer/dispatch/readback experiment beats the CPU path.

## Release qualification

- [ ] Max 2026 application runtime, not just SDK compilation.
- [x] Max 2027 interactive navigation and editing for the named 0.63 fixtures, with loaded binary/script identities; broader cases below remain open.
- [ ] Original scene and a substantially heavier foliage scene with complete supported sources.
- [ ] Renderer and IPR startup/stop, cancellation, scene reset and shutdown.
- [ ] Repeated switching/editing without stale resources or monotonic memory growth.
- [ ] A real 32 GB workstation and a second GPU/vendor where support is intended.
- [ ] Separate cold and warm behavior; report p50/p95/p99 milliseconds and input-to-visible latency.
- [ ] Installer/uninstaller, save/open, fallback behavior and the boss's Max 2026 handoff documentation.

## Rules for choosing the next loop

If unchanged camera movement rebuilds or uploads point data, fix retention first. If CPU submission is expensive but GPU time is low, reduce per-point/per-item submission. If GPU time dominates, reduce visible work through quality controls, grouping or spatial levels. If the disabled control is already slow, identify the non-scatter scene cost before attributing total FPS to Cyrus. If edits are slow but navigation is fast, work on the operation trace rather than the drawing backend.

A failed experiment still completes a loop when its cause and evidence are recorded. Complexity earns its place by improving a measured artist workflow.
