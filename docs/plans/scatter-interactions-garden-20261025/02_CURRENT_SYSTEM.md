# Current implementation and integration gaps

## Evidence boundary

Source investigation used branch `codex/workflow-0.75`, HEAD `588abff0ce211d7dc63798b8c5310631895465c7`, with substantial pre-existing local changes preserved. The owned scene loads the exact extracted **0.86.9.2 Max 2027 package pair**, not the dirty generated working script. The packaged `CyrusScatter.ms` differs from the current generated source. Schema value 59 is a serialization identity, not a version label.

The knowledge corpus reported stale relevant source/foundation entries. Source was inspected directly; retrieved history did not establish current behavior. The live Scatter connector returned `OUTCOME_UNKNOWN` and no inspection scope. Host evidence therefore comes from owned Max 2027 scripts, not connector writes.

## Source map

| Boundary | Source inspected | Finding |
|---|---|---|
| Layer ownership and evaluation | `AminScatter/tools/ui/templates/unified-core.ms`: `newLayer`, `setLayerSurfaces`, `evaluateProcedural` | Ordered persistent layers own sources and receivers; complete root publication |
| Placement storage | `AminScatter/include/placement_store.h`: `Record`, `View`, `Token` | 96-byte native records; immutable views and bounded paging |
| Source correspondence | `AminScatter/include/placement_binding.h`: `SourceCohort` | Placement source ordinals must use their frozen ordered bindings |
| Source geometry | `AminScatter/src/source_geometry.inc` | Pivot-local extraction uses `objectTM * Inverse(nodeTM)`; source world placement is removed |
| Transform bounds | `AminScatter/include/procedural.h`, implementation of `transformScaleBound` | Conservative transformed bounds are available; a radius is not surface contact |
| Existing spacing | `AminScatter/src/source_clearance.cpp`; controller `procSetPair` | Own-copy, layer and external radius policies; separate from mesh bending/occupancy |
| Atomic result | `AminScatter/include/placement_publication.h`; `src/point_publication.inc` | Staged complete publication and retained display resources |
| Viewport geometry | `AminScatter/src/mesh_display.inc` | Shared source buffers plus per-placement matrix; no per-placement guide-pose input |
| Renderer | controller `CyrusPFBuild` | PFlow Shape_Instance prototypes deduplicated per source; transforms grouped through script arrays |
| Asset merge | `AminScatter/tools/ui/templates/recipes.ms`: `CyrusModelMerge` | Validates independent model/material graph; catalog remaps image filenames |
| Preparation host | `CyrusVegetationLab/experiments/stem-live/preparation_host.inl` | Eight-slot experimental catalog, copied snapshots, source fingerprint and explicit acceptance |
| Preparation inference | `.../analysis.cpp`, `analysis.hpp` | Ordered round-tube profile with grounded spatial branch forest; bounded topology |
| Fitting and delivery | `.../stem_core.cpp`, `plugin.cpp` | Independent prepared plant, single sphere, guide fit, cached preview/full geometry |
| Frozen core contract | `CyrusVegetationLab/core/include/cyrus_vegetation/prototype_v1.hpp` | Obstacle enum admits sphere and box; no arbitrary triangle-mesh obstacle API |

These are search anchors, not certification of every line or every working-tree edit. The evidence manifest pins the inspected files used for decisions.

## What can be reused

Scatter already has the right foundation for many copies: source bindings, native placement storage, stable identities, dependency keys, retained instanced display, Manual/Live rules and complete publication. The independent lab supplies source analysis, reviewed hierarchies, immutable numeric fitting, foliage bindings and an independent delivered-mesh audit. Keep these strengths and create explicit adapter boundaries.

## What is missing

1. **Per-placement state.** A Scatter plant is generally a native placement record, not an `INode`. The lab's single prepared object cannot be attached once per procedural row without creating a different, expensive architecture.
2. **Shared preparation.** The lab snapshots world-space source geometry and binds full mesh/part data per prepared object. Scatter needs a pivot-local immutable source definition reused across placements.
3. **Directional relationships.** Existing pair spacing is symmetric. An obstacle-to-reactor graph needs its own settings and dependency keys.
4. **Arbitrary stone contact.** The lab exposes only an admitted standard sphere. The reviewed A/B/C collision contract supports spheres/boxes. Jolt reuse does not make triangle-mesh signed occupancy, concavity or visible mesh contact delivered capabilities.
5. **Root cover.** Radius rejection can create a broad empty ring. Actual covered roots require an explicit policy; the baseline's static XY masks only illustrate one narrow case.
6. **Grass and tree preparation.** Both selected grasses need a blade/ribbon profile; phlox has unresolved elevated guides; the tree hits a topology budget. Raising caps alone does not supply correct trunk/branch/leaf inference.
7. **Unique posed geometry.** Viewport transforms alone cannot express different bends for copies of the same source. PFlow likewise shares one source shape. Both need a bounded posed representation.
8. **Contact quality.** Current capsule envelopes include foliage offsets and child-root envelopes; this explains visible clearance larger than the requested gap. Broad search radius, conservative guide envelopes and final surface gap must be independent.
9. **Lifecycle and delivery.** Scatter-integrated Undo, stale jobs, save/reopen, source editing, source-container membership, renderer parity and held-drag publication are not established by the standalone lab.

The [0.3.1 report](../../../CyrusVegetationLab/experiments/stem-live/REPORT_031.md) also records substantial stem triangle-edge strain under stronger bending and unresolved sustained held-mouse qualification. Its historical timing results remain single-plant evidence. No wind, plant self-collision or time-dependent dynamics should be inferred from a fast static fit.

## Contracts selected

Apply F01 ownership, F02 conditional identity/stability, F03 dependencies, F04 Manual/Live, F05 atomic publication, F06 bounded work/memory, F07 host-thread/lifetime, F08 reuse/display, F09 geometry, F10 units and F11 persistence from the [engineering foundation](../../ENGINEERING_FOUNDATION.md). F12 applies if Surface Analyzer publications are consumed. Required contracts are acceptance criteria, not an assertion that this proposal already implements them.
