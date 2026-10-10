# C — Surface Stroke Volumes

**Hypothesis:** spatially indexed, mesh-anchored analytic brush segments may give accurate queries and useful curved-surface painting without raster storage. This is an alternative to test, not an excuse to retain Cyrus's current evaluator. **Status: initial 0.1.0 slice built and tested; connected-fold surface-distance gate fails.** [Results](../../results/0.1.0-2026-10-10/README.md).

The implemented slice saves ordered analytic sweeps with anchors/world positions, rebuilds a BVH at gesture completion and supports hard/soft chronological queries. It paints/erases on the tested sphere but leaks across a connected fold. Anchors are recorded; deformation following is absent and receiver edits suspend data. Undo copies operation/index state. The shared CPU preview derives a resolved 50% contour. The brief below remains a design target; it does not establish retained display or suitable long-history latency.

## Representation and workflow

Save ordered gestures with receiver identity, topology signature, face/barycentric anchors, segment radii and operation. Reconstruct positions from receiver geometry; build bounds around swept segments and a spatial index. Implement ordinary capsule/variable-radius sweep mathematics independently using public algorithms.

For hard coverage, find relevant operations and resolve the latest covering operation. Do not test every recorded gesture for every candidate. Identical or provably redundant operations may be removed only with an equivalence check; do not assume every old stroke can be discarded. The initial spatial index can be a simple static hierarchy plus an active-gesture buffer, with rebuilding cost reported separately.

Show a derived resolved border and optional fill on the receiver. Their extraction is part of the method's cost, not free: drawing every capsule outline would show internal overlaps, while centerlines do not show painted coverage. Use spatially bounded adaptive surface cells for derived display, with a declared geometric tolerance and persistent unaffected chunks. These cells are not canonical storage. Do not reuse the existing budget-truncated Cyrus overlay.

## First usable slice

- Hard paint/erase on the common plane; anchor storage; indexed queries; correct chronology.
- Degenerate segments/single clicks, variable radius, repeated crossings and an erase hole.
- Separate counters for total segments, tested segments per query, index preparation, border extraction and upload.
- Then a sphere and folded mesh before claiming general curved-surface support.

Soft chronological blending is a later, separately timed capability. It can require visiting more operations than hard last-hit queries, particularly in heavily overlapping areas.

## Why this could win

Canonical coverage is analytic rather than resolution-limited. Anchors can follow unchanged mesh topology. Sparse strokes may remain compact, and spatial indexing can skip distant input. The existing Chaos investigation supports this family as a serious candidate, but does not establish its performance for our workload.

## Risks and limits to expose

Overlapping strokes defeat spatial culling and can make work grow with history. Efficient query does not imply efficient resolved-boundary drawing. Deformation requires updated segment bounds. Long world-space chords can cut through a curved receiver between sparse hits; input must subdivide/reproject or break those spans.

**A Euclidean capsule can reach the back of a thin or folded surface.** Receiver identity prevents leakage to other receivers, but not within the same mesh. First measure this behavior explicitly. Then test an authored local face patch / surface-distance restriction if needed, identifying the changed semantics and cost. Connected-component and normal-angle filters alone do not solve every fold. Do not call such a filter geodesic.

## Decision gates

- Hard query oracle passes; overlapping operation order is exact.
- Growing history and growing spatial coverage are tested independently.
- Boundaries remain complete and match queries at the stated display tolerance.
- Thin/folded mesh tests pass under a clearly declared footprint mode, or the limitation disqualifies that workflow.
- Reject if solving history cost requires replacing its authoritative representation with B/D; record that as a different method rather than hiding it.

Implementation: [volumes.cpp](src/volumes.cpp), [generated window](scripts/Launch.ms), shared [native tests](../../tests/core_tests.cpp), [fold diagnostic](../../tests/diagnostics.cpp) and [Max tests](../../tests/host_tests.ms). See the [common plan](../../docs/IMPLEMENTATION_PLAN.md) and [tests](../../docs/TEST_PLAN.md).
