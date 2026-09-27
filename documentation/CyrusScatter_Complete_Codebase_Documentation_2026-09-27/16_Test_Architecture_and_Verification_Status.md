# 16 — Test Architecture and Verification Status

## CTest targets

Scatter:
- `scatter_core`
- `scatter_spacing`
- `scatter_weights`
- `scatter_orientation`
- `scatter_edge_border`
- `scatter_boundary_falloff`

Analyzer:
- `analyzer_core`

## Static test coverage observed

### scatter_core
Covers determinism, area-weighted triangle sampling, source distribution, prefix stability, transform independence, movement projection, normal alignment, preview budgets, XYZ scaling, density masks, clustering/diversity, Area include/exclude/hole behavior, density preservation, line/analyzer bands, single anchors, straight street caps, final cleanup and constrained relaxation.

### spacing
Relax energy reduction, deterministic relaxation, surface projection, collision separation/thinning, masks, line strokes, tilted surfaces, disabled compatibility and timing output.

### weights
Weighted source ratios, zero weights, all-zero behavior, grouped weights, stroke restrictions and negative-weight rejection.

### orientation
Forward axes, scale preservation, convex/concave/45° corners, masked street corners, holes, winding, tilted plane, Edge offsets, local rotation and blend behavior.

### edge border
Spacing, deterministic jitter, masks, count independence, collision/relax interaction, separate elements, corner pinning/count/angle and generation guard.

### boundary falloff
Delete/scale/density, deterministic monotonic thinning, holes/elements, Area side direction, world-XY projection and dense curves.

### analyzer_core
Connected mixed elements, global spacing, tiny-radius work guards, minimum-point override, fit radius, relax, rotated/tilted equivalents, auto modes, rectangle/star/hole cases, non-planar rejection.

## Important limitation

These tests were **read but not executed** in this documentation pass.

## Required pre-licensing runtime verification

1. configure/build Release with Max SDK;
2. run all CTests;
3. clean Max 2026 load;
4. open representative old scenes;
5. save/reopen without visual/count drift;
6. CS Edit legacy/current migration;
7. production render and cancellation;
8. Corona IR;
9. render worker/network path;
10. install/upgrade/uninstall;
11. regenerate MAXScript and verify deterministic diff.

Do not mark any of these “passed” until actual logs are captured.
