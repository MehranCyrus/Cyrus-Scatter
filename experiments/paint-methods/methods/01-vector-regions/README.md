# A — Vector Regions

**Hypothesis:** resolving brush input into closed borders is a strong fit for terrain planting regions and editable landscape design. It must demonstrate its editing cost on complicated drawings. **Status: initial 0.1.0 slice built and tested.** [Results and remaining gates](../../results/0.1.0-2026-10-10/README.md).

The implemented slice saves current Clipper2 contours/holes, unions/subtracts variable-radius sweeps, queries polygon inclusion and displays the canonical border. It supports dedicated Undo/Redo, cancel, external save/load and common CPU preview. Contour queries currently scan paths; indexed border distance, spline interchange and fade are not implemented. It rejects the sphere/fold domain. The brief below is the design target, not a claim that every extension exists.

## Representation and workflow

Save oriented closed contours, holes, receiver identity, fixed projection frame, coordinate precision and optional boundary-fade settings. The contours are authoritative. Old gestures are not replayed to answer coverage queries.

Convert brush movement into a swept 2D footprint. Union it into the current region for Paint; subtract it for Erase. Begin with a pinned public integer polygon Boolean implementation. Bound circle approximation by world-space error rather than blindly copying Forest's observed vertex count. Use local coordinates and validate integer range. Keep a tentative gesture result with one Undo snapshot and commit atomically.

Show the resulting border immediately. Query inclusion against indexed contours; index nearby segments for optional distance-to-border density. Expose import/export of closed Max splines once basic editing works. Re-import after explicit spline editing rather than introducing fragile bidirectional callbacks in the first slice.

## First usable slice

- One plane, hard Paint/Erase, radius, clear, Undo/Redo, outline and fixed candidate points.
- Islands, holes, crossed strokes and erase cuts with unambiguous winding/fill rules.
- Frozen precision in physical units; explicit error if the requested scene scale exceeds its range.
- Counts/timings for changed contours, total vertices, Boolean work, query work and display upload.

Next: terrain projection, spline interchange, adjustable inner/outer boundary fade and representative fill. Choose and qualify a separate fill triangulation path; current Clipper2 upstream warns about its triangulation implementation. Do not let that unqualified component undermine a Boolean comparison.

## Why this could win

An artist edits the planting border directly. Repeated paint inside a solid region need not accumulate query history. A region can naturally become a spline and participate in include/exclude composition. Smooth interior density near the border can be defined separately from brush history.

## Risks and limits to expose

Boolean cost depends on contour complexity and intersections, not just stroke count. Thousands of islands or sawtooth borders can still become expensive. Simplification must respect the declared error and preserve holes/features; never simplify until it merely looks fast. Quantization can lose tiny features. Undo contour snapshots may dominate memory.

A single projected frame cannot distinguish the front/back of a sphere or stacked parts of one folded surface. The initial supported domain is terrain or a surface single-valued in the chosen frame. Split receivers do not automatically fix overlap within one receiver. Mark unsupported cases clearly instead of guessing a height.

Boundary fade is not a replacement for painting arbitrary grayscale values inside a region. Test these as separate capabilities. Fade outside the border also requires querying candidates outside it; an exclusion remains authoritative.

## Decision gates

- Growing-area scribble retains every component at the declared tolerance.
- Query cost follows current border complexity rather than accumulated redundant gestures.
- Spline round-trip and hole orientation survive within the stated approximation.
- Boolean, fill and Undo work stay inside the agreed interaction budget on representative terrain.
- Reject as a universal solution if freeform support requires inventing an untested surface parameterization.

Implementation: [vector.cpp](src/vector.cpp), [generated window](scripts/Launch.ms), shared [native tests](../../tests/core_tests.cpp) and [Max tests](../../tests/host_tests.ms). Shared contracts and test IDs are in the [implementation](../../docs/IMPLEMENTATION_PLAN.md) and [test](../../docs/TEST_PLAN.md) plans.
