# Cyrus Surface Analyzer 0.14

0.14: general model/display notifications no longer trigger analysis; geometry, topology, transforms, stack changes and parameter changes still update.

Realtime analysis waits for mouse release. Internal Cyrus PFlow deletion events no longer trigger a redundant analysis. Native engine remains bin05.

3ds Max 2026: Create > Geometry > Cyrus > Surface Analyzer.
Independent native C++ analysis engine with a MAXScript Modify panel.

## Controls

- **Fit radius** replaces Min width in the UI. A disk of this radius around every accepted point must fit inside its element, clear of both exterior edges and holes. It is a hard geometric constraint in the element plane. Zero disables footprint clearance. New nodes default to 0.5 metres; old scene Min width migrates to half that value. The legacy parameter remains serialized but is no longer used by UI analysis.
- **Point radius** controls centre-to-centre separation. This is independent of Fit radius. It does not mean disks must be non-overlapping.
- **Min points** is a total minimum per element. Zero keeps radius-only spacing. The minimum can reduce Point radius separation (marked `*`), but never violates Fit radius. If no eligible space remains, no point is fabricated; the UI reports an unmet minimum.
- **Relax steps**, 0–200, controls a bounded iterative constrained Laplacian solver on the clipped guide paths. It reduces raster zigzags; points are then redistributed and exact boundary clearance is rechecked. Zero disables relaxation. This is geometric guide relaxation, not a physical simulation or globally optimal point packing. Rings retain their circular form.
- **Ring factor** controls the preferred ring radius as a fraction of centre clearance. Fit radius can shrink it further so point footprints fit.
- **Min length** retains the existing path/region length filter. Resolution (48–768) controls raster analysis precision and cost.
- **Update > Manual** preserves output until Analyze. **Real-time** updates geometry, topology, transform, time and setting changes using source events (150ms delay) and a 250ms main-thread timer. Idle inputs do not recompute. Analysis pauses during rendering and never runs from viewport drawing.

## Elements, geometry and results

Each edge-connected mesh element is analyzed independently before plane fitting and boundary extraction. Attached elements may have different heights or orientations. Holes remain within their element. Vertices must be welded; proximity does not join separate topology. Individually nonplanar elements, closed solids and invalid boundaries are rejected with their element index. A failed update preserves the prior cache.

Auto chooses a principal straight region for approximately orthogonal boundaries, a ring for balanced radial stars, or branched paths otherwise. Minor short edges and small edge-angle deviations no longer automatically force the branched method. Manual method overrides remain available; Auto is a heuristic and cannot infer every design intention.

Straight regions use an approximate largest raster rectangle in a basis aligned with the longest boundary edge. Branched paths come from raster thinning. Fit radius clips guides, relaxation reduces small bends, and a final analytic point-to-boundary test checks every accepted point, including minimum-count replacements. Very narrow features can be missed by raster resolution. The eligible region need not be fully covered, and some branches can receive no points due to separation from other branches/elements.

Surface area is the sum of world-space triangle areas. Overlapping faces are not unioned. With positive Fit radius, Region area is the raster estimate of feasible point-centre area. With Fit radius zero, it retains the mode-specific rectangle/disk/width-filter region measure. Path is aggregate guide length. Areas display in square metres using scene system units.

## Output and persistence

Boundary/path/point toggles draw cached results. Explicit spline/helper exports create independent snapshots, not live links. Source meshes are not modified. Cached results, update mode and settings persist in MAX files. Nodes and guides are schematic and non-rendering. Cyrus Scatter can reference Analyzer paths and sample points through its Area controls; that Scatter adapter evaluates path bands and point-radius masks in world XY, even though Analyzer itself supports separately oriented planar elements. See the [artist-zone integration audit](../docs/Artist_Zones_Integration_2026-10-03/CODEBASE_AUDIT.md#a03--analyzer-integration-exists-but-its-geometry-scope-differs) for the current source scope and proposed extensions.

Keep versions' binary folders separate and restart Max after installation. Source scene files are never overwritten by installation. Extremely small Point radius values exceeding the candidate budget are rejected explicitly. C++ analysis remains single-threaded and synchronous; large meshes/many elements/high resolution can still pause the UI.

## Build and checks

Build Release x64 with Visual Studio 2022, CMake and the Max 2026 SDK (`MAXSDK_ROOT`). Run analyzer_tests. Installer payload consists of the DLL, script, README and installer files.

Tests cover attached mixed elements, radius exclusion, minimum overrides, hard Fit radius after Relax and minimum replacement, tilted surfaces, holes, slightly non-orthogonal straight regions and impossible footprints. Real Max tests validate final boundary distances, UI, live updates, idle behavior and saved settings. The supplied three-shape scene is used only in separate test processes and copied preview outputs.
