# 04 — Scatter Core Engine

## Public API

`include/scatter.h` defines:
- `Vec3`, `Triangle`, `Range`;
- `Area`;
- `LineBand`;
- `Settings`;
- `Instance`;
- `BoundaryFalloff`;
- `FinalSettings`;
- `PreviewPoint`.

Public operations:
`scatter`, `finalize`, `boundaryFalloff`, `orientBoundary`, `edgeBorderPoints`, `prepareEdgeRows`, `sampleSource`, `pointCloud`.

## Scatter algorithm stages

`scatter()` performs validation, deterministic random-stream setup, surface-area sampling, masks/distribution, source/group selection, transforms, line/analyzer band assignment and optional spacing/collision.

Important design detail: separate RNG streams are used for placement, transforms, sources, distribution/scales/diversity. This preserves determinism when unrelated controls change.

### Surface sampling
The engine samples triangles by area rather than face count. Tests explicitly use a 1:9 area ratio to detect face-uniform bugs.

### Distribution
- 0: random;
- 1: clustered distribution/diversity behavior;
- 2: UV density using channel data supplied by the bridge.

### Areas
Areas are loop masks with include/exclude semantics. `preserveDensity` changes whether rejected candidates are refilled.

### LineBand kinds
Header comments define:
- 0 legacy spline;
- 1/2 Analyzer outer/inner border;
- 3 center;
- 4 radius;
- 5 single anchor;
- 6 is used by Edge Border preparation/processing.

Bands can restrict source groups/source IDs, scale ranges, inside/outside, masks, straight ends, outward facing, corner blending, local rotation, corner pinning, offset and jitter.

## Spacing/collision

`spacing.inc` uses:
- a spatial point grid;
- a triangle BVH/surface tree for reprojection;
- up to 128 neighbor visits per point/iteration;
- capped movement;
- optional normal-frame transport when the projected triangle changes.

Relax runs before collision thinning.

## Edge Border

`edgeBorderPoints()` creates ordered boundary samples independent of ordinary Count. It:
- computes perimeter spacing;
- supports edge masks;
- optionally pins corners based on turn angle;
- supports multiple samples per corner;
- applies deterministic along/across jitter;
- enforces a 500,000-point guard;
- deliberately keeps local offset as a later orientation-stage transform.

## Boundary/area falloff

`boundaryFalloff()` builds a segment tree and applies:
- delete band;
- deterministic density thinning;
- scale curve;
- optional side restriction for Area include/exclude behavior.

It never creates new points.

## Final cleanup/relax

`finalize()`:
- optionally removes sparse points/islands;
- projects movement back to the surface;
- preserves area/line/density constraints;
- respects blocker radii/gap;
- checks movement paths as well as endpoints;
- can preserve collision separation;
- keeps original count only when cleanup does not remove points.

## Orientation

`orientBoundary()` supports source forward axes +Y/-Y/+X/-X, outward boundary frames, corner blending, Edge Border local XYZ rotation, and final local forward offset.

## Design rule for licensing

Do not put provider SDK calls inside this core. Authorization belongs at the Max/native host boundary so the engine remains deterministic, testable and reusable.
