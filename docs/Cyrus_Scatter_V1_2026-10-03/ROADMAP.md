# Next work after the v1 foundation

The native UI, scene-owned Brush, stable candidate path and existing retained display form the baseline. Keep the plugin usable while adding capabilities. Each step needs a reproducible fixture and an output invariant before a performance comparison.

## 1. Artist qualification of this build

Try the v1 package in saved copies of real projects. Check single-click native headers, layer switching, viewport hiding, Manual/Real-time publication, curved painting, history edits, Undo/Redo, Copy, save/reopen, CS Edit and final rendering. Qualify the boss's Max 2026 installation in that actual host. Add the renderer/proxy types used at work; current new render evidence is Scanline only.

Keep source complexity, preview mode/budgets and displayed counts with every timing. Separate scene loading, first generation, stroke commit, Update and camera navigation. A controller removal control and equivalent native instances help distinguish plugin overhead from unavoidable drawing cost. Prefer reproducible failure steps over a generic FPS screenshot.

Acceptance: no loss of strokes or placements on supported inputs, correct final visibility semantics, stable caches during idle/navigation, and documented failures for unsupported combinations. Fix reproduced regressions before extending the feature set.

## 2. Shared plant groups and collision correctness

Artist feedback identified confusion between a plant group, its Brush mask and the shared receiving surface. The [installed 1.0.1 diagnosis](../Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_REVIEW.md) also reproduces independent mask dots, collision-before-mask underfill, removed raw blockers, mutually empty blocker groups and blockers ignoring CS Edit moves.

Implement the [shared planting-group plan](../Artist_Zones_Integration_2026-10-03/PLANTING_GROUPS_IMPLEMENTATION.md) before new zone types or display detail features. Reuse the current records and native editor, bind painting to the active group on the shared surface, clarify placed versus displayed counts, and evaluate an explicit new spacing policy against accepted final placements in stable priority order. Preserve existing scene behavior until explicit conversion. Product changes remain pending; the new diagnostic intentionally characterizes the current limitations.

Acceptance: grass plus red/blue/yellow painted groups on a plane and sphere; independent erase/history; deterministic shared spacing; no removed or stale edited blockers; centre/Mesh identity agreement when uncapped; explicit Manual and budget status; stable Edit/persistence/Undo contracts and retained navigation performance.

## 3. Unified artist zones

Use the existing Area spline/mesh and Analyzer support first. Add durable zone IDs, human labels and vegetation roles as procedural input; layer GUIDs already provide the ownership foundation. Keep the surface binding, zone mask, Brush mask, base density and layer settings separately inspectable. Specify union/intersection/subtraction instead of inferring it from overlapping shapes.

A zone can restrict several layers, and one layer can use several zones. Define coordinate/scale/unit rules, target validation, ownership and Undo before adding a convenient manager. Preserve existing include/exclude and directional blocker semantics; introduce symmetric pair-gap rules only as an explicit option with its own tests.

Acceptance fixtures: spline versus equivalent mesh zone, overlapping Grass/Shrubs/Trees, exclusion holes, transformed targets, deletion/rebinding, copy, deterministic seeds, layer-order rules and save/reopen. New zones must not make the editor perform geometry work during browsing.

## 4. Density visualization and reuse

The saved procedural document remains authoritative. Artist feedback now establishes the need to distinguish painted coverage from plant-centre dots; the plant-group plan above handles that first. A continuous coverage overlay needs its own bounded display experiment. A grayscale image can be a derived export or a separate input, but requires explicit UV/channel, resolution, unit/domain and filtering metadata. Do not silently generate an atlas or replace surface-anchored strokes with pixels.

Start with export/import on a planar domain and strict matching metadata. Then evaluate existing UVs on curved targets. Test deterministic replay, seams, nonuniform scaling, missing maps, target mismatch and sampling error. Reusable stroke/document transfer to matching targets needs a fingerprint/remapping contract distinct from image exchange.

## 5. Broader Brush combinations

Add a mask-constrained Relax/Final Relax solver: moved points must remain on the receiver and inside the intended field, with stable identity and explicit underfill behavior. A simple final rejection may be sufficient before a more complex solver; compare both on output quality and cost. Multi-target documents and animated/deforming targets each require explicit reference and invalidation policies.

Only optimize replay/index building after profiling long real histories. Keep the exhaustive/reference evaluator as a correctness oracle. Measure time/memory per target, stroke, index build, query and publish. Max SDK calls remain on the host thread; copied plain-data work can use bounded CPU workers when its size justifies it.

## 6. MCP integration with the new inputs

Extend the provider-neutral API to inspect stable layer/zone identities, source roles, surface bindings and committed mask summaries. Include world bounds, units, surface normals and protected regions for spatial reasoning. A future plan should name enrolled assets/zones, not select arbitrary objects by name or run arbitrary scripts.

Brush/zone mutations need bounded operations, versioned payloads, artist review, local approval, exact idempotency, revisions and Undo/rollback. Add protocol tests and real host failure injection before exposing them as tools. The existing schema 1.0 remains usable while this extension is designed. CAD/PDF plan registration and camera/reference composition are subsequent modes with their own input validation.

Custom ML comes after a useful deterministic API and representative, consented examples. Record versions, units, seeds, source roles, zones, settings, camera and artist corrections; operational connection journals are not a training dataset.

## 7. Heavy-scene wide-to-close display

Return to the [heavy-scene roadmap](../Heavy_Scene_Viewport_2026-10-02/ROADMAP.md) and the [retained Mesh results](../Retained_Mesh_Preview_2026-10-02/RESULTS.md). Point Cloud / Proxy / Mesh already exist; automatic projected detail is not implemented in v1. Compare the same foliage and camera path with retained buffers, spatial culling and a bounded on-screen point/detail budget. Specify Preview versus Full Detail and the cost of switching.

Evaluate point hierarchies or per-source levels before selecting a GPU API. Near-camera refinement must preserve recognizability without global resampling, flicker or repeated uploads. Test grazing/bird's-eye views, close inspection, selection, device reset and memory limits. Keep final geometry exact. The FStorm video demonstrates a feasible user experience; it does not disclose its private algorithm or prove unbounded hardware capacity.

Acceptance: measured presented frame times in a specified heavy scene/hardware configuration, no camera-triggered placement generation, bounded uploads/memory and consistent render/bake output. GPU compute is justified only if a measured computation boundary remains important after simpler caching and data-flow improvements.

## Working loop

Record the question and current control → build the smallest experiment → verify output/Undo/lifecycle → measure the relevant work → retain or reject the idea → update the evidence and artist guide. Keep only source/docs and selected evidence in Git. Preserve dated findings and identify what a new result supersedes. End each loop with a usable package and an explicit remaining qualification boundary.
