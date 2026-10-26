# Dense lavender / moving sphere — Max 2027 experiment

24 October 2026. **Result: dense geometry can react automatically, but this whole-clump preparation and full-resolution update path are not ready for fluid, natural Scatter interaction.** The core fit is cheap; source admission, dense deformation/verification, per-instance delivery and botanical preparation are the significant work.

This is a private experiment. CyrusScatter and the qualified Vegetation Lab 0.1.0 native/script pair are unchanged. No new production feature, installer, renderer support or research-matrix acceptance is claimed.

## Asset and controls

Selected the existing **A084 — Lavender 05**, after inspecting six real flower/grass/lavender models. It has **577,792 vertices / 832,240 triangles**, height 1.1946 m, and one combined geometry node. No subdivision, decimation or replacement primitive was used. The original file remains unchanged; SHA-256 `78e8b37e7f08c4a52050a4f274da5b6de3baad886b41b0327ffe69359a5e41a3`. See the [catalog source](F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusScatter-0.86.7-20261020/Content/Library/Models/Shrubs/A084 - Lavender - 05/model.max). Inventory: `build/vegetation-dense-inventory-20261024-01/inventory.tsv`.

The experiment bound all source vertices to one nine-node clamped guide, preserving topology, UV map topology and face material IDs in the copied mesh. It prepares immutable rest data once and always computes from that rest state. This deliberately coarse whole-clump mapping has only **1 vertex at the minimum-Z anchor plane**; it is not a rig defining every individual stem root. Source material/normal fidelity is not qualified: witnesses use a plain two-sided material and regenerated geometric normals.

The moving sphere has radius 0.1672 m, initially moves across the upper canopy, and requests 1 mm clearance. A separate 0.1 mm solver guard covers the bounded float conversion. The sphere is a moving contact probe, not a falling rigid body or a ground-settling test.

## A scaling failure found before bending

The original C render-ID uniqueness check is a nested loop in `CyrusVegetationLab/core/delivery/src/geometry.hpp`. For this asset it performs up to **166,921,508,736 ID comparisons**. The first owned Max attempt remained inside cold admission for at least **183.1 seconds**, was unresponsive, and was stopped using only its verified owned PID. Source inspection explains the quadratic scaling. Failure evidence remains at `build/vegetation-dense-live-20261024-02/hang-observation.json`.

An **experiment-only**, hash-pinned variant replaces that check with sorting a copied ID vector and checking adjacent duplicates. Original reviewed C sources stay untouched. The new ID buffer is 4,622,336 bytes for this asset (at most 16 MB in the private 2M-vertex profile); it is additional scratch, not a whole-process cap. A standalone execution admitted 577,792 IDs in about 15 ms. The original four C test groups plus a new large-ID/late-duplicate/zero-ID/order control passed **5/5 groups**, separately in the automated and pointer builds.

With the variant, preparation took **298.9 ms**. Full cold C realization took 176.4 ms and independent rest validation 226.7 ms. Source and binding admission belong in a reusable preparation cache, rather than being repeated for each drag sample.

## Full-resolution automatic movement

A native 16 ms main-thread timer observes the sphere pose and coalesces unchanged input. Seventeen direct poses and twelve event-loop-driven sphere movements were exercised. The latter issued no Fit/Update command inside their movement loop. The final run published **31 complete successors** across sweep/live/away/restore controls. Every published float mesh passed the probe's whole-triangle sphere check and minimum-Z anchor check before its output object was replaced.

| Phase | Median ms | P95 ms |
| --- | ---: | ---: |
| Jolt world + 9-node guide fit | 0.169 | 0.794 |
| 577,792-vertex deformation / float conversion | 41.042 | 62.319 |
| 832,240-triangle contact + edge-strain check | 54.665 | 61.455 |
| Max mesh copy / staging / bounds | 20.332 | 25.447 |
| Max output-object publication | 3.556 | 6.840 |
| Redraw request, deferred | 0.008 | 0.015 |
| Total native update | 130.944 | 145.932 |

The CPU update median corresponds to at most **7.6 updates/s before presentation costs**. This is **not presented FPS**. The redraw call is deferred and does not time actual GPU upload, draw completion or monitor presentation. Automatic request-to-redraw-request latency: median 144.4 ms, P95 502.7 ms; maximum 502.7 ms. No 30/60 FPS claim is supported.

Source preparation count remained one. Unrelated box movement left attempts and generation unchanged. Moving the sphere away restored the rest geometry to within 6.94e-18 m. Blocked-root and unsupported-scale controls retained the previous generation. The prototype still processes a whole mesh on changed sphere inputs even when the resulting pose is unchanged; broad-phase/pose-equality reuse is a clear missing optimization.

## Contact passes; natural vegetation does not

A separate exact C control found **94.7 mm penetration** in the original unbent plant at the chosen intrusive sphere pose. The bent candidate passed full independent C validation with zero reported penetration, and the cached sampler differed from C's double sampler by only 5.38e-08 m. The delivered float positions were separately checked by the probe against every triangle.

The first candidate audit correctly returned ResourceLimit: the 40,000 guide-query budget cannot admit 832,240 visible obstacle/triangle pairs. A fresh run used an explicit **842,240 pair audit budget**, separately from the guide's 40,000-query budget, and passed. Raising the declaration does not make those checks inexpensive.

The visible result is too conservative: the smallest accepted surface gap in the tested samples was **89.7 mm** despite a 1 mm target. The guide envelope reaches about 0.554 m radius and moves the entire clump. At the strongest sampled bend, up to **40.4% of tested face-edge occurrences changed length by more than 10%**, with a maximum relative edge change of 122.6%. Edges shorter than 10 micrometres are excluded; shared edges are counted per triangle. This is deformation evidence, not a physical material model. A contact/guide validation pass does not establish botanical realism.

Render witnesses use the same camera and full geometry, with the sphere farther away in Rest and closer in Bent:

![Original shape with sphere farther away](F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusVegetation-Dense-Live-Test-20261024/Rest.png)

![Coarse whole-clump bend with sphere nearer](F:/Cursor/_Cyrus_Apps/CyrusScatter/dist/CyrusVegetation-Dense-Live-Test-20261024/Bent.png)

## Physical pointer check

Computer Use targeted only the returned window titled **DVP_OWNED_POINTER_TEST_20261024.max**, in owned Max PID 14412. Three X-gizmo drags were performed. A deeper push at sphere core X ≈0.378 m reached the fitter's 800-iteration limit and retained the previous result. Moving back to X ≈0.581 m converged and visibly bent the plant; moving away to X ≈0.925 m restored its shape. The original source was never edited.

Instrumentation recorded **0 captures and 0 publications while the left button was down** for those drag-triggered updates. The observed successful updates were captured after release. **Continuous held-drag feedback is therefore unproven**, even though automatic updates after real pointer movement and between scripted pose changes work. The input stroke duration and Max interaction scheduling were not separately profiled, so these observations do not prove that Max intrinsically prevents continuous feedback. An interaction-aware continuous input hook and a longer held-drag witness are still required. Physical accepted updates are listed in `pointer-final.json`; this is not a passing smooth-drag qualification.

## What this means for CyrusScatter

Current source inspection shows why this is more than adding a Collider checkbox:

1. **Preserve placement and source instancing.** `AminScatter/include/point_preview.h` groups shared source triangles with instance matrices. `src/mesh_display.inc` reuses geometry/instance buffers, and `src/point_publication.inc` stages coherent successors. Updating a shared source mesh would bend every copy. Keep those placements/source caches intact and add per-affected-instance deformation state/delivery keyed by stable layer + instance + source revisions.
2. **Add explicit directional roles.** A stone layer supplies collider instances/proxies; a vegetation layer selects those collider layers and owns clearance/stiffness/preparation settings. Existing source-clearance rules govern acceptance/removal and should not silently become deformation rules. Roots and instance identities stay fixed.
3. **Use local active sets and recovery.** Broad-phase queries should consider plant bounds and collider influence, then perform narrow contact tests. Query the union of old/new affected regions so plants recover when the stone leaves. Skip unchanged poses and keep distant plants in the shared source stream. The present probe has only one plant, not a scalable layer spatial index.
4. **Prepare stems and attached parts.** This imported clump has no tested per-stem binding data. Multiple guides, true rooted stem groups and appropriate leaf/flower-head following are needed to avoid treating all branches as a wide tube. Reuse that preparation across instances. This is the strongest visual issue found.
5. **Separate interactive delivery from final quality.** Current 0.86.9.2 evidence distinguishes live Edit gizmo feedback from full mesh commit on release. Its generic Live node callback is batched with mouseUp:true / delay:150. Continuous collider interaction needs a dedicated bounded scheduling/presentation path. First measure a reduced interactive mesh/cage plus full-resolution refinement; only consider a shader deformation path if those measured costs still require it. Renderer/Bake output must consume the same accepted pose at full quality.

The next useful acceptance is one properly prepared multi-stem asset, one stone-layer/plant-layer dependency, a bounded nearby population, old-region recovery, a cheaper interactive representation, and measured updates **during a sustained physical drag**. This test does not authorize or implement that integration.

## Memory, identity and limits

`memory.tsv` samples whole-process Working Set and Private Bytes after load, preparation, cold control, sweep and finish; values include Max, plugins, original/output meshes, rendering and allocator retention. They are not VRAM or an isolated per-instance/peak-memory measurement. For the final run preparation added roughly 159.4 MiB Private Bytes over the loaded-source sample. Per-tick gesture Undo growth and lifecycle stress remain unqualified.

All execution used **Max 2027**, matched SDK, MSVC Release, the pinned Jolt commit and the separate private DLX. Automated and pointer host receipts verify loaded paths, script/native identity and an unchanged normal Max INI. Other artist windows/profiles were not mutated. Both owned processes quit after their fixtures completed. No integration/version bump/install into the artist profile was performed. Other renderer/material fidelity, multiple plants/stones, true dynamics, long drags, animation seeking and production-memory/Undo gates remain open. The research library's 68 cases and eight experiments retain their original Pending status.

Evidence roots: `F:\Cursor\_Cyrus_Apps\CyrusScatter\build\vegetation-dense-live-20261024-04`, `F:\Cursor\_Cyrus_Apps\CyrusScatter\build\vegetation-dense-pointer-20261024-01`, `F:\Cursor\_Cyrus_Apps\CyrusScatter\build\vegetation-dense-probe-20261024-05`, `F:\Cursor\_Cyrus_Apps\CyrusScatter\build\vegetation-dense-probe-20261024-06`. Full native/core identities, hang observation, sampler/triangle audit, raw timings and pointer records accompany this report. Baked witness scenes are at [bent scene](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-dense-live-20261024-04/Dense_Lavender_Bent_Max2027.max) and [restored scene](F:/Cursor/_Cyrus_Apps/CyrusScatter/build/vegetation-dense-live-20261024-04/Dense_Lavender_Restored_Max2027.max); they are ordinary scene snapshots, not self-installing live systems.
