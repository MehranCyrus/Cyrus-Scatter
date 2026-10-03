# Procedural Brush: first implementation and evidence

3 October 2026. Base checkout: `b757b0f`. Production native version 0.64 and UI revision 2026-10-02.5 were the starting point. **An isolated M0/M1 prototype is implemented. Production integration and full milestone qualification remain open.**

The first demonstration works on a four-vertex plane and a sphere: paint, erase, adjust density, resize or disable an earlier stroke, Undo/Redo, copy, save and reopen. It uses the existing retained Mesh display for the cone preview. This work does not replace the production scatter sampler, viewport paths, layer manager or installers.

## Implemented behavior

- A native scene-owned `ReferenceTarget` stores a versioned stroke history and a real target-node reference. A custom attribute on a lab helper owns that document; the rollout does not own the paint.
- Each raw cursor sample records a triangle/barycentric anchor, projection ray, captured view and local-to-world metric. Radius edits resample and re-hit the original screen path. They do not draw a 3D chord through curved geometry.
- The core evaluates an editable field on the surface independently of existing plants and original vertex density. Connected footprint traversal, world-distance falloff and captured self-visibility restrict coverage. This is **not exact geodesic distance**.
- Paint and Erase are ordered operations. A stroke uses its maximum dab influence; separate strokes build coverage. Paint is `M + (1-M)*q`; Erase is `M*(1-q)`.
- A fixed 10,000-candidate population is thinned with stable per-candidate thresholds. Density/paint changes preserve surviving transforms and never refill erased areas elsewhere.
- A whole gesture is one Undo transaction. Earlier-stroke enable, strength and radius edits are undoable. Copied documents have independent histories; cloning a target together with its controller remaps the reference.
- Live preview is coalesced by a 250 ms rollout timer. Manual mode evaluates the bounded mask overlay but leaves plant buffers unchanged until Update. Stop respects that choice.
- Hidden, frozen, deleted, time-changed or geometry-changed targets invalidate the lab binding. A topology/shape change with existing paint rejects rebinding and preserves history. Translation can be explicitly revalidated. Scene open/reset ends painting; pre-save finishes valid provisional input before serialization.

The initial overlay consists of candidate-sampled dots; it is not a continuous painted heatmap. The lab displays one selected Brush layer at a time and uses a fixed cone source. Neither limitation belongs to the eventual product specification.

## Source map

| File | Responsibility |
| --- | --- |
| `AminScatter/include/brush.h`, `src/brush.cpp` | Host-independent surface/BVH, connected footprint, replay, stable acceptance and storage codec. |
| `AminScatter/src/brush_lab.cpp` | Optional Max Painter adapter, target lifetime, transactions, native saved document and diagnostic MAXScript API. |
| `AminScatter/src/brush_storage_plugin.cpp` | Registers the scene class through a companion DLH. |
| `AminScatter/tests/brush_tests.cpp`, `tests/data/brush_sphere_pole.txt` | Core tests and the actual Max sphere-pole numerical regression. |
| `tools/brush_lab/` | Build, private launch, UI harness, host fixtures and CPU history probe. |

`AMIN_BUILD_BRUSH_LAB` and `AMIN_BUILD_BRUSH_BENCHMARK` default to OFF. Core tests are available in ordinary native test builds. No production UI regeneration or installation was performed.

## Findings that changed the implementation

**Supplied triangulation alone does not make Painter's reported face an exact persistent anchor.** The grid probe found negative native barycentrics on 13 of 132 hits. Native reconstruction was close, but the largest native-vs-canonical hit difference was approximately 0.238 scene units near curved edges. Persistent anchors now use an exact BVH ray query against the same copied indexed mesh, checked against an exhaustive oracle. Painter still supplies interaction and the cursor; tiny-brush cursor correspondence near edges remains a qualification item.

**An exact nearest-distance tie exposed a BVH slab issue.** At the Max sphere pole, the old box test selected face 19 while exhaustive testing selected face 3 at the same ray parameter. Conservative box padding now accounts for triangle barycentric tolerance and floating-point error. The exported 1,106-vertex / 2,208-face mesh and ray are a regression fixture; both paths now select face 3.

**A DLX scripting extension is insufficient for saved scene class registration.** Early disposable fixtures could save a payload but could not reconstruct the document on load. The companion `CyrusBrushStorage.dlh` registers the descriptor, matching the existing production Edit plug-in pattern. The deliverable includes both DLLs. Early development scenes are not release artifacts.

**Clone references must follow Max's remapping lifecycle.** A controller-only copy keeps the original surface. A controller+surface copy uses a post-patch remapping callback. Cloning an external node reference unconditionally produced the wrong binding and was removed.

**Right-click exit requires an explicit Painter handler.** The no-argument `StartPaintSession()` does not promise exit behavior. The final adapter supplies `IPainterRightClickHandler` and cancels provisional input through the same guarded stop path.

These are findings from local SDK sources and actual fixtures, not deductions about competitors' private implementations. Relevant public interfaces: [Painter V7](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_painter_interface___v7.html), [Painter Canvas V5](https://help.autodesk.com/cloudhelp/2027/ENU/MAXDEV-CPP-API-REF/class_i_painter_canvas_interface___v5.html), and [MAXScript plug-in development](https://help.autodesk.com/cloudhelp/2024/ENU/Max-Developer-Help/writing_plug-ins/writing_maxscript_plug-ins.html).

## Measured and verified scope

The native build has **11 suites: all passed under both SDK configurations**. The Brush unit suite covers opacity, ordered erase, repeat callbacks, radius replay, capture metrics, thin disconnected sheets, self-visibility, deterministic thresholds, indexed/reference agreement, malformed storage and the pole regression. Max 2026 was compile/native-test qualified only; its application is not installed here.

Max 2027 fixtures used private binaries and recorded actual loaded module paths. Primary host run `acceptance-g` produced:

| Check | Result |
| --- | --- |
| Real mouse painting | 545 flat-surface plants; 196 curved-surface plants; one stroke each. |
| Picking grid | 132 hits over plane/sphere and top/perspective views; canonical BVH and exhaustive face/distance agreed. |
| Whole mouse gesture Undo/Redo | Empty after Undo; exact original transforms after Redo. |
| Earlier stroke radius edit | Curved count reduced from 196 to 85 at radius 8; Undo restored exact transforms. |
| Disable stroke | Empty mask; Undo restored original result. |
| Density 0.5 | 96 survivors, each at its original transform; restoring 1.0 recovered all 196. |
| Manual real erase gesture | 196 to 145; survivors unchanged; mask evaluated; **zero plant uploads** through Stop. Explicit Update published it. Undo/Redo matched. |
| Warm inactive navigation | 20 scripted orbit redraws: **zero additional field builds/queries and zero Brush-caused preview publication/uploads**. This is a work-counter assertion, not an FPS guarantee. |
| Copy and target lifecycle | Independent controller copy; pair-copy target remap; hide/delete stopped the session; pending-input Stop preserved committed paint. |
| Target edits | Translation followed after explicit bind; changed sphere segmentation suspended/rejected binding; restoring original shape recovered paint. |
| Fresh-process reopening | Both original counts and transform signatures matched in `reopen-h`; final candidate uses `acceptance-i`. |

The final right-click handler is a host-only follow-up to run g. Its evidence and final binary hashes are recorded separately so earlier results are not mislabeled as having run on an identical DLL.

Core correctness cases do not substitute for the complete Max wall/terrain/folded-surface/multiple-viewport matrix. Same-topology deformation, mirrored/nonuniform placement orientation, merge, layer deletion during a native mouse drag, save/autosave mid-drag and production Undo callbacks need additional host tests. The programmatic pending-input cancellation test is not a hardware mouse-drag cancellation test.

## Performance result and next optimization

A CPU-only Release smoke probe evaluated 10,000 fixed grid candidates on a four-vertex plane. Each history entry contained **one dab**, with alternating paint/erase semantics. These are single-run wall times on the development machine, with Max sessions open, not controlled statistical benchmarks:

| History | Distributed: query time | Overlapping: query time |
| --- | ---: | ---: |
| 10 strokes | 3.08 ms | 7.57 ms |
| 100 strokes | 41.90 ms | 70.88 ms |
| 1,000 strokes | 333.46 ms | 657.44 ms |

At 1,000 strokes, append followed by full rebuild/evaluation took approximately 314 ms distributed and 797 ms overlapping. Serialized intent was 260,016 bytes. This is not total RAM: indices, snapshots, resampled dabs, candidates and Undo copies add memory. All six cases matched 65 reference queries exactly. See [raw history results](evidence/2026-10-03/history.csv).

This exposes a useful limitation: indexing only by affected **face** is coarse on a huge triangle. Many distant dabs still share that face, and each edit currently rebuilds/replays the field over all candidates. The prototype is responsive for its short demonstration strokes but **is not qualified for long-history or heavy-scene painting**. A 250 ms UI timer is also not a measured input-to-visible latency target.

The next performance loop should compare a small spatial index of dab bounds within coarse faces, cached weights for the touched candidate region, and append-only active-stroke scratch against this exact replay oracle. Earlier-stroke edits need ordered replay of the affected union. Measure long paths as well as single dabs. Optimize one measured cost, retain all correctness fixtures, then address Undo memory: the current restore records copy the paint document per operation.

No CUDA/OpenCL, worker threads, source-mesh regeneration scheme or new GPU display engine was added. Ordinary post-Brush navigation consumes the existing retained display. That protects the previous viewport architecture while the new painting costs become measurable.

## Next integration boundary

1. Qualify remaining M0/M1 geometry, lifecycle and interaction cases; improve the sparse overlay and long-history costs.
2. Carry native candidate keys and anchors through the real pipeline before Brush compaction, then apply Brush before raw blockers and final operations. The prototype's original candidate index is stable only within its fixed isolated population.
3. Add controls through the authoritative UI generator; keep old scenes Brush-disabled by default. Implement keyed CS Edit and render/bake/Manual revision rules from the integration audit.
4. Test supported combinations in actual Max 2026 and 2027, including old scenes and render/export paths, before distributing a production Brush build.

Use the [lab instructions](../../tools/brush_lab/README.md) to reproduce or try the prototype. The [implementation plan](IMPLEMENTATION_PLAN.md) remains the full acceptance contract; this report records partial completion rather than replacing that contract with a smaller success claim.
