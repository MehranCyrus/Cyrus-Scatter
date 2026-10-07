# Source audit for artist zones and integrated painting

3 October 2026. Read with the [integration proposal](README.md). Findings below are from the inspected working tree, not a runtime reproduction. File hashes and the baseline Git status are in [audit.json](audit.json). Line numbers are inspection anchors and can move after edits; function names identify the relevant code.

## A01 — useful area filtering already exists

[max_bridge.cpp](../../AminScatter/src/max_bridge.cpp), `aminScatterAdvanced_cf`, lines 283–307 and `aminScatterValidArea_cf`, lines 385–397, accept closed shape curves and sample them into loops. [scatter.cpp](../../AminScatter/src/scatter.cpp), `AreaMask` and the rejection loop around lines 329–337, implement XY containment, Include union and Exclude precedence.

Reuse this as the first zone adapter. A drawn plane is not accepted as an Area node today. A receiving mesh can already be a scatter surface; converting a separate mesh into a projected zone is new work. The spline sampling uses pieces × 16 with a minimum of three; curved-boundary approximation and topology changes need a tolerance/accuracy test before presenting zones as precise CAD constraints.

Do not assume that every arbitrary input loop is valid because the node is closed. Add fixtures for self-intersections, nested loops, holes, duplicate/coplanar inputs, narrow boundaries and transformed objects. A reported plant centre inside a loop is not proof that its entire footprint fits.

## A02 — controller targets and row identities need a product model

[AminScatterObject.ms](../../AminScatter/scripts/AminScatterObject.ms), `layerSettings`, `syncLayerSurface` and `layerEntries`, around lines 11609–11666, store layer objects/names/enabled flags in parallel tabs and synchronize controller surfaces to each layer. `overlapBlockers` also references layer positions. Current UI construction is bounded to ten layers.

Add persistent layer/zone identities and explicit layer-local target subsets while retaining controller ownership. Translate legacy blocker indices at the boundary. Do not silently reinterpret a stored integer as a new ID. Names, UI row order and Analyzer element indices are not durable semantic identifiers. The layer-copy helper also participates in migration: independent duplication must clone editable documents, while migration must preserve their intended ownership.

## A03 — Analyzer integration exists, but its geometry scope differs

[analyzer-area.cjs](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/analyzer-area.cjs), `applyAnalyzerArea`, generates layer parameters for paths/point-radius masks. The final generated implementation appears around line 10830. [analyzer_area_bridge.inc](../../AminScatter/src/analyzer_area_bridge.inc), `cyrusAnalyzerArea_cf`, explicitly evaluates both path bands and point disks in world XY. The adapter returns original two-field rows.

Reuse this optional geometric input. Do not require Analyzer for every hand-drawn zone or Brush target, and do not equate its tilted-element support with a fully surface-aware Scatter Area adapter. Analyzer guides are derived outputs; a persistent artist zone can reference them but should own its semantic identity separately. Its README's obsolete statement that no scatter integration exists was corrected in this documentation pass.

## A04 — density maps exist, with resolution and dispatch limitations

[AminScatterObject.ms](../../AminScatter/scripts/AminScatterObject.ms), `cspImpl_placements`, lines 11436–11463, renders `densityMap` to 128 × 128 pixels, converts RGB to a scalar and passes it to the advanced generator. [max_bridge.cpp](../../AminScatter/src/max_bridge.cpp) reads a square 2–512 grid and requires surface UVs for density distribution. [scatter.cpp](../../AminScatter/src/scatter.cpp), lines 314–325, interpolates UVs and bilinearly samples the grid with coordinates clamped to [0,1].

This is an existing input mechanism, not an integrated painting system. There is no independent paint-overlay or editable stroke history in this path. It also renders the map within placement generation rather than a dedicated mask cache.

**Static dispatch concern:** the simple-transform branch condition around line 11456 does not test `distributionMode`. With `advancedAxes` disabled, Count population, no source weights/collision/relaxation/areas, one target and low diversity mode, the source can select `aminScatterTransforms`, which has no density-weight argument, despite computing map pixels above it. `advancedAxes` defaults true, so this is not a claim that all density-map scenes are broken. Reproduce this non-default configuration in Max before a fix, then add a focused regression covering both dispatch branches. Do not route future Brush through a bypassable UI convenience flag.

## A05 — current Count behavior is not paint thinning

[scatter.cpp](../../AminScatter/src/scatter.cpp), `scatter`, around lines 258 and 301–337, can allow up to count × 100 attempts for masks/density when `preserveDensity` is false. The UI sets that flag from plants-per-square-metre population mode. Source/transform generation and rejection happen in an ordered pipeline; simply attaching ordinal keys to surviving rows does not establish stable candidate identity.

For Brush-enabled layers, build the identified base independently of changing mask/zone membership and apply deterministic acceptance afterward. Keep existing disabled-mode behavior. Count means the documented base population/cap in the painted mode, not a demand to refill every erased plant. Changes to actual population/sampling recipes need explicit revision/rebind behavior. Density increases must be tested at new candidate anchors; a fixed-population lab proof does not establish stable extension at every capacity.

## A06 — provenance is lost at several bridges

[scatter.h](../../AminScatter/include/scatter.h), `Instance`, carries a triangle and source but no persistent candidate key or barycentric anchor. Target meshes are combined by the native bridge. `aminScatterAdvanced_cf` exports only transform/source rows. Final-pass import also constructs instances from those rows and supplies a placeholder triangle.

Keep an owned native `CandidateBatch` through the new path: target identity, canonical triangle/barycentric root, stable key, source identity, transform and population binding. Recompute provenance when a qualified operation moves a root. Expose legacy two-field rows only to consumers that need them. Arbitrarily appending a third field is incompatible with several `row->size == 2` checks and is not a complete migration. Trace blockers, final-pass recursion, source filtering, CS Edit, preview, render and bake independently.

## A07 — spacing has a reusable native broad phase, but raw blockers have limits

[max_bridge.cpp](../../AminScatter/src/max_bridge.cpp), `cyrusRemoveOverlaps_cf`, lines 100–141, bins blockers into spatial cells and supports XY or 3D centre-distance testing. In source-radius mode the rejection threshold is gap plus both per-instance radii. [radius.cjs](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/radius.cjs) defines artist source radii and optional scale following.

[AminScatterObject.ms](../../AminScatter/scripts/AminScatterObject.ms), `cachedBlockerRows`, around line 11400, calls `placements ... rawOnly:true`. The raw path includes area/falloff/source transforms but skips inter-layer overlap, final cleanup/relaxation and `CyrusEditApplyLayer`. The normal path applies the edit afterward, around line 11516. Therefore blocker locations can differ from final visible/edited locations. This is a source-level consequence, not a measured regression introduced by this review.

Immediately required for any Brush integration: filter raw blockers by Brush membership and key their caches by mask revisions, as the existing Brush plan requires. Separately, the proposed final-placement priority mode uses accepted edited blockers, pair-specific gaps and acyclic dependencies. Preserve legacy raw behavior; do not silently change saved scenes. A single source radius cannot simultaneously represent trunk, canopy and exact foliage intersections.

## A08 — CS Edit protects its binding; paint needs a new keyed entry

[edit.cjs](https://github.com/MehranCyrus/Cyrus-Scatter/blob/01a04b296247d2c1f4c2c36d0a2cd87fb188c2b2/AminScatter/tools/ui/edit.cjs), `CyrusEditApplyLayer`, fingerprints input rows with seeds and a layer index. [cyrus_edit_stack.inc](../../AminScatter/src/cyrus_edit_stack.inc), `cyrusEditStack_cf`, constructs IDs as `b:<incoming row index>`. `applyStable` marks changed signatures invalid; it already retains internal rows whose input IDs disappear.

The immediate risk is invalidating edits when mask filtering changes the input signature, not evidence that current code silently transfers an edit to the wrong plant. Add a keyed entry and a population binding that excludes mask-only membership revisions. Keep missing edited candidates dormant, with their original identity and copy lineage. Never suppress signature validation while retaining compacted ordinal IDs. Migrate only when correspondence is provable; otherwise preserve records and request an explicit rebind through the product UI.

## A09 — Brush storage is reusable; product ownership and overlay are incomplete

[brush.h](../../AminScatter/include/brush.h) defines strokes, surface anchors and the scalar-field interface independently of Max. The `PaintDocument` implementation formerly called `brush_lab.cpp` is now in [brush_host.cpp](../../AminScatter/src/brush_host.cpp); it supplies a native reference target, save/load/clone and stroke-level Undo integration. [brush_storage_plugin.cpp](../../AminScatter/src/brush_storage_plugin.cpp) supplies the registration companion. The following opt-in/UI observations describe this dated audit, not today's implementation; use the [0.73 implementation](../Unified_System_0.73_2026-10-06/IMPLEMENTATION.md) for current Brush ownership and controls.

Move the qualified document/session functionality behind layer ownership rather than copying the prototype's helper-window workflow into the product. Add independent target bindings, safe session end on layer changes, saved mask initialization and old-scene defaults. The current lab document binds one static mesh; multi-target product support still needs design and testing.

`PaintDocument::evaluate`, around line 155, creates the field and evaluates every candidate; its overlay takes a sparse subset of positive candidate samples. The mask itself exists independently, but the visualization is not continuous and can hide detail where no candidate is sampled. A black/white overlay must query the same field on an independent display domain.

## A10 — local evaluation is the next measured performance opportunity

[brush.cpp](../../AminScatter/src/brush.cpp), `Field::Impl`, indexes dabs by affected face. `evaluate` combines the strongest contribution within each stroke and then applies paint/erase in order. The lab rebuilds field state on revision changes, and Undo stores document copies.

Use a local dab index and affected-candidate cache before adopting GPU compute. Preserve reference agreement for surface connectivity, captured-view visibility, radius edits and ordered erasing. Do not confuse serialized bytes with peak RAM. The [earlier history probe](../Brush_Tool_2026-10-02/IMPLEMENTATION_2026-10-03.md) establishes a reason to optimize; no new speedup was measured here.

Retain separate committed, provisional and applied revisions. Include mask/zone/accepted-blocker/edit revisions in the right dependency keys rather than serializing histories into polling strings. Do not sample maps or replay fields from redraw callbacks. Manual preview/IR, final render and explicit bake must follow the existing Brush contract; previously baked scene nodes remain explicit artist-owned output.

## A11 — MCP has authored regions, not the unified zone editor

[panel.py](../../CyrusMCP/cyrus_mcp/panel.py) lets the artist pick a site, assets, planting splines and protected splines. [max_host.py](../../CyrusMCP/cyrus_mcp/max_host.py), `enroll`, supplies labels, polygons, area and opaque IDs within its bounded context. [models.py](../../CyrusMCP/cyrus_mcp/models.py) / [plan.schema.json](../../CyrusMCP/cyrus_mcp/plan.schema.json) accept one `region_id` per layer with count, seed, weighted assets, scale, yaw and underfill behavior, plus global clearance.

Reuse the boundary-validation and approved-plan workflow. The current schema does not accept procedural brush histories, scalar mask references, mesh-zone authoring, per-pair rules or existing artist-layer mutation. Region IDs from enrollment are not a substitute for persistent semantic zone records. The [MCP roadmap status](../MCP_Implementation_2026-10-03/ROADMAP_STATUS.md) remains authoritative for delivered scope; do not extend it merely by describing new fields in an AI prompt.

## Required interaction tests

These extend rather than replace the [Brush acceptance matrix](../Brush_Tool_2026-10-02/IMPLEMENTATION_PLAN.md).

| Case | Required observation |
| --- | --- |
| Two Include zones overlap in one layer | Union without double emission; Exclude still wins |
| Tree/shrub/grass zones overlap | Each layer retains its meaning; only configured footprint relationships remove candidates |
| Moved/deleted tree is a blocker | New priority mode follows its accepted final position/deletion; legacy mode remains documented |
| Painted mask removes an edited candidate | Edit becomes dormant; repaint/Undo restores the same ID and correction |
| Layer rename/reorder/delete/copy | Bindings follow identities; no accidental mask sharing or edit transfer |
| Large four-vertex plane, tiny stroke | Independent overlay and new sample queries show the same bounded paint |
| Curved, folded or stacked targets | Correct target/side, explicit projection behavior, no unrelated-surface flood |
| Gray mask with Count versus density | Stated thinning semantics; no replacement population outside an erased region |
| Simple/advanced density-map dispatch | Both supported routes honor the selected distribution |
| Topology change, missing target/map | Saved intent survives; invalidity is visible; no automatic name-based retarget |
| Long history and early-stroke edits | Indexed and exhaustive results agree; latency, allocations and Undo RAM recorded |
| Inactive navigation and display switches | No new mask/Analyzer/base-generation work; renderer population unaffected |
| Save/Open, clone/remap, Manual, render, bake | Correct committed/applied revisions and complete output snapshots |
| MCP stale plan or unauthorized artist edit | Rejected without changing authored inputs; approved operations use the same evaluator |

No production build or runtime tests were executed for this documentation review. The linked implementation reports contain earlier measured evidence and their qualification limits.
