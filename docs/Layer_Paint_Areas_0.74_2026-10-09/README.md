# Layer surfaces and Paint Areas â€” 0.74 development

9 October 2026. This supersedes the ownership decision left open in the October 8 UI report. Product/package version remains **0.74.0**, serialization **54**, calculation model **CyrusUnified1**. Exact script and native identities, rather than the caption, identify this build. No artist scene or normal installation was modified. Computer-use tools were not used.

## Installer

[Max 2027 development installer](../../dist/Layer_Paint_Areas_0.74_2026-10-09/Max2027/CyrusScatter-0.74.0-Max2027.mzp) · [exact package identity](PACKAGE.json). Run through Scripting > Run Script, then restart Max. Use a saved scene copy for artist acceptance. The matching script and all four native modules must travel together; the installed profile was not changed here.

## Artist workflow

1. Add/select a **Layer**, such as Grass.
2. Under **Surfaces**, add the receivers for that layer. Under **Models**, choose its source models. Set its count/density under Population. Ordinary scattering needs no Paint Area.
3. To restrict placement, open **Painting**, add a **Paint Area**, and choose its **Surface**. If the layer has exactly one receiver, it is selected automatically. Otherwise select the target explicitly.
4. Paint and Erase edit that selected area. Releasing the mouse does not create another area. Use **+** only to create another named area. Undo/Redo remains available; the individual saved-stroke editor is removed.
5. A second area may target the sphere while the first targets the plane in the same layer. Both use the layer's models/population. Areas do not allocate independent populations. Overlapping area weights combine by maximum and each candidate is accepted at most once.
6. Turn **Use Paint Areas** off to use the whole layer's receiving surfaces while retaining paint. With it on, empty or disabled areas permit no ordinary instances. Fill/Clear changes the selected area only.

Removing a target **from the receiver list** retains its area and document as inactive. Adding the same scene node back restores eligibility. Deleting the actual Max scene node is different: restoring its identity requires Undo or a saved scene; a newly created object with the same name is not the same receiver. An area containing strokes or filled coverage cannot be silently assigned to a different surface.

Strength and Softness affect the next brush action. Area density scales its coverage weight; it is not an independent count. Coverage tint/samples are feedback, not a promise that later spacing/cleanup accepts every point. The main panel, container editing view and popup use the same records. The popup's old model-group selector appears only for older multi-set layers.

## Completed checklist

- [x] Layers before Surfaces; new layers own receiver lists.
- [x] Models and population remain on the layer; no compulsory Paint Area for normal scatter.
- [x] Named optional areas under Painting with explicit receiver selection, enable, rename and remove.
- [x] Plane and curved sphere painting in one layer, including the actual Start Brush callback.
- [x] Union coverage without duplicate populations/instances; source selection does not follow area selection.
- [x] Remove/restore receivers, including all receivers, without discarding authored coverage.
- [x] Deep-copy paint documents with layer copy; retain target references.
- [x] Remove per-stroke editing controls; preserve native Undo/Redo and existing document data.
- [x] Preserve tested older single-set and multi-set 0.74 results; explicit **Use existing paint** for single-set coverage adoption.
- [x] Native exact-result brush query optimizations with reference comparisons.
- [x] Scripted Max checks for shared views, Manual/Live, Undo/Redo and save/reopen.

## What this batch does not complete

- [ ] **Canonical final-region storage / contour terrain brush.** Documents still preserve strokes internally. Hiding history is not claimed as a representation rewrite. Soft paint, erase, surface anchors and existing files remain exact; the native optimization avoids provably irrelevant evaluation, not every historical field build. The 150 ms feedback timer is unchanged. Full input-to-feedback latency and peak memory remain unmeasured.
- [ ] **Stable per-receiver sampling / incremental placement generation.** The combined sampler is unchanged. Adding/removing receivers can still move existing instances. Count and Density stability are separate engine work, as agreed for the next batch.
- [ ] **Converting old multi-set populations into the new single-population workflow.** These sets own models, budgets and collision relationships. They remain readable and retain their calculation; they are not silently flattened into regions. Adding Paint Areas is blocked for these older multi-set layers with an explanation. Existing model groups remain accessible in the popup. Complete conversion needs its own preservation tests.
- [ ] Physical dragging/visual/DPI acceptance, Max 2026 runtime, new renderer qualification and vendor-relative FPS. No computer-use interaction was performed.

Limits are explicit: ten populations remain the existing engine capacity; new area APIs bound a layer to 128 areas/receivers. They do not enable unbounded native work.

## Engineering changes

`regionSettings` is appended after existing parameter blocks. Area records are referenced MaxObjects, outside `layerObjects`, with independent IDs and documents; they never enter procedural population allocation. The layer stores a separate selected-area ID so browsing areas does not switch its model owner. Existing scene defaults retain old shared-receiver behavior until a layer's surfaces are explicitly edited. New layers own a snapshot of any explicitly preconfigured controller receivers; otherwise they start empty.

The native region filter maps concatenated candidate face anchors back to their receiver/local face, validates the target and document topology, combines weights by maximum, and retains each keyed candidate at most once. Face counts are cached with the candidate base rather than remeshing receivers on each mask application. Missing targets are skipped; mismatched active topology fails instead of transferring paint. Atomic procedural publication remains the existing mechanism.

The brush field evaluates the existing affine paint/erase composition in reverse order and stops only at exactly zero remaining transmission. A conservative bound of all brush footprints rejects points outside them before replay. Bounds account for nonuniform scale, shear and reflection. These are derived accelerations; the ordered reference evaluator remains the oracle. They do not modify serialized stroke bytes or claim a new contour brush.

The generated inventory/catalog has **232 semantic controls**. History controls, set weights/order/visibility and set-background authoring are explicitly retired from the new UI; historical control mappings document those removals. Source-container membership and retained viewport buffers are unchanged.

## Verification and reproduction

See [EVIDENCE.json](EVIDENCE.json) for exact identities, commands and saved witnesses. Native tests include mixed-strength paint/erase equivalence, opaque repeated paint/erase work bounds, outside-region rejection, sheared/reflected footprints, curved geometry and disconnected sheets.

The private Max fixtures are [Max_Layer_Regions_074.ms](../../tools/procedural_lab/Max_Layer_Regions_074.ms) and [the older-scene witness](../../tools/procedural_lab/Max_Layer_Regions_074_Legacy.ms). They require `MCPFixtureDir` under the owned qualification directory. Call `LRSetup`, `LRRun`, `LRViews`, `LRReopen`, then `LRAdditional`. The older witness creates files in a separate host with the frozen pre-area 0.74 script/native pair; the current host compares them before/after explicit adoption. Never run reset/load fixtures in an artist session.

Final qualification passed **45 ownership/painting checks**, **23 mounted grip controls** (8 main, 8 container, 7 popup), grip lifecycle and shared-view regressions, **14 native suites** and **141 Python tests**. Generator/catalog consistency also passed. Final source, package and loaded-module hashes agree.

The paired CPU benchmark evaluated 10,000 positions on a two-triangle plane with 1,000 identical hard strokes. Three warm-run medians: query time **485.9953 ms before / 3.8671 ms after**; field construction **0.6758 / 0.6847 ms**. Both accepted the same 316 positions with zero analytic error. This intentionally repetitive case benefits from outside-bound rejection and opaque composition; scattered/soft history and field construction still have costs. It is not an input-latency or vendor-speed comparison. Reproduce with [brush_region_benchmark.cpp](../../tools/procedural_lab/brush_region_benchmark.cpp), compiled against the frozen baseline/current `amin_scatter` libraries recorded in EVIDENCE.json.

Scripted callbacks establish owner binding and execution, not visual quality or physical stylus behavior. Unit-test timing is not viewport FPS. Raw scenes, modules and logs remain under ignored `build/`; installer binaries remain under ignored `dist/`.

## Next acceptance

Finish the stored-region design and benchmark brush feedback before describing painting as independent of accumulated history. Then address stable receiver sampling with the 20-to-21 Density/Fixed Total tests, reorder/save-reopen identity, collisions and per-stage counters. Do not substitute vendor behavior for these Cyrus acceptance tests.
