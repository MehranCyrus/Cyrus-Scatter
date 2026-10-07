# Brush codebase integration audit

2 October 2026. Follow-up to the [decision guide](README.md) and [implementation plan](IMPLEMENTATION_PLAN.md). This audit adds concrete implementation locations to that plan; its milestones and E01–E14 remain the single acceptance checklist.

Scope: relevant generator/templates, generated MAXScript, native data bridges, cache/render/bake paths, persistence examples, threading and diagnostics. Source inspected at HEAD `1bfb400abc19b7472b4c20621970d435ac214c33` with existing uncommitted retained-display work. These are static observations, not measured Brush bottlenecks or newly demonstrated failures in a shipped Brush feature.

## CB01 Separate placement, source sampling and display work

**Observed:** [generated `cspImpl_refreshPreview`](../../AminScatter/scripts/AminScatterObject.ms) calls placements, source-point sampling and preview construction during one rebuild. Display controls ultimately use this rebuild path. A single dirty flag does not distinguish paint acceptance from base-generation or source-geometry changes.

**Required for Brush:** keep the reusable identified base, evaluated acceptance and display snapshot separate. A Brush-only edit must not rerun the sampler or resample unchanged plant meshes. Cache source samples using the resolved geometry/representation, object-offset mapping, sample count, seed and relevant validity/revision. Color/style changes should not invalidate source geometry. Avoid hashing all mesh contents on every mouse event.

Implement the initial separation only for the new Brush path. Use existing output builders with completed accepted subsets before considering a general cache refactor. In E08, count base generations and source extractions: unchanged inputs should cause zero of either during a warm paint stroke.

## CB02 Publish a complete preview without clearing the valid one first

**Observed:** the same rebuild resets `cachedPoints`, radii and counts before entering its build, clears the cache on failure, then sets dirty false. That does not implement the new Brush plan's last-valid-display behavior.

**Required:** assemble provisional preview data in temporary ownership, then replace the published cache and counters together after success. On a Brush failure retain the old completed display with a stale/error status; do not call it current. A valid empty mask is a successful empty result and must replace the previous display.

Keep retry state explicit so failure does not cause endless work on every redraw. Test both failure and legitimate zero-population publication in E12/E14. Preserve the renderer's explicit failure behavior rather than silently rendering the stale viewport snapshot.

## CB03 Preserve metadata across native/MAXScript boundaries

**Observed:** [`max_bridge.cpp`](../../AminScatter/src/max_bridge.cpp) exports placements as exactly `#(transform, sourceIndex)`. Its final-pass reader rebuilds Instance records with triangle zero. [Boundary falloff](../../AminScatter/src/boundary_falloff_bridge.inc) and [orientation](../../AminScatter/src/orientation_bridge.inc) also reconstruct records from those two fields. Several consumers require rows of size two.

**Required:** adding candidate ID/barycentric fields to `Instance` alone is insufficient. Recommend an owned native CandidateBatch for the Brush path, with keys/anchors retained through existing algorithm calls. Materialize legacy rows only at consumers that do not need provenance. Keep current public row APIs unchanged for Brush-disabled callers.

Each operation must return the corresponding surviving metadata or update anchors when positions move. Do not keep an untracked side array indexed by compacted rows. Test the complete filter/move/edit chain, not only the initial scatter function.

This is the main integration seam to design before M2. It reuses existing algorithms; it does not require another scatter engine.

## CB04 Validate active paint targets even in Manual mode

**Observed:** [`externalChanged` and `invalidateLive`](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/before.ms) intentionally gate ordinary live invalidation on Realtime. Node-event delivery is batched and delayed until mouse-up by [the performance stages](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/performance.cjs).

**Required:** distinguish “do not regenerate plants automatically” from “the painting surface is still valid.” An active Brush session needs target reference/geometry/transform validation in both modes. Invalidate or suspend before accepting another sample after a relevant change; do not wait for the normal preview timer to refresh an obsolete hit mesh.

Keep Manual's existing viewport behavior. This is a Brush-session validity channel, not a reason to enable global Realtime. Extend E07/E12 with target transforms, modifier changes, deletion and Undo while Manual painting is active.

## CB05 Give render, IR and bake explicit Brush revisions

**Observed:** [`CyrusPFKey`, `CyrusPFBuild` and `AminScatterRenderBegin`](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/pflow.ms) govern render transport. Detailed layer-property polling is inside the Realtime branch. `refreshAll` advances a separate manual revision. Render and [`bakeInstances`](../../AminScatter/scripts/AminScatterObject.ms) call placements again; neither simply consumes the viewport cache.

**Required:** include a compact committed paint revision and binding validity in render input keys. Merely adding a ReferenceTarget property to the generic field list must not be assumed to detect edits inside that holder. Never stringify complete stroke history for periodic key polling.

Define distinct update intent for Brush-enabled layers:

| Consumer | Required Brush state |
| --- | --- |
| Cursor/mask overlay | Active provisional stroke, visibly provisional |
| Realtime plant preview | Most recent complete accepted result; pending status if behind |
| Manual plant preview and IR | Last explicitly applied state until Update |
| Production render / explicit bake | Current committed paint and valid current inputs, resolved at the operation boundary |
| Saved scene | Committed document; never just a provisional or disposable preview |

This makes the previous plan's render promise concrete. Production preparation must detect a committed paint change even when a Manual preview/IR key is unchanged. Qualify behavior on Brush-enabled layers without silently changing legacy Manual policy for old scenes.

Baking creates artist-owned scene instances and sets `autoRender=false`; later painting must not quietly rewrite those baked nodes. Mark output stale or clearly require an explicit rebake/removal workflow. Exercise E10/E13 with both auto-render and baked output.

## CB06 Make Brush Undo local without weakening other Undo handling

**Observed:** [`AminScatterLayerUndo`](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/before.ms) walks every controller/layer on every scene Undo/Redo and calls `forcePreviewUpdate`. That resets build counts and can make unrelated layers rebuild. A local Brush restore object alone would not prevent this broader callback.

**Required:** provide an explicit affected-layer/dependent-layer path for Brush-owned Undo/Redo. Ensure the existing global callback recognizes that completed handling or reconciles revisions without forcing unrelated generations. Retain the conservative fallback for changes whose dependencies are not known.

Measure Undo with several independent controllers plus one real blocker dependency. Only the actual dependent set should rebuild for a Brush-only operation. Do not use an unscoped global “skip next Undo” flag that can swallow unrelated artist edits.

## CB07 Persist and copy the native holder deliberately

**Observed:** [`AminScatterCopyLayer`](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/before.ms) copies controllers/arrays and directly assigns other values. Its current generated uses include older-scene migration; it is not evidence of an existing dedicated Copy Layer UI. A newly added maxObject holder would otherwise need explicit copy policy.

[Native storage](../../AminScatter/src/cyrus_edit_storage.inc) and [class-descriptor registration](../../AminScatter/src/edit_plugin.cpp) provide examples to study. The transient native preview Value is not a saved document.

**Required:** register a stable persistent Brush class through the existing plugin registration arrangement, and verify fresh-process save/open without the Brush UI. Explicitly distinguish migration transfer, independent controller/layer copy and intentional Max object instancing. Do not clone the document on every ordinary surface synchronization.

Save/reset callbacks for [PFlow](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/pflow.ms) and [retained display](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/retained-points.cjs) delete disposable objects at different lifecycle hooks. Brush must finish/cancel its transaction at a safe boundary and retain authority in the layer-owned holder through both cleanups. Test callback ordering, reopen and script reload in E03/E12.

## CB08 Integrate with the generated and lazily mounted UI

**Observed:** [`generate.cjs`](../../AminScatter/tools/ui/generate.cjs) creates separate rollout declarations for ten layer slots, replaces the old render block with PFlow, then applies ordered transformation stages. [Host UI](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/templates/host.ms) rebuilds panels on resizing; the performance stage mounts layer contents lazily.

**Required:** create Brush controls for all supported slots through the generator, with explicit anchor-count checks. Place new UI before responsive transformation and account for trace-wrapper anchors. Validate generated output in a disposable directory so generator checking cannot overwrite unrelated working changes.

Bind an active session to the actual layer object/ID, not an activeLayer index or rollout singleton. Panel collapse, resize, selection change and deletion must not silently transfer the stroke to another layer. The session/data lifetime belongs outside disposable UI controls; define whether a UI transition suspends or finishes interaction.

## CB09 Reuse existing compute and test infrastructure

Useful existing pieces:

- [Pure C++ core and native tests](../../AminScatter/CMakeLists.txt): add a host-independent Brush evaluator to the existing library/tests.
- [`forRanges`](../../AminScatter/include/execution.h): synchronous bounded participation on owned numeric data, with worker joins and serial fallback. Reuse only after profiling; spawning workers for every tiny dab may cost more than serial evaluation.
- [Spacing grid and projection code](../../AminScatter/src/spacing.inc): inspect reusable pieces, but nearest-point projection is not camera-ray picking and does not supply surface adjacency. Preserve the known face/tie qualification requirement.
- [Trace hooks](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/trace.cjs) and [performance monitor](../../tools/performance/CyrusPerformanceMonitor.ms): extend existing recording instead of adding a competing profiler.
- [Viewport lifecycle fixtures](../../tools/tests/viewport_performance_smoke.ms) and [retained-display lifecycle fixtures](../../tools/performance/retained_integration/lifecycle.ms): extend their isolated patterns for Brush clone/save/mode-switch tests. Existing fixtures are not Brush qualification.

Expose compact Brush statistics: active/committed/applied revisions, surface conversions, base generations, source-sample rebuilds, affected queries, replay work, pending publications, upload bytes and retained memory. Preserve existing `cacheSnapshot` positions or version its consumers explicitly. The monitor intentionally does not retain native preview caches; keep that property and avoid copying full strokes every observation.

## Prioritized implementation delta

| When | Codebase work |
| --- | --- |
| M0 | CB04 target validity; CB08 session ownership independent of panels; measure Painter separately |
| M1 | CB01 reusable base/field separation, CB02 transactional publication, CB03 identified native batch, CB07 durable holder; use CB09 fixtures |
| M2 | CB03 all supported bridges, CB05 consumer/revision policy, CB06 scoped Undo, complete CB07/CB08 product lifecycle |
| M3, only if measured | Broader source-sample caching across layers, regional uploads, spatial partitioning or parallel field evaluation |

The highest-value performance change for Brush is avoiding unnecessary base generation and source extraction during a stroke. Its speedup is not yet quantified. Correctness priorities are metadata preservation, Manual-mode surface validity and consistent committed output.

No production code, generator output or scene was changed by this audit. Native or Max runtime tests were not run: the deliverable is the implementation map and updated acceptance requirements.
