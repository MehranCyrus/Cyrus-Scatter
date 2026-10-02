# Procedural Brush evidence and final review

Reviewed 2 October 2026. Revision 3.1 retains the Houdini/Blender/Unreal research and native Painter source inspection, with a further [codebase integration audit](CODEBASE_INTEGRATION.md) of caching, metadata transport, Manual mode, rendering, persistence, Undo and generated UI.

The [decision guide](README.md) states the recommendation. The [implementation plan](IMPLEMENTATION_PLAN.md) owns all proposed behavior and experiments. This file records evidence; no competing implementation plan is maintained here.

## Primary external sources

The observations below are documented behavior or named source inspection. Cyrus's formulas, data model and integration choices are proposals.

| ID | Primary source | Verified observation and limit |
| --- | --- | --- |
| H01 | [SideFX Attribute Paint](https://www.sidefx.com/docs/houdini/nodes/sop/attribpaint.html) | Caches paint evaluation and retains stroke history. Distinguishes volume, surface and screen shapes, plus visibility restrictions. Visible-only checks use rays and have a cost. Attribute painting's deformation correspondence depends on consistent point numbering. This is not a ready-made arbitrary-mesh field for Cyrus. |
| H02 | [SideFX Stroke](https://www.sidefx.com/docs/houdini/nodes/sop/stroke.html) | Stores stroke parameters and samples including projection information, primitive identity and parametric hit coordinates. Parametric coordinates are distinct from texture UVs. |
| H03 | [SideFX Scatter](https://www.sidefx.com/docs/houdini/nodes/sop/scatter.html) | Documents scatter-on-rest then interpolation for fixed-topology deformation. Provides primitive seeds and output IDs. Point order can change independently of position. Forced total count uses density as relative distribution, which differs from reducing total coverage. |
| H04 | [SideFX Attribute Interpolate](https://www.sidefx.com/docs/houdini/nodes/sop/attribinterpolate.html) | Interpolates using primitive/parametric locations or explicit point weights. It does not establish arbitrary retopology correspondence. |
| H05 | [SideFX HeightField Paint](https://www.sidefx.com/docs/houdini/nodes/sop/heightfield_paint.html) | Caches painted volumes and exposes recaching after upstream changes. Notes high-resolution display cost and possible dropped stroke samples. A fast field evaluator alone is not enough for responsive authoring. |
| H06 | [SideFX terrain masks](https://www.sidefx.com/docs/houdini/heightfields/masking.html) | Named masks can be painted, derived from terrain features, combined and reused downstream. |
| H07 | [SideFX Scatter and Align](https://www.sidefx.com/docs/houdini/nodes/sop/scatteralign.html) | Separates density, spacing and exact-count controls; density painting can influence distribution. |
| H08 | [SideFX Attribute Remap](https://www.sidefx.com/docs/houdini/nodes/sop/attribremap.html) | Range/ramp operations alter an attribute without repainting its input. |
| H09 | [SideFX Spray Paint](https://www.sidefx.com/docs/houdini/nodes/sop/spraypaint.html) | Point spraying can itself be procedural, with adjustable rate/stroke settings and separate random seeds. Density-area painting is chosen because of the owner's requested workflow. |
| H10 | [SideFX state Undo](https://www.sidefx.com/docs/houdini/hom/state_undo.html) | Groups a drag spanning callbacks into one Undo operation and separates incidental guide changes from user edits. |
| H11 | [SideFX state events](https://www.sidefx.com/docs/houdini/hom/state_events.html) | Explicit interruption/resumption handles focus loss, viewport departure and temporary tools; mouse-button tracking needs interruption handling. Max requires its own corresponding lifecycle implementation. |
| B01 | [Blender 4.5.0 distribution source](https://github.com/blender/blender/blob/v4.5.0/source/blender/nodes/geometry/nodes/node_geo_distribute_points_on_faces.cc) | The inspected Poisson path samples a maximum-density population, removes close points, then applies density-factor rejection. It hashes barycentric coordinates for rejection and combines barycentrics/triangle index for output IDs. Compaction can reorder output. This is precedent for stable thinning, not proof of collision-free identity or topology-independent stability. |
| U01 | [Epic PCG generation modes](https://dev.epicgames.com/documentation/en-us/unreal-engine/using-pcg-generation-modes-in-unreal-engine) | Partitioned/hierarchical generation can share coarser results with smaller cells; the documentation warns about duplicated data across grid levels. Useful if later measurements justify partitioning, not a reason to adopt a world-generation framework now. |
| K01 | [Krita opacity and flow](https://docs.krita.org/en/reference_manual/brushes/brush_settings/opacity_and_flow.html) | Distinguishes per-stroke opacity from per-dab flow and wash from buildup modes. This highlights the need to define Cyrus's stroke semantics; it does not supply our surface algorithm or formula. |
| A01 | [Autodesk Painter V5](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_painter_interface___v5.html) | Exposes session/picking, point-gather toggles and mesh-cache updates. Native brush availability is not a measured scalability result. |
| A02 | [Autodesk Painter V7](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_painter_interface___v7.html) | Allows supplied ObjectStates for hit meshes and provides a right-click session handler. This offers a concrete way to probe common triangulation with Cyrus. |
| A03 | [Autodesk Painter canvas](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_painter_canvas_interface___v5.html) | Supplies hit node/face/barycentric data and stroke lifecycle callbacks. Warns that hit mesh correspondence can differ across modifier-stack levels. |
| A04 | [Autodesk RestoreObj](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_restore_obj.html) | Defines Undo/Redo restoration, repeated-call robustness and approximate memory size reporting. |
| A05 | [Autodesk rendering process threading](https://help.autodesk.com/cloudhelp/2026/ENU/MAXDEV-CPP-API-REF/class_max_s_d_k_1_1_rendering_a_p_i_1_1_i_rendering_process.html) | States that the SDK is generally not thread safe and most scene operations belong on the main thread. This source's render-job mechanism is not prescribed as a Brush scheduler. |
| A06 | [Autodesk reference management](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_ref_mgr.html) | ReferenceTarget/reference-remapping facilities support host ownership and cloning. Cyrus's particular holder must still be tested. |
| A07 | [Autodesk scripted plugin clauses](https://help.autodesk.com/cloudhelp/2024/ENU/MAXScript-Help/files/MAXScript-Tools-and-Interaction/Creating-MAXScript-Tools/Scripted-Plug-ins/GUID-461915FA-31A2-49CE-84AF-2544B782ACA3.html) | Documents persistent parameter-block names and the maxObject parameter type. Schema names, reference cycles and migration need deliberate handling. |

The inspected SideFX pages identify Houdini 22.0; the retrieved Epic page identified 5.8. B01 is intentionally pinned to 4.5.0, not called Blender's latest release. English Blender manual retrieval failed, including a repeat attempt in this pass; the specific distribution conclusion uses accessible official source instead.

To reproduce B01 inspection, read `sample_mesh_surface`, `distribute_points_poisson_disk`, `update_elimination_mask_based_on_density_factors` and `compute_attribute_outputs`. Vendor code was studied as evidence, not copied into Cyrus.

Earlier workflow comparisons remain useful but do not resolve our implementation: [Forest Paint areas](https://docs.itoosoft.com/forestpack/forest-plugin/areas) have a documented XY surface-mode requirement; a direct-instance brush is also a different product contract from this requested editable density mask.

## Local Autodesk SDK inspection

Both installed SDKs contain Painter headers and native examples. The 2026/2027 `include/IPainterInterface.h` files have identical SHA-256:

```text
b6d984fb5f5e880c5770878e0134a96bbe968b9bba86ac9c91974986cc9de7dc
```

Local root pattern: `build/tooling/max<year>-sdk/Program Files/Autodesk/3ds Max <year> SDK/maxsdk/`. SDK source is local tooling, not redistributed in the documentation package.

| ID | File / symbol inspected in the 2027 SDK | Observation |
| --- | --- | --- |
| S01 | `samples/PainterInterface/PointGatherer.cpp`, `AddWeightFromSegment` | Clears counters over point arrays, uses spatial cell lists, then scans the point arrays to test gathered entries. Spatial acceleration here does not eliminate full-set bookkeeping. Its distance-to-segment weighting does not by itself implement our connected visible surface contract. |
| S02 | `samples/PainterInterface/painterInterface.cpp`, `HitTest`, `UpdateMeshes`, `UpdateMeshesByObjState` | View transform/viewport-size changes invoke mesh-tree updates. The inspected update paths free/rebuild search caches; the ordinary path evaluates target objects. Disabling point gathering does not remove picking rebuilds. |
| S03 | `include/IPainterInterface.h`, V7 methods; corresponding implementation | Supplied ObjectStates offer control over hit geometry. Keep owned backing objects alive and exercise repeated view updates/end-session; do not rely on a temporary callback-local object remaining valid. |
| S04 | `howto/PainterInterface/PaintDeformTest/PaintDeformTestPainterInterface.cpp` | Demonstrates stroke-level hold/accept/cancel integration. Its mesh refresh behavior serves a deformation example and is not automatically necessary for a static mask brush. |

These are observations about supplied SDK code, not proof that a loaded Autodesk binary has identical cost. M0 must measure entry, warm picking and picking after orbit with the installed build. The recommendation to disable point gathering is a probe configuration, not a verified optimization result.

## Local Cyrus integration findings

Inspected HEAD: `1bfb400abc19b7472b4c20621970d435ac214c33`, with concurrent uncommitted retained-display work. That commit alone does not identify every inspected file. Re-read these integration points when coding.

| ID | Source and symbol | Finding / implication |
| --- | --- | --- |
| C01 | [max_bridge.cpp](../../AminScatter/src/max_bridge.cpp), `meshOf` / `surfaceMeshes`; [scatter.h](../../AminScatter/include/scatter.h) | Concatenated triangles lose explicit per-target provenance; Instance has triangle/source but no persistent candidate key or barycentric anchor. Brush needs those data paths. |
| C02 | [scatter.cpp](../../AminScatter/src/scatter.cpp), `scatter`; [generated placements](../../AminScatter/scripts/AminScatterObject.ms), `cspImpl_placements` | Rejections influence later sequential random-stream consumption. Existing density mode caps requested candidates at 100,000. A separate Brush acceptance stage preserves the existing base for mask-only edits. |
| C03 | [edit.cjs](../../AminScatter/tools/ui/edit.cjs), `CyrusEditApplyLayer`; [cyrus_edit_stack.inc](../../AminScatter/src/cyrus_edit_stack.inc), `cyrusEditStack_cf` / `applyStable` | The entry point creates b:ordinal IDs and the caller fingerprints compacted rows with a layer index. The internal stack already retains rows whose input IDs disappear, useful for a future keyed entry path; current bindings do not make Brush compatible automatically. |
| C04 | [preview_sampling.h](../../AminScatter/include/preview_sampling.h), `previewPointIndex`; [preview.cpp](../../AminScatter/src/preview.cpp), `aminScatterBuildPreview_cf` | Preview samples depend on total population and ordinal position. Removing a plant can alter sample selection elsewhere. The preview API validates a 500,000-point maximum. |
| C05 | [storage.ms](../../AminScatter/tools/ui/templates/storage.ms), `syncLayerSurface`, `newLayer` | Controller surfaces synchronize to layers; independent paint-target subsets and proper paint-document copy handling are required. Current controller limit is ten layers. |
| C06 | [overlaps.cjs](../../AminScatter/tools/ui/overlaps.cjs); [performance.cjs](../../AminScatter/tools/ui/performance.cjs); [final.cjs](../../AminScatter/tools/ui/final.cjs) | Blockers use cached rawOnly placements. Final cleanup/relaxation uses a finalPass recursion that returns early. A filter placed only at the end misses important consumers. |
| C07 | [retained-points.cjs](../../AminScatter/tools/ui/retained-points.cjs) | Held-input scheduling and completed-cache publication need an active-paint path. Local field work does not establish partial GPU publication. |

Selected SHA-256 values at this inspection:

```text
src/scatter.cpp
16e56f583cf608b23a29e2d07608e5b68bfec36de7f3035ebe510ed59987fe7f
src/cyrus_edit_stack.inc
53d689602439f0f956a643b0f0ccc561247b82d6b162d6a067073abe1e23a6ab
src/max_bridge.cpp
7fecb26bc4c785a947689fdb07d7ce487d503049f232089162279af30c243aa9
```

Paths in this hash block are relative to `AminScatter/`. Hashes record inspected source, not loaded-plugin identities.

## Conclusions from different engineering perspectives

| Perspective | Consequence for the chosen design |
| --- | --- |
| Artist intent | Preserve editable coverage when plant models/density change. A mask overlay explains sparse or pending preview results. |
| Geometry | Face correspondence, radius metric, connected footprint and visibility are separate problems. A normal under the cursor solves only part of them. |
| Procedural evaluation | Cache results while retaining the recipe; arbitrary new queries must remain meaningful. |
| Sampling/statistics | Stable thinning changes membership without refilling. It gives neither an exact final count nor maximally packed painted regions. |
| Integration | Raw blockers, moving final passes, CS Edit and preview selection have distinct order/identity requirements. |
| Interaction | Stroke opacity differs from callback/dab accumulation. Interruptions must close the transaction predictably. |
| Performance | Picking, history replay, mask queries, base generation and buffer publication need separate measurements. |
| Reliability | Source history survives invalid caches, missing targets and unsupported versions. Failed updates must not become silently different output. |

The research supports these architectural decisions; it does not determine a universal fastest data structure. A spatial index plus exact stroke-field evaluation is a modest first implementation. A sparse surface atlas, independent evaluation mesh, tiled generation or multithreading remains conditional on measurements.

## Corrections and work status

Revision 3 replaces the previous maximum-only paint blend with bounded per-stroke opacity, fixes the proposed pipeline position, chooses a reproducible target-local visibility scope, and separates placement identity from preview identity. It also makes same-topology shape changes unsupported in the first static version instead of implying that a topology fingerprint alone solves deformation.

The former E01–E10 experiments are retained in the [single acceptance matrix](IMPLEMENTATION_PLAN.md#7-acceptance-and-measurement-matrix); E11–E14 cover opacity/input sampling, interruption/failure handling, cross-layer/edit integration and preview stability.

This pass read primary documentation and local implementation, consolidated the plan and checked documentation consistency/links. It did not modify production code, launch or benchmark a Brush implementation, install a plugin, or edit the artist scene. No unchecked implementation milestone is a completed result.

The follow-up source audit records CB01–CB09 separately to keep this vendor/source ledger concise. Its proposed changes are incorporated into the same M0–M3 milestones and E01–E14 matrix. Existing monitor, native threading and lifecycle-test facilities are reuse opportunities; they have not been run as Brush tests.
