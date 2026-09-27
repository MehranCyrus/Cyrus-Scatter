# 11 — Cyrus Surface Analyzer Internals

## Native API

`analyzer.h` defines:
- `V`;
- `Mesh`;
- `Settings`;
- `Result`;
- `analyze(const Mesh&, const Settings&)`.

Settings include mode, raster resolution, point count/minimum, width/length, ring fraction, point radius, fit radius and relax iterations.

Result includes boundaries, paths, points, per-element modes/counts/relax flags, area, region area, path length and aggregate mode.

## Connected elements

`elements.cpp::elements()` groups faces connected through shared topology edges and remaps each group to its own mesh. Holes remain in their element.

## Per-element analysis

`analyzeElement()`:
1. validates nonempty/manifold/open boundary topology;
2. computes face area and averaged normal;
3. extracts welded boundary loops;
4. constructs a local planar basis from the longest boundary edge;
5. rejects non-planar geometry beyond tolerance;
6. rasterizes interior/clearance;
7. auto-classifies radial / orthogonal / general modes unless mode is forced;
8. generates a ring, largest interior rectangle centerline, or thinned/pruned skeleton;
9. converts local paths back to world space.

## Point sampling

Outer `analyze()`:
- applies global spacing across elements;
- samples paths according to point radius;
- guards against extreme candidate counts;
- applies fit-radius boundary clearance;
- if minimum points are requested and normal radius sampling yields too few, minimum count has explicit priority and can replace that element's samples;
- aggregates per-element results.

## Scripted object

`CyrusSurfaceAnalyzer.ms` class:
- name `Surface Analyzer`;
- class ID `#(0x45a201c7,0x1829bc63)`;
- category `Cyrus`;
- version 13.

`runAnalysis()` calls `cyrusAnalyzeSurface`, flattens boundaries/paths into tab data, computes optional Street Side edges, stores stats and increments `analysisRuns`.

## Realtime lifecycle

- NodeEventCallback with 150 ms mouse-up delay;
- 250 ms .NET timer;
- live input signature;
- render flag suppresses realtime updates during render;
- redraw callback renders boundary/path/street/point overlays.

## Export

Analyzer can create:
- boundary splines;
- center-path splines;
- Street Side splines;
- Point helper objects.

## Scatter integration

Scatter consumes Analyzer-published properties for:
- Border/inner border;
- Centerline;
- Points/single anchors;
- Street Side;
- Edge Border;
- Analyzer Area masks;
- boundary falloff;
- street-layout offset/trim.
