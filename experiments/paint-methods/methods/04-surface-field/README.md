# D — Baked Surface Field

**Hypothesis:** keeping current paint values directly on surface patches gives history-independent queries and avoids projection ambiguity on curved objects. **Status: initial 0.1.0 storage slice built and tested; planned surface-distance footprint is missing and the connected-fold gate fails.** [Results](../../results/0.1.0-2026-10-10/README.md).

Current values live in sparse face-local grids independent of original vertex density. Hard/soft painting, a maximum-influence gesture stencil, copy-on-write history, save/load, coarse-plane detail and tested sphere paint/erase exist. A host-discovered diagonal seam was repaired and regression-tested. The footprint is currently connectivity/normal-restricted Euclidean, not geodesic; separate face storage does not prevent fold leakage. Face scans, mixed-resolution seams, deformation following and retained display need further work. The design below describes those targets rather than completed capabilities.

## Representation and workflow

Save receiver identity/topology, current values in sparse triangular face tiles, physical resolution metadata and adjacency/seam rules. Address locations by face plus barycentric coordinates. This is neither a world-projected mask nor a replay of recorded brush volumes. It requires no artist-authored UV layout.

Do not store values only at the receiver's existing vertices: a two-triangle plane must support a small brush. Allocate finer samples within faces independently of the artist's mesh density. Begin with uniform resolution per face chosen from its world dimensions, then add bounded sparse subdivision only if measured memory needs it. Large faces must not force one monolithic allocation; tiles subdivide their barycentric domain.

Map a hit to its face; traverse neighboring affected patches to update the swept footprint. For the first planar slice, use the same geometric footprint as A/B/C. For freeform work, implement and qualify surface-distance propagation across adjacent faces rather than claiming a 3D radius automatically follows the surface. Boundary samples/gutters must agree across face edges, including different patch resolutions. Freeze allocation resolution during a gesture; explicit refinement preserves existing values within a tested error bound.

Use the common soft gesture stencil and changed-block Undo. Candidate queries read local field values without old strokes. Extract the boundary from the current field and update only affected display chunks. Save canonical values; stroke logs may be retained as optional diagnostic traces but cannot be required for evaluation.

## First usable slice

- Two-triangle plane, hard paint/erase, sub-face detail and a diagonal seam crossing.
- Same plane triangulated differently; quantify output differences within tolerance.
- Tile allocation/query/Undo/upload counters.
- Sphere crossing many face edges, then thin folded surface and mixed-size triangles.

Next: soft painting, stable-topology deformation, robust seam refinement, serialization and nonuniform scale. Non-manifold edges need an explicit policy; start by treating ambiguous branches as barriers and report that limitation.

## Why this could win

Current-state queries do not depend on stroke count. Front and back have distinct surface addresses. Deformation can carry paint without reprojecting it from a single plane. Houdini's cached attribute workflow and per-face texture concepts support exploring this direction, but neither proves this proposed implementation will be fast.

## Risks and limits to expose

This is the most complex initial kernel: seam handling, distance propagation and resolution allocation may outweigh its benefits. Tiny triangles and huge triangles present different memory problems. Same face count does not establish a valid saved field after topology changes. A deforming surface can stretch the field's physical resolution even when the values remain attached.

Do not silently bake a coarse approximation to make tests fast. Account for all tiles, stencils, adjacency, Undo and peak publication buffers. No complete Ptex dependency is planned for the first slice; its per-face mapping is an architectural reference, not an off-the-shelf brush solution.

## Decision gates

- A tiny brush works on a coarse plane without modifying the receiver mesh.
- Equivalent surface triangulations agree within the declared error band.
- No seam cracks or front/back leakage in the qualified footprint mode.
- Queries remain independent of redundant history; affected-area edit costs stay acceptable.
- Topology changes suspend paint safely; unchanged-topology deformation preserves its attachment.

Implementation: [field.cpp](src/field.cpp), [generated window](scripts/Launch.ms), shared [native tests](../../tests/core_tests.cpp), [fold diagnostic](../../tests/diagnostics.cpp) and [Max tests](../../tests/host_tests.ms). See the [common plan](../../docs/IMPLEMENTATION_PLAN.md) and [tests](../../docs/TEST_PLAN.md).
